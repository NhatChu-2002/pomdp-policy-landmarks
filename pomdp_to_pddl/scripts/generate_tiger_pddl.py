#!/usr/bin/env python3
"""
generate_tiger_pddl.py
======================
Reads a Tiger POMDP policy trace CSV and auto-generates:
  - <output_prefix>_domain.pddl
  - <output_prefix>_problem.pddl

CSV format (no header):
  TRACE, episode, action, obs, belief_left, belief_right

Actions: listen, left, right
Obs:     left, right

Usage:
  python3 generate_tiger_pddl.py tiger_policy.csv [output_prefix]
"""

import sys
from collections import defaultdict

# -----------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------
TAPE_LENGTH  = 28   # t0..t28
STEP_COUNTER = 6    # k0..k6


# -----------------------------------------------------------------------
# BELIEF -> FSC NODE
# -----------------------------------------------------------------------
def belief_to_node(b_left):
    b = round(b_left, 3)
    if abs(b - 0.5) < 0.02:  return 'b0'
    if b > 0.5:
        if b >= 0.99:  return 'bl3'
        if b >= 0.93:  return 'bl2'
        return 'bl1'
    else:
        if b <= 0.01:  return 'br3'
        if b <= 0.07:  return 'br2'
        return 'br1'


# -----------------------------------------------------------------------
# PARSE CSV
# -----------------------------------------------------------------------
def parse_csv(path):
    episodes = defaultdict(list)
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            p = line.split(',')
            ep     = int(p[1].strip())
            action = p[2].strip()
            obs    = p[3].strip()
            b_left = float(p[4].strip())
            episodes[ep].append({'action': action, 'obs': obs, 'b_left': b_left})
    return episodes


# -----------------------------------------------------------------------
# DERIVE FSC
# -----------------------------------------------------------------------
def derive_fsc(episodes):
    """
    Walk all episodes and build the complete FSC.

    Key rules derived from the Tiger reference encoding:
      1. listen transitions are extracted directly from belief-level changes
      2. For each depth-2 node (bl2, br2), add the SYMMETRIC contradicting
         obs branch that steps back to depth-1 of the same dominant side:
           bl2 --listen/right--> bl1
           br2 --listen/left-->  br1
         This matches the reference encoding exactly.
      3. Only bl3 and br3 are terminal open-door nodes.
         bl2 and br2 are listen nodes, not open nodes.
    """
    listen_transitions = {}  # node -> {obs: next_node}
    open_nodes         = {}  # node -> 'open_left' | 'open_right'
    all_nodes          = set(['b0'])

    for ep, steps in episodes.items():
        for i, s in enumerate(steps):
            cur    = belief_to_node(s['b_left'])
            action = s['action']
            obs    = s['obs']
            all_nodes.add(cur)

            if action == 'listen' and i + 1 < len(steps):
                nxt = belief_to_node(steps[i+1]['b_left'])
                all_nodes.add(nxt)
                if cur not in listen_transitions:
                    listen_transitions[cur] = {}
                listen_transitions[cur][obs] = nxt

            elif action in ('left', 'right'):
                # Only add open_door if this node doesn't already have both
                # listen branches (i.e. it is truly a terminal node)
                # bl3/br3 are terminal; bl2/br2 are listen nodes
                if cur in ('bl3', 'br3'):
                    door = 'open_right' if s['b_left'] > 0.5 else 'open_left'
                    open_nodes[cur] = door

    # ---------------------------------------------------------------
    # SYMMETRY FIX: add missing obs branches for depth-2 nodes
    # bl2 --right--> bl1  (already in trace usually)
    # br2 --left-->  br1  (often missing from trace, add explicitly)
    # This matches the reference encoding exactly.
    # ---------------------------------------------------------------
    if 'bl2' in listen_transitions and 'right' not in listen_transitions['bl2']:
        listen_transitions['bl2']['right'] = 'bl1'
        all_nodes.add('bl1')

    if 'br2' in listen_transitions and 'left' not in listen_transitions['br2']:
        listen_transitions['br2']['left'] = 'br1'
        all_nodes.add('br1')

    # Ensure bl3/br3 are in all_nodes if they appear as open nodes
    for n in list(open_nodes.keys()):
        all_nodes.add(n)

    return {
        'listen_transitions': listen_transitions,
        'open_nodes':         open_nodes,
        'all_nodes':          all_nodes,
    }


# -----------------------------------------------------------------------
# GENERATE DOMAIN PDDL
# -----------------------------------------------------------------------
def gen_domain(fsc, domain_name):
    listen_trans = fsc['listen_transitions']
    open_nodes   = fsc['open_nodes']

    L = []
    def w(s=''): L.append(s)
    def c(s):    L.append(f'  ;; {s}')

    w(f'(define (domain {domain_name})')
    w('  (:requirements :strips :adl :negative-preconditions :typing)')
    w()
    w('  (:types node tape tag direction)')
    w()

    # predicates
    w('  (:predicates')
    w('    (at ?n - node)')
    w()
    w('    ;; Step counter')
    w('    ' + ' '.join(f'(k{i})' for i in range(STEP_COUNTER + 1)))
    w()
    w('    ;; Tape')
    w('    (tape-at ?t - tape)')
    w('    (next ?t ?tp - tape)')
    w('    (consumed ?t - tape)')
    w()
    w('    ;; Belief direction — k(left)/k(right) and k-not(left)/k-not(right)')
    w('    (k ?d - direction)')
    w('    (k-not ?d - direction)')
    w()
    w('    ;; Tiger position tags')
    w('    (tiger-left  ?g - tag)')
    w('    (tiger-right ?g - tag)')
    w()
    w('    ;; Confirmation')
    w('    (confirmed ?g - tag)')
    w('    (tiger-confirmed)')
    w()
    w('    ;; Commitment flags — produce disjunctive landmarks')
    w('    (belief-committed)')
    w('    (negbelief-committed)')
    w()
    w('    (done)')
    w('  )')
    w()

    # --- LISTEN ACTIONS ---
    c('=================================================================')
    c('LISTEN ACTIONS')
    c('Two outcomes per node (left obs / right obs)')
    c('Each pair produces one SIZE-2 disjunctive landmark on FSC nodes')
    c('=================================================================')
    w()

    for node in sorted(listen_trans.keys()):
        trans = listen_trans[node]
        for obs in ('left', 'right'):
            if obs not in trans:
                continue
            next_node = trans[obs]
            if obs == 'left':
                k_set='left';  k_clr='right'; kn_set='right'; kn_clr='left'
            else:
                k_set='right'; k_clr='left';  kn_set='left';  kn_clr='right'

            c(f'listen at {node}, obs={obs} -> {next_node}')
            w(f'  (:action pi_listen_{node}_{obs}')
            w(f'    :parameters (?t ?tp - tape)')
            w(f'    :precondition (and')
            w(f'      (not (done)) (at {node})')
            w(f'      (tape-at ?t) (next ?t ?tp) (not (consumed ?t))')
            w(f'    )')
            w(f'    :effect (and')
            w(f'      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)')
            w(f'      (not (at {node})) (at {next_node})')
            w(f'      (k {k_set}) (not (k {k_clr}))')
            w(f'      (k-not {kn_set}) (not (k-not {kn_clr}))')
            w(f'    )')
            w(f'  )')
            w()

    # --- BELIEF COMMITMENT ---
    c('=================================================================')
    c('BELIEF COMMITMENT')
    c('Produces: disj {k(left), k(right)}')
    c('=================================================================')
    w()
    w('  (:action commit-belief-left')
    w('    :precondition (and (k left) (not (belief-committed)))')
    w('    :effect (belief-committed)')
    w('  )')
    w()
    w('  (:action commit-belief-right')
    w('    :precondition (and (k right) (not (belief-committed)))')
    w('    :effect (belief-committed)')
    w('  )')
    w()

    # --- NEG-BELIEF COMMITMENT ---
    c('=================================================================')
    c('NEG-BELIEF COMMITMENT')
    c('Produces: disj {k-not(left), k-not(right)}')
    c('=================================================================')
    w()
    w('  (:action commit-negbelief-left')
    w('    :precondition (and (k-not left) (not (negbelief-committed)))')
    w('    :effect (negbelief-committed)')
    w('  )')
    w()
    w('  (:action commit-negbelief-right')
    w('    :precondition (and (k-not right) (not (negbelief-committed)))')
    w('    :effect (negbelief-committed)')
    w('  )')
    w()

    # --- OPEN DOOR ACTIONS ---
    c('=================================================================')
    c('OPEN DOOR ACTIONS')
    c('Requires both commitment flags, advances k counter, resets belief')
    c('=================================================================')
    w()

    for node in sorted(open_nodes.keys()):
        door = open_nodes[node]
        k_req  = 'left'  if door == 'open_right' else 'right'
        kn_req = 'right' if door == 'open_right' else 'left'

        c(f'{door} from {node}')
        w(f'  (:action pi_{door}_from_{node}')
        w(f'    :precondition (and')
        w(f'      (at {node})')
        w(f'      (k {k_req}) (k-not {kn_req})')
        w(f'      (belief-committed) (negbelief-committed)')
        w(f'      (not (done))')
        w(f'    )')
        w(f'    :effect (and')
        w(f'      (not (at {node})) (at b0)')
        w()
        for i in range(STEP_COUNTER):
            w(f'      (when (k{i}) (and (not (k{i})) (k{i+1})))')
        w()
        w(f'      (not (k left)) (not (k right))')
        w(f'      (not (k-not left)) (not (k-not right))')
        w(f'      (not (belief-committed))')
        w(f'      (not (negbelief-committed))')
        w(f'    )')
        w(f'  )')
        w()

    # --- CONFIRMATION ---
    c('=================================================================')
    c('CONFIRMATION')
    c('=================================================================')
    w()
    w('  (:action check-tiger-via-belief')
    w('    :parameters (?g - tag)')
    w('    :precondition (and')
    w('      (not (done))')
    w('      (belief-committed) (negbelief-committed)')
    w('      (not (confirmed ?g))')
    w('    )')
    w('    :effect (confirmed ?g)')
    w('  )')
    w()
    w('  (:action confirm-all-tags')
    w('    :precondition (and')
    w('      (confirmed tagL) (confirmed tagR)')
    w('      (not (tiger-confirmed))')
    w('      (belief-committed) (negbelief-committed)')
    w('    )')
    w('    :effect (tiger-confirmed)')
    w('  )')
    w()

    # --- FINISH ---
    c('=================================================================')
    c('FINISH')
    c('=================================================================')
    w()
    w(f'  (:action finish')
    w(f'    :precondition (k{STEP_COUNTER})')
    w(f'    :effect (done)')
    w(f'  )')
    w()
    w(')')

    return '\n'.join(L)


# -----------------------------------------------------------------------
# GENERATE PROBLEM PDDL
# -----------------------------------------------------------------------
def gen_problem(fsc, problem_name, domain_name):
    all_nodes = fsc['all_nodes']
    all_nodes.add('b0')

    L = []
    def w(s=''): L.append(s)

    w(f'(define (problem {problem_name})')
    w(f'  (:domain {domain_name})')
    w()
    w('  (:objects')

    # nodes: b0 first, then bl*, then br*
    node_list = sorted(all_nodes, key=lambda n: (
        0 if n == 'b0' else
        1 if n.startswith('bl') else
        2
    ))
    w('    ;; FSC nodes derived from policy trace')
    w('    ' + ' '.join(node_list) + ' - node')
    w()
    w('    ;; Tape')
    w('    ' + ' '.join(f't{i}' for i in range(TAPE_LENGTH + 1)) + ' - tape')
    w()
    w('    ;; Tags')
    w('    tagL tagR - tag')
    w()
    w('    ;; Directions')
    w('    left right - direction')
    w('  )')
    w()
    w('  (:init')
    w('    (at b0)')
    w('    (k0)')
    w('    (tape-at t0)')
    for i in range(TAPE_LENGTH):
        w(f'    (next t{i} t{i+1})')
    w('    (tiger-left  tagL)')
    w('    (tiger-right tagR)')
    w('  )')
    w()
    w('  (:goal (and (done) (tiger-confirmed)))')
    w(')')

    return '\n'.join(L)


# -----------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------
def main():
    if len(sys.argv) < 2:
        print('Usage: python3 generate_tiger_pddl.py <trace.csv> [output_prefix]')
        sys.exit(1)

    csv_path = sys.argv[1]
    prefix   = sys.argv[2] if len(sys.argv) > 2 else 'tiger_policy'

    domain_name  = f'{prefix}_fsc_nd'
    problem_name = f'{prefix}_run_nd'

    print(f'Reading: {csv_path}')
    episodes = parse_csv(csv_path)
    print(f'Episodes: {sorted(episodes.keys())}')

    fsc = derive_fsc(episodes)
    print(f'FSC nodes:  {sorted(fsc["all_nodes"])}')
    print(f'Open-door:  {sorted(fsc["open_nodes"].keys())}')
    print(f'Listen nodes: {sorted(fsc["listen_transitions"].keys())}')

    domain_pddl  = gen_domain(fsc, domain_name)
    problem_pddl = gen_problem(fsc, problem_name, domain_name)

    domain_path  = f'{prefix}_domain.pddl'
    problem_path = f'{prefix}_problem.pddl'

    with open(domain_path,  'w') as f: f.write(domain_pddl)
    with open(problem_path, 'w') as f: f.write(problem_pddl)

    print(f'\nWritten: {domain_path}')
    print(f'Written: {problem_path}')
    print()
    print('Expected disjunctive landmarks:')
    seen = set()
    for node, trans in sorted(fsc['listen_transitions'].items()):
        targets = sorted(set(trans.values()))
        if len(targets) > 1:
            key = tuple(targets)
            if key not in seen:
                seen.add(key)
                print(f'  disj {{{", ".join(f"at({t})" for t in targets)}}}')
    print('  disj {k(left), k(right)}')
    print('  disj {k-not(left), k-not(right)}')

if __name__ == '__main__':
    main()

# Lab notebook: POMDP policy landmarks

One entry per experiment or attempt, newest last. Each entry says what was tried,
what came out (with the result file), what we learned, and whether it belongs in
the paper. Add an entry right after every run, including failed and negative ones.

Verdict tags: **PAPER** (in the paper), **SUPPLEMENT**, **LESSON** (changes how we
work or what we claim), **DROP** (tried, not worth reporting), **OPEN** (unresolved).

---

## 2026-11-24

### E1. Hand-written belief-state controllers (v1/v2 paper)
- Tried: hand-written K/N/U controllers for Tiger, Channel, Mine, Sensor, RockSample-4;
  RHW landmarks; exhaustive ground truth; FSC and "gate" ablation; induction from
  SARSOP traces; 33 mutants.
- Result: all landmarks sound. Reviews (ARS panel, two independent): 4/10, because
  faithfulness to the solver's policy was assumed and false for Sensor/RockSample,
  and landmarks could be read off the commitment rules.
- Learned: an encoding that adds its own steps (gates) produces plausible but wrong
  landmark graphs (Tiger/Channel/Mine got identical graphs).
- Verdict: **LESSON** + one paragraph in the paper ("the encoding must not add
  structure"). Hand-written controllers otherwise **DROP**.

### E2. Exact policy-graph extraction from SARSOP (v3 core)
- Tried: `pomdp/extract_policy_graph.jl` enumerates all beliefs a SARSOP policy
  reaches; evidence-level abstraction; compile to STRIPS; RHW.
- Result: 25 policies (Tiger 0.6-0.95, Sensor 0.75-0.95, Channel, Mine 2x2/3x3,
  RockSample 4x4 x5, 5x5 x3, 7x8). `results/extracted.json`.
- Learned: faithful by construction; theorem "landmark iff reached with probability 1
  given termination (injective abstraction)" is a known Markov-chain fact (Baier &
  Katoen 2008) applied to the policy graph: present it as such.
- Verdict: **PAPER** (Section 3).

### E3. Exact value check of extracted graphs
- Tried: compute the exact discounted value of each graph and compare with SARSOP's
  value at b0 (`extraction.policy_value`).
- Result: 21/25 equal to 3 decimals; 3 RockSample above SARSOP's lower bound (not
  converged); Mine-3x3 -13.2 vs bound 0.38.
- Learned: this is the strongest evidence that the graph IS the policy. Keep it for
  every new graph.
- Verdict: **PAPER** (RQ1).

### E4. Mine-3x3 termination (first wrong claim)
- Tried: Gauss-Seidel first-passage solver -> P(term)=0.26; then exact linear solve
  -> P(term)=1 with 7.6e10 expected steps.
- Result: BOTH wrong. Reviewer B found 7 self-loops from merging beliefs at 1e-9;
  simulation with exact beliefs (`pomdp/simulate_policy.jl`, 2,000 runs): return
  -13.4 +- 0.3, 26% of runs end, all commits to cells 5 or 8, 60% stuck probing a
  value believed > 0.9999.
- Learned: (1) iterative solvers on near-absorbing chains silently under-converge:
  use exact linear solves; (2) belief merging can create loops: log lossy merges;
  (3) check surprising numbers by simulation before writing them.
- Verdict: **PAPER** (defective-policy finding, simulation numbers) + **LESSON**.

### E5. Re-review of v3
- Result: A 4/10, B 5/10. Main objection: on an explicit graph the planner is
  unnecessary; exact graph search gives complete landmarks.
- Verdict: **LESSON** -> reframe (v4): exact extraction is the main tool, RHW a
  comparison.

### E6. Exact landmark extraction (`policy_landmarks/exact.py`)
- Tried: search on the explicit state graph; single facts and same-predicate
  disjunctions (first capped at 3 facts, later complete for belief/commitment groups).
- Result: 489 minimal landmarks over 25 policies; most are mixed-level belief
  disjunctions (146) and route alternatives (150) that restate the chain.
  Kept classes (single facts, one-strength and one-direction belief disjunctions,
  commitment disjunctions): 193 exact, RHW 167 (87%). `results/exact.json`, `kept.json`.
- Learned: "complete" landmark sets are verbose; a readable graph needs a class
  filter, and the filter must be stated. RHW missed all commitment disjunctions until
  the encoding kept commitment facts (FD's translator drops facts no action needs).
- Verdict: **PAPER** (RQ2, Table 2).

### E7. Terminal / path / choice classification
- Result: Tiger's intermediate levels are forced by the model (unit-step evidence);
  the informative part is cross-variable orderings and route landmarks.
- Verdict: **PAPER** (Section 3). Honest framing of what landmarks add.

### E8. Bin ablation (RockSample)
- Result: rock resolution order identical in all 36 graphs (9 policies x 4 bin
  settings); only the coarse setting changes graphs. `results/bins.json`.
- Verdict: **PAPER** (RQ3).

### E9. QMDP contrast (25 models)
- Result: Tiger thresholds 1-2 levels lower where QMDP's value is lower; Channel/Mine
  commit only to value 1 (12-34% of runs end, by simulation); Sensor and RockSample
  never end. `results/qmdp.json`.
- Learned: QMDP is a weak comparison (reviewers said so); useful only as an extreme.
- Verdict: **PAPER** (short), not a headline.

### E10. Single-action mutants (66)
- Result: landmark graph changes for 41; 13 have runs that never end (6 of them with
  unchanged landmarks); 15 only change the value; 4 change nothing.
  `results/mutants.json`.
- Learned: landmarks describe only runs that end -> always report termination with
  every graph (first version wrongly said only 1 mutant stopped ending).
- Verdict: **PAPER** (RQ4, Table 4) + **LESSON**.

### E11. Merge audit and re-extraction
- Result: lossy merges only in Mine-3x3 (8) and the three QMDP probe graphs (1 each);
  none in mutants. Time-limited SARSOP runs are not reproducible: RockSample(5,5) s1
  and RockSample(7,8) changed on re-solve (7,8: 677 -> 593 nodes) but the rock order
  of 7,8 stayed the same.
- Learned: release the graphs; never claim bit-for-bit reproducible SARSOP runs.
- Verdict: **PAPER** (RQ1, reproducibility sentence).

### E12. Re-review of v4 / v4.1
- Result: A 5/10, B 6/10. Remaining: small domains, no second point-based solver, no
  user study, no case where landmarks show what value/actions do not.
- Verdict: **LESSON** -> E13-E17.

### E13. PBVI as a second point-based solver
- Tried: PointBasedValueIteration.jl 0.2.4 in a pinned Julia project
  (`pomdp/Project.toml`; the global env could not install it because of a yanked
  Qt build).
- Result: with the default 10 iterations it ran 80+ min on Tiger 0.6; with 5
  iterations Tiger solves in 2 s but Tiger 0.7 hung again (batch timed out after
  90 min with 2/25 done). Now running one model per process with a 3-min cap.
- Learned: the package is unreliable; report coverage honestly ("finished X of 25")
  or drop it.
- Verdict: **OPEN**.

### E14. Larger RockSample
- Tried: RockSample(11,11) with default SARSOP -> 12-node exit-only policy, because
  NativeSARSOP gives its initial bounds only 1 s (upper bound stuck at 0). Added
  `SARSOP_INIT_TIME`.
- Result: RockSample(8,8) (16,385 states): 753-node graph, 12 kept landmarks, exact
  1.4 s. RockSample(11,11) (247,809 states): 129-node graph, value 38.31 >= bound
  37.86, 28 kept landmarks, 8 of 11 rocks settled on every run in order
  7,3,9,5,4,6,1,11, exact 0.08 s. `results/large.json`.
- Learned: policy graphs stay small even when the state space grows 20x; the cost
  follows the policy, not the model. A 10x larger *graph* (reviewer A's ask) did
  not materialize.
- Verdict: **PAPER** ("Larger models" paragraph).

### E15. Tag (C)
- Tried: classic Tag (Pineau et al. 2003) as a QuickPOMDP with the robot starting in
  the bottom-left cell; opponent location as 29 one-hot evidence variables.
- Result: 842 states, SARSOP 600 s (gap 2.3), 268-node graph, 1 lossy merge, value
  -11.162 = bound -11.163, P(term) 0.84 in the graph. 49 kept landmarks; on every run
  that ends the opponent is first ruled out of the same 10 cells (bottom corridor to
  column 8, three room cells): the search route. RHW finds 24/49.
- Learned: categorical hidden state works with one-hot evidence variables; P(term)
  < 1 needs a simulation check before claiming it.
- Verdict: **PAPER** (short, as a recognized benchmark) once P(term) is checked.

### E16. Runtime monitoring (B)
- Tried: run 3 converged RockSample(4,4) SARSOP policies (seeds 1,3,5) in worlds whose
  sensor is worse than the model (efficiency 20 nominal; 10, 5, 2), 1,000 runs each
  (`pomdp/monitor_runs.jl`). Monitor: flag a run when a nominal landmark is reached
  later than in 99% of nominal runs. Baseline: flag runs longer than 99% of nominal.
- Result (`results/monitor.json`): seed 1 flags 1.5% / 3.5% / 7% of runs at
  efficiency 10 / 5 / 2 (0.4% false alarms), exactly the same runs the length
  baseline flags; seeds 3 and 5 flag nothing. Returns drop only slightly
  (seed 1: 34.7 -> 31.1).
- Learned: a worse sensor does not delay the agent's belief milestones; the agent
  stays confident and follows its nominal path, just with more wrong beliefs.
  Landmarks constrain *what the agent believes*, not whether those beliefs are
  right, so they cannot detect a miscalibrated sensor on their own. Timing monitors
  add nothing over episode length here.
- Verdict: **DROP** as a headline; **LESSON** for the Discussion (one sentence on
  what landmarks cannot see).

### E17. Same value, different beliefs (A)
- Tried: re-solve RockSample 4x4 (5 seeds) and 5x5 (3 seeds) with discount 0.90 and
  0.99 and with 10 s / 30 s time limits; evaluate every policy under discount 0.95.
- Result: running.
- Verdict: **OPEN**.

### E18. K / K-not knowledge view (advisor's request)
- Tried: a second abstraction of the same policy graphs, `controller(g, eps=...)`:
  kn-V(K) if P(V) >= 1-eps (the policy knows V), kn-V(Knot) if P(V) <= eps, else
  kn-V(U). Same exact extraction. These are the KL / K-not-L literals of contingent
  planning (Albore et al. 2009; Bonet & Geffner 2011), read probabilistically.
- Result (eps = 0.05): Tiger, all accuracies: "knows left or knows right" before
  opening a door. Sensor q = 0.95: knows a, then b, then diagnoses. Sensor q = 0.75:
  NO knowledge landmark; it diagnoses at 90% confidence. Channel: knows whether value
  1 is hidden. Mine-3x3: knows the mine is NOT in each of 7 cells, then commits to 5
  or 8. RockSample(4,4) s1: knows rock 4 bad -> (2,1) -> knows rock 3 bad -> (3,1) ->
  knows rock 1 bad -> knows rock 2 bad.
- Confidence each policy always reaches before acting (largest grid eps at which
  "K or Knot" is a landmark): Sensor 0.75/0.8 at 90%, 0.85 95%, 0.9 98%, 0.95 95%;
  Tiger 95-99%; Mine-2x2 90% on 3 cells; RockSample 95-99.9% per rock.
- Learned: the knowledge view gives the advisor-style explanation ("what the policy
  knows before it acts") and exposes a policy that acts on belief rather than
  knowledge (Sensor 0.75), which the value alone does not show. The graded view
  remains the right tool for "how much evidence". The two views answer different
  questions; present both.
- Verdict: **PAPER** (new subsection: two views of the same graph; table of the
  confidence each policy reaches before acting).

### E17 (result). Same value, different beliefs
- Result (`results/variants.json`): 8 RockSample maps, 34 policies (base, solved with
  discount 0.90 / 0.99, or with 10 s / 30 s SARSOP limits; all evaluated under
  discount 0.95; no lossy merges). 44 pairs of policies on the same map have values
  within 1% of each other; 31 of them have different landmark graphs, and 12 differ
  in the order in which they resolve the rocks. Example: RockSample(4,4) seed 1, the
  policy solved with discount 0.99 is 0.46% worse in value but checks rock 3 before
  rock 4 (base: rock 4 first); RockSample(5,5) seed 3 base vs discount 0.90: 0.48%
  apart, orders 2,5,4,1,3 vs 5,4,1,2,3.
- Learned: this is the clearest case of landmarks showing what the value cannot:
  near-identical returns, different information-gathering strategies.
- Verdict: **PAPER** (RQ4 headline; answers reviewer B's "no case where landmarks
  show what value/actions do not").

### E13 (update). PBVI, one model per process, 3-minute cap
- Result: after 15 of 25 models, PBVI finished 3 (Tiger 0.6, 0.65 and one more
  Tiger) and timed out on the other Tiger accuracies and on all 8 RockSample maps.
- Verdict: **DROP** from the paper's claims; mention as a limitation (no second
  point-based solver beyond QMDP). If a second solver is needed later, try HSVI or a
  newer PBVI with a time limit, or Perseus.

### E19. Re-review of v5 (reviewer A)
- Result: A 6/10 (from 5). Resolved: Mine-3x3, exactness cap, RHW figure, QMDP merges,
  timing. Remaining: no user study / second solver / graph >= 5,000 nodes; Tag P(term)
  unverified (47 nodes in a region closed by the lossy merge); overreach ("31 of 44"
  includes granularity differences, lead with 12 of 44 order changes; 90% confidence
  is readable from end-node beliefs; Theorem 1(2) does not hold for the non-injective
  knowledge view).
- Done: text fixes (title, abstract, theorem scope, least solution of first-passage
  equations, Table 3 caption); Tag re-solved once and checked by simulation of the
  same policy (`pomdp/check_graph_by_simulation.jl`, running).
- Learned: lead with the substantive number (order changes), not the inclusive one;
  every derived quantity from a graph with lossy merges needs a same-policy
  simulation check.
- Verdict: **LESSON**.

### E20. Re-review of v5 (reviewer B) and exact confidence numbers
- Result: B 7/10 (accept, from 6). New WRONG (minor): the Sensor q = 0.8 policy
  diagnoses at 0.94, not 0.9. Remaining: Tag's 16% never-ending runs (shuttling
  between (9,1) and (10,1)) look like a merge loop or a second defective policy;
  larger models are unconverged (gaps 7.0 and 10.4); no Monte Carlo baseline; the
  knowledge view is a threshold on the same beliefs (presentation, not new
  information); no script for its numbers.
- Done: `run_paper.py knowledge` computes, by bisection on eps, the confidence each
  policy always reaches about each variable before the episode ends
  (`results/knowledge.json`): Sensor 0.90 / 0.94 / 0.97 / 0.99 / 0.95 for q = 0.75
  ... 0.95; Tiger 0.962-0.997; RockSample 0.919-0.9999 per rock; Channel 0.94-0.96;
  Mine-2x2 0.91-0.96; Mine-3x3 0.89-0.97.
- Learned: report exact values, not grid steps; present the knowledge view as a
  shared vocabulary with a per-run guarantee, not as new information.
- Verdict: **PAPER** (numbers) + **LESSON**.

### E13 (final). PBVI coverage and what its policies do
- Result (`results/pbvi.json`): with 5 iterations and a 3-minute cap per model, PBVI
  finished 9 of 25 models (Sensor x5, Tiger 0.6/0.65/0.85, Mine-2x2); all RockSample,
  Channel, Mine-3x3 and five Tiger accuracies timed out.
- The finished policies are much worse than SARSOP's (Sensor q=0.75: -4.65 vs 3.55;
  Mine-2x2: -3.06 vs 9.56), and the landmark graphs say why: every PBVI Sensor policy
  lacks "sensor b reaches +-1" (it never reads sensor b) and commits only to diagnoses
  with b working; the Mine-2x2 policy commits only to cells 1 or 2; Tiger 0.6 never
  ends; Tiger 0.85 has exactly SARSOP's graph and value.
- Learned: under-converged point-based policies are a natural use case: the landmark
  diff names the information they skip. But 5-iteration PBVI is a weak solver;
  present it as "an under-converged second solver", not as a fair comparison.
- Verdict: **PAPER** (short, in RQ4 next to QMDP), with coverage stated (9 of 25).

### E15 (result). Tag checked by simulation of the same policy
- Tried: `pomdp/check_graph_by_simulation.jl` solves Tag once (600 s), writes the graph,
  and simulates that same policy with exact beliefs (2,000 runs).
- Result: graph 237 nodes, 1 lossy merge, P(term) 0.819; simulation: 82.2% of runs
  end, return -11.27 +- 0.15 (graph value -11.13, bound -11.15). The other runs
  shuttle east/west between (8,1) and (9,1) forever. The 10 "opponent ruled out"
  landmarks are identical to the first 600 s solve (archived as superseded/tag-run1).
- Learned: the non-termination is real, not a merge artifact: a second flawed
  time-limited SARSOP policy. Check graph-derived numbers on the same policy.
- Verdict: **PAPER** (Tag paragraph, v5.1).

## 2026-11-25: research phase (plan: Thesis_draft(2)/notes/research-plan.md)

### E21. R1: landmarks from sampled runs
- Tried: sample N runs from each policy graph (Markov chain), keep single facts and
  same-predicate pairs that hold on every sampled run that ends ("empirical
  landmarks"), compare with the exact set; 10 repetitions per N; exact probability q
  that a run that ends avoids a false landmark (`policy_landmarks/sampling.py`,
  `results/sampling.json`).
- Result: true landmarks always survive (by definition); false ones vanish after
  10-50 runs for Tiger/Sensor/Channel/Mine and 20-100 for RockSample 4x4/5x5. They
  persist where policies have rare branches: RockSample(7,8) still has 1 false
  landmark at 300 runs ("at (3,4) or (7,7)", q = 0.0078, ~590 runs for 1% risk);
  Tag has 5 at 300 runs ("opponent ruled out of (7,4)", q = 0.00095, ~4,800 runs).
- Learned: (1) exact extraction matters exactly where rare branches exist; (2) many
  "near-landmarks" hold on 99.9% of runs, which may be more useful to a user than
  strict landmarks -> delta-landmarks (reached with probability >= 1 - delta);
  (3) sampling gives a clean guarantee for delta-landmarks even without enumeration:
  if F holds on all N runs, P(q_F > delta) <= (1 - delta)^N (N = 300 -> delta = 1.5%
  at 99% confidence). This is the route to POMCP / learned policies (R4).
- Verdict: **PAPER** (answers reviewer B's Monte Carlo question) + new direction:
  **delta-landmarks** (exact from the graph, statistical from samples).

### E22. R2: correctness on the product with the true rocks
- Tried: `policy_landmarks/truth.py` runs a RockSample policy graph jointly with the
  true rock qualities (rocks fixed except sampling; moves deterministic), with a true
  sensor whose efficiency may differ from the model (20 nominal; 10, 5, 2). Exact
  expected bad samples, good rocks left behind, and value, no simulation
  (`results/truth.json`).
- Validation: at the nominal sensor the product value equals the graph value on all
  9 RockSample policies (after fixing a bug: exit reward first not credited); weak-
  sensor values agree with E16's simulations (seed 1, efficiency 2: 30.76 exact vs
  31.14 simulated).
- Result: value drops only ~11% (seed 1: 34.5 -> 30.8) while mistakes multiply (bad
  samples x8, good rocks left x14). Per rock (43 rocks, 9 policies): the 11 rocks whose
  cell is a landmark (visited on every run) have exactly 0 errors under every sensor;
  the 32 others average 0.033 errors nominal and 0.162 with the weak sensor (max 0.49).
  Seed 5's policy visits every rock and is immune.
- Learned: the landmark graph predicts which beliefs are exposed to a sensor fault
  (resolved remotely vs by visiting), and the product chain quantifies it. This turns
  E16's negative result into a positive one: timing cannot see a miscalibrated sensor,
  but the structure of the landmarks can. RockSample(7,8)'s unconverged policy samples
  rock 6 with 0.46 expected errors even with the nominal sensor.
- Verdict: **PAPER** (new RQ: from landmarks to robustness) + generalize beyond
  RockSample (Sensor, Tag) next.

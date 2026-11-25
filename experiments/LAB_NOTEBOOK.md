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

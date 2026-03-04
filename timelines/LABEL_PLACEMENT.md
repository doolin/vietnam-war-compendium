# Label Placement for Timelines

## The Problem

Placing event labels on a timeline without overlap while remaining legible is
a variant of the **Point-Feature Label Placement (PFLP)** problem, which is
**NP-hard**. Even the simplest version — "can all labels be placed without
overlap?" — is NP-complete (Marks & Shieber, 1991).

Timelines are a constrained (1D) variant: points are ordered along the time
axis, but the vertical placement of variable-height labels with connectors
back to fixed points is still combinatorial. Dense clusters (e.g., 12 events
in Jan-Feb 1968 during Tet) make this especially difficult.

## Key Literature

### Foundational Complexity Result

- **Marks, J. & Shieber, S. (1991).** "The Computational Complexity of
  Cartographic Label Placement."
  https://dash.harvard.edu/handle/1/24019781
  - Proved PFLP is NP-hard for the general case. All exact algorithms have
    exponential time complexity; practical solutions require heuristics.

### Empirical Algorithms

- **Christensen, Marks, & Shieber (1995).** "An Empirical Study of Algorithms
  for Point-Feature Label Placement."
  https://dl.acm.org/doi/10.1145/212332.212334
  - Compared greedy, exhaustive search, discrete gradient descent, and
    **simulated annealing**. Simulated annealing performed best in practice.

### Fast Overlap Detection

- **Redmond & Mote (2021, UW Interactive Data Lab).** "Fast and Flexible
  Overlap Detection for Chart Labeling with Occupancy Bitmap."
  https://idl.cs.washington.edu/files/2021-FastLabels-VIS.pdf
  - Uses a bitmap grid to detect overlaps, enabling greedy placement at
    interactive speeds. Integrated into Vega-Lite.

### Grid-Based Practical Algorithm

- **Lu, Fan, Yan, Li, & Arikawa (2017).** "A Fast and Practical Grid Based
  Algorithm for Point-Feature Label Placement Problem."
  https://arxiv.org/abs/1712.05936
  - Grid partitioning approach for real-time labeling on screen maps.

### Vega-Lite Integration

- **Lilley et al. (2024).** "Legible Label Layout for Data Visualization,
  Algorithm and Integration into Vega-Lite."
  https://arxiv.org/html/2405.10953v2
  - 8-position candidate model, balances runtime vs. label count placed.

### Additional References

- **Automatic Label Placement** — Wikipedia overview of the field:
  https://en.wikipedia.org/wiki/Automatic_label_placement
- **Placing Labels in Road Maps: Algorithms and Complexity** (2020):
  https://link.springer.com/article/10.1007/s00453-020-00678-7

## Practical Approaches for This Project

The current SVG timeline uses fixed-height event boxes with no overlap
avoidance. With 70+ events this breaks down.

**Candidate approaches (to investigate):**

1. **Simulated annealing** — best empirical results for PFLP. Assign each
   label a vertical position, minimize an energy function penalizing overlaps
   and long connectors. Well-suited to batch SVG generation (no real-time
   constraint).

2. **Force-directed / spring model** — treat labels as particles that repel
   each other and are attracted to their anchor point on the axis. Iterate
   until equilibrium. Simpler to implement than SA, good for 1D-constrained
   problems.

3. **Greedy with occupancy bitmap** — fast, deterministic, but can produce
   suboptimal layouts for dense clusters. Could work well combined with the
   existing tier/LOD system to limit visible labels.

4. **Tier-based filtering first** — the existing LOD system (tiers 0-3)
   already reduces label count at different zoom levels. Better LOD filtering
   may be sufficient for the overview, with overlap avoidance only needed at
   detailed zoom levels.

5. **Hybrid** — use tier filtering to reduce to a manageable set, then apply
   SA or force-directed layout on the visible subset.

## Relevance to Current Timeline

The Tet chronology (31 events, Nov 1967 - Mar 1968) is a good test case:
events are dense in late January through February 1968. The full indochina
timeline (88+ events, 1941-1972) has sparse and dense regions, making it a
good stress test for any placement algorithm.

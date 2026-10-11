# Timeline Design References

Literature on the timeline as a graphic form and on dense event-history
visualization. For the label-placement literature (PFLP, simulated
annealing, occupancy bitmaps) see `LABEL_PLACEMENT.md`.

Local copies of the freely available papers live in `references/`.

## The timeline as a graphic form

- **Rosenberg, D. & Grafton, A. (2010).** *Cartographies of Time: A History
  of the Timeline.* Princeton Architectural Press. ISBN 9781568987637.
  - The standard reference on the timeline as a graphic form: Eusebius's
    chronicle tables, Priestley's *Chart of Biography* (1765), Playfair, and
    the conventions that came out of them. If you want one book on
    timelines specifically, this is it.
  - Copyrighted trade book, no PDF. Buy or borrow.

- **Tufte, E.** *Beautiful Evidence* (2006) and *Envisioning Information*
  (1990). Graphics Press.
  - The usual general authority. No timeline-only book, but these two cover
    time-series, small multiples, and Minard's march chart, the best-known
    timeline-on-a-map. His data-ink and layering principles apply directly.
  - Owned in print.

## Design space

- **Brehmer, M., Lee, B., Bach, B., Henry Riche, N., & Munzner, T. (2017).**
  "Timelines Revisited: A Design Space and Considerations for Expressive
  Storytelling." *IEEE Transactions on Visualization and Computer Graphics*
  23(9). DOI 10.1109/TVCG.2016.2614803.
  - Project page with author preprint: https://timelinesrevisited.github.io/
  - Local copy: `references/brehmer-2017-timelines-revisited.pdf`
  - The most useful one for working with a model. Organizes timelines into
    three choices:
    - **Representation:** linear, radial, grid, spiral, or arbitrary.
    - **Scale:** chronological, relative, logarithmic, sequential, or
      sequential with interim durations.
    - **Layout:** unified, faceted, segmented, or faceted and segmented.
  - Argues that only certain combinations work well for a given narrative
    purpose.

## Dense multi-track event histories

- **Plaisant, C., Milash, B., Rose, A., Widoff, S., & Shneiderman, B.
  (1996).** "LifeLines: Visualizing Personal Histories." *Proc. ACM CHI '96*,
  221–227. DOI 10.1145/238386.238493.
  - Author copy: https://www.cs.umd.edu/~ben/papers/Plaisant1996LifeLines.pdf
  - Project page (University of Maryland HCI Lab, with the follow-on papers):
    https://www.cs.umd.edu/hcil/lifelines/
  - Local copy: `references/plaisant-1996-lifelines.pdf`
  - The reference for dense, multi-track event histories: many parallel
    lanes with intervals and point events.

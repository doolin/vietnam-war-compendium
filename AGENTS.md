# Agent Notes

Working notes for future deep dives and ongoing development.

## Label Placement (NP-hard)

Timeline label placement without overlap is a variant of Point-Feature Label
Placement, which is NP-hard (Marks & Shieber, 1991). Literature survey and
candidate approaches documented in `timelines/LABEL_PLACEMENT.md`. Key
candidates: simulated annealing, force-directed layout, tier-based filtering.
Needs a deep dive to choose and implement an approach.

## Timeline Design Literature

The design-space references (Rosenberg & Grafton, Tufte, Brehmer et al.
2017, Plaisant's LifeLines) are in `timelines/REFERENCES.md`, with local
PDFs of the papers in `timelines/references/`. Brehmer's
representation/scale/layout taxonomy is the vocabulary to use when
discussing timeline layout choices.

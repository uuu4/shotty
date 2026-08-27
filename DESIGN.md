# Design

Visual authority for Shotty's web surfaces. PRODUCT.md owns product truth; this file owns
durable visual decisions. Surface: `docs/index.html`, mode **Persuade**.

## The world

The category standard, taken deliberately and executed straight. The owner chose the
conventional macOS indie-utility page over four invented worlds, so convention is the
commitment: no irony, no smuggled quirk, no half-measure toward a concept that was
declined. Craft bar, in the owner's words: **between ponytail and Ghostty** — Ghostty-level
typography and detail, ponytail-level restraint. Nothing exists on the page unless it does
work.

The one idea the surface owns: a utility sold on a number anyone can verify in one shell
command, not on a feature list. The proof sections *are* the page.

## Color

Committed dark. The use scene decides it: a developer at their own Mac, often at night,
deciding whether to install something.

| Token | Value | Role |
|---|---|---|
| `--bg` | `#111110` | ground, warm near-black, never blue-black |
| `--bg-2` | `#191917` | raised panels, terminal blocks |
| `--bg-3` | `#201F1C` | window chrome, key caps |
| `--line` | `#2B2A26` | hairline rules; the page separates with rules, not cards |
| `--line-2` | `#3A3833` | stronger borders, data bars |
| `--text` | `#ECEAE4` | warm off-white |
| `--dim` | `#9B968A` | secondary text, tinted from the ground's hue, never gray |
| `--faint` | `#8F8A7E` | tertiary text; floor is 4.5:1, do not darken it |
| `--ghost` | `#5F5B53` | non-text labels only (panel heads); never body copy |
| `--mark` | `#E5484D` | **reserved** |

`--mark` is the app's own annotation red and carries one meaning: *a human made this mark*.
It is spent on the word "before" in the headline, the verified numbers in the terminal, the
393 total, and the default pen color in the demo. Nothing else may use it. A red CTA would
spend the reservation and is forbidden.

No gradients. No glass as decoration. No gradient text.

## Type

- **Archivo** (400/500/600/700) — everything structural. Display sits at
  `clamp(2.3rem, 5.6vw, 4.25rem)`, weight 700, tracking `-.035em`, `text-wrap: balance` on
  headings.
- **JetBrains Mono** (400/500) — code, terminal output, commands, counts. Mono here is data
  and measurement, never a costume for "technical".
- `kbd` uses the system face first (`-apple-system`), because JetBrains Mono has no U+21E7
  and renders ⌘⇧2 wrong.
- Body measure stays 58–66ch. Numeric columns use `font-variant-numeric: tabular-nums`.

## Components

Rules over cards. There is no icon-card feature grid and there will not be one; it is the
category's laziest container and the proof sections replace it.

- **Terminal block** — bordered panel, muted head, `white-space: pre`. Prompts in
  `--ghost`, commands in `--text`, verified numbers in `--mark`, comments in `--dim`.
- **Manifest row** — three columns: name, a shared 150px bar track, a tabular count. The
  shared track is what makes it read as data instead of stray dashes.
- **Panels** — `.panel` for text, `.panel.shot` for anything representing a captured screen
  (darker ground `#0B0B0A`, inset 1px light rule standing in for the lit selection, size
  readout in the head).
- **Icons** — authored SVG, 24-box, 1.8 stroke, round caps and joins. No emoji, no unicode
  glyphs standing in for icons, with no exceptions: the wordmark used to be a `✂︎` character
  and it looked exactly like what it was. `✂︎` appears once, in Install prose, describing the
  glyph the app actually puts in the menu bar — that is text about a symbol, not a symbol
  doing an icon's job.

- **The mark** — four selection corners around one lit rectangle, in a 24-box: `stroke-width`
  2.3 at 60% for the corners, a solid `currentColor` rect at x6.8 y8.4 w8.4 h5.2. It is the
  app's own gesture, not the category's scissors, and it survives 21px because it is two
  shapes and no detail. Monochrome deliberately — `--mark` stays reserved, so the 393 keeps
  the only red above the fold. `docs/icon.svg` carries the same geometry on the ground colour;
  change one and change both.

## Live demonstrations

Two, and both prove a claim the page makes. Neither is decoration, and that is the test any
future one has to pass.

1. **The capture gesture** (hero). Drag on the page: it dims outside your box, lights inside,
   and the toolbar appears under the selection. Beside it, **what lands on your clipboard** —
   the selected pixels cropped out of the real image with your strokes baked in, drawn to a
   canvas from the same source and the same paths. The demo used to stop at the gesture and
   never show the result, which left the story a beat short.

   Everything here derives from the screen's measured box, so nothing reads a cached one:
   `size()` runs at the top of every interaction. A page loaded in a collapsed or hidden
   state otherwise hands the first drag a box that does not exist. The surface is a real screenshot the owner
   supplied (`docs/shot.webp`), because an authored mock read as a diagram and the point of
   the demo is recognition — people screenshot pages, not diagrams.

   Recorded because it will come up again: this puts a third party's interface and a real
   person on the page. I raised that; the owner decided it, twice, and it is their call and
   their project. If it ever has to go, swap `shot.webp` for another screenshot and retune
   the four normalized rectangles in the teaching animation and the keyboard entry point —
   nothing else is coupled to the image.

   Every coordinate in this demo is derived from the screen's measured box, and that box is
   not final until the image lays out. A cached image reports `complete === true` before
   layout, so load events are not enough: a `ResizeObserver` on `.screen` is what keeps the
   overlay honest. Writing the measured size into the SVG's `width`/`height` attributes is
   what once pinned it to its own first measurement and trapped every drag in a 300×150
   corner — set the `viewBox` and nothing else.
2. **The OCR reconstruction** (OCR section). `Overlay.layout(_:)` ported to JS, running for
   real in the visitor's browser on fragments carrying synthetic Vision-like noise. Three
   steps: boxes, rows resolved (red bands show the grouping), columns resolved. The last step
   asserts the output equals the input and says so — **if the port is ever wrong, the page
   says so out loud instead of lying.**

Plus one ambient piece, held to the same test. The hero field is **the demo screenshot
itself**, sampled into a 96-column glyph grid by luminance with the range stretched (a dark
UI otherwise samples to nothing but spaces). A selection window drifts across it, and inside
the window the real image shows through with a live pixel readout — the app's dim/lit gesture
and the page's pixels-become-characters thesis in one object. It is the world of the "ASCII
Live Render" direction the roll declined, kept as ambience rather than as the page's identity.

The first version of this was a plasma noise field with a box on it. It passed no test; it
was decoration wearing the argument's clothes, and the owner called it. **If the field ever
stops being a picture of something real, delete it rather than tuning it.** One moving
element is the budget: the drift plus the readout. A second would put it back in decoration.

It samples once on load and on resize, drifts at ~14fps only while on screen and while the
tab is visible, is hidden below 1000px, and holds one still frame under
`prefers-reduced-motion`.

**Reduced motion must never gate the content, only the motion.** Both interactive
demonstrations used to wait for an `IntersectionObserver` before showing anything, including
under `prefers-reduced-motion` — where there is no animation to schedule and therefore no
reason to wait. A visitor with that preference got an empty screen and an OCR stage stuck on
step one. They now render their resolved state at init and skip the observer entirely.

Both interactive pieces cancel their teaching animation the moment the visitor touches them. A demonstration
that fights the person trying it is worse than no demonstration.

## Generated data, never typed

Numbers quoted in prose are generated too, not only the table: `sync.py` emits `funcs`, and
the page writes `Overlay.layout(_:)`'s line count from it. That number shipped wrong once —
44 against the file's 45, because the hand-typed version did not count the function's own
closing brace while every other count on the page does. A number the generator does not own
is a number that drifts.


`docs/source.js` is generated by `docs/sync.py` from `main.swift`: region names, line ranges,
code counts, the demo excerpt, and the full readable source behind each manifest row. Nothing
on the page is a hand-typed number any more, and `sync.py` asserts the regions cover exactly
the file's code lines, so a drifted count fails loudly instead of shipping.

**Run `python3 docs/sync.py` after any change to `main.swift`.**

The expanded source carries the file's own line numbers, seeded from each region's real
start. A row that says 45–131 and then shows unnumbered code is asking to be taken on trust,
which is the one thing this page does not ask for anywhere else.

It writes two files. `source.js` carries the numbers — counts, ranges, the OCR sample — and
is ~1.3 kB. `source-bodies.js` carries the highlighted source behind the manifest rows, is
~31 kB, and is fetched the first time someone actually opens a row. 91% of the payload was
source most visitors never read, on a page that argues against shipping what you do not
need.

Both are content-hashed into their URLs, along with every local asset. That is not tidiness:
every figure on this page comes out of `source.js`, so a cached copy is the page quoting
numbers that have moved, and `og.png` is cached by unfurlers under a URL that would outlive
any redesign of the card.

## Motion

One authored moment per section, and only one: on first scroll into the demo, a ghost cursor performs a
single drag-select and draws one stroke, then hands control to the visitor. Exponential
ease-out (`1 - (1-k)^4`). Under `prefers-reduced-motion` it renders the end state directly
and animates nothing. Everything else is a 150–180ms color or border transition on hover.
No scroll-triggered section entrances.

## Browser surfaces

Themed, not defaulted: `::selection` in tinted mark red, `:focus-visible` as a 2px mark ring
at 3px offset, scrollbars in `--line-2` on the ground with a 3px inset. These are cheap and
they are the difference between built and assembled.

## Two failure modes this page has already hit

**Class-name collisions.** `.steps` was the OCR stage's segmented control and also
`ol.steps` in Install. `display:flex` from one laid the other out sideways and made the
whole page scroll horizontally. Component classes here are prefixed by their owner
(`.stage-steps`, `.panel-head`, `.row .rg`); a bare generic noun is a trap.

**Grid items blowing out their track.** Grid and flex children default to
`min-width:auto`, so any `white-space:pre` descendant — a command, a terminal block, a
table — widens the column past the viewport and the page scrolls sideways. Every grid
child that can contain preformatted content carries `min-width:0`.

Neither is caught by the detector or by looking at a desktop screenshot. The check that
finds them is one line: compare `document.documentElement.scrollWidth` to `clientWidth`
at a narrow width, and if they differ, list every element whose `right` exceeds it.

## Rules that outlive this page

1. Any claim on any surface must be verifiable by a command the visitor can run. If the
   line count changes, the page changes the same day.
2. Never state what a competitor's tool fails to do. State what Shotty does.
3. `--mark` stays reserved for human marks.
4. New sections earn their place or do not ship. The craft bar is restraint.

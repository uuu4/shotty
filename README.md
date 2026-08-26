# Shotty — Lightshot for Mac

Press a key. Drag a box. Draw on it. Copy it.

macOS ships a decent screenshot tool, but there is no moment between *selecting* and
*saving* where you can actually mark something up. You capture, a thumbnail slides in,
you race the timer to click it, Markup opens in a separate window, and by then the point
is gone. Shotty puts the annotation step exactly where Lightshot puts it: on the screen
you just froze, before anything is written anywhere.

- **One shortcut** — `⌘⇧2` freezes the screen and dims it.
- **Select in place** — drag a box; your selection stays lit, everything else stays dark.
- **Draw before you commit** — pen, rectangle, arrow, highlighter, 5 colours, undo. Nothing
  has been copied or saved yet, and nothing will be until you say so.
- **OCR that keeps the layout** — `⌘R` reads the selection and puts the text on your
  clipboard with the indentation intact. Code stays code.
- **~450 lines of Swift, no dependencies, no menu bar clutter, no telemetry, no account.**

## Install

Requires macOS 13+ and the Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/uuu4/shotty.git
cd shotty && ./build.sh && open Shotty.app
```

The first capture asks for Screen Recording permission (System Settings → Privacy &
Security → Screen Recording). Grant it, then `open Shotty.app` once more. Shotty lives in
the menu bar as `✂︎` — no Dock icon.

To launch it at login: System Settings → General → Login Items → `+` → `Shotty.app`.

## Keys

| | |
|---|---|
| `⌘⇧2` | capture |
| drag | select an area — drag again outside it to reselect |
| `P` `R` `A` `H` | pen · rectangle · arrow · highlighter |
| `⌘Z` | undo last stroke |
| `⌘C` / `Return` | copy the selection to the clipboard |
| `⌘S` | save it to the Desktop |
| `⌘R` | OCR the selection to the clipboard |
| `Esc` | cancel |

## The OCR

Vision returns text as a bag of boxes, which is why most OCR output arrives as one
flattened blob. Shotty estimates character width from the median box, maps every fragment
back to a column, and reprints the block with its indentation, column gaps and paragraph
breaks. Small selections get upscaled 2× first, and language correction is off by default
so it stops "fixing" your identifiers — flip `ocrLanguageCorrection` at the top of
`main.swift` if you mostly capture prose.

## Not doing

Text tool, resize handles, upload-to-a-server links, history, cloud anything. Screenshots
belong on your clipboard, not on someone's bucket.

## License

MIT

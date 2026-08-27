# Shotty

**[uuu4.github.io/shotty](https://uuu4.github.io/shotty/)** — try the capture gesture and
watch the OCR reconstruction run, without installing anything.

**An open source, 393-line screenshot tool for macOS.** Capture a region, draw on it, copy
it — or OCR it with the indentation intact. Small enough to read before you run it.

```bash
wc -l main.swift                  # 459 lines, 393 of them code
grep -c 'URLSession\|http' main.swift   # 0 — there is no network code
```

That is the whole pitch. Every other screenshot tool on this platform is a closed binary
with a feature list. This is one Swift file under MIT: no dependencies, no build system, no
account, no telemetry, and nothing that talks to a server. Read it over a coffee, fork it,
change whatever annoys you.

## What it does

Press `⌘⇧2`. The screen freezes and dims. Drag a box — your selection stays lit, everything
else stays dark. Draw on it with pen, rectangle, arrow or highlighter. **Nothing has been
copied or saved yet**, and nothing will be until you press Copy, Save or OCR.

The macOS built-in tool captures first and lets you annotate afterwards, in a window that
opens somewhere else, after you catch a thumbnail before it expires. Shotty puts the
drawing step where the selection already is.

## Install

Requires macOS 13+ and the Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/uuu4/shotty.git
cd shotty && ./build.sh && open Shotty.app
```

`build.sh` is `swiftc` plus an Info.plist — read that too, it is 22 lines.

The first capture asks for Screen Recording permission (System Settings → Privacy &
Security → Screen Recording). Grant it, then `open Shotty.app` once more. Shotty lives in
the menu bar as `✂︎`, with no Dock icon. To start it at login: System Settings → General →
Login Items → `+` → `Shotty.app`.

## Keys

| | |
|---|---|
| `⌘⇧2` | capture |
| drag | select an area — drag outside it to reselect |
| `P` `R` `A` `H` | pen · rectangle · arrow · highlighter |
| `⌘Z` | undo last stroke |
| `⌘C` / `Return` | copy the selection to the clipboard |
| `⌘S` | save it to the Desktop |
| `⌘R` | OCR the selection to the clipboard |
| `Esc` | cancel |

## The OCR

Vision hands back text as a bag of bounding boxes, so the straightforward implementation
returns a flattened blob. Shotty estimates character width from the median box, maps every
fragment back to a column, and reprints the block — indentation, column gaps and paragraph
breaks survive, so screenshotting a code block returns something you can paste into an
editor. Small selections are upscaled 2× first, and language correction is off by default
so it stops "fixing" your identifiers. Flip `ocrLanguageCorrection` at the top of
`main.swift` if you mostly capture prose.

The whole OCR path is 80 lines; `Overlay.layout(_:)` is 44 of them, and that is the part worth reading.

## Not doing

Text tool, resize handles, upload links, history, cloud sync, updater, analytics. Each one
costs lines, and the line count is the point.

## License

MIT — fork it, change the keybinding, ship your own.

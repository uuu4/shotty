# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML/CSS, single file, no dependencies and no build step. Published from
`/docs` on GitHub Pages at `uuu4.github.io/shotty`; a custom domain may be
attached later without changing the build.

## Users

Primary: developers who screenshot constantly — code, logs, terminal output, a
broken UI — and who would rather run a tool they can read than a closed binary
with a feature list. They are mid-conversation when they capture; the screenshot
is a message, not an archive. They also want the text back out of it.

Secondary: anyone who wants the annotate-before-commit flow without an account,
an updater or an upload.

Set 2026-08-27: an earlier draft made Windows switchers primary under a
"Lightshot for Mac" position. That position was retired (see Positioning) and the
audience moved with it, because a line count is an argument only a developer
finds persuasive.

## Product Purpose

Shotty restores the annotate-before-commit step that macOS lacks. Pressing the
hotkey freezes and dims the screen; the selected region stays lit; the toolbar
appears under the selection; nothing reaches the clipboard or the disk until the
user presses Copy, Save or OCR. Success is that a user who missed Lightshot stops
noticing that they are on macOS.

## Positioning

**Auditable smallness.** 393 lines of code in one Swift file (459 with comments
and blanks), no dependencies, no build system, and zero network calls — both
numbers verifiable in one shell command, which is the pitch itself. Every
competitor on this platform is a closed binary; this one can be read before it is
run.

Supporting, not leading: OCR that reconstructs row/column layout from Vision's
bounding boxes so indentation survives. It is the technically interesting hook in
the body copy, never the headline claim.

Retired 2026-08-27, do not reinstate: the slogan "Lightshot for Mac" and any
framing built on macOS lacking a Lightshot. Skillbrains ships Lightshot Screenshot
on the Mac App Store (id526298438, free, macOS 10.7+); the claim was false and
would have been the first comment on any launch post.

Also retired: any claim about a competitor's OCR quality. Shottr uses the same
Vision framework and preserves line breaks. Shotty's column reconstruction is a
real difference but an unverified-by-us one, so state what Shotty does and never
what another tool fails to do.

## Operating Context

macOS 13+, built from source with `./build.sh` (swiftc plus an Info.plist).
Lives in the menu bar as `✂︎`, no Dock icon. Requires the Screen Recording
permission on first capture. Global hotkey is registered through Carbon, so it
needs no Accessibility permission. Users are keyboard-first: `⌘⇧2` to capture,
`P R A H` for tools, `⌘Z`, `⌘C`, `⌘S`, `⌘R`, `Esc`.

## Capabilities and Constraints

Confirmed: fullscreen dim-and-select overlay; pen, rectangle, arrow, highlighter;
five colors; undo; copy to clipboard; save to Desktop; layout-preserving OCR with
2x upscaling for small selections and language correction off by default.
~450 lines of Swift, zero dependencies, MIT.

Constraints to state honestly, never dress up: install is build-from-source (no
signed .dmg, no Homebrew cask yet); one display per capture; no text tool, no
resize handles, no history, no cloud, no uploads. Undecided: paid tier of any
kind — there is none and none is planned copy.

## Brand Commitments

Name: Shotty — kept by the owner with the Shottr name-similarity risk explicitly
accepted. Slogan: "Small enough to read before you run it", supported by the
literal line count. Voice: plain, technical, unhurried; describes the mechanism
instead of selling it; never uses "effortless", "seamless" or "magical"; never
attacks a named competitor, because the position does not need one.

## Evidence on Hand

Real and verifiable, in order of persuasive weight: 393 lines of code / 459 total
(`wc -l main.swift`); zero network calls (`grep -c 'URLSession\|http' main.swift`
returns 0); the source at `main.swift`; the public repo at github.com/uuu4/shotty;
the MIT license. The two shell commands are evidence a visitor can run, which is
worth more than any screenshot of a feature.

Absent and never to be fabricated: the demo GIF (owner will record it; the page
must hold a slot for it), user counts, download numbers, stars, testimonials,
press, awards, benchmark comparisons against Shottr or CleanShot.

## Product Principles

1. Nothing leaves the machine. No account, no upload, no telemetry — say it
   plainly and let it be the proof.
2. The mechanism is the pitch. Explain how the OCR reconstructs columns; do not
   claim "smart" or "AI-powered".
3. Honest about immaturity. Build-from-source and the missing GIF are stated, not
   hidden behind a fake download button.
4. Keyboard-first, like the product itself.
5. Readable in a sitting — the small, auditable codebase is a feature and belongs
   in the argument.

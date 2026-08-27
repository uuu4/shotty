import Cocoa
import Carbon.HIToolbox
import Vision

// ── Settings ──────────────────────────────────────────────────────────────
let hotKeyCode = UInt32(kVK_ANSI_2)              // ⌘⇧2 to capture
let hotKeyMods = UInt32(cmdKey | shiftKey)
let saveDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
let ocrLanguages = ["en-US"]                     // add more, e.g. "de-DE"; unsupported ones are dropped
let ocrLanguageCorrection = false                // set true if you mostly capture prose, not code

enum Tool { case pen, rect, arrow, highlight }
struct Anno { var tool: Tool; var color: NSColor; var points: [NSPoint] }
enum Mode { case selecting, editing }

// ── Fullscreen overlay: select and annotate in the same place ─────────────
final class Overlay: NSView {
    static let palette: [NSColor] = [.systemRed, .systemYellow, .systemBlue, .systemGreen, .white]

    let shot: NSImage                 // screen frozen at the moment the hotkey fired
    let scale: CGFloat                // screen pixel/point ratio
    var mode: Mode = .selecting
    var sel: NSRect = .zero
    var dragStart: NSPoint = .zero
    var annos: [Anno] = []
    var current: Anno?
    var tool: Tool = .pen
    var color: NSColor = .systemRed
    var exporting = false
    var bar: NSStackView!
    weak var status: NSTextField?
    var onClose: (() -> Void)?

    init(shot: NSImage, size: NSSize, scale: CGFloat) {
        self.shot = shot
        self.scale = scale
        super.init(frame: NSRect(origin: .zero, size: size))
        buildBar()
    }
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    // ── drawing ──
    override func draw(_ dirty: NSRect) {
        shot.draw(in: bounds)

        if exporting {                                  // export: image + annotations only
            drawAnnos()
            return
        }

        // dim everything outside the selection
        NSColor.black.withAlphaComponent(0.5).setFill()
        let mask = NSBezierPath(rect: bounds)
        if !sel.isEmpty { mask.append(NSBezierPath(rect: sel)) }
        mask.windingRule = .evenOdd
        mask.fill()

        drawAnnos()

        guard !sel.isEmpty else {
            hint("Drag to select an area · Esc to cancel")
            return
        }
        NSColor.white.setStroke()
        let b = NSBezierPath(rect: sel)
        b.lineWidth = 1
        b.stroke()
        label("\(Int(sel.width * scale)) × \(Int(sel.height * scale))",
              at: NSPoint(x: sel.minX + 4, y: sel.maxY + 6))
    }

    private func drawAnnos() {
        NSGraphicsContext.saveGraphicsState()
        if !sel.isEmpty { NSBezierPath(rect: sel).addClip() }   // annotations never spill outside
        for a in annos { stroke(a) }
        if let c = current { stroke(c) }
        NSGraphicsContext.restoreGraphicsState()
    }

    private func stroke(_ a: Anno) {
        guard a.points.count >= 2 else { return }
        let path = NSBezierPath()
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        path.lineWidth = a.tool == .highlight ? 16 : 3

        switch a.tool {
        case .pen, .highlight:
            path.move(to: a.points[0])
            for p in a.points.dropFirst() { path.line(to: p) }
            // ponytail: overlapping highlighter strokes darken; add layer flattening if it bothers you
            (a.tool == .highlight ? a.color.withAlphaComponent(0.3) : a.color).setStroke()
        case .rect:
            let p = a.points
            path.appendRect(NSRect(x: min(p[0].x, p[1].x), y: min(p[0].y, p[1].y),
                                   width: abs(p[0].x - p[1].x), height: abs(p[0].y - p[1].y)))
            a.color.setStroke()
        case .arrow:
            let s = a.points[0], e = a.points[1]
            path.move(to: s); path.line(to: e)
            let ang = atan2(e.y - s.y, e.x - s.x), len: CGFloat = 14
            for d in [CGFloat.pi * 0.85, -CGFloat.pi * 0.85] {
                path.move(to: e)
                path.line(to: NSPoint(x: e.x + cos(ang + d) * len, y: e.y + sin(ang + d) * len))
            }
            a.color.setStroke()
        }
        path.stroke()
    }

    private func label(_ s: String, at p: NSPoint) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white]
        let str = NSAttributedString(string: s, attributes: attrs)
        let box = NSRect(origin: p, size: str.size()).insetBy(dx: -5, dy: -3)
        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: box, xRadius: 4, yRadius: 4).fill()
        str.draw(at: p)
    }

    private func hint(_ s: String) {
        let str = NSAttributedString(string: s, attributes: [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)])
        str.draw(at: NSPoint(x: (bounds.width - str.size().width) / 2, y: bounds.height * 0.5))
    }

    // ── mouse ──
    override func mouseDown(with e: NSEvent) {
        let p = convert(e.locationInWindow, from: nil)
        if mode == .editing && sel.contains(p) {
            current = Anno(tool: tool, color: color, points: [p])
        } else {                                   // clicking outside the selection starts a new one
            mode = .selecting
            annos.removeAll()
            bar.isHidden = true
            dragStart = p
            sel = .zero
            window?.invalidateCursorRects(for: self)
        }
        needsDisplay = true
    }

    override func mouseDragged(with e: NSEvent) {
        let p = convert(e.locationInWindow, from: nil)
        if mode == .selecting {
            sel = NSRect(x: min(dragStart.x, p.x), y: min(dragStart.y, p.y),
                         width: abs(dragStart.x - p.x), height: abs(dragStart.y - p.y))
        } else if var c = current {
            if c.tool == .pen || c.tool == .highlight { c.points.append(p) } else { c.points = [c.points[0], p] }
            current = c
        }
        needsDisplay = true
    }

    override func mouseUp(with e: NSEvent) {
        if mode == .selecting {
            guard sel.width > 5, sel.height > 5 else { sel = .zero; needsDisplay = true; return }
            sel = sel.integral
            mode = .editing
            placeBar()
            bar.isHidden = false
            window?.invalidateCursorRects(for: self)
        } else {
            if let c = current, c.points.count >= 2 { annos.append(c) }
            current = nil
        }
        needsDisplay = true
    }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(mode == .selecting ? bounds : sel, cursor: .crosshair)
    }

    // ── keyboard ──
    override func keyDown(with e: NSEvent) {
        switch (e.keyCode, e.charactersIgnoringModifiers ?? "") {
        case (53, _): onClose?()
        case (36, _): copyShot()
        case (_, "p"): tool = .pen; flash("pen")
        case (_, "r"): tool = .rect; flash("rectangle")
        case (_, "a"): tool = .arrow; flash("arrow")
        case (_, "h"): tool = .highlight; flash("highlighter")
        default: super.keyDown(with: e)
        }
    }
    override func performKeyEquivalent(with e: NSEvent) -> Bool {
        guard e.modifierFlags.contains(.command) else { return false }
        switch e.charactersIgnoringModifiers ?? "" {
        case "c": copyShot()
        case "s": saveShot()
        case "r": runOCR()
        case "z": if !annos.isEmpty { annos.removeLast(); needsDisplay = true }
        default: return false
        }
        return true
    }

    // ── toolbar ──
    private func buildBar() {
        bar = NSStackView()
        bar.spacing = 4
        bar.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        bar.layer?.cornerRadius = 6
        bar.isHidden = true

        func btn(_ t: String, _ sel: Selector) -> NSButton {
            let b = NSButton(title: t, target: self, action: sel)
            b.bezelStyle = .inline
            b.attributedTitle = NSAttributedString(string: t, attributes: [
                .foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 13)])
            return b
        }
        bar.addArrangedSubview(btn("✎", #selector(toolPen)))
        bar.addArrangedSubview(btn("▭", #selector(toolRect)))
        bar.addArrangedSubview(btn("↗", #selector(toolArrow)))
        bar.addArrangedSubview(btn("▬", #selector(toolHi)))
        for (i, c) in Overlay.palette.enumerated() {
            let b = NSButton(title: "●", target: self, action: #selector(pickColor(_:)))
            b.bezelStyle = .inline
            b.tag = i
            b.attributedTitle = NSAttributedString(string: "●", attributes: [
                .foregroundColor: c, .font: NSFont.systemFont(ofSize: 16)])
            bar.addArrangedSubview(b)
        }
        bar.addArrangedSubview(btn("↶", #selector(undo)))
        bar.addArrangedSubview(btn("Copy", #selector(copyShot)))
        bar.addArrangedSubview(btn("Save", #selector(saveShot)))
        bar.addArrangedSubview(btn("OCR", #selector(runOCR)))

        let st = NSTextField(labelWithString: "⌘C · ⌘S · ⌘R · ⌘Z · Esc")
        st.font = .systemFont(ofSize: 11)
        st.textColor = .white.withAlphaComponent(0.6)
        bar.addArrangedSubview(st)
        status = st

        addSubview(bar)
    }

    private func placeBar() {
        let size = bar.fittingSize
        var y = sel.minY - size.height - 8
        if y < 8 { y = min(sel.maxY + 8, bounds.height - size.height - 8) }
        let x = min(max(sel.maxX - size.width, 8), bounds.width - size.width - 8)
        bar.frame = NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    @objc func toolPen() { tool = .pen; flash("pen") }
    @objc func toolRect() { tool = .rect; flash("rectangle") }
    @objc func toolArrow() { tool = .arrow; flash("arrow") }
    @objc func toolHi() { tool = .highlight; flash("highlighter") }
    @objc func undo() { if !annos.isEmpty { annos.removeLast(); needsDisplay = true } }
    @objc func pickColor(_ s: NSButton) { color = Overlay.palette[s.tag] }
    func flash(_ s: String) { status?.stringValue = s }

    // ── export: selection only, at full resolution ──
    private func render() -> NSBitmapImageRep? {
        guard !sel.isEmpty else { return nil }
        exporting = true
        bar.isHidden = true
        defer { exporting = false; bar.isHidden = false; needsDisplay = true }
        guard let rep = bitmapImageRepForCachingDisplay(in: sel) else { return nil }
        cacheDisplay(in: sel, to: rep)
        return rep
    }

    @objc func copyShot() {
        guard let png = render()?.representation(using: .png, properties: [:]) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setData(png, forType: .png)
        onClose?()
    }

    @objc func saveShot() {
        guard let png = render()?.representation(using: .png, properties: [:]) else { return }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH.mm.ss"
        try? png.write(to: saveDir.appendingPathComponent("Screenshot \(f.string(from: Date())).png"))
        onClose?()
    }

    @objc func runOCR() {
        guard var cg = render()?.cgImage else { return }
        flash("Running OCR…")
        // Vision struggles below ~20px text height, and thin glyphs like _ drop out entirely.
        // Scale up to a height floor rather than a fixed 2x, so a small crop gets more.
        if cg.height < 1200 { cg = upscale(cg, min(4, max(2, Int((1200.0 / Double(cg.height)).rounded(.up))))) }

        let req = VNRecognizeTextRequest { [weak self] r, _ in
            let obs = r.results as? [VNRecognizedTextObservation] ?? []
            let text = Overlay.layout(obs)
            DispatchQueue.main.async {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(text, forType: .string)
                self?.flash(text.isEmpty ? "no text found"
                                         : "\(text.split(separator: "\n").count) lines copied")
            }
        }
        req.recognitionLevel = .accurate
        // language correction mangles identifiers in code/terminal shots; see the flag up top
        req.usesLanguageCorrection = ocrLanguageCorrection
        // keep only what this macOS version actually ships a model for
        if let sup = try? req.supportedRecognitionLanguages() {
            let ok = ocrLanguages.filter(sup.contains)
            if !ok.isEmpty { req.recognitionLanguages = ok }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
        }
    }

    private func upscale(_ cg: CGImage, _ f: Int) -> CGImage {
        let w = cg.width * f, h = cg.height * f
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return cg }
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage() ?? cg
    }

    /// Rebuilds the row/column layout from bounding boxes: indentation, inter-column
    /// gaps and paragraph breaks all survive.
    static func layout(_ obs: [VNRecognizedTextObservation]) -> String {
        struct Piece { let s: String; let x: CGFloat; let y: CGFloat; let w: CGFloat; let h: CGFloat }
        let pieces: [Piece] = obs.compactMap {
            guard let t = $0.topCandidates(1).first else { return nil }
            let b = $0.boundingBox
            return Piece(s: t.string, x: b.minX, y: b.midY, w: b.width, h: b.height)
        }
        guard !pieces.isEmpty else { return "" }

        // column 0 is the leftmost glyph, not the crop edge — otherwise a few px of
        // margin adds a phantom space to every single line
        let x0 = pieces.map { $0.x }.min() ?? 0

        // ponytail: character width is estimated from the median; exact for a single font,
        // indentation can drift by a space when one shot mixes very different sizes
        let ws = pieces.filter { $0.s.count > 2 }.map { $0.w / CGFloat($0.s.count) }.sorted()
        let charW = ws.isEmpty ? 0.01 : ws[ws.count / 2]
        let hs = pieces.map { $0.h }.sorted()
        let lineH = max(hs[hs.count / 2], 0.001)

        var lines: [[Piece]] = []
        for p in pieces.sorted(by: { $0.y > $1.y }) {           // top to bottom
            if var last = lines.last, let ref = last.first, abs(ref.y - p.y) < lineH * 0.5 {
                last.append(p)
                lines[lines.count - 1] = last
            } else {
                lines.append([p])
            }
        }

        var out: [String] = []
        var prevY: CGFloat?
        for line in lines {
            let row = line.sorted { $0.x < $1.x }
            guard let first = row.first else { continue }
            if let py = prevY {                                  // blank lines in between
                let blanks = Int(((py - first.y) / lineH - 1.4).rounded(.down))
                if blanks > 0 { out.append(contentsOf: Array(repeating: "", count: min(blanks, 3))) }
            }
            prevY = first.y
            var text = ""
            for p in row {
                let col = Int(((p.x - x0) / charW).rounded())    // column from the leftmost glyph
                if col > text.count {
                    text += String(repeating: " ", count: col - text.count)
                } else if !text.isEmpty {
                    text += " "
                }
                text += p.s
            }
            out.append(text)
        }
        return out.joined(separator: "\n")
    }
}

// ── Borderless window that hosts the overlay ──────────────────────────────
final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

var live: OverlayWindow?

func capture() {
    guard live == nil else { return }
    let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main!
    let main = NSScreen.screens[0].frame
    // screencapture uses a top-left-origin global coordinate space
    let r = screen.frame
    let rectArg = "\(Int(r.minX)),\(Int(main.maxY - r.maxY)),\(Int(r.width)),\(Int(r.height))"

    let url = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("shotty-\(UUID().uuidString).png")
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    p.arguments = ["-x", "-o", "-R", rectArg, url.path]     // silent, no shadow, no UI of its own
    p.terminationHandler = { _ in
        DispatchQueue.main.async {
            defer { try? FileManager.default.removeItem(at: url) }
            guard let img = NSImage(contentsOf: url) else { return }
            img.size = r.size                                // pixels → points, so the overlay sits 1:1
            show(img, on: screen)
        }
    }
    try? p.run()
}

func show(_ img: NSImage, on screen: NSScreen) {
    let w = OverlayWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
    w.level = .screenSaver                                   // above the menu bar as well
    w.backgroundColor = .clear
    w.isOpaque = false
    w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    w.isReleasedWhenClosed = false

    let v = Overlay(shot: img, size: screen.frame.size, scale: screen.backingScaleFactor)
    v.onClose = { w.close(); live = nil }
    w.contentView = v

    live = w
    NSApp.activate(ignoringOtherApps: true)
    w.makeKeyAndOrderFront(nil)
    w.makeFirstResponder(v)
}

// ── Global hotkey (Carbon; needs no Accessibility permission) ─────────────
var hotKeyRef: EventHotKeyRef?
func installHotKey() {
    var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in capture(); return noErr }, 1, &spec, nil, nil)
    let id = EventHotKeyID(signature: OSType(0x53484f54), id: 1)
    RegisterEventHotKey(hotKeyCode, hotKeyMods, id, GetApplicationEventTarget(), 0, &hotKeyRef)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    func applicationDidFinishLaunching(_ n: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "✂︎"
        let menu = NSMenu()
        menu.addItem(withTitle: "Capture  ⌘⇧2", action: #selector(grab), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        installHotKey()
    }
    @objc func grab() { capture() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

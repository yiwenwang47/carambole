//
//  TokenPileScene.swift
//  carambole
//
//  The 03 Gravité pile (design/motion.html `.c3` + its Matter.js script): today's
//  elements as pill-shaped physics tokens that fall into a pile above the bottom
//  buttons. Palette fills for new and review, dashed outline = fragile.
//  Tokens can be dragged and thrown; `shake()` tosses them (Secouer); device tilt
//  (CoreMotion) leans the gravity. `sync(_:)` diffs the set: tokens whose element
//  left the queue fall through the floor and fade, new ones drop in from the top —
//  the pile is never rebuilt. Reduce motion: tokens sit settled in rows, static.
//
//  Shapes are always capsules (pills), never dots. Colours come from the
//  learner's palette (`AppPalette.current`): new / review fills, a dashed
//  fragile outline, and in Surimpression the fills multiply where they overlap.
//
//  Labels are never cut (no « … »): a label wider than one line wraps onto a
//  second line in a taller pill (`PillLayout`). Every label of every book fits
//  in 2 lines (`_selfTest`). A 2-line pill joins and leaves exactly like a
//  1-line one; only its spawn point is sized to it, so it starts fully above
//  the top edge and inside the side walls.
//
//  Smooth drop: tokens are spawned one per ~30 ms (not all in one frame), pill
//  textures are cached, the walls are only rebuilt when the size really
//  changes, and a long frame never turns into one big physics step.
//

import CoreMotion
import SpriteKit
import UIKit

// MARK: - Token model

/// One token on the pile. Identity is the element id.
struct TokenSpec: Identifiable, Equatable {
    enum Kind: Equatable {
        case new, review, fragile
    }

    let id: String
    let label: String
    let kind: Kind
}

// MARK: - Scene

final class TokenPileScene: SKScene {
    // MARK: Constants (motion.html 03 script, Matter units → SpriteKit)

    /// Pill height (Matter `h = 34`). A 2-line pill adds one line height (52).
    private static let tokenHeight: CGFloat = 34
    /// 1-line pill width = max(64, text + 30); text up to 146 pt stays on one
    /// line (176 pt pill, as before).
    private static let minWidth: CGFloat = 64
    private static let oneLineText: CGFloat = 146
    /// Widest text box of a 2-line pill. The widest real need is Book 1's
    /// « Terminaisons masculines : / -age, -ment, -eau » at ~159 pt (+3% kerning
    /// margin 164), so the widest pill is ~189–196 pt: under half of a 390 pt
    /// screen. Most 2-line pills are narrower: they take the narrowest width
    /// that still breaks the label into 2 lines (balanced lines).
    private static let twoLineText: CGFloat = 166
    /// Text inset from the pill's ends (both 1- and 2-line pills).
    private static let textPad: CGFloat = 15
    /// Matter gravity 1.1 (×0.001 px/ms²) = 1100 pt/s²; SpriteKit is 150 pt/m.
    /// Doubled from the prototype: the user found the drop too slow.
    private static let gravity: CGFloat = 2200 / 150
    /// Initial downward speed of arriving tokens (pt/s).
    private static let dropSpeed: CGFloat = 900
    /// More tokens than this would overflow the screen; the count still says all.
    private static let maxTokens = 48
    /// Gap between two arriving tokens.
    private static let spawnGap: TimeInterval = 0.03
    /// Longest physics step allowed (a hitch is simulated slower, not further).
    private static let maxStep: TimeInterval = 1.0 / 40

    // MARK: Configuration (set by TodayView before / while presented)

    /// Distance from the scene's bottom edge to the floor (button row + 10 pt).
    var floorInset: CGFloat = 94 {
        didSet { if floorInset != oldValue { layoutBounds() } }
    }

    /// Accessibility reduce motion: settled rows, no drag, no tilt, no shake.
    var reduceMotion = false

    /// True while a finger holds a token, or for a moment after the release, so a
    /// rightward throw is not mistaken for the swipe-back gesture.
    var isHandlingTouch: Bool {
        grab != nil || CACurrentMediaTime() - lastRelease < 0.35
    }

    // MARK: State

    private var nodes: [String: SKSpriteNode] = [:]
    private var specs: [String: TokenSpec] = [:]
    /// Spec order, for the reduce-motion row layout.
    private var order: [String] = []
    private var pending: [TokenSpec]?
    private var walls: SKNode?
    private let motion = CMMotionManager()

    private struct Grab {
        let node: SKSpriteNode
        let anchor: SKNode
        let joint: SKPhysicsJointSpring
    }
    private var grab: Grab?
    private var lastRelease: CFTimeInterval = 0
    private var lastUpdate: TimeInterval?
    private var wallSize: CGSize = .zero
    private var wallInset: CGFloat = -1
    private static var textureCache: [String: SKTexture] = [:]

    // MARK: Lifecycle

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .white
    }

    convenience override init() {
        self.init(size: CGSize(width: 1, height: 1))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .white
        lastUpdate = nil
        physicsWorld.gravity = CGVector(dx: 0, dy: -Self.gravity)
        layoutBounds()
        startTilt()
        if let p = pending, size.width > 1 {
            pending = nil
            sync(p)
        }
    }

    override func willMove(from view: SKView) {
        motion.stopDeviceMotionUpdates()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 1 else { return }
        layoutBounds()
        if reduceMotion { layoutSettled() }
        if let p = pending, view != nil {
            pending = nil
            sync(p)
        }
    }

    // MARK: Walls

    /// Floor + side walls as one edge chain. The walls run far above the screen so
    /// tokens spawned (or tossed) above the top stay in the column.
    private func layoutBounds() {
        guard size.width > 1, size != wallSize || floorInset != wallInset else { return }
        wallSize = size
        wallInset = floorInset
        walls?.removeFromParent()
        let top = size.height * 4
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: top))
        path.addLine(to: CGPoint(x: 0, y: floorInset))
        path.addLine(to: CGPoint(x: size.width, y: floorInset))
        path.addLine(to: CGPoint(x: size.width, y: top))
        let node = SKNode()
        let body = SKPhysicsBody(edgeChainFrom: path)
        body.friction = 0.3
        body.restitution = 0.25
        node.physicsBody = body
        addChild(node)
        walls = node
    }

    // MARK: Sync

    /// Diff the pile against `newSpecs`: removed ids fall out, added ids drop in,
    /// kind changes (e.g. review → fragile) restyle in place.
    func sync(_ newSpecs: [TokenSpec]) {
        let capped = Array(newSpecs.prefix(Self.maxTokens))
        guard view != nil, size.width > 1 else {
            pending = capped
            return
        }
        let incoming = Set(capped.map(\.id))

        // Leaving: let them fall through the floor and fade.
        for (id, node) in nodes where !incoming.contains(id) {
            if grab?.node === node { releaseGrab() }
            leave(node)
            nodes[id] = nil
            specs[id] = nil
        }

        // Restyle kept tokens whose kind changed.
        for spec in capped {
            if let node = nodes[spec.id], specs[spec.id] != spec {
                node.texture = Self.texture(spec)
                node.blendMode = Self.blend(spec)
                specs[spec.id] = spec
            }
        }

        // Arriving: drop in from above, staggered (prototype: `-40 - i*30`; a bit
        // wider here so the longer real labels never spawn interpenetrating).
        let arriving = capped.filter { nodes[$0.id] == nil }
        let made = arriving.map { spec -> (TokenSpec, SKSpriteNode) in
            let node = makeToken(spec)
            if !reduceMotion { node.zRotation = CGFloat.random(in: -0.6...0.6) }
            return (spec, node)
        }
        // All of a batch enter from one height (as before), now high enough that
        // the tallest tilted pill of the batch starts wholly above the top edge:
        // a 2-line pill never pops in already half on screen.
        let lift = made.map { Self.extent(of: $0.1).height }.max() ?? 0
        for (i, (spec, node)) in made.enumerated() {
            nodes[spec.id] = node
            specs[spec.id] = spec
            if reduceMotion {
                node.physicsBody?.isDynamic = false
                addChild(node)
            } else {
                // One token per `spawnGap`, each entering just above the top edge
                // already moving at `dropSpeed`: the work (and the contacts) are
                // spread over frames instead of one tall column at once. Its x
                // keeps the whole tilted pill inside the side walls, so a wide
                // 2-line pill never spawns into a wall and gets kicked out.
                let half = Self.extent(of: node).width
                let lo = half + 2, hi = size.width - half - 2
                node.position = CGPoint(x: hi > lo ? CGFloat.random(in: lo...hi) : size.width / 2,
                                        y: size.height + lift + 2)
                run(.sequence([.wait(forDuration: Self.spawnGap * Double(i)), .run { [weak self, weak node] in
                    guard let self, let node, self.nodes[spec.id] === node else { return }
                    node.position.y = self.size.height + lift + 2
                    node.physicsBody?.velocity = CGVector(dx: 0, dy: -Self.dropSpeed)
                    self.addChild(node)
                }]))
            }
        }
        order = capped.map(\.id)
        if reduceMotion { layoutSettled() }
    }

    // MARK: Frame

    /// Caps the simulated time per frame: after a hitch the pile moves a normal
    /// step instead of one huge one (huge steps push pills into each other and
    /// they burst apart).
    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard let last = lastUpdate else { return }
        let dt = currentTime - last
        physicsWorld.speed = dt > Self.maxStep ? CGFloat(Self.maxStep / dt) : 1
    }

    /// Half-width and half-height of a node's tilted bounding box.
    private static func extent(of node: SKSpriteNode) -> CGSize {
        let c = abs(cos(node.zRotation)), s = abs(sin(node.zRotation))
        let w = node.size.width / 2, h = node.size.height / 2
        return CGSize(width: w * c + h * s, height: w * s + h * c)
    }

    /// Leaving (any height): collisions off, it falls through the pile and the
    /// floor, behind the start buttons, fading out in 0.7 s.
    private func leave(_ node: SKSpriteNode) {
        node.name = nil
        // Not yet dropped in: just forget it.
        guard node.parent != nil else { return }
        if let body = node.physicsBody {
            body.categoryBitMask = 0
            body.collisionBitMask = 0
            body.contactTestBitMask = 0
            body.isDynamic = !reduceMotion
        }
        let fade = SKAction.fadeOut(withDuration: reduceMotion ? 0.25 : 0.7)
        node.run(.sequence([fade, .removeFromParent()]))
    }

    // MARK: Reduce motion: settled rows

    /// Pack tokens left-to-right in rows up from the floor, a settled pile without
    /// any falling. Rows alternate their start a little so it reads as stacked.
    private func layoutSettled() {
        guard size.width > 1 else { return }
        let inset: CGFloat = 12
        // Rows first, then each row as tall as its tallest pill (1- or 2-line),
        // pills centred on the row's mid-line.
        var rows: [[SKSpriteNode]] = [[]]
        var x = inset
        for id in order {
            guard let node = nodes[id] else { continue }
            if node.parent == nil { addChild(node) }
            let w = node.size.width
            if x + w > size.width - inset, x > inset + 1 {
                rows.append([])
                x = inset + (rows.count.isMultiple(of: 2) ? 18 : 0)
            }
            node.zRotation = 0
            node.position.x = x + w / 2
            node.physicsBody?.isDynamic = false
            rows[rows.count - 1].append(node)
            x += w + 4
        }
        var y = floorInset
        for row in rows where !row.isEmpty {
            let h = row.map(\.size.height).max() ?? Self.tokenHeight
            for node in row { node.position.y = y + h / 2 }
            y += h + 2
        }
    }

    // MARK: Token nodes

    private func makeToken(_ spec: TokenSpec) -> SKSpriteNode {
        let texture = Self.texture(spec)
        let node = SKSpriteNode(texture: texture, size: texture.size())
        node.name = "token"
        node.blendMode = Self.blend(spec)
        let w = node.size.width, h = node.size.height, r = h / 2
        // Capsule body: a box between two end circles (all convex, all pills).
        let body = SKPhysicsBody(bodies: [
            SKPhysicsBody(rectangleOf: CGSize(width: max(1, w - h), height: h)),
            SKPhysicsBody(circleOfRadius: r, center: CGPoint(x: -(w - h) / 2, y: 0)),
            SKPhysicsBody(circleOfRadius: r, center: CGPoint(x: (w - h) / 2, y: 0)),
        ])
        body.restitution = 0.25
        body.friction = 0.3
        body.linearDamping = 0.1
        body.angularDamping = 0.2
        body.usesPreciseCollisionDetection = true
        node.physicsBody = body
        return node
    }

    /// Cached texture for a pill (label + kind + palette).
    private static func texture(_ spec: TokenSpec) -> SKTexture {
        let palette = AppPalette.current
        let key = "\(palette.rawValue)|\(spec.kind)|\(spec.label)"
        if let t = textureCache[key] { return t }
        let t = SKTexture(image: pillImage(spec, theme: palette.theme))
        textureCache[key] = t
        return t
    }

    /// Surimpression: coloured pills multiply where they overlap.
    private static func blend(_ spec: TokenSpec) -> SKBlendMode {
        AppPalette.current.theme.overprint && spec.kind != .fragile ? .multiply : .alpha
    }

    /// Renders one pill (motion.html `pill()` + fill/stroke rules) with its label in
    /// Manrope 400 13pt, centered 1pt low as in the prototype. Fills come from the
    /// palette; text is always ink.
    static func pillImage(_ spec: TokenSpec, theme: AppTheme) -> UIImage {
        let ink = UIColor(AppColor.ink)
        let layout = PillLayout(shortLabel(spec.label))
        let size = layout.size
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            // Multiply pills sit on opaque white: white × what's below = no
            // change, while transparent corners would multiply to black.
            if theme.overprint && spec.kind != .fragile {
                UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: size))
            }
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
            let pill = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
            pill.lineWidth = 1
            switch spec.kind {
            case .review:
                UIColor(hex: theme.tokenReview).setFill(); pill.fill()
            case .new:
                UIColor(hex: theme.tokenNew).setFill(); pill.fill()
            case .fragile:
                // White fill so overlapping pills don't show through the dashes.
                UIColor.white.setFill(); pill.fill()
                pill.lineWidth = 1.5
                pill.setLineDash([3, 3], count: 2, phase: 0)
                UIColor(hex: theme.fragile).setStroke(); pill.stroke()
            }
            var attrs = PillLayout.attributes
            attrs[.foregroundColor] = ink
            (layout.text as NSString).draw(with: layout.textRect, options: [.usesLineFragmentOrigin],
                                           attributes: attrs, context: nil)
        }
    }

    /// Size and text box of one pill. Never truncates: text up to `oneLineText`
    /// is one line; wider text word-wraps in the narrowest box (≤ `twoLineText`)
    /// that holds it in 2 lines; and should a label ever need 3, the pill grows
    /// a line rather than cutting it (`_selfTest` fails first).
    struct PillLayout {
        let text: String
        let lines: Int
        let size: CGSize
        let textRect: CGRect

        static let font = AppFonts.uiFont(AppFonts.manrope, size: 13, wght: 400)
        static let attributes: [NSAttributedString.Key: Any] = {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            style.lineBreakMode = .byWordWrapping
            return [.font: font, .paragraphStyle: style]
        }()

        init(_ label: String) {
            let text = Self.frenchSpacing(label)
            self.text = text
            let lineH = Self.font.lineHeight
            let oneW = ceil((text as NSString).size(withAttributes: Self.attributes).width)
            var box = CGSize(width: oneW, height: lineH)
            var lines = 1
            if oneW > TokenPileScene.oneLineText {
                // Narrowest whole-point width that still gives 2 lines (line
                // count only falls as the box widens), else the widest box.
                var lo = Int(ceil(oneW / 2)), hi = Int(TokenPileScene.twoLineText)
                if Self.measure(text, width: CGFloat(hi)).lines <= 2 {
                    while lo < hi {
                        let mid = (lo + hi) / 2
                        if Self.measure(text, width: CGFloat(mid)).lines <= 2 { hi = mid } else { lo = mid + 1 }
                    }
                }
                let m = Self.measure(text, width: CGFloat(hi))
                box = CGSize(width: CGFloat(hi), height: m.height)
                lines = m.lines
            }
            self.lines = lines
            let pad = TokenPileScene.textPad
            let usedW = lines == 1 ? oneW : Self.measure(text, width: box.width).width
            let w = max(TokenPileScene.minWidth, usedW + 2 * pad)
            let h = TokenPileScene.tokenHeight + CGFloat(lines - 1) * ceil(lineH)
            size = CGSize(width: w, height: h)
            // Centred in the pill, 1 pt low as in the prototype.
            textRect = CGRect(x: (w - box.width) / 2, y: (h - CGFloat(lines) * lineH) / 2 + 1,
                              width: box.width, height: max(box.height, CGFloat(lines) * lineH) + 1)
        }

        /// Wrapped size and line count of `text` in a box `width` wide.
        static func measure(_ text: String, width: CGFloat) -> (width: CGFloat, height: CGFloat, lines: Int) {
            let r = (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
            return (ceil(r.width), ceil(r.height), max(1, Int((r.height / font.lineHeight).rounded())))
        }

        /// French spacing: the space before « : ; ? ! » » and after « « » is a
        /// no-break space, so a line never starts with « : » or ends on « « ».
        /// Same glyphs and widths; the label's text is unchanged.
        static func frenchSpacing(_ s: String) -> String {
            s.replacingOccurrences(of: #" ([:;?!»])"#, with: "\u{00A0}$1", options: .regularExpression)
                .replacingOccurrences(of: "« ", with: "«\u{00A0}")
        }
    }

    /// Element labels can be long ("ne ... jamais (never)"): drop the English gloss
    /// in parentheses; whatever is still wider than one line wraps to a second.
    static func shortLabel(_ label: String) -> String {
        let stripped = label.replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
        let trimmed = stripped.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? label : trimmed
    }

    // MARK: Secouer

    /// Toss every token up (motion.html: vx ±7, vy −10…−20 px/frame at 60 fps).
    func shake() {
        guard !reduceMotion else { return }
        releaseGrab()
        for node in nodes.values {
            guard let body = node.physicsBody else { continue }
            body.velocity = CGVector(dx: CGFloat.random(in: -0.5...0.5) * 14 * 60,
                                     dy: (10 + CGFloat.random(in: 0...10)) * 60)
            body.angularVelocity = CGFloat.random(in: -4...4)
        }
    }

    // MARK: Tilt (CoreMotion)

    /// Lean gravity sideways with the device; it never points up, so a phone held
    /// flat or upside down keeps the pile on the floor.
    private func startTilt() {
        guard !reduceMotion, motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let g = data?.gravity else { return }
            let gx = CGFloat(max(-1, min(1, g.x)))
            let gy = CGFloat(min(-0.6, g.y))
            self.physicsWorld.gravity = CGVector(dx: gx * Self.gravity, dy: gy * Self.gravity)
        }
    }

    // MARK: Drag / throw

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !reduceMotion, grab == nil, let touch = touches.first else { return }
        let p = touch.location(in: self)
        guard let node = nodes(at: p).first(where: { $0.name == "token" }) as? SKSpriteNode,
              let body = node.physicsBody else { return }
        // A static anchor under the finger, joined by a soft spring (Matter's
        // MouseConstraint, stiffness 0.2): the token hangs from where it was held.
        let anchor = SKNode()
        anchor.position = p
        let anchorBody = SKPhysicsBody(circleOfRadius: 1)
        anchorBody.isDynamic = false
        anchorBody.categoryBitMask = 0
        anchorBody.collisionBitMask = 0
        anchor.physicsBody = anchorBody
        addChild(anchor)
        let joint = SKPhysicsJointSpring.joint(withBodyA: anchorBody, bodyB: body, anchorA: p, anchorB: p)
        joint.frequency = 6
        joint.damping = 0.8
        physicsWorld.add(joint)
        node.zPosition = (nodes.values.map(\.zPosition).max() ?? 0) + 1
        grab = Grab(node: node, anchor: anchor, joint: joint)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let grab, let touch = touches.first else { return }
        grab.anchor.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseGrab()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseGrab()
    }

    private func releaseGrab() {
        guard let grab else { return }
        physicsWorld.remove(grab.joint)
        grab.anchor.removeFromParent()
        // Keep the throw, but cap it so a flick can't tunnel through a wall.
        if let body = grab.node.physicsBody {
            let v = body.velocity
            let speed = hypot(v.dx, v.dy)
            let cap: CGFloat = 2400
            if speed > cap { body.velocity = CGVector(dx: v.dx * cap / speed, dy: v.dy * cap / speed) }
        }
        self.grab = nil
        lastRelease = CACurrentMediaTime()
    }
}

#if DEBUG
extension TokenPileScene {
    /// Every element label of every book fits a pill in at most 2 lines, with
    /// the real font and UIKit wrapping. Off the main thread (it lays out ~1,900
    /// labels); a failure asserts.
    static func _selfTest() {
        DispatchQueue.global(qos: .utility).async {
            let short = PillLayout("il y a")
            assert(short.lines == 1 && short.size.height == tokenHeight, "short label: one line")
            let long = PillLayout(shortLabel("Terminaisons masculines : -age, -ment, -eau"))
            assert(long.lines == 2 && long.size.width <= twoLineText + 2 * textPad, "longest label: 2 lines")
            var twoLine = 0, widest: CGFloat = 0
            for descriptor in BookCatalog.all {
                for element in ContentLoader.loadBook(descriptor).allElements {
                    let layout = PillLayout(shortLabel(element.label))
                    assert(layout.lines <= 2, "pill needs \(layout.lines) lines: \(element.label)")
                    if layout.lines == 2 { twoLine += 1 }
                    widest = max(widest, layout.size.width)
                }
            }
            print("TokenPileScene._selfTest: ok, \(twoLine) two-line pills, widest \(widest) pt")
        }
    }
}
#endif

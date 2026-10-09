//
//  TokenPileScene.swift
//  carambole
//
//  The 03 Gravité pile (design/motion.html `.c3` + its Matter.js script): today's
//  elements as pill-shaped physics tokens that fall into a pile above the bottom
//  buttons. White + ink outline = new, black = review, dashed outline = fragile.
//  Tokens can be dragged and thrown; `shake()` tosses them (Secouer); device tilt
//  (CoreMotion) leans the gravity. `sync(_:)` diffs the set: tokens whose element
//  left the queue fall through the floor and fade, new ones drop in from the top —
//  the pile is never rebuilt. Reduce motion: tokens sit settled in rows, static.
//
//  Shapes are always capsules (pills), never dots.
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

    /// Pill height (Matter `h = 34`).
    private static let tokenHeight: CGFloat = 34
    /// Pill width = max(64, text + 30), capped so long element labels stay pills.
    private static let minWidth: CGFloat = 64
    private static let maxWidth: CGFloat = 176
    /// Matter gravity 1.1 (×0.001 px/ms²) = 1100 pt/s²; SpriteKit is 150 pt/m.
    /// Doubled from the prototype: the user found the drop too slow.
    private static let gravity: CGFloat = 2200 / 150
    /// Initial downward speed of arriving tokens (pt/s).
    private static let dropSpeed: CGFloat = 900
    /// More tokens than this would overflow the screen; the count still says all.
    private static let maxTokens = 48

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

    // MARK: Lifecycle

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    convenience override init() {
        self.init(size: CGSize(width: 1, height: 1))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        backgroundColor = .clear
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
        guard size.width > 1 else { return }
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
                let image = Self.pillImage(spec)
                node.texture = SKTexture(image: image)
                specs[spec.id] = spec
            }
        }

        // Arriving: drop in from above, staggered (prototype: `-40 - i*30`; a bit
        // wider here so the longer real labels never spawn interpenetrating).
        let arriving = capped.filter { nodes[$0.id] == nil }
        for (i, spec) in arriving.enumerated() {
            let node = makeToken(spec)
            if reduceMotion {
                node.physicsBody?.isDynamic = false
            } else {
                let x = 40 + CGFloat.random(in: 0...max(1, size.width - 80))
                node.position = CGPoint(x: x, y: size.height + 40 + CGFloat(i) * 46)
                node.zRotation = CGFloat.random(in: -0.6...0.6)
                // Thrown in, not dropped from rest: the whole column already
                // falls at `dropSpeed`, so even a tall stack lands in about a second.
                node.physicsBody?.velocity = CGVector(dx: 0, dy: -Self.dropSpeed)
            }
            addChild(node)
            nodes[spec.id] = node
            specs[spec.id] = spec
        }
        order = capped.map(\.id)
        if reduceMotion { layoutSettled() }
    }

    private func leave(_ node: SKSpriteNode) {
        node.name = nil
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
        let h = Self.tokenHeight
        let inset: CGFloat = 12
        var x = inset
        var row = 0
        for id in order {
            guard let node = nodes[id] else { continue }
            let w = node.size.width
            if x + w > size.width - inset, x > inset + 1 {
                row += 1
                x = inset + (row.isMultiple(of: 2) ? 0 : 18)
            }
            node.zRotation = 0
            node.position = CGPoint(x: x + w / 2, y: floorInset + h / 2 + CGFloat(row) * (h + 2))
            node.physicsBody?.isDynamic = false
            x += w + 4
        }
    }

    // MARK: Token nodes

    private func makeToken(_ spec: TokenSpec) -> SKSpriteNode {
        let image = Self.pillImage(spec)
        let node = SKSpriteNode(texture: SKTexture(image: image), size: image.size)
        node.name = "token"
        let w = image.size.width, h = image.size.height, r = h / 2
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

    /// Renders one pill (motion.html `pill()` + fill/stroke rules) with its label in
    /// Manrope 400 13pt, centered 1pt low as in the prototype.
    static func pillImage(_ spec: TokenSpec) -> UIImage {
        let font = AppFonts.uiFont(AppFonts.manrope, size: 13, wght: 400)
        let ink = UIColor(AppColor.ink)
        let paper = UIColor(AppColor.paper)
        let text = shortLabel(spec.label)
        let textW = (text as NSString).size(withAttributes: [.font: font]).width
        let w = min(maxWidth, max(minWidth, ceil(textW) + 30))
        let h = tokenHeight
        let size = CGSize(width: w, height: h)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
            let pill = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
            pill.lineWidth = 1
            switch spec.kind {
            case .review:
                ink.setFill(); pill.fill()
            case .new:
                UIColor.white.setFill(); pill.fill()
                ink.setStroke(); pill.stroke()
            case .fragile:
                // Paper fill so overlapping pills don't show through the dashes.
                paper.setFill(); pill.fill()
                pill.setLineDash([3, 3], count: 2, phase: 0)
                ink.setStroke(); pill.stroke()
            }
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            style.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: spec.kind == .review ? paper : ink,
                .paragraphStyle: style,
            ]
            let lineH = font.lineHeight
            let textRect = CGRect(x: 15, y: (h - lineH) / 2 + 1, width: w - 30, height: lineH)
            (text as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }

    /// Element labels can be long ("ne ... jamais (never)"): drop the English gloss
    /// in parentheses; the pill truncates whatever is still too wide.
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

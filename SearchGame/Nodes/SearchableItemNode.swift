import SpriteKit

protocol SearchableItemDelegate: AnyObject {
    func itemWasFound(_ item: SearchableItemNode)
}

class SearchableItemNode: SKSpriteNode {
    
    // MARK: - Properties
    
    let itemType: String
    let animationType: AnimationType
    private(set) var isFound: Bool = false
    weak var delegate: SearchableItemDelegate?
    
    // MARK: - Initialization
    
    init(type: String, animation: AnimationType = .bobbing, texture: SKTexture? = nil) {
        self.itemType = type
        self.animationType = animation
        
        // Prefer generated/real art if present in bundle, fallback to procedural placeholder.
        let nodeTexture =
            texture
            ?? AssetLoader.texture(named: type)
            ?? SearchableItemNode.createPlaceholderTexture(for: type)
        let size = CGSize(width: 48, height: 48)  // Smaller size to blend in
        
        super.init(texture: nodeTexture, color: .clear, size: size)
        
        self.name = "searchable_\(type)"
        self.zPosition = 10
        
        // Start idle animation
        startAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        switch animationType {
        case .bobbing:
            startBobbingAnimation()
        case .swaying:
            startSwayingAnimation()
        case .floating:
            startFloatingAnimation()
        case .walking:
            startWalkingAnimation()
        default:
            startBobbingAnimation()  // Default to bobbing
        }
    }
    
    private func startBobbingAnimation() {
        let bobHeight: CGFloat = 2
        let duration = Double.random(in: 1.2...1.8)
        
        let moveUp = SKAction.moveBy(x: 0, y: bobHeight, duration: duration)
        let moveDown = SKAction.moveBy(x: 0, y: -bobHeight, duration: duration)
        moveUp.timingMode = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut
        
        // Random start delay so items don't all sync
        let delay = SKAction.wait(forDuration: Double.random(in: 0...1))
        let bob = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
        
        run(SKAction.sequence([delay, bob]))
    }
    
    private func startSwayingAnimation() {
        let swayAngle: CGFloat = 0.05
        let duration = Double.random(in: 1.5...2.5)
        
        let swayRight = SKAction.rotate(byAngle: swayAngle, duration: duration)
        let swayLeft = SKAction.rotate(byAngle: -swayAngle * 2, duration: duration * 2)
        let swayBack = SKAction.rotate(byAngle: swayAngle, duration: duration)
        
        swayRight.timingMode = .easeInEaseOut
        swayLeft.timingMode = .easeInEaseOut
        swayBack.timingMode = .easeInEaseOut
        
        let delay = SKAction.wait(forDuration: Double.random(in: 0...1))
        let sway = SKAction.repeatForever(SKAction.sequence([swayRight, swayLeft, swayBack]))
        
        run(SKAction.sequence([delay, sway]))
    }
    
    private func startFloatingAnimation() {
        let bobHeight: CGFloat = 3
        let duration = Double.random(in: 1.8...2.5)
        
        let moveUp = SKAction.moveBy(x: 0, y: bobHeight, duration: duration)
        let moveDown = SKAction.moveBy(x: 0, y: -bobHeight, duration: duration)
        moveUp.timingMode = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut
        
        let rotateRight = SKAction.rotate(byAngle: 0.02, duration: duration)
        let rotateLeft = SKAction.rotate(byAngle: -0.02, duration: duration)
        
        let bob = SKAction.sequence([moveUp, moveDown])
        let rotate = SKAction.sequence([rotateRight, rotateLeft])
        
        let delay = SKAction.wait(forDuration: Double.random(in: 0...1))
        let combined = SKAction.repeatForever(SKAction.group([bob, rotate]))
        
        run(SKAction.sequence([delay, combined]))
    }
    
    private func startWalkingAnimation() {
        let distance: CGFloat = 30
        let duration = Double.random(in: 2.0...3.0)
        
        let moveRight = SKAction.moveBy(x: distance, y: 0, duration: duration)
        let moveLeft = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let flipRight = SKAction.scaleX(to: 1.0, duration: 0.1)
        let flipLeft = SKAction.scaleX(to: -1.0, duration: 0.1)
        
        let walkRight = SKAction.sequence([flipRight, moveRight])
        let walkLeft = SKAction.sequence([flipLeft, moveLeft])
        
        let delay = SKAction.wait(forDuration: Double.random(in: 0...1))
        let walk = SKAction.repeatForever(SKAction.sequence([walkRight, walkLeft]))
        
        run(SKAction.sequence([delay, walk]))
    }
    
    // MARK: - Placeholder Textures
    
    private static func createPlaceholderTexture(for type: String) -> SKTexture {
        switch type {
        case "rock":
            return createRockTexture()
        case "flower":
            return createFlowerTexture()
        case "mushroom":
            return createMushroomTexture()
        case "duck":
            return createDuckTexture()
        default:
            return createGenericTexture(type: type)
        }
    }
    
    private static func createRockTexture() -> SKTexture {
        let size = CGSize(width: 48, height: 48)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        // Rock shape - grayish with some variation
        let rockColor = UIColor(red: 0.55, green: 0.55, blue: 0.52, alpha: 1.0)
        let highlightColor = UIColor(red: 0.65, green: 0.65, blue: 0.62, alpha: 1.0)
        
        // Main rock body
        context.setFillColor(rockColor.cgColor)
        let rockPath = CGMutablePath()
        rockPath.move(to: CGPoint(x: 8, y: 12))
        rockPath.addCurve(to: CGPoint(x: 40, y: 12), control1: CGPoint(x: 12, y: 6), control2: CGPoint(x: 36, y: 6))
        rockPath.addCurve(to: CGPoint(x: 44, y: 28), control1: CGPoint(x: 44, y: 16), control2: CGPoint(x: 46, y: 24))
        rockPath.addCurve(to: CGPoint(x: 8, y: 28), control1: CGPoint(x: 36, y: 36), control2: CGPoint(x: 12, y: 36))
        rockPath.closeSubpath()
        context.addPath(rockPath)
        context.fillPath()
        
        // Black outline
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.5)
        context.addPath(rockPath)
        context.strokePath()
        
        // Highlight
        context.setFillColor(highlightColor.cgColor)
        context.fillEllipse(in: CGRect(x: 14, y: 14, width: 12, height: 8))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    private static func createFlowerTexture() -> SKTexture {
        let size = CGSize(width: 48, height: 48)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Stem
        context.setStrokeColor(UIColor(red: 0.4, green: 0.65, blue: 0.4, alpha: 1.0).cgColor)
        context.setLineWidth(3)
        context.move(to: CGPoint(x: centerX, y: 8))
        context.addLine(to: CGPoint(x: centerX, y: centerY - 4))
        context.strokePath()
        
        // Petals - pastel pink
        let petalColor = UIColor(red: 1.0, green: 0.75, blue: 0.80, alpha: 1.0)
        context.setFillColor(petalColor.cgColor)
        
        for i in 0..<5 {
            let angle = CGFloat(i) * (2 * .pi / 5) - .pi / 2
            let petalX = centerX + cos(angle) * 10
            let petalY = centerY + 6 + sin(angle) * 10
            context.fillEllipse(in: CGRect(x: petalX - 7, y: petalY - 10, width: 14, height: 20))
        }
        
        // Black outlines for petals
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2)
        for i in 0..<5 {
            let angle = CGFloat(i) * (2 * .pi / 5) - .pi / 2
            let petalX = centerX + cos(angle) * 10
            let petalY = centerY + 6 + sin(angle) * 10
            context.strokeEllipse(in: CGRect(x: petalX - 7, y: petalY - 10, width: 14, height: 20))
        }
        
        // Center
        context.setFillColor(UIColor(red: 1.0, green: 0.85, blue: 0.40, alpha: 1.0).cgColor)
        context.fillEllipse(in: CGRect(x: centerX - 6, y: centerY, width: 12, height: 12))
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokeEllipse(in: CGRect(x: centerX - 6, y: centerY, width: 12, height: 12))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    private static func createMushroomTexture() -> SKTexture {
        let size = CGSize(width: 48, height: 48)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let centerX = size.width / 2
        
        // Stem
        let stemColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        context.setFillColor(stemColor.cgColor)
        let stemRect = CGRect(x: centerX - 8, y: 6, width: 16, height: 18)
        context.fill(stemRect)
        
        // Stem outline
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.5)
        context.stroke(stemRect)
        
        // Cap - red
        let capColor = UIColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1.0)
        context.setFillColor(capColor.cgColor)
        let capRect = CGRect(x: centerX - 18, y: 20, width: 36, height: 22)
        context.fillEllipse(in: capRect)
        
        // Cap outline
        context.strokeEllipse(in: capRect)
        
        // White spots
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: centerX - 10, y: 26, width: 8, height: 8))
        context.fillEllipse(in: CGRect(x: centerX + 2, y: 28, width: 6, height: 6))
        context.fillEllipse(in: CGRect(x: centerX - 4, y: 34, width: 5, height: 5))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    private static func createDuckTexture() -> SKTexture {
        let size = CGSize(width: 48, height: 48)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Body - soft yellow
        let bodyColor = UIColor(red: 1.0, green: 0.90, blue: 0.60, alpha: 1.0)
        context.setFillColor(bodyColor.cgColor)
        let bodyRect = CGRect(x: centerX - 16, y: centerY - 10, width: 28, height: 20)
        context.fillEllipse(in: bodyRect)
        
        // Head
        let headRect = CGRect(x: centerX + 4, y: centerY + 2, width: 16, height: 16)
        context.fillEllipse(in: headRect)
        
        // Black outlines
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.5)
        context.strokeEllipse(in: bodyRect)
        context.strokeEllipse(in: headRect)
        
        // Beak
        let beakColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        context.setFillColor(beakColor.cgColor)
        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: centerX + 18, y: centerY + 8))
        beakPath.addLine(to: CGPoint(x: centerX + 28, y: centerY + 10))
        beakPath.addLine(to: CGPoint(x: centerX + 18, y: centerY + 12))
        beakPath.closeSubpath()
        context.addPath(beakPath)
        context.fillPath()
        context.addPath(beakPath)
        context.strokePath()
        
        // Eye
        context.setFillColor(UIColor.black.cgColor)
        context.fillEllipse(in: CGRect(x: centerX + 12, y: centerY + 10, width: 4, height: 4))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    private static func createGenericTexture(type: String) -> SKTexture {
        let size = CGSize(width: 48, height: 48)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        // Generic colored circle with outline
        let colors: [UIColor] = [
            UIColor(red: 0.95, green: 0.75, blue: 0.75, alpha: 1.0),
            UIColor(red: 0.75, green: 0.95, blue: 0.75, alpha: 1.0),
            UIColor(red: 0.75, green: 0.75, blue: 0.95, alpha: 1.0),
            UIColor(red: 0.95, green: 0.95, blue: 0.75, alpha: 1.0)
        ]
        let color = colors[abs(type.hashValue) % colors.count]
        
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(x: 6, y: 6, width: 36, height: 36))
        
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.5)
        context.strokeEllipse(in: CGRect(x: 6, y: 6, width: 36, height: 36))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    // MARK: - Interaction
    
    func handleTap() {
        guard !isFound else { return }
        
        isFound = true
        
        // Stop current animations
        removeAllActions()
        
        // Play sound
        SoundManager.shared.playItemFound()
        
        // Found animation sequence
        let scaleUp = SKAction.scale(to: 1.4, duration: 0.1)
        let sparkle = SKAction.run { [weak self] in self?.addSparkleEffect() }
        let wait = SKAction.wait(forDuration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        let scaleDown = SKAction.scale(to: 0.3, duration: 0.25)
        
        let disappear = SKAction.group([fadeOut, scaleDown])
        let sequence = SKAction.sequence([scaleUp, sparkle, wait, disappear])
        
        run(sequence) { [weak self] in
            guard let self = self else { return }
            self.delegate?.itemWasFound(self)
            self.removeFromParent()
        }
    }
    
    private func addSparkleEffect() {
        let sparkleCount = 6
        
        for i in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: 3)
            sparkle.fillColor = .white
            sparkle.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
            sparkle.lineWidth = 1
            sparkle.zPosition = zPosition + 1
            sparkle.position = .zero
            addChild(sparkle)
            
            let angle = CGFloat(i) / CGFloat(sparkleCount) * .pi * 2
            let distance: CGFloat = 40
            let endPoint = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPoint, duration: 0.25)
            let fade = SKAction.fadeOut(withDuration: 0.25)
            let scale = SKAction.scale(to: 0.2, duration: 0.25)
            let group = SKAction.group([move, fade, scale])
            
            sparkle.run(group) {
                sparkle.removeFromParent()
            }
        }
    }
}

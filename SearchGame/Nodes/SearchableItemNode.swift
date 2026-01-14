import SpriteKit

protocol SearchableItemDelegate: AnyObject {
    func itemWasFound(_ item: SearchableItemNode)
}

class SearchableItemNode: SKSpriteNode {
    
    // MARK: - Properties
    
    let itemType: String
    private(set) var isFound: Bool = false
    weak var delegate: SearchableItemDelegate?
    
    // MARK: - Initialization
    
    init(type: String, texture: SKTexture? = nil) {
        self.itemType = type
        
        // Prefer generated/real art if present in bundle, fallback to procedural placeholder.
        let nodeTexture =
            texture
            ?? AssetLoader.texture(named: type)
            ?? SearchableItemNode.createPlaceholderTexture(for: type)
        let size = CGSize(width: 64, height: 64)
        
        super.init(texture: nodeTexture, color: .clear, size: size)
        
        self.name = "searchable_\(type)"
        self.zPosition = 10
        
        // Add subtle idle animation
        addIdleAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Placeholder
    
    private static func createPlaceholderTexture(for type: String) -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Duck body - soft yellow ellipse
        let bodyColor = UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
        let bodyRect = CGRect(x: centerX - 22, y: centerY - 12, width: 44, height: 32)
        context.setFillColor(bodyColor.cgColor)
        context.fillEllipse(in: bodyRect)
        
        // Duck body shadow/depth
        let shadowColor = UIColor(red: 0.95, green: 0.75, blue: 0.25, alpha: 0.5)
        let shadowRect = CGRect(x: centerX - 18, y: centerY - 8, width: 36, height: 20)
        context.setFillColor(shadowColor.cgColor)
        context.fillEllipse(in: shadowRect.offsetBy(dx: 0, dy: 6))
        
        // Duck head
        let headRect = CGRect(x: centerX + 8, y: centerY + 4, width: 24, height: 24)
        context.setFillColor(bodyColor.cgColor)
        context.fillEllipse(in: headRect)
        
        // Beak
        let beakColor = UIColor(red: 1.0, green: 0.55, blue: 0.20, alpha: 1.0)
        context.setFillColor(beakColor.cgColor)
        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: centerX + 30, y: centerY + 14))
        beakPath.addLine(to: CGPoint(x: centerX + 42, y: centerY + 16))
        beakPath.addLine(to: CGPoint(x: centerX + 30, y: centerY + 20))
        beakPath.closeSubpath()
        context.addPath(beakPath)
        context.fillPath()
        
        // Eye
        context.setFillColor(UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor)
        context.fillEllipse(in: CGRect(x: centerX + 22, y: centerY + 18, width: 5, height: 5))
        
        // Eye highlight
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: centerX + 23, y: centerY + 19, width: 2, height: 2))
        
        // Wing hint
        let wingColor = UIColor(red: 0.95, green: 0.78, blue: 0.30, alpha: 0.7)
        context.setFillColor(wingColor.cgColor)
        let wingRect = CGRect(x: centerX - 10, y: centerY - 2, width: 20, height: 14)
        context.fillEllipse(in: wingRect)
        
        // Tail feathers
        context.setFillColor(bodyColor.cgColor)
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: centerX - 22, y: centerY))
        tailPath.addLine(to: CGPoint(x: centerX - 30, y: centerY + 8))
        tailPath.addLine(to: CGPoint(x: centerX - 26, y: centerY + 4))
        tailPath.addLine(to: CGPoint(x: centerX - 32, y: centerY + 2))
        tailPath.addLine(to: CGPoint(x: centerX - 22, y: centerY - 4))
        tailPath.closeSubpath()
        context.addPath(tailPath)
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    // MARK: - Animations
    
    private func addIdleAnimation() {
        let scaleUp = SKAction.scale(to: 1.05, duration: 1.0)
        let scaleDown = SKAction.scale(to: 0.95, duration: 1.0)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let forever = SKAction.repeatForever(sequence)
        run(forever, withKey: "idle")
    }
    
    // MARK: - Interaction
    
    func handleTap() {
        guard !isFound else { return }
        
        isFound = true
        removeAction(forKey: "idle")
        
        // Play sound
        SoundManager.shared.playItemFound()
        
        // Found animation sequence
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        
        let group = SKAction.group([fadeOut, scaleDown])
        let sequence = SKAction.sequence([scaleUp, group])
        
        // Add sparkle effect
        addSparkleEffect()
        
        run(sequence) { [weak self] in
            guard let self = self else { return }
            self.delegate?.itemWasFound(self)
            self.removeFromParent()
        }
    }
    
    private func addSparkleEffect() {
        let sparkleCount = 8
        
        for i in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: 4)
            sparkle.fillColor = .white
            sparkle.strokeColor = .clear
            sparkle.zPosition = zPosition + 1
            sparkle.position = .zero
            addChild(sparkle)
            
            let angle = CGFloat(i) / CGFloat(sparkleCount) * .pi * 2
            let distance: CGFloat = 60
            let endPoint = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPoint, duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let scale = SKAction.scale(to: 0.1, duration: 0.3)
            let group = SKAction.group([move, fade, scale])
            
            sparkle.run(group) {
                sparkle.removeFromParent()
            }
        }
    }
}

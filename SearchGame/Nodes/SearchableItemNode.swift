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
        
        // Use placeholder if no texture provided
        let nodeTexture = texture ?? SearchableItemNode.createPlaceholderTexture(for: type)
        let size = CGSize(width: 80, height: 80)
        
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
        let size = CGSize(width: 80, height: 80)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        // Draw circle background
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
        context.setFillColor(UIColor.systemYellow.cgColor)
        context.fillEllipse(in: rect)
        
        // Draw border
        context.setStrokeColor(UIColor.systemOrange.cgColor)
        context.setLineWidth(3)
        context.strokeEllipse(in: rect)
        
        // Draw emoji
        let emoji = "🦆"
        let font = UIFont.systemFont(ofSize: 40)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = emoji.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        emoji.draw(in: textRect, withAttributes: attributes)
        
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

import SpriteKit

/// Non-interactive animated decoration (clouds, trees, etc.)
class DecorationNode: SKSpriteNode {
    
    let decorationType: String
    let animationType: AnimationType
    private var animationPath: [CGPoint]?
    private var animationSpeed: CGFloat
    
    // MARK: - Initialization
    
    init(type: String, animation: AnimationType, path: [CGPoint]? = nil, animSpeed: CGFloat = 1.0) {
        self.decorationType = type
        self.animationType = animation
        self.animationPath = path
        self.animationSpeed = animSpeed
        
        // Load texture or create placeholder
        let texture = AssetLoader.texture(named: type) ?? DecorationNode.createPlaceholder(for: type)
        let size = DecorationNode.sizeForType(type)
        
        super.init(texture: texture, color: .clear, size: size)
        
        self.name = "decoration_\(type)"
        self.isUserInteractionEnabled = false
        
        startAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Size
    
    private static func sizeForType(_ type: String) -> CGSize {
        switch type {
        case "cloud", "cloud_small", "cloud_large":
            return CGSize(width: 120, height: 60)
        case "tree":
            return CGSize(width: 80, height: 120)
        case "bush":
            return CGSize(width: 60, height: 40)
        default:
            return CGSize(width: 64, height: 64)
        }
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        switch animationType {
        case .drifting:
            startDriftingAnimation()
        case .swaying:
            startSwayingAnimation()
        case .bobbing:
            startBobbingAnimation()
        case .floating:
            startFloatingAnimation()
        case .flickering:
            startFlickeringAnimation()
        case .driving:
            startDrivingAnimation()
        case .walking:
            startWalkingAnimation()
        case .flowing:
            startFlowingAnimation()
        case .none:
            break
        }
    }
    
    private func startDriftingAnimation() {
        // Clouds drift slowly across the scene
        let driftDistance: CGFloat = 30 * animationSpeed
        let duration = 8.0 / Double(animationSpeed)
        
        let moveRight = SKAction.moveBy(x: driftDistance, y: 0, duration: duration)
        let moveLeft = SKAction.moveBy(x: -driftDistance, y: 0, duration: duration)
        moveRight.timingMode = .easeInEaseOut
        moveLeft.timingMode = .easeInEaseOut
        
        // Also slight vertical movement
        let moveUp = SKAction.moveBy(x: 0, y: 5, duration: duration / 2)
        let moveDown = SKAction.moveBy(x: 0, y: -5, duration: duration / 2)
        let vertical = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
        
        let horizontal = SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft]))
        
        run(SKAction.group([horizontal, vertical]))
    }
    
    private func startSwayingAnimation() {
        // Trees/flowers sway gently
        let swayAngle: CGFloat = 0.03 * animationSpeed
        let duration = 2.0 / Double(animationSpeed)
        
        let swayRight = SKAction.rotate(byAngle: swayAngle, duration: duration)
        let swayLeft = SKAction.rotate(byAngle: -swayAngle * 2, duration: duration * 2)
        let swayBack = SKAction.rotate(byAngle: swayAngle, duration: duration)
        
        swayRight.timingMode = .easeInEaseOut
        swayLeft.timingMode = .easeInEaseOut
        swayBack.timingMode = .easeInEaseOut
        
        run(SKAction.repeatForever(SKAction.sequence([swayRight, swayLeft, swayBack])))
    }
    
    private func startBobbingAnimation() {
        // Gentle up/down bobbing
        let bobHeight: CGFloat = 3 * animationSpeed
        let duration = 1.5 / Double(animationSpeed)
        
        let moveUp = SKAction.moveBy(x: 0, y: bobHeight, duration: duration)
        let moveDown = SKAction.moveBy(x: 0, y: -bobHeight, duration: duration)
        moveUp.timingMode = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut
        
        run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
    }
    
    private func startFloatingAnimation() {
        // Floating on water - bob + slight rotation
        let bobHeight: CGFloat = 4 * animationSpeed
        let duration = 2.0 / Double(animationSpeed)
        
        let moveUp = SKAction.moveBy(x: 0, y: bobHeight, duration: duration)
        let moveDown = SKAction.moveBy(x: 0, y: -bobHeight, duration: duration)
        moveUp.timingMode = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut
        
        let rotateRight = SKAction.rotate(byAngle: 0.02, duration: duration)
        let rotateLeft = SKAction.rotate(byAngle: -0.02, duration: duration)
        
        let bob = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
        let rotate = SKAction.repeatForever(SKAction.sequence([rotateRight, rotateLeft]))
        
        run(SKAction.group([bob, rotate]))
    }
    
    private func startFlickeringAnimation() {
        // Fire/light flickering effect
        let duration = 0.1 / Double(animationSpeed)
        
        let scaleUp = SKAction.scale(to: 1.05, duration: duration)
        let scaleDown = SKAction.scale(to: 0.95, duration: duration)
        let fadeUp = SKAction.fadeAlpha(to: 1.0, duration: duration)
        let fadeDown = SKAction.fadeAlpha(to: 0.8, duration: duration)
        
        let flicker = SKAction.repeatForever(SKAction.sequence([
            SKAction.group([scaleUp, fadeUp]),
            SKAction.group([scaleDown, fadeDown]),
            SKAction.group([scaleUp, fadeDown]),
            SKAction.group([scaleDown, fadeUp])
        ]))
        
        run(flicker)
    }
    
    private func startDrivingAnimation() {
        guard let pathPoints = animationPath, pathPoints.count >= 2 else {
            // Fallback: just move back and forth
            let distance: CGFloat = 200 * animationSpeed
            let duration = 5.0 / Double(animationSpeed)
            
            let moveRight = SKAction.moveBy(x: distance, y: 0, duration: duration)
            let moveLeft = SKAction.moveBy(x: -distance, y: 0, duration: duration)
            
            run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
            return
        }
        
        // Follow path
        var actions: [SKAction] = []
        for i in 0..<pathPoints.count {
            let nextIndex = (i + 1) % pathPoints.count
            let distance = hypot(
                pathPoints[nextIndex].x - pathPoints[i].x,
                pathPoints[nextIndex].y - pathPoints[i].y
            )
            let duration = Double(distance / (50 * animationSpeed))
            
            let move = SKAction.move(to: pathPoints[nextIndex], duration: max(0.5, duration))
            move.timingMode = .easeInEaseOut
            actions.append(move)
        }
        
        run(SKAction.repeatForever(SKAction.sequence(actions)))
    }
    
    private func startWalkingAnimation() {
        // Walk back and forth with slight bobbing
        let distance: CGFloat = 100 * animationSpeed
        let duration = 3.0 / Double(animationSpeed)
        
        let moveRight = SKAction.moveBy(x: distance, y: 0, duration: duration)
        let moveLeft = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let flipRight = SKAction.scaleX(to: 1.0, duration: 0.1)
        let flipLeft = SKAction.scaleX(to: -1.0, duration: 0.1)
        
        let walkRight = SKAction.group([flipRight, moveRight])
        let walkLeft = SKAction.group([flipLeft, moveLeft])
        
        // Add bobbing while walking
        let bobUp = SKAction.moveBy(x: 0, y: 3, duration: 0.2)
        let bobDown = SKAction.moveBy(x: 0, y: -3, duration: 0.2)
        let bob = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        
        run(SKAction.group([
            SKAction.repeatForever(SKAction.sequence([walkRight, walkLeft])),
            bob
        ]))
    }
    
    private func startFlowingAnimation() {
        // Water flowing effect - move texture
        // This is simplified; real water would use shader
        let duration = 2.0 / Double(animationSpeed)
        
        let moveRight = SKAction.moveBy(x: 20, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -20, y: 0, duration: 0)
        
        run(SKAction.repeatForever(SKAction.sequence([moveRight, reset])))
    }
    
    // MARK: - Placeholder
    
    private static func createPlaceholder(for type: String) -> SKTexture {
        let size = sizeForType(type)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        switch type {
        case "cloud", "cloud_small", "cloud_large":
            // Simple cloud shape
            context.setFillColor(UIColor(white: 1.0, alpha: 0.9).cgColor)
            context.fillEllipse(in: CGRect(x: size.width * 0.1, y: size.height * 0.2, width: size.width * 0.5, height: size.height * 0.6))
            context.fillEllipse(in: CGRect(x: size.width * 0.3, y: size.height * 0.1, width: size.width * 0.5, height: size.height * 0.7))
            context.fillEllipse(in: CGRect(x: size.width * 0.5, y: size.height * 0.25, width: size.width * 0.4, height: size.height * 0.5))
            
        case "tree":
            // Simple tree
            context.setFillColor(UIColor(red: 0.55, green: 0.35, blue: 0.20, alpha: 1.0).cgColor)
            context.fill(CGRect(x: size.width * 0.4, y: 0, width: size.width * 0.2, height: size.height * 0.4))
            context.setFillColor(UIColor(red: 0.35, green: 0.60, blue: 0.35, alpha: 1.0).cgColor)
            context.fillEllipse(in: CGRect(x: size.width * 0.1, y: size.height * 0.3, width: size.width * 0.8, height: size.height * 0.7))
            
        default:
            // Generic placeholder
            context.setFillColor(UIColor.gray.withAlphaComponent(0.5).cgColor)
            context.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
}

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var cameraNode: SKCameraNode!
    private var backgroundNode: SKSpriteNode!
    private var hudLayer: SKNode!
    private var counterLabel: SKLabelNode!
    
    private var searchableItems: [SearchableItemNode] = []
    private var foundCount: Int = 0
    private var totalCount: Int = 0
    private var currentLevel: Int = 1
    
    // Camera bounds
    private var minCameraX: CGFloat = 0
    private var maxCameraX: CGFloat = 0
    private var minCameraY: CGFloat = 0
    private var maxCameraY: CGFloat = 0
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        
        setupCamera()
        setupBackground()
        setupHUD()
        setupSearchableItems()
        setupGestures()
        
        // Start background music
        SoundManager.shared.playBackgroundMusic()
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }
    
    private func setupBackground() {
        // Prefer generated/real art if present in bundle, fallback to procedural scene.
        if let tex = AssetLoader.texture(named: "bg_farm_day") {
            let backgroundSize = tex.size()
            backgroundNode = SKSpriteNode(texture: tex, size: backgroundSize)
            backgroundNode.position = CGPoint(x: backgroundSize.width / 2, y: backgroundSize.height / 2)
            backgroundNode.zPosition = -100
            addChild(backgroundNode)
            calculateCameraBounds()
            return
        }

        let backgroundSize = CGSize(width: 2048, height: 1536)

        // Create beautiful gradient background
        backgroundNode = SKSpriteNode(texture: createGradientTexture(size: backgroundSize), size: backgroundSize)
        backgroundNode.position = CGPoint(x: backgroundSize.width / 2, y: backgroundSize.height / 2)
        backgroundNode.zPosition = -100
        addChild(backgroundNode)
        
        // Add scenic elements
        addScenicElements()
        
        // Calculate camera bounds
        calculateCameraBounds()
    }
    
    private func createGradientTexture(size: CGSize) -> SKTexture {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        // Sky gradient (top to middle)
        let skyColors = [
            UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0).cgColor,  // Light sky blue
            UIColor(red: 0.69, green: 0.88, blue: 0.90, alpha: 1.0).cgColor,  // Pale turquoise
            UIColor(red: 0.98, green: 0.91, blue: 0.71, alpha: 1.0).cgColor   // Warm horizon
        ]
        let skyGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: skyColors as CFArray, locations: [0.0, 0.5, 1.0])!
        context.drawLinearGradient(skyGradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: size.height * 0.35), options: [])
        
        // Ground gradient (middle to bottom)
        let groundColors = [
            UIColor(red: 0.56, green: 0.74, blue: 0.56, alpha: 1.0).cgColor,  // Soft green
            UIColor(red: 0.42, green: 0.63, blue: 0.42, alpha: 1.0).cgColor,  // Medium green
            UIColor(red: 0.33, green: 0.52, blue: 0.33, alpha: 1.0).cgColor   // Darker green
        ]
        let groundGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: groundColors as CFArray, locations: [0.0, 0.5, 1.0])!
        context.drawLinearGradient(groundGradient, start: CGPoint(x: 0, y: size.height * 0.4), end: CGPoint(x: 0, y: 0), options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    private func addScenicElements() {
        let bgSize = backgroundNode.size
        
        // Add clouds
        addClouds(in: bgSize)
        
        // Add hills in background
        addHills(in: bgSize)
        
        // Add trees
        addTrees(in: bgSize)
        
        // Add flowers
        addFlowers(in: bgSize)
        
        // Add pond
        addPond(in: bgSize)
    }
    
    private func addClouds(in size: CGSize) {
        let cloudPositions: [(x: CGFloat, y: CGFloat, scale: CGFloat)] = [
            (200, size.height - 150, 1.0),
            (600, size.height - 200, 0.7),
            (1000, size.height - 120, 1.2),
            (1400, size.height - 180, 0.8),
            (1800, size.height - 140, 1.1)
        ]
        
        for (x, y, scale) in cloudPositions {
            let cloud = createCloud()
            cloud.position = CGPoint(x: x - size.width / 2, y: y - size.height / 2)
            cloud.setScale(scale)
            cloud.zPosition = -95
            backgroundNode.addChild(cloud)
            
            // Gentle floating animation
            let moveUp = SKAction.moveBy(x: 0, y: 10, duration: Double.random(in: 3...5))
            let moveDown = SKAction.moveBy(x: 0, y: -10, duration: Double.random(in: 3...5))
            cloud.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
        }
    }
    
    private func createCloud() -> SKNode {
        let cloud = SKNode()
        let circleRadii: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
            (0, 0, 40), (-35, -5, 30), (35, -5, 30), (-20, 15, 25), (20, 15, 25)
        ]
        
        for (x, y, r) in circleRadii {
            let circle = SKShapeNode(circleOfRadius: r)
            circle.fillColor = SKColor(white: 1.0, alpha: 0.9)
            circle.strokeColor = .clear
            circle.position = CGPoint(x: x, y: y)
            cloud.addChild(circle)
        }
        return cloud
    }
    
    private func addHills(in size: CGSize) {
        // Background hills
        let hillColors: [SKColor] = [
            SKColor(red: 0.45, green: 0.65, blue: 0.45, alpha: 0.6),
            SKColor(red: 0.50, green: 0.70, blue: 0.50, alpha: 0.7),
            SKColor(red: 0.55, green: 0.72, blue: 0.55, alpha: 0.8)
        ]
        
        let hillData: [(xOffset: CGFloat, width: CGFloat, height: CGFloat, colorIndex: Int)] = [
            (300, 600, 200, 0),
            (800, 500, 180, 1),
            (1400, 700, 220, 0),
            (1900, 550, 190, 2)
        ]
        
        for (xOffset, width, height, colorIndex) in hillData {
            let hill = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
            hill.fillColor = hillColors[colorIndex]
            hill.strokeColor = .clear
            hill.position = CGPoint(x: xOffset - size.width / 2, y: size.height * 0.35 - size.height / 2)
            hill.zPosition = -90
            backgroundNode.addChild(hill)
        }
    }
    
    private func addTrees(in size: CGSize) {
        let treePositions: [CGFloat] = [150, 450, 750, 1100, 1500, 1850]
        
        for x in treePositions {
            let tree = createTree()
            let y = CGFloat.random(in: (size.height * 0.15)...(size.height * 0.35))
            tree.position = CGPoint(x: x - size.width / 2, y: y - size.height / 2)
            tree.zPosition = -80 + CGFloat.random(in: 0...5)
            tree.setScale(CGFloat.random(in: 0.8...1.2))
            backgroundNode.addChild(tree)
        }
    }
    
    private func createTree() -> SKNode {
        let tree = SKNode()
        
        // Trunk
        let trunk = SKShapeNode(rectOf: CGSize(width: 20, height: 60), cornerRadius: 5)
        trunk.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.20, alpha: 1.0)
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: 30)
        tree.addChild(trunk)
        
        // Foliage layers
        let foliageColors = [
            SKColor(red: 0.30, green: 0.55, blue: 0.30, alpha: 1.0),
            SKColor(red: 0.35, green: 0.60, blue: 0.35, alpha: 1.0),
            SKColor(red: 0.40, green: 0.65, blue: 0.40, alpha: 1.0)
        ]
        
        let foliageData: [(y: CGFloat, radius: CGFloat, colorIndex: Int)] = [
            (70, 50, 0), (95, 40, 1), (115, 30, 2)
        ]
        
        for (y, radius, colorIndex) in foliageData {
            let foliage = SKShapeNode(circleOfRadius: radius)
            foliage.fillColor = foliageColors[colorIndex]
            foliage.strokeColor = .clear
            foliage.position = CGPoint(x: 0, y: y)
            tree.addChild(foliage)
        }
        
        // Add gentle sway animation
        let swayRight = SKAction.rotate(byAngle: 0.02, duration: 2.0)
        let swayLeft = SKAction.rotate(byAngle: -0.02, duration: 2.0)
        tree.run(SKAction.repeatForever(SKAction.sequence([swayRight, swayLeft, swayLeft, swayRight])))
        
        return tree
    }
    
    private func addFlowers(in size: CGSize) {
        let flowerColors: [SKColor] = [
            SKColor(red: 1.0, green: 0.75, blue: 0.80, alpha: 1.0),   // Pink
            SKColor(red: 1.0, green: 0.95, blue: 0.70, alpha: 1.0),   // Yellow
            SKColor(red: 0.85, green: 0.75, blue: 1.0, alpha: 1.0),   // Lavender
            SKColor(red: 1.0, green: 0.85, blue: 0.70, alpha: 1.0)    // Peach
        ]
        
        for _ in 0..<40 {
            let flower = createFlower(color: flowerColors.randomElement()!)
            let x = CGFloat.random(in: 50...(size.width - 50))
            let y = CGFloat.random(in: 50...(size.height * 0.25))
            flower.position = CGPoint(x: x - size.width / 2, y: y - size.height / 2)
            flower.zPosition = -70
            flower.setScale(CGFloat.random(in: 0.5...1.0))
            backgroundNode.addChild(flower)
        }
    }
    
    private func createFlower(color: SKColor) -> SKNode {
        let flower = SKNode()
        
        // Petals
        for i in 0..<5 {
            let petal = SKShapeNode(ellipseOf: CGSize(width: 12, height: 20))
            petal.fillColor = color
            petal.strokeColor = .clear
            let angle = CGFloat(i) * (2 * .pi / 5)
            petal.position = CGPoint(x: cos(angle) * 8, y: sin(angle) * 8)
            petal.zRotation = angle + .pi / 2
            flower.addChild(petal)
        }
        
        // Center
        let center = SKShapeNode(circleOfRadius: 6)
        center.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.40, alpha: 1.0)
        center.strokeColor = .clear
        flower.addChild(center)
        
        return flower
    }
    
    private func addPond(in size: CGSize) {
        // Pond shape
        let pond = SKShapeNode(ellipseOf: CGSize(width: 350, height: 200))
        pond.fillColor = SKColor(red: 0.40, green: 0.70, blue: 0.85, alpha: 0.8)
        pond.strokeColor = SKColor(red: 0.50, green: 0.75, blue: 0.88, alpha: 0.5)
        pond.lineWidth = 8
        pond.position = CGPoint(x: size.width * 0.65 - size.width / 2, y: size.height * 0.2 - size.height / 2)
        pond.zPosition = -75
        backgroundNode.addChild(pond)
        
        // Water shimmer effect
        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 1.5),
            SKAction.fadeAlpha(to: 0.9, duration: 1.5)
        ])
        pond.run(SKAction.repeatForever(shimmer))
        
        // Lily pads
        let lilyPositions: [(x: CGFloat, y: CGFloat)] = [
            (size.width * 0.60, size.height * 0.22),
            (size.width * 0.70, size.height * 0.18),
            (size.width * 0.68, size.height * 0.24)
        ]
        
        for (x, y) in lilyPositions {
            let lily = SKShapeNode(ellipseOf: CGSize(width: 30, height: 25))
            lily.fillColor = SKColor(red: 0.30, green: 0.60, blue: 0.30, alpha: 0.9)
            lily.strokeColor = .clear
            lily.position = CGPoint(x: x - size.width / 2, y: y - size.height / 2)
            lily.zPosition = -74
            backgroundNode.addChild(lily)
        }
    }
    
    private func calculateCameraBounds() {
        guard let view = view else { return }
        
        let viewSize = view.bounds.size
        let bgSize = backgroundNode.size
        
        minCameraX = viewSize.width / 2
        maxCameraX = bgSize.width - viewSize.width / 2
        minCameraY = viewSize.height / 2
        maxCameraY = bgSize.height - viewSize.height / 2
        
        // Center camera initially
        cameraNode.position = CGPoint(
            x: bgSize.width / 2,
            y: bgSize.height / 2
        )
    }
    
    private func setupHUD() {
        hudLayer = SKNode()
        hudLayer.zPosition = 1000
        cameraNode.addChild(hudLayer)
        
        // Counter background
        let counterBg = SKShapeNode(rectOf: CGSize(width: 150, height: 50), cornerRadius: 12)
        counterBg.fillColor = SKColor(white: 0, alpha: 0.6)
        counterBg.strokeColor = SKColor(white: 1, alpha: 0.3)
        counterBg.lineWidth = 2
        
        guard let view = view else { return }
        counterBg.position = CGPoint(x: 0, y: view.bounds.height / 2 - 60)
        hudLayer.addChild(counterBg)
        
        // Counter label
        counterLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        counterLabel.fontSize = 24
        counterLabel.fontColor = .white
        counterLabel.verticalAlignmentMode = .center
        counterLabel.position = counterBg.position
        hudLayer.addChild(counterLabel)
        
        updateCounter()
    }
    
    private func setupSearchableItems() {
        // Generate random positions across entire background
        let bgSize = backgroundNode.size
        let itemCount = currentLevel == 1 ? 7 : 9 // More ducks on level 2
        
        totalCount = itemCount
        
        // Define playable area (avoid edges)
        let margin: CGFloat = 100
        let minX = margin
        let maxX = bgSize.width - margin
        let minY = margin
        let maxY = bgSize.height - margin
        
        for _ in 0..<itemCount {
            let randomX = CGFloat.random(in: minX...maxX)
            let randomY = CGFloat.random(in: minY...maxY)
            
            let item = SearchableItemNode(type: "duck")
            item.position = CGPoint(x: randomX, y: randomY)
            item.delegate = self
            item.zPosition = 50
            addChild(item)
            searchableItems.append(item)
        }
        
        updateCounter()
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view?.addGestureRecognizer(panGesture)
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        // Invert Y because SpriteKit Y is inverted
        let newX = cameraNode.position.x - translation.x
        let newY = cameraNode.position.y + translation.y
        
        // Clamp to bounds
        cameraNode.position.x = max(minCameraX, min(maxCameraX, newX))
        cameraNode.position.y = max(minCameraY, min(maxCameraY, newY))
        
        gesture.setTranslation(.zero, in: view)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let locationInCamera = touch.location(in: cameraNode)
        let locationInScene = touch.location(in: self)
        
        let nodesInCamera = cameraNode.nodes(at: locationInCamera)
        
        // Check for button tap
        for node in nodesInCamera {
            if node.name == "nextLevelButton" {
                loadNextLevel()
                return
            }
        }
        
        // Check for searchable items
        let touchedNodes = nodes(at: locationInScene)
        for node in touchedNodes {
            if let searchable = node as? SearchableItemNode {
                searchable.handleTap()
                break
            }
        }
    }
    
    private func loadNextLevel() {
        currentLevel += 1
        
        // Clear current level
        searchableItems.removeAll()
        foundCount = 0
        
        // Remove all children except camera
        removeAllChildren()
        addChild(cameraNode)
        
        // Reload scene
        setupBackground()
        setupHUD()
        setupSearchableItems()
        
        SoundManager.shared.playItemFound()
    }
    
    // MARK: - Game Logic
    
    private func updateCounter() {
        counterLabel.text = "🦆 \(foundCount)/\(totalCount)"
    }
    
    private func checkVictory() {
        if foundCount >= totalCount {
            showVictory()
        }
    }
    
    private func showVictory() {
        // Play victory sound
        SoundManager.shared.playVictory()
        
        // Dark overlay for contrast
        let overlay = SKShapeNode(rectOf: CGSize(width: 2000, height: 2000))
        overlay.fillColor = SKColor(white: 0, alpha: 0)
        overlay.strokeColor = .clear
        overlay.position = .zero
        overlay.zPosition = 1990
        cameraNode.addChild(overlay)
        
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.3)
        overlay.run(fadeIn)
        
        // Contrasting victory label with background
        let victoryBg = SKShapeNode(rectOf: CGSize(width: 500, height: 120), cornerRadius: 20)
        victoryBg.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        victoryBg.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        victoryBg.lineWidth = 8
        victoryBg.position = .zero
        victoryBg.zPosition = 2000
        victoryBg.setScale(0)
        cameraNode.addChild(victoryBg)
        
        let victoryLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        victoryLabel.text = "🎉 ALL FOUND! 🎉"
        victoryLabel.fontSize = 48
        victoryLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        victoryLabel.position = .zero
        victoryLabel.verticalAlignmentMode = .center
        victoryLabel.zPosition = 2010
        victoryLabel.setScale(0)
        cameraNode.addChild(victoryLabel)
        
        // Animated entrance with bounce
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        scaleDown.timingMode = .easeInEaseOut
        let bounce = SKAction.sequence([scaleUp, scaleDown])
        
        victoryBg.run(bounce)
        victoryLabel.run(bounce)
        
        // Pulse animation
        let pulseUp = SKAction.scale(to: 1.05, duration: 0.8)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.8)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        let repeatPulse = SKAction.repeatForever(pulse)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            victoryBg.run(repeatPulse)
            victoryLabel.run(repeatPulse)
        }
        
        // Show next level button after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showNextLevelButton()
        }
    }
    
    private func showNextLevelButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 250, height: 60), cornerRadius: 12)
        button.fillColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        button.lineWidth = 4
        button.position = CGPoint(x: 0, y: -100)
        button.zPosition = 2020
        button.name = "nextLevelButton"
        button.alpha = 0
        cameraNode.addChild(button)
        
        let buttonLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        buttonLabel.text = "Next Level ▶"
        buttonLabel.fontSize = 28
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = button.position
        buttonLabel.zPosition = 2030
        buttonLabel.alpha = 0
        cameraNode.addChild(buttonLabel)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        button.run(fadeIn)
        buttonLabel.run(fadeIn)
    }
}

// MARK: - SearchableItemDelegate

extension GameScene: SearchableItemDelegate {
    func itemWasFound(_ item: SearchableItemNode) {
        foundCount += 1
        updateCounter()
        checkVictory()
    }
}

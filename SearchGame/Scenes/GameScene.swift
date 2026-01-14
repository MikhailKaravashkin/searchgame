// swiftlint:disable blanket_disable_command
// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable identifier_name
// swiftlint:disable large_tuple
// swiftlint:disable line_length
// swiftlint:disable trailing_whitespace
// swiftlint:disable function_body_length
// swiftlint:disable trailing_comma
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
    private var levelStartTime: Date?
    private var timerLabel: SKLabelNode!
    
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
        
        // Start level timer
        levelStartTime = Date()
        
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
        // Load background based on current level
        let bgName = currentLevel == 1 ? "bg_farm_day" : "bg_forest_evening"
        
        // Prefer generated/real art if present in bundle, fallback to procedural scene.
        if let tex = AssetLoader.texture(named: bgName) {
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
        
        // Camera cannot move beyond background edges
        // Background is positioned at (bgSize.width/2, bgSize.height/2)
        minCameraX = viewSize.width / 2
        maxCameraX = bgSize.width - viewSize.width / 2
        minCameraY = viewSize.height / 2
        maxCameraY = bgSize.height - viewSize.height / 2
        
        // If background is smaller than view, lock camera
        if bgSize.width < viewSize.width {
            minCameraX = bgSize.width / 2
            maxCameraX = bgSize.width / 2
        }
        if bgSize.height < viewSize.height {
            minCameraY = bgSize.height / 2
            maxCameraY = bgSize.height / 2
        }
        
        // Center camera initially
        cameraNode.position = CGPoint(
            x: bgSize.width / 2,
            y: bgSize.height / 2
        )
    }
    
    private func setupHUD() {
        // Remove old HUD if exists
        hudLayer?.removeFromParent()
        
        hudLayer = SKNode()
        hudLayer.zPosition = 1000
        cameraNode.addChild(hudLayer)
        
        guard let view = view else { return }
        
        // Position counter below safe area (Dynamic Island / notch)
        let safeAreaTop: CGFloat = 60 // Safe margin from top
        let counterYPosition = view.bounds.height / 2 - safeAreaTop - 40
        
        // Counter background
        let counterBg = SKShapeNode(rectOf: CGSize(width: 150, height: 50), cornerRadius: 12)
        counterBg.fillColor = SKColor(white: 0, alpha: 0.6)
        counterBg.strokeColor = SKColor(white: 1, alpha: 0.3)
        counterBg.lineWidth = 2
        counterBg.position = CGPoint(x: 0, y: counterYPosition)
        hudLayer.addChild(counterBg)
        
        // Item icon (duck or mushroom depending on level)
        let itemIcon: SKNode
        let itemType = getCurrentItemType()
        if let texture = AssetLoader.texture(named: itemType) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: 32, height: 32)
            itemIcon = sprite
        } else {
            // Fallback: create simple icon programmatically
            itemIcon = createItemIcon(type: itemType)
        }
        itemIcon.position = CGPoint(x: -50, y: counterYPosition)
        itemIcon.name = "itemIcon"
        hudLayer.addChild(itemIcon)
        
        // Counter label (just numbers now)
        counterLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        counterLabel.fontSize = 24
        counterLabel.fontColor = .white
        counterLabel.verticalAlignmentMode = .center
        counterLabel.horizontalAlignmentMode = .left
        counterLabel.position = CGPoint(x: -25, y: counterYPosition)
        hudLayer.addChild(counterLabel)
        
        // Timer label (top left)
        timerLabel = SKLabelNode(fontNamed: "Helvetica")
        timerLabel.fontSize = 20
        timerLabel.fontColor = .white
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.verticalAlignmentMode = .top
        timerLabel.position = CGPoint(x: -view.bounds.width / 2 + 20, y: counterYPosition)
        timerLabel.text = "⏱ 0:00"
        hudLayer.addChild(timerLabel)
        
        updateCounter()
    }
    
    private func createItemIcon(type: String) -> SKNode {
        if type == "mushroom" {
            return createMushroomIcon()
        }
        return createDuckIcon()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        updateTimer()
    }
    
    private func updateTimer() {
        guard let startTime = levelStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        timerLabel.text = String(format: "⏱ %d:%02d", minutes, seconds)
    }
    
    private func createDuckIcon() -> SKNode {
        // Simple programmatic duck icon
        let icon = SKShapeNode(ellipseOf: CGSize(width: 28, height: 22))
        icon.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
        icon.strokeColor = SKColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0)
        icon.lineWidth = 2
        
        // Simple beak
        let beak = SKShapeNode(circleOfRadius: 4)
        beak.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        beak.strokeColor = .clear
        beak.position = CGPoint(x: 14, y: 0)
        icon.addChild(beak)
        
        return icon
    }
    
    private func createMushroomIcon() -> SKNode {
        let mushroom = SKNode()
        
        // Cap
        let cap = SKShapeNode(ellipseOf: CGSize(width: 26, height: 20))
        cap.fillColor = SKColor(red: 0.95, green: 0.4, blue: 0.4, alpha: 1.0)
        cap.strokeColor = SKColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        cap.lineWidth = 2
        cap.position = CGPoint(x: 0, y: 4)
        mushroom.addChild(cap)
        
        // Stem
        let stem = SKShapeNode(rectOf: CGSize(width: 10, height: 12), cornerRadius: 2)
        stem.fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        stem.strokeColor = SKColor(red: 0.8, green: 0.75, blue: 0.65, alpha: 1.0)
        stem.lineWidth = 2
        stem.position = CGPoint(x: 0, y: -6)
        mushroom.addChild(stem)
        
        // Spots
        let spot1 = SKShapeNode(circleOfRadius: 3)
        spot1.fillColor = .white
        spot1.strokeColor = .clear
        spot1.position = CGPoint(x: -6, y: 6)
        mushroom.addChild(spot1)
        
        let spot2 = SKShapeNode(circleOfRadius: 2.5)
        spot2.fillColor = .white
        spot2.strokeColor = .clear
        spot2.position = CGPoint(x: 6, y: 5)
        mushroom.addChild(spot2)
        
        return mushroom
    }
    
    private func setupSearchableItems() {
        // Items spawn only within background bounds (not beyond it)
        let bgSize = backgroundNode.size
        let itemCount = 20
        
        totalCount = itemCount
        
        // Playable area = background size with margin
        // Background is centered, so coordinates are relative to scene origin
        let margin: CGFloat = 80
        let minX: CGFloat = margin
        let maxX: CGFloat = bgSize.width - margin
        let minY: CGFloat = margin
        let maxY: CGFloat = bgSize.height - margin
        
        let itemType = currentLevel == 1 ? "duck" : "mushroom"

        // Prevent overlap / touching: simple rejection sampling with min distance.
        // Item size is 64x64; use slightly larger spacing to avoid edge contact.
        var minDistance: CGFloat = 74
        var placedPositions: [CGPoint] = []

        // Try a few passes decreasing spacing if the background is too dense to fit 20 items.
        while placedPositions.count < itemCount && minDistance >= 54 {
            let maxAttempts = itemCount * 300
            var attempts = 0

            while placedPositions.count < itemCount && attempts < maxAttempts {
                attempts += 1
                let randomX = CGFloat.random(in: minX...maxX)
                let randomY = CGFloat.random(in: minY...maxY)
                let candidatePoint = CGPoint(x: randomX, y: randomY)

                var isValidPlacement = true
                for existingPoint in placedPositions {
                    let deltaX = candidatePoint.x - existingPoint.x
                    let deltaY = candidatePoint.y - existingPoint.y
                    if (deltaX * deltaX + deltaY * deltaY) < (minDistance * minDistance) {
                        isValidPlacement = false
                        break
                    }
                }

                if isValidPlacement {
                    placedPositions.append(candidatePoint)
                }
            }

            if placedPositions.count < itemCount {
                minDistance -= 6
            }
        }

        for placedPoint in placedPositions {
            let item = SearchableItemNode(type: itemType)
            item.position = placedPoint
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
            if node.name == "restartButton" {
                restartGame()
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
        clearLevel()
        loadLevel()
    }
    
    private func restartGame() {
        currentLevel = 1
        clearLevel()
        loadLevel()
    }
    
    private func clearLevel() {
        // Remove all victory UI (explicit names so Restart always disappears)
        let namesToRemove: Set<String> = [
            "victoryOverlay",
            "victoryPanel",
            "victoryLabel",
            "timeLabel",
            "nextLevelButton",
            "nextLevelButtonLabel",
            "restartButton",
            "restartButtonLabel",
        ]

        cameraNode.children.forEach { node in
            if let name = node.name, namesToRemove.contains(name) {
                node.removeFromParent()
            }
        }
        
        // Clear items
        searchableItems.forEach { $0.removeFromParent() }
        searchableItems.removeAll()
        foundCount = 0
        
        // Remove old background and children
        backgroundNode?.removeFromParent()
        children.filter { $0 != cameraNode }.forEach { $0.removeFromParent() }
    }
    
    private func loadLevel() {
        // Reload scene
        setupBackground()
        setupHUD()
        setupSearchableItems()
        
        // Reset timer
        levelStartTime = Date()
        
        SoundManager.shared.playItemFound()
    }
    
    // MARK: - Game Logic
    
    private func updateCounter() {
        counterLabel.text = "\(foundCount)/\(totalCount)"
    }
    
    private func getCurrentItemType() -> String {
        return currentLevel == 1 ? "duck" : "mushroom"
    }
    
    private func getCurrentItemEmoji() -> String {
        return currentLevel == 1 ? "🦆" : "🍄"
    }
    
    private func checkVictory() {
        if foundCount >= totalCount {
            showVictory()
        }
    }
    
    private func showVictory() {
        // Stop timer
        let finalTime = levelStartTime.map { Date().timeIntervalSince($0) } ?? 0
        levelStartTime = nil
        
        // Play victory sound
        SoundManager.shared.playVictory()
        
        // Dark overlay for contrast
        let overlay = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000))
        overlay.fillColor = SKColor(white: 0, alpha: 0)
        overlay.strokeColor = .clear
        overlay.position = .zero
        overlay.zPosition = 1990
        overlay.name = "victoryOverlay"
        cameraNode.addChild(overlay)
        
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.3)
        overlay.run(fadeIn)
        
        guard let view = view else { return }
        let viewWidth = view.bounds.width
        
        // Contrasting victory panel (fits in screen)
        let panelWidth = min(viewWidth - 40, 400)
        let victoryBg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: 220), cornerRadius: 20)
        victoryBg.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        victoryBg.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        victoryBg.lineWidth = 8
        victoryBg.position = .zero
        victoryBg.zPosition = 2000
        victoryBg.setScale(0)
        victoryBg.name = "victoryPanel"
        cameraNode.addChild(victoryBg)
        
        // ALL FOUND label
        let victoryLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        victoryLabel.text = "ALL FOUND!"
        victoryLabel.fontSize = 36
        victoryLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        victoryLabel.position = CGPoint(x: 0, y: 50)
        victoryLabel.verticalAlignmentMode = .center
        victoryLabel.zPosition = 2010
        victoryLabel.setScale(0)
        victoryLabel.name = "victoryLabel"
        cameraNode.addChild(victoryLabel)
        
        // Time label
        let minutes = Int(finalTime) / 60
        let seconds = Int(finalTime) % 60
        let timeLabel = SKLabelNode(fontNamed: "Helvetica")
        timeLabel.text = String(format: "Time: %d:%02d", minutes, seconds)
        timeLabel.fontSize = 24
        timeLabel.fontColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        timeLabel.position = CGPoint(x: 0, y: 10)
        timeLabel.verticalAlignmentMode = .center
        timeLabel.zPosition = 2010
        timeLabel.setScale(0)
        timeLabel.name = "timeLabel"
        cameraNode.addChild(timeLabel)
        
        // Animated entrance with bounce
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        scaleDown.timingMode = .easeInEaseOut
        let bounce = SKAction.sequence([scaleUp, scaleDown])
        
        victoryBg.run(bounce)
        victoryLabel.run(bounce)
        timeLabel.run(bounce)
        
        // Show button after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.showLevelButton()
        }
    }
    
    private func showLevelButton() {
        let maxLevel = 2
        let isLastLevel = currentLevel >= maxLevel
        
        let button = SKShapeNode(rectOf: CGSize(width: 220, height: 55), cornerRadius: 12)
        button.fillColor = isLastLevel ? 
            SKColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1.0) :
            SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        button.lineWidth = 4
        button.position = CGPoint(x: 0, y: -60)
        button.zPosition = 2020
        button.name = isLastLevel ? "restartButton" : "nextLevelButton"
        button.alpha = 0
        cameraNode.addChild(button)
        
        let buttonLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        buttonLabel.text = isLastLevel ? "↻ Restart" : "Next Level ▶"
        buttonLabel.fontSize = 26
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = button.position
        buttonLabel.zPosition = 2030
        buttonLabel.alpha = 0
        buttonLabel.name = button.name! + "Label"
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

// swiftlint:enable trailing_comma
// swiftlint:enable function_body_length
// swiftlint:enable trailing_whitespace
// swiftlint:enable line_length
// swiftlint:enable large_tuple
// swiftlint:enable identifier_name
// swiftlint:enable type_body_length
// swiftlint:enable file_length
// swiftlint:enable blanket_disable_command

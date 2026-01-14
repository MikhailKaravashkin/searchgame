import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var cameraNode: SKCameraNode!
    private var backgroundNode: SKSpriteNode!
    private var hudLayer: SKNode!
    private var itemCounters: [String: (icon: SKNode, label: SKLabelNode, found: Int, total: Int)] = [:]
    
    private var currentLevel: Level?
    private var currentLevelIndex: Int = 0
    private var levelIds: [String] = ["level1"]  // Add more levels here
    
    private var searchableItems: [SearchableItemNode] = []
    private var decorations: [DecorationNode] = []
    private var foundCounts: [String: Int] = [:]
    
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
        loadCurrentLevel()
        setupGestures()
        
        SoundManager.shared.playBackgroundMusic()
    }
    
    // MARK: - Level Loading
    
    private func loadCurrentLevel() {
        let levelId = levelIds[currentLevelIndex]
        
        do {
            currentLevel = try LevelLoader.load(levelId: levelId)
            setupLevel()
        } catch {
            print("Failed to load level \(levelId): \(error)")
            // Fallback to procedural level
            setupFallbackLevel()
        }
    }
    
    private func setupLevel() {
        guard let level = currentLevel else { return }
        
        // Reset state
        foundCounts = [:]
        for item in level.searchItems {
            foundCounts[item.type] = 0
        }
        
        setupBackground()
        setupDecorations()
        setupSearchableItems()
        setupHUD()
        
        levelStartTime = Date()
    }
    
    private func setupFallbackLevel() {
        // Create a simple fallback level if JSON loading fails
        let fallbackLevel = """
        {
            "id": "fallback",
            "name": "Fallback Level",
            "background": "bg_farm_day",
            "searchItems": [
                {"type": "rock", "count": 4, "animation": "bobbing"},
                {"type": "flower", "count": 4, "animation": "swaying"}
            ]
        }
        """
        
        if let data = fallbackLevel.data(using: .utf8),
           let level = try? LevelLoader.loadFromData(data) {
            currentLevel = level
            setupLevel()
        }
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }
    
    private func setupBackground() {
        guard let level = currentLevel else { return }
        
        // Try to load generated background
        if let tex = AssetLoader.texture(named: level.background) {
            let backgroundSize = tex.size()
            backgroundNode = SKSpriteNode(texture: tex, size: backgroundSize)
            backgroundNode.position = CGPoint(x: backgroundSize.width / 2, y: backgroundSize.height / 2)
            backgroundNode.zPosition = -100
            addChild(backgroundNode)
            calculateCameraBounds()
            return
        }
        
        // Fallback to procedural background
        let backgroundSize = CGSize(width: 2048, height: 1536)
        backgroundNode = SKSpriteNode(texture: createGradientTexture(size: backgroundSize), size: backgroundSize)
        backgroundNode.position = CGPoint(x: backgroundSize.width / 2, y: backgroundSize.height / 2)
        backgroundNode.zPosition = -100
        addChild(backgroundNode)
        
        addProceduralScenery()
        calculateCameraBounds()
    }
    
    private func setupDecorations() {
        guard let level = currentLevel, let decorationConfigs = level.decorations else { return }
        
        for config in decorationConfigs {
            let positions = config.positions ?? [DecorationConfig.Position(x: 500, y: 500)]
            let path = config.path?.map { $0.cgPoint }
            let speed = config.speed ?? 1.0
            let zPos = config.zPosition ?? -50
            
            for pos in positions {
                let decoration = DecorationNode(
                    type: config.type,
                    animation: config.animation,
                    path: path,
                    animSpeed: speed
                )
                decoration.position = pos.cgPoint
                decoration.zPosition = zPos
                addChild(decoration)
                decorations.append(decoration)
            }
        }
    }
    
    private func setupSearchableItems() {
        guard let level = currentLevel else { return }
        
        let bgSize = backgroundNode.size
        let margin: CGFloat = 80
        
        for itemConfig in level.searchItems {
            let animation = itemConfig.animation ?? .bobbing
            let zPos = itemConfig.zPosition ?? 50
            
            // Use predefined positions or generate random ones
            let positions: [CGPoint]
            if let predefinedPositions = itemConfig.positions {
                positions = predefinedPositions.map { $0.cgPoint }
            } else {
                // Generate random positions within spawn zones or background bounds
                positions = generateRandomPositions(
                    count: itemConfig.count,
                    zones: level.spawnZones,
                    bounds: CGRect(x: margin, y: margin, width: bgSize.width - margin * 2, height: bgSize.height - margin * 2)
                )
            }
            
            for (index, pos) in positions.prefix(itemConfig.count).enumerated() {
                let item = SearchableItemNode(type: itemConfig.type, animation: animation)
                item.position = pos
                item.zPosition = zPos + CGFloat(index) * 0.1  // Slight z variation
                item.delegate = self
                addChild(item)
                searchableItems.append(item)
            }
        }
    }
    
    private func generateRandomPositions(count: Int, zones: [SpawnZone]?, bounds: CGRect) -> [CGPoint] {
        var positions: [CGPoint] = []
        
        for _ in 0..<count {
            let point: CGPoint
            if let zones = zones, !zones.isEmpty {
                let zone = zones.randomElement()!
                point = zone.randomPoint()
            } else {
                point = CGPoint(
                    x: CGFloat.random(in: bounds.minX...bounds.maxX),
                    y: CGFloat.random(in: bounds.minY...bounds.maxY)
                )
            }
            positions.append(point)
        }
        
        return positions
    }
    
    private func setupHUD() {
        hudLayer?.removeFromParent()
        hudLayer = SKNode()
        hudLayer.zPosition = 1000
        cameraNode.addChild(hudLayer)
        
        guard let view = view, let level = currentLevel else { return }
        
        let safeAreaTop: CGFloat = 60
        let topY = view.bounds.height / 2 - safeAreaTop
        
        // Timer label (top left)
        timerLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        timerLabel.fontSize = 18
        timerLabel.fontColor = .white
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.verticalAlignmentMode = .top
        timerLabel.position = CGPoint(x: -view.bounds.width / 2 + 16, y: topY)
        timerLabel.text = "⏱ 0:00"
        hudLayer.addChild(timerLabel)
        
        // Bottom panel for item counters
        let bottomY = -view.bounds.height / 2 + 80
        let panelWidth = view.bounds.width - 32
        let panelHeight: CGFloat = 90
        
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 16)
        panel.fillColor = SKColor(white: 0.1, alpha: 0.85)
        panel.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        panel.lineWidth = 2
        panel.position = CGPoint(x: 0, y: bottomY)
        hudLayer.addChild(panel)
        
        // Level name
        let levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.text = level.name
        levelLabel.fontSize = 14
        levelLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        levelLabel.position = CGPoint(x: 0, y: bottomY + panelHeight / 2 - 18)
        hudLayer.addChild(levelLabel)
        
        // Progress bar
        let progressBgWidth = panelWidth - 40
        let progressBg = SKShapeNode(rectOf: CGSize(width: progressBgWidth, height: 8), cornerRadius: 4)
        progressBg.fillColor = SKColor(white: 0.2, alpha: 1.0)
        progressBg.strokeColor = .clear
        progressBg.position = CGPoint(x: 0, y: bottomY + panelHeight / 2 - 35)
        progressBg.name = "progressBg"
        hudLayer.addChild(progressBg)
        
        let progressFill = SKShapeNode(rectOf: CGSize(width: 0, height: 8), cornerRadius: 4)
        progressFill.fillColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        progressFill.strokeColor = .clear
        progressFill.position = CGPoint(x: -progressBgWidth / 2, y: bottomY + panelHeight / 2 - 35)
        progressFill.name = "progressFill"
        hudLayer.addChild(progressFill)
        
        // Item counters
        let itemCount = level.searchItems.count
        let spacing = panelWidth / CGFloat(itemCount + 1)
        let startX = -panelWidth / 2 + spacing
        
        itemCounters.removeAll()
        
        for (index, itemConfig) in level.searchItems.enumerated() {
            let x = startX + spacing * CGFloat(index)
            let y = bottomY - 10
            
            // Item icon container
            let iconBg = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 10)
            iconBg.fillColor = SKColor(white: 0.15, alpha: 1.0)
            iconBg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
            iconBg.lineWidth = 2
            iconBg.position = CGPoint(x: x, y: y)
            hudLayer.addChild(iconBg)
            
            // Item icon
            let icon: SKNode
            if let texture = AssetLoader.texture(named: itemConfig.type) {
                let sprite = SKSpriteNode(texture: texture)
                sprite.size = CGSize(width: 36, height: 36)
                icon = sprite
            } else {
                icon = createIconForType(itemConfig.type)
            }
            icon.position = CGPoint(x: x, y: y)
            icon.zPosition = 1001
            hudLayer.addChild(icon)
            
            // Counter label
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.fontSize = 14
            label.fontColor = .white
            label.text = "0/\(itemConfig.count)"
            label.position = CGPoint(x: x, y: y - 35)
            label.verticalAlignmentMode = .center
            hudLayer.addChild(label)
            
            itemCounters[itemConfig.type] = (icon: icon, label: label, found: 0, total: itemConfig.count)
        }
    }
    
    private func createIconForType(_ type: String) -> SKNode {
        // Use the same placeholder creation as SearchableItemNode but smaller
        let node = SKNode()
        
        let colors: [String: SKColor] = [
            "rock": SKColor(red: 0.55, green: 0.55, blue: 0.52, alpha: 1.0),
            "flower": SKColor(red: 1.0, green: 0.75, blue: 0.80, alpha: 1.0),
            "mushroom": SKColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1.0),
            "duck": SKColor(red: 1.0, green: 0.90, blue: 0.60, alpha: 1.0)
        ]
        
        let color = colors[type] ?? SKColor.gray
        
        let circle = SKShapeNode(circleOfRadius: 16)
        circle.fillColor = color
        circle.strokeColor = .black
        circle.lineWidth = 2
        node.addChild(circle)
        
        return node
    }
    
    // MARK: - Camera
    
    private func calculateCameraBounds() {
        guard let view = view else { return }
        
        let viewSize = view.bounds.size
        let bgSize = backgroundNode.size
        
        minCameraX = viewSize.width / 2
        maxCameraX = bgSize.width - viewSize.width / 2
        minCameraY = viewSize.height / 2
        maxCameraY = bgSize.height - viewSize.height / 2
        
        if bgSize.width < viewSize.width {
            minCameraX = bgSize.width / 2
            maxCameraX = bgSize.width / 2
        }
        if bgSize.height < viewSize.height {
            minCameraY = bgSize.height / 2
            maxCameraY = bgSize.height / 2
        }
        
        cameraNode.position = CGPoint(x: bgSize.width / 2, y: bgSize.height / 2)
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        updateTimer()
    }
    
    private func updateTimer() {
        guard let startTime = levelStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        timerLabel?.text = String(format: "⏱ %d:%02d", minutes, seconds)
    }
    
    private func updateProgress() {
        guard let level = currentLevel, let view = view else { return }
        
        let totalFound = foundCounts.values.reduce(0, +)
        let totalItems = level.totalItemCount
        let progress = CGFloat(totalFound) / CGFloat(totalItems)
        
        let panelWidth = view.bounds.width - 32
        let progressBgWidth = panelWidth - 40
        let fillWidth = progressBgWidth * progress
        
        if let progressFill = hudLayer.childNode(withName: "progressFill") as? SKShapeNode {
            progressFill.removeFromParent()
            
            let newFill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 8), cornerRadius: 4)
            newFill.fillColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
            newFill.strokeColor = .clear
            
            let bottomY = -view.bounds.height / 2 + 80
            let panelHeight: CGFloat = 90
            newFill.position = CGPoint(x: -progressBgWidth / 2 + fillWidth / 2, y: bottomY + panelHeight / 2 - 35)
            newFill.name = "progressFill"
            hudLayer.addChild(newFill)
        }
    }
    
    // MARK: - Gestures
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view?.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        let newX = cameraNode.position.x - translation.x
        let newY = cameraNode.position.y + translation.y
        
        cameraNode.position.x = max(minCameraX, min(maxCameraX, newX))
        cameraNode.position.y = max(minCameraY, min(maxCameraY, newY))
        
        gesture.setTranslation(.zero, in: view)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let locationInCamera = touch.location(in: cameraNode)
        let locationInScene = touch.location(in: self)
        
        // Check HUD buttons
        let nodesInCamera = cameraNode.nodes(at: locationInCamera)
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
        
        // Check searchable items
        let touchedNodes = nodes(at: locationInScene)
        for node in touchedNodes {
            if let searchable = node as? SearchableItemNode {
                searchable.handleTap()
                break
            }
        }
    }
    
    // MARK: - Level Transitions
    
    private func loadNextLevel() {
        currentLevelIndex += 1
        if currentLevelIndex >= levelIds.count {
            currentLevelIndex = 0  // Loop back
        }
        clearLevel()
        loadCurrentLevel()
    }
    
    private func restartGame() {
        currentLevelIndex = 0
        clearLevel()
        loadCurrentLevel()
    }
    
    private func clearLevel() {
        // Remove victory UI
        cameraNode.children.forEach { node in
            if node.name?.contains("victory") == true ||
               node.name?.contains("Button") == true ||
               node.name == "timeLabel" {
                node.removeFromParent()
            }
        }
        
        // Clear items and decorations
        searchableItems.forEach { $0.removeFromParent() }
        searchableItems.removeAll()
        decorations.forEach { $0.removeFromParent() }
        decorations.removeAll()
        
        // Clear HUD
        hudLayer?.removeFromParent()
        itemCounters.removeAll()
        
        // Remove background
        backgroundNode?.removeFromParent()
        children.filter { $0 != cameraNode }.forEach { $0.removeFromParent() }
    }
    
    // MARK: - Victory
    
    private func checkVictory() {
        guard let level = currentLevel else { return }
        
        let totalFound = foundCounts.values.reduce(0, +)
        if totalFound >= level.totalItemCount {
            showVictory()
        }
    }
    
    private func showVictory() {
        let finalTime = levelStartTime.map { Date().timeIntervalSince($0) } ?? 0
        levelStartTime = nil
        
        SoundManager.shared.playVictory()
        
        // Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000))
        overlay.fillColor = SKColor(white: 0, alpha: 0)
        overlay.strokeColor = .clear
        overlay.zPosition = 1990
        overlay.name = "victoryOverlay"
        cameraNode.addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 0.7, duration: 0.3))
        
        guard let view = view else { return }
        let panelWidth = min(view.bounds.width - 40, 350)
        
        // Victory panel
        let victoryBg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: 200), cornerRadius: 20)
        victoryBg.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        victoryBg.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        victoryBg.lineWidth = 6
        victoryBg.position = .zero
        victoryBg.zPosition = 2000
        victoryBg.setScale(0)
        victoryBg.name = "victoryPanel"
        cameraNode.addChild(victoryBg)
        
        // ALL FOUND label
        let victoryLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        victoryLabel.text = "🎉 ALL FOUND!"
        victoryLabel.fontSize = 32
        victoryLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        victoryLabel.position = CGPoint(x: 0, y: 40)
        victoryLabel.verticalAlignmentMode = .center
        victoryLabel.zPosition = 2010
        victoryLabel.setScale(0)
        cameraNode.addChild(victoryLabel)
        
        // Time
        let minutes = Int(finalTime) / 60
        let seconds = Int(finalTime) % 60
        let timeLabel = SKLabelNode(fontNamed: "Helvetica")
        timeLabel.text = String(format: "Time: %d:%02d", minutes, seconds)
        timeLabel.fontSize = 20
        timeLabel.fontColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        timeLabel.position = CGPoint(x: 0, y: 5)
        timeLabel.verticalAlignmentMode = .center
        timeLabel.zPosition = 2010
        timeLabel.setScale(0)
        timeLabel.name = "timeLabel"
        cameraNode.addChild(timeLabel)
        
        // Animate
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        victoryBg.run(bounce)
        victoryLabel.run(bounce)
        timeLabel.run(bounce)
        
        // Show button
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showLevelButton()
        }
    }
    
    private func showLevelButton() {
        let isLastLevel = currentLevelIndex >= levelIds.count - 1
        
        let button = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 12)
        button.fillColor = isLastLevel ?
            SKColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0) :
            SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        button.lineWidth = 3
        button.position = CGPoint(x: 0, y: -50)
        button.zPosition = 2020
        button.name = isLastLevel ? "restartButton" : "nextLevelButton"
        button.alpha = 0
        cameraNode.addChild(button)
        
        let buttonLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        buttonLabel.text = isLastLevel ? "↻ Play Again" : "Next Level ▶"
        buttonLabel.fontSize = 22
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = CGPoint(x: 0, y: -50)
        buttonLabel.zPosition = 2030
        buttonLabel.alpha = 0
        buttonLabel.name = (button.name ?? "") + "Label"
        cameraNode.addChild(buttonLabel)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        button.run(fadeIn)
        buttonLabel.run(fadeIn)
    }
    
    // MARK: - Procedural Fallback
    
    private func createGradientTexture(size: CGSize) -> SKTexture {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let skyColors = [
            UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0).cgColor,
            UIColor(red: 0.69, green: 0.88, blue: 0.90, alpha: 1.0).cgColor,
            UIColor(red: 0.98, green: 0.91, blue: 0.71, alpha: 1.0).cgColor
        ]
        let skyGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: skyColors as CFArray, locations: [0.0, 0.5, 1.0])!
        context.drawLinearGradient(skyGradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: size.height * 0.35), options: [])
        
        let groundColors = [
            UIColor(red: 0.56, green: 0.74, blue: 0.56, alpha: 1.0).cgColor,
            UIColor(red: 0.42, green: 0.63, blue: 0.42, alpha: 1.0).cgColor,
            UIColor(red: 0.33, green: 0.52, blue: 0.33, alpha: 1.0).cgColor
        ]
        let groundGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: groundColors as CFArray, locations: [0.0, 0.5, 1.0])!
        context.drawLinearGradient(groundGradient, start: CGPoint(x: 0, y: size.height * 0.4), end: CGPoint(x: 0, y: 0), options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
    
    private func addProceduralScenery() {
        // Add simple clouds and trees as decorations
        let bgSize = backgroundNode.size
        
        // Clouds
        for i in 0..<5 {
            let cloud = DecorationNode(type: "cloud", animation: .drifting)
            cloud.position = CGPoint(
                x: CGFloat(i) * (bgSize.width / 5) + 100,
                y: bgSize.height - CGFloat.random(in: 100...200)
            )
            cloud.zPosition = -90
            addChild(cloud)
            decorations.append(cloud)
        }
        
        // Trees
        for i in 0..<6 {
            let tree = DecorationNode(type: "tree", animation: .swaying)
            tree.position = CGPoint(
                x: CGFloat(i) * (bgSize.width / 6) + 100,
                y: CGFloat.random(in: bgSize.height * 0.15...bgSize.height * 0.35)
            )
            tree.zPosition = -80
            addChild(tree)
            decorations.append(tree)
        }
    }
}

// MARK: - SearchableItemDelegate

extension GameScene: SearchableItemDelegate {
    func itemWasFound(_ item: SearchableItemNode) {
        let type = item.itemType
        foundCounts[type] = (foundCounts[type] ?? 0) + 1
        
        // Update counter
        if var counter = itemCounters[type] {
            counter.found = foundCounts[type] ?? 0
            counter.label.text = "\(counter.found)/\(counter.total)"
            itemCounters[type] = counter
            
            // Visual feedback when complete
            if counter.found >= counter.total {
                let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                counter.icon.run(SKAction.sequence([scaleUp, scaleDown]))
            }
        }
        
        updateProgress()
        checkVictory()
    }
}

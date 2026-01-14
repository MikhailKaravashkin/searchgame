import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var cameraNode: SKCameraNode!
    private var hudLayer: SKNode!
    private var itemCounters: [String: (icon: SKNode, label: SKLabelNode, found: Int, total: Int)] = [:]
    
    private var worldBuilder: WorldBuilder?
    private var worldSize = CGSize(width: 2400, height: 1400)  // Scrollable world
    
    private var searchableItems: [SearchableItemNode] = []
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
        
        backgroundColor = SKColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1.0)
        
        setupCamera()
        buildWorld()
        setupGestures()
        
        SoundManager.shared.playBackgroundMusic()
    }
    
    // MARK: - World Building
    
    private func buildWorld() {
        // Create procedural animated world
        worldBuilder = WorldBuilder(scene: self, worldSize: worldSize)
        worldBuilder?.buildWorld()
        
        // Get searchable items from world builder
        searchableItems = worldBuilder?.searchableNodes ?? []
        
        // Initialize found counts
        foundCounts = [:]
        let itemTypes = Set(searchableItems.map { $0.itemType })
        for itemType in itemTypes {
            foundCounts[itemType] = 0
        }
        
        setupHUD()
        calculateCameraBounds()
        
        levelStartTime = Date()
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }
    
    private func setupHUD() {
        hudLayer?.removeFromParent()
        hudLayer = SKNode()
        hudLayer.zPosition = 1000
        cameraNode.addChild(hudLayer)
        
        guard let view = view else { return }
        
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
        levelLabel.text = "Find All Items"
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
        
        // Item counters - group by type from searchable items
        let itemTypes = Set(searchableItems.map { $0.itemType })
        let typeCounts = Dictionary(grouping: searchableItems, by: { $0.itemType }).mapValues { $0.count }
        let sortedTypes = Array(itemTypes).sorted()
        
        let itemCount = sortedTypes.count
        let spacing = panelWidth / CGFloat(itemCount + 1)
        let startX = -panelWidth / 2 + spacing
        
        itemCounters.removeAll()
        
        for (index, itemType) in sortedTypes.enumerated() {
            let typeCount = typeCounts[itemType] ?? 0
            let xPos = startX + spacing * CGFloat(index)
            let yPos = bottomY - 10
            
            // Item icon container
            let iconBg = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 10)
            iconBg.fillColor = SKColor(white: 0.15, alpha: 1.0)
            iconBg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
            iconBg.lineWidth = 2
            iconBg.position = CGPoint(x: xPos, y: yPos)
            hudLayer.addChild(iconBg)
            
            // Item icon
            let icon: SKNode
            if let texture = AssetLoader.texture(named: itemType) {
                let sprite = SKSpriteNode(texture: texture)
                sprite.size = CGSize(width: 36, height: 36)
                icon = sprite
            } else {
                icon = createIconForType(itemType)
            }
            icon.position = CGPoint(x: xPos, y: yPos)
            icon.zPosition = 1001
            hudLayer.addChild(icon)
            
            // Counter label
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.fontSize = 14
            label.fontColor = .white
            label.text = "0/\(typeCount)"
            label.position = CGPoint(x: xPos, y: yPos - 35)
            label.verticalAlignmentMode = .center
            hudLayer.addChild(label)
            
            itemCounters[itemType] = (icon: icon, label: label, found: 0, total: typeCount)
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
        
        minCameraX = viewSize.width / 2
        maxCameraX = worldSize.width - viewSize.width / 2
        minCameraY = viewSize.height / 2
        maxCameraY = worldSize.height - viewSize.height / 2
        
        if worldSize.width < viewSize.width {
            minCameraX = worldSize.width / 2
            maxCameraX = worldSize.width / 2
        }
        if worldSize.height < viewSize.height {
            minCameraY = worldSize.height / 2
            maxCameraY = worldSize.height / 2
        }
        
        cameraNode.position = CGPoint(x: worldSize.width / 2, y: worldSize.height / 2)
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
        guard let view = view else { return }
        
        let totalFound = foundCounts.values.reduce(0, +)
        let totalItems = searchableItems.count + totalFound  // Include already found
        let progress = totalItems > 0 ? CGFloat(totalFound) / CGFloat(searchableItems.count + totalFound) : 0
        
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
    
    private func restartGame() {
        clearLevel()
        buildWorld()
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
        
        // Clear world
        worldBuilder?.cleanup()
        worldBuilder = nil
        
        searchableItems.removeAll()
        
        // Clear HUD
        hudLayer?.removeFromParent()
        itemCounters.removeAll()
        
        // Remove all children except camera
        children.filter { $0 != cameraNode }.forEach { $0.removeFromParent() }
    }
    
    // MARK: - Victory
    
    private func checkVictory() {
        // All items found when searchableItems is empty (all removed)
        if searchableItems.isEmpty {
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
        let button = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 12)
        button.fillColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        button.lineWidth = 3
        button.position = CGPoint(x: 0, y: -50)
        button.zPosition = 2020
        button.name = "restartButton"
        button.alpha = 0
        cameraNode.addChild(button)
        
        let buttonLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        buttonLabel.text = "↻ Play Again"
        buttonLabel.fontSize = 22
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = CGPoint(x: 0, y: -50)
        buttonLabel.zPosition = 2030
        buttonLabel.alpha = 0
        buttonLabel.name = "restartButtonLabel"
        cameraNode.addChild(buttonLabel)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        button.run(fadeIn)
        buttonLabel.run(fadeIn)
    }
    
}

// MARK: - SearchableItemDelegate

extension GameScene: SearchableItemDelegate {
    func itemWasFound(_ item: SearchableItemNode) {
        let type = item.itemType
        foundCounts[type] = (foundCounts[type] ?? 0) + 1
        
        // Remove from searchable items
        if let index = searchableItems.firstIndex(of: item) {
            searchableItems.remove(at: index)
        }
        
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

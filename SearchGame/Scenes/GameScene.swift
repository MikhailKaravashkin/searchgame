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
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }
    
    private func setupBackground() {
        // Placeholder background - will be replaced with actual art
        let backgroundSize = CGSize(width: 2048, height: 1536)
        backgroundNode = SKSpriteNode(color: SKColor(red: 0.2, green: 0.3, blue: 0.2, alpha: 1.0), size: backgroundSize)
        backgroundNode.position = CGPoint(x: backgroundSize.width / 2, y: backgroundSize.height / 2)
        backgroundNode.zPosition = -100
        addChild(backgroundNode)
        
        // Add placeholder pattern to show scrolling works
        addPlaceholderPattern()
        
        // Calculate camera bounds
        calculateCameraBounds()
    }
    
    private func addPlaceholderPattern() {
        let gridSize: CGFloat = 200
        let backgroundSize = backgroundNode.size
        
        for x in stride(from: gridSize, to: backgroundSize.width, by: gridSize) {
            for y in stride(from: gridSize, to: backgroundSize.height, by: gridSize) {
                let dot = SKShapeNode(circleOfRadius: 5)
                dot.fillColor = SKColor(white: 1.0, alpha: 0.2)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: x - backgroundSize.width / 2, y: y - backgroundSize.height / 2)
                dot.zPosition = -99
                backgroundNode.addChild(dot)
            }
        }
        
        // Add text showing this is placeholder
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "Placeholder Background"
        label.fontSize = 48
        label.fontColor = SKColor(white: 1.0, alpha: 0.3)
        label.position = .zero
        label.zPosition = -98
        backgroundNode.addChild(label)
        
        let sublabel = SKLabelNode(fontNamed: "Helvetica")
        sublabel.text = "Pan to scroll • Tap items to find"
        sublabel.fontSize = 24
        sublabel.fontColor = SKColor(white: 1.0, alpha: 0.3)
        sublabel.position = CGPoint(x: 0, y: -40)
        sublabel.zPosition = -98
        backgroundNode.addChild(sublabel)
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
        // Add placeholder searchable items
        let itemPositions: [CGPoint] = [
            CGPoint(x: 400, y: 400),
            CGPoint(x: 800, y: 600),
            CGPoint(x: 1200, y: 300),
            CGPoint(x: 1600, y: 800),
            CGPoint(x: 500, y: 1000)
        ]
        
        totalCount = itemPositions.count
        
        for position in itemPositions {
            let item = SearchableItemNode(type: "duck")
            item.position = position
            item.delegate = self
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
        let location = touch.location(in: self)
        
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if let searchable = node as? SearchableItemNode {
                searchable.handleTap()
                break
            }
        }
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
        let victoryLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        victoryLabel.text = "🎉 All Found! 🎉"
        victoryLabel.fontSize = 48
        victoryLabel.fontColor = .white
        victoryLabel.position = .zero
        victoryLabel.zPosition = 2000
        victoryLabel.setScale(0)
        cameraNode.addChild(victoryLabel)
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
        scaleUp.timingMode = .easeOut
        victoryLabel.run(scaleUp)
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

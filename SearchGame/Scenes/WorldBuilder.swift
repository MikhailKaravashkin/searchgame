import SpriteKit

/// Builds a procedural animated world from individual sprites
class WorldBuilder {
    
    private weak var scene: SKScene?
    private var worldSize: CGSize
    
    // World layers
    private var groundLayer: SKNode!
    private var backLayer: SKNode!      // Trees, houses in back
    private var midLayer: SKNode!       // Fences, bushes
    private var frontLayer: SKNode!     // Characters, items
    private var skyLayer: SKNode!       // Clouds, sun, birds
    
    // All animated nodes for update loop
    private(set) var animatedNodes: [SKNode] = []
    private(set) var searchableNodes: [SearchableItemNode] = []
    
    init(scene: SKScene, worldSize: CGSize) {
        self.scene = scene
        self.worldSize = worldSize
        setupLayers()
    }
    
    private func setupLayers() {
        groundLayer = SKNode()
        groundLayer.zPosition = -100
        scene?.addChild(groundLayer)
        
        backLayer = SKNode()
        backLayer.zPosition = -50
        scene?.addChild(backLayer)
        
        midLayer = SKNode()
        midLayer.zPosition = 0
        scene?.addChild(midLayer)
        
        frontLayer = SKNode()
        frontLayer.zPosition = 50
        scene?.addChild(frontLayer)
        
        skyLayer = SKNode()
        skyLayer.zPosition = 100
        scene?.addChild(skyLayer)
    }
    
    // MARK: - Build World
    
    func buildWorld() {
        buildGround()
        buildSky()
        buildTrees()
        buildHouses()
        buildFences()
        buildBushes()
        buildFlowers()
        buildAnimatedCharacters()
        buildSearchableItems()
    }
    
    // MARK: - Ground & Sky
    
    private func buildGround() {
        // Sky gradient (top half)
        let skyNode = SKSpriteNode(color: SKColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1.0), size: CGSize(width: worldSize.width, height: worldSize.height * 0.6))
        skyNode.position = CGPoint(x: worldSize.width / 2, y: worldSize.height * 0.7)
        skyNode.zPosition = -110
        scene?.addChild(skyNode)
        
        // Ground (bottom half) - grass green
        let groundNode = SKSpriteNode(color: SKColor(red: 0.6, green: 0.82, blue: 0.6, alpha: 1.0), size: CGSize(width: worldSize.width, height: worldSize.height * 0.5))
        groundNode.position = CGPoint(x: worldSize.width / 2, y: worldSize.height * 0.25)
        groundNode.zPosition = -105
        scene?.addChild(groundNode)
    }
    
    private func buildSky() {
        // Sun
        if let sunTexture = AssetLoader.texture(named: "sun") {
            let sun = SKSpriteNode(texture: sunTexture)
            sun.size = CGSize(width: 80, height: 80)
            sun.position = CGPoint(x: worldSize.width * 0.85, y: worldSize.height * 0.9)
            skyLayer.addChild(sun)
            
            // Gentle pulsing
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 2),
                SKAction.scale(to: 1.0, duration: 2)
            ])
            sun.run(SKAction.repeatForever(pulse))
        }
        
        // Clouds - moving across screen
        for idx in 0..<5 {
            if let cloudTexture = AssetLoader.texture(named: "cloud") {
                let cloud = SKSpriteNode(texture: cloudTexture)
                cloud.size = CGSize(width: CGFloat.random(in: 80...120), height: CGFloat.random(in: 40...60))
                let startX = CGFloat(idx) * (worldSize.width / 4) + CGFloat.random(in: -50...50)
                cloud.position = CGPoint(x: startX, y: worldSize.height * CGFloat.random(in: 0.8...0.95))
                cloud.alpha = 0.9
                skyLayer.addChild(cloud)
                
                // Drift animation - move across entire screen
                let moveRight = SKAction.moveBy(x: worldSize.width + 200, y: 0, duration: Double.random(in: 60...120))
                let reset = SKAction.moveBy(x: -(worldSize.width + 200), y: 0, duration: 0)
                cloud.run(SKAction.repeatForever(SKAction.sequence([moveRight, reset])))
                
                animatedNodes.append(cloud)
            }
        }
    }
    
    // MARK: - Static Decorations
    
    private func buildTrees() {
        let treeTypes = ["tree_green", "tree_pink"]
        let treePositions: [(xRatio: CGFloat, yRatio: CGFloat, scale: CGFloat)] = [
            (0.05, 0.55, 0.8), (0.15, 0.50, 1.0), (0.25, 0.52, 0.9),
            (0.40, 0.48, 1.1), (0.55, 0.53, 0.85), (0.70, 0.50, 1.0),
            (0.85, 0.52, 0.95), (0.95, 0.48, 0.9)
        ]
        
        for (idx, pos) in treePositions.enumerated() {
            let treeType = treeTypes[idx % treeTypes.count]
            if let texture = AssetLoader.texture(named: treeType) {
                let tree = SKSpriteNode(texture: texture)
                tree.size = CGSize(width: 100 * pos.scale, height: 120 * pos.scale)
                tree.position = CGPoint(x: worldSize.width * pos.xRatio, y: worldSize.height * pos.yRatio)
                backLayer.addChild(tree)
                
                // Gentle swaying
                let sway = SKAction.sequence([
                    SKAction.rotate(byAngle: 0.02, duration: Double.random(in: 2...3)),
                    SKAction.rotate(byAngle: -0.04, duration: Double.random(in: 4...6)),
                    SKAction.rotate(byAngle: 0.02, duration: Double.random(in: 2...3))
                ])
                tree.run(SKAction.repeatForever(sway))
                animatedNodes.append(tree)
            }
        }
    }
    
    private func buildHouses() {
        let houseTypes = ["house_pink", "house_yellow"]
        let housePositions: [(xRatio: CGFloat, yRatio: CGFloat)] = [
            (0.12, 0.42), (0.35, 0.40), (0.60, 0.43), (0.82, 0.41)
        ]
        
        for (idx, pos) in housePositions.enumerated() {
            let houseType = houseTypes[idx % houseTypes.count]
            if let texture = AssetLoader.texture(named: houseType) {
                let house = SKSpriteNode(texture: texture)
                house.size = CGSize(width: 110, height: 100)
                house.position = CGPoint(x: worldSize.width * pos.xRatio, y: worldSize.height * pos.yRatio)
                backLayer.addChild(house)
            }
        }
    }
    
    private func buildFences() {
        if let fenceTexture = AssetLoader.texture(named: "fence") {
            // Row of fences at bottom
            let fenceWidth: CGFloat = 100
            let fenceY = worldSize.height * 0.18
            var xPos: CGFloat = fenceWidth / 2
            
            while xPos < worldSize.width {
                let fence = SKSpriteNode(texture: fenceTexture)
                fence.size = CGSize(width: fenceWidth, height: 40)
                fence.position = CGPoint(x: xPos, y: fenceY)
                midLayer.addChild(fence)
                xPos += fenceWidth * 0.9  // Slight overlap
            }
        }
    }
    
    private func buildBushes() {
        if let bushTexture = AssetLoader.texture(named: "bush") {
            let bushPositions: [CGPoint] = [
                CGPoint(x: worldSize.width * 0.08, y: worldSize.height * 0.25),
                CGPoint(x: worldSize.width * 0.22, y: worldSize.height * 0.22),
                CGPoint(x: worldSize.width * 0.45, y: worldSize.height * 0.24),
                CGPoint(x: worldSize.width * 0.68, y: worldSize.height * 0.23),
                CGPoint(x: worldSize.width * 0.88, y: worldSize.height * 0.25)
            ]
            
            for pos in bushPositions {
                let bush = SKSpriteNode(texture: bushTexture)
                bush.size = CGSize(width: 50, height: 35)
                bush.position = pos
                midLayer.addChild(bush)
                
                // Gentle sway
                let sway = SKAction.sequence([
                    SKAction.rotate(byAngle: 0.01, duration: 1.5),
                    SKAction.rotate(byAngle: -0.02, duration: 3),
                    SKAction.rotate(byAngle: 0.01, duration: 1.5)
                ])
                bush.run(SKAction.repeatForever(sway))
            }
        }
    }
    
    private func buildFlowers() {
        let flowerTypes = ["flower_pink", "flower_yellow"]
        
        // Scatter flowers on ground
        for _ in 0..<20 {
            let flowerType = flowerTypes.randomElement()!
            if let texture = AssetLoader.texture(named: flowerType) {
                let flower = SKSpriteNode(texture: texture)
                flower.size = CGSize(width: 20, height: 25)
                flower.position = CGPoint(
                    x: CGFloat.random(in: 50...(worldSize.width - 50)),
                    y: CGFloat.random(in: worldSize.height * 0.08...worldSize.height * 0.2)
                )
                flower.zPosition = -5
                midLayer.addChild(flower)
                
                // Gentle sway
                let sway = SKAction.sequence([
                    SKAction.rotate(byAngle: 0.03, duration: Double.random(in: 1...2)),
                    SKAction.rotate(byAngle: -0.06, duration: Double.random(in: 2...4)),
                    SKAction.rotate(byAngle: 0.03, duration: Double.random(in: 1...2))
                ])
                flower.run(SKAction.repeatForever(sway))
            }
        }
    }
    
    // MARK: - Animated Characters (non-searchable)
    
    private func buildAnimatedCharacters() {
        // Walking cats
        let catTypes = ["cat_white", "cat_gray"]
        let catPositions: [(x: CGFloat, y: CGFloat, walkDistance: CGFloat)] = [
            (worldSize.width * 0.2, worldSize.height * 0.28, 100),
            (worldSize.width * 0.5, worldSize.height * 0.30, 80),
            (worldSize.width * 0.75, worldSize.height * 0.26, 120)
        ]
        
        for (idx, pos) in catPositions.enumerated() {
            let catType = catTypes[idx % catTypes.count]
            if let texture = AssetLoader.texture(named: catType) {
                let cat = SKSpriteNode(texture: texture)
                cat.size = CGSize(width: 40, height: 35)
                cat.position = CGPoint(x: pos.x, y: pos.y)
                cat.name = "decoration_cat"
                frontLayer.addChild(cat)
                
                // Walking animation
                let walkRight = SKAction.group([
                    SKAction.scaleX(to: 1.0, duration: 0.1),
                    SKAction.moveBy(x: pos.walkDistance, y: 0, duration: Double.random(in: 3...5))
                ])
                let walkLeft = SKAction.group([
                    SKAction.scaleX(to: -1.0, duration: 0.1),
                    SKAction.moveBy(x: -pos.walkDistance, y: 0, duration: Double.random(in: 3...5))
                ])
                cat.run(SKAction.repeatForever(SKAction.sequence([walkRight, walkLeft])))
                animatedNodes.append(cat)
            }
        }
        
        // Walking person
        if let personTexture = AssetLoader.texture(named: "person") {
            let person = SKSpriteNode(texture: personTexture)
            person.size = CGSize(width: 35, height: 50)
            person.position = CGPoint(x: worldSize.width * 0.3, y: worldSize.height * 0.32)
            person.name = "decoration_person"
            frontLayer.addChild(person)
            
            let walkRight = SKAction.group([
                SKAction.scaleX(to: 1.0, duration: 0.1),
                SKAction.moveBy(x: 150, y: 0, duration: 5)
            ])
            let walkLeft = SKAction.group([
                SKAction.scaleX(to: -1.0, duration: 0.1),
                SKAction.moveBy(x: -150, y: 0, duration: 5)
            ])
            person.run(SKAction.repeatForever(SKAction.sequence([walkRight, walkLeft])))
            animatedNodes.append(person)
        }
        
        // Pandas sitting and bobbing
        if let pandaTexture = AssetLoader.texture(named: "panda") {
            let pandaPositions = [
                CGPoint(x: worldSize.width * 0.18, y: worldSize.height * 0.35),
                CGPoint(x: worldSize.width * 0.65, y: worldSize.height * 0.33)
            ]
            
            for pos in pandaPositions {
                let panda = SKSpriteNode(texture: pandaTexture)
                panda.size = CGSize(width: 45, height: 50)
                panda.position = pos
                panda.name = "decoration_panda"
                frontLayer.addChild(panda)
                
                // Gentle bobbing
                let bob = SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 5, duration: 1.5),
                    SKAction.moveBy(x: 0, y: -5, duration: 1.5)
                ])
                panda.run(SKAction.repeatForever(bob))
                animatedNodes.append(panda)
            }
        }
    }
    
    // MARK: - Searchable Items
    
    private func buildSearchableItems() {
        guard let scene = scene as? GameScene else { return }
        
        // These are the items player needs to find
        // They look similar to decorations but are searchable
        let searchableConfigs: [(type: String, count: Int, animation: AnimationType)] = [
            ("basket", 4, .bobbing),
            ("flower_pink", 4, .swaying),
            ("cat_white", 4, .walking),
            ("panda", 4, .bobbing)
        ]
        
        for config in searchableConfigs {
            let positions = generateSearchablePositions(count: config.count)
            
            for pos in positions {
                let item = SearchableItemNode(type: config.type, animation: config.animation)
                item.position = pos
                item.delegate = scene
                item.zPosition = frontLayer.zPosition + 10
                scene.addChild(item)
                searchableNodes.append(item)
            }
        }
    }
    
    private func generateSearchablePositions(count: Int) -> [CGPoint] {
        var positions: [CGPoint] = []
        
        for _ in 0..<count {
            let pos = CGPoint(
                x: CGFloat.random(in: worldSize.width * 0.1...worldSize.width * 0.9),
                y: CGFloat.random(in: worldSize.height * 0.15...worldSize.height * 0.45)
            )
            positions.append(pos)
        }
        
        return positions
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        groundLayer?.removeFromParent()
        backLayer?.removeFromParent()
        midLayer?.removeFromParent()
        frontLayer?.removeFromParent()
        skyLayer?.removeFromParent()
        animatedNodes.removeAll()
        searchableNodes.removeAll()
    }
}

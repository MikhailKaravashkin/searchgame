import XCTest
@testable import SearchGame

final class LevelTests: XCTestCase {
    
    // MARK: - Level Parsing Tests
    
    func testLevelDecodingFromJSON() throws {
        let json = """
        {
            "id": "test_level",
            "name": "Test Level",
            "background": "test_bg",
            "ambientSound": "ambient_forest",
            "searchItems": [
                {"type": "duck", "count": 3}
            ],
            "spawnZones": [[100, 100, 500, 500]]
        }
        """
        
        let data = json.data(using: .utf8)!
        let level = try LevelLoader.loadFromData(data)
        
        XCTAssertEqual(level.id, "test_level")
        XCTAssertEqual(level.name, "Test Level")
        XCTAssertEqual(level.background, "test_bg")
        XCTAssertEqual(level.ambientSound, "ambient_forest")
        XCTAssertEqual(level.searchItems.count, 1)
        XCTAssertEqual(level.searchItems[0].type, "duck")
        XCTAssertEqual(level.searchItems[0].count, 3)
    }
    
    func testLevelTotalItemCount() throws {
        let json = """
        {
            "id": "test",
            "name": "Test",
            "background": "bg",
            "searchItems": [
                {"type": "duck", "count": 3},
                {"type": "star", "count": 5}
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let level = try LevelLoader.loadFromData(data)
        
        XCTAssertEqual(level.totalItemCount, 8)
    }
    
    func testLevelWithPositions() throws {
        let json = """
        {
            "id": "test",
            "name": "Test",
            "background": "bg",
            "searchItems": [
                {
                    "type": "duck",
                    "count": 2,
                    "positions": [
                        {"x": 100, "y": 200},
                        {"x": 300, "y": 400}
                    ]
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let level = try LevelLoader.loadFromData(data)
        
        let positions = level.searchItems[0].positions!
        XCTAssertEqual(positions.count, 2)
        XCTAssertEqual(positions[0].cgPoint, CGPoint(x: 100, y: 200))
        XCTAssertEqual(positions[1].cgPoint, CGPoint(x: 300, y: 400))
    }
    
    // MARK: - SpawnZone Tests
    
    func testSpawnZoneDecoding() throws {
        let json = """
        {
            "id": "test",
            "name": "Test",
            "background": "bg",
            "searchItems": [],
            "spawnZones": [[50, 100, 500, 600]]
        }
        """
        
        let data = json.data(using: .utf8)!
        let level = try LevelLoader.loadFromData(data)
        
        let zone = level.spawnZones![0]
        XCTAssertEqual(zone.minX, 50)
        XCTAssertEqual(zone.minY, 100)
        XCTAssertEqual(zone.maxX, 500)
        XCTAssertEqual(zone.maxY, 600)
    }
    
    func testSpawnZoneRandomPoint() {
        let zone = SpawnZone(minX: 0, minY: 0, maxX: 100, maxY: 100)
        
        for _ in 0..<100 {
            let point = zone.randomPoint()
            XCTAssertGreaterThanOrEqual(point.x, 0)
            XCTAssertLessThanOrEqual(point.x, 100)
            XCTAssertGreaterThanOrEqual(point.y, 0)
            XCTAssertLessThanOrEqual(point.y, 100)
        }
    }
    
    func testSpawnZoneCGRect() {
        let zone = SpawnZone(minX: 10, minY: 20, maxX: 110, maxY: 220)
        let rect = zone.cgRect
        
        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 20)
        XCTAssertEqual(rect.width, 100)
        XCTAssertEqual(rect.height, 200)
    }
    
    // MARK: - Interactive Objects Tests
    
    func testInteractiveObjectsDecoding() throws {
        let json = """
        {
            "id": "test",
            "name": "Test",
            "background": "bg",
            "searchItems": [],
            "interactiveObjects": [
                {
                    "type": "pig",
                    "sound": "oink",
                    "probability": 0.33
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let level = try LevelLoader.loadFromData(data)
        
        let interactive = level.interactiveObjects![0]
        XCTAssertEqual(interactive.type, "pig")
        XCTAssertEqual(interactive.sound, "oink")
        XCTAssertEqual(interactive.probability, 0.33, accuracy: 0.001)
    }
    
    // MARK: - Particle Config Tests
    
    func testParticleConfigDecoding() throws {
        let json = """
        {
            "id": "test",
            "name": "Test",
            "background": "bg",
            "searchItems": [],
            "particles": [
                {
                    "type": "fireflies",
                    "position": [100, 200]
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let level = try LevelLoader.loadFromData(data)
        
        let particle = level.particles![0]
        XCTAssertEqual(particle.type, "fireflies")
        XCTAssertEqual(particle.cgPosition, CGPoint(x: 100, y: 200))
    }
}

import Foundation
import CoreGraphics

// MARK: - Animation Types

enum AnimationType: String, Codable {
    case none
    case drifting      // Clouds moving slowly
    case flowing       // Water/river texture animation
    case driving       // Vehicle moving along path
    case walking       // Character walking back and forth
    case floating      // Gentle bobbing on water
    case flickering    // Fire/light flickering
    case swaying       // Trees/flowers swaying in wind
    case bobbing       // Idle slight movement
}

// MARK: - Level Model

struct Level: Codable, Identifiable {
    let id: String
    let name: String
    let background: String
    let ambientSound: String?
    let decorations: [DecorationConfig]?
    let searchItems: [SearchItemConfig]
    let spawnZones: [SpawnZone]?
    
    var totalItemCount: Int {
        searchItems.reduce(0) { $0 + $1.count }
    }
    
    var itemTypes: [String] {
        searchItems.map { $0.type }
    }
}

// MARK: - Decoration Configuration

struct DecorationConfig: Codable {
    let type: String
    let animation: AnimationType
    let positions: [Position]?
    let path: [Position]?  // For driving/walking animations
    let speed: CGFloat?
    let zPosition: CGFloat?
    
    struct Position: Codable {
        let x: CGFloat
        let y: CGFloat
        
        var cgPoint: CGPoint {
            CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Search Item Configuration

struct SearchItemConfig: Codable {
    let type: String
    let count: Int
    let animation: AnimationType?
    let positions: [Position]?
    let zPosition: CGFloat?
    
    struct Position: Codable {
        let x: CGFloat
        let y: CGFloat
        
        var cgPoint: CGPoint {
            CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Spawn Zone

struct SpawnZone: Codable {
    let minX: CGFloat
    let minY: CGFloat
    let maxX: CGFloat
    let maxY: CGFloat
    
    init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let values = try container.decode([CGFloat].self)
        
        guard values.count >= 4 else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "SpawnZone requires 4 values [minX, minY, maxX, maxY]"
            )
        }
        
        self.minX = values[0]
        self.minY = values[1]
        self.maxX = values[2]
        self.maxY = values[3]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([minX, minY, maxX, maxY])
    }
    
    var cgRect: CGRect {
        CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    func randomPoint() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }
}

// MARK: - Level Loader

class LevelLoader {
    
    enum LevelError: Error {
        case fileNotFound
        case decodingFailed(Error)
    }
    
    static func load(levelId: String) throws -> Level {
        guard let url = Bundle.main.url(forResource: levelId, withExtension: "json", subdirectory: "Levels") else {
            throw LevelError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Level.self, from: data)
        } catch {
            throw LevelError.decodingFailed(error)
        }
    }
    
    static func loadFromData(_ data: Data) throws -> Level {
        let decoder = JSONDecoder()
        return try decoder.decode(Level.self, from: data)
    }
}

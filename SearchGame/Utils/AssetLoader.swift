import Foundation
import UIKit
import SpriteKit

enum AssetLoader {
    /// Load a PNG from `SearchGame/Resources/Generated/` (bundled as resources).
    /// Example: name="duck" -> Generated/duck.png
    static func generatedTexture(named name: String) -> SKTexture? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Generated"),
           let img = UIImage(contentsOfFile: url.path) {
            return SKTexture(image: img)
        }
        return nil
    }

    /// Load an image from Asset Catalog (or main bundle by name).
    static func catalogTexture(named name: String) -> SKTexture? {
        if let img = UIImage(named: name) {
            return SKTexture(image: img)
        }
        return nil
    }

    /// Best-effort load (Generated -> Asset Catalog).
    static func texture(named name: String) -> SKTexture? {
        generatedTexture(named: name) ?? catalogTexture(named: name)
    }
}

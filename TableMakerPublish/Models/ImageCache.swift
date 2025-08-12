import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Set cache limits
        cache.countLimit = 100 // Maximum number of images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
} 
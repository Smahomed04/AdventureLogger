//
//  ImageCacheManager.swift
//  AdventureLogger
//
//  Image caching utility using Kingfisher (Swift Package Manager)
//

import Foundation
import SwiftUI
import Kingfisher

/// Manages image caching for place photos
/// Uses Kingfisher library (added via Swift Package Manager)
class ImageCacheManager {
    static let shared = ImageCacheManager()

    private init() {
        setupCache()
    }

    /// Configure cache settings
    private func setupCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024 // 500 MB
        cache.diskStorage.config.expiration = .days(7) // Cache for 7 days
    }

    /// Clear all cached images
    func clearCache() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
        print("Image cache cleared")
    }

    /// Get cache size
    func getCacheSize(completion: @escaping (String) -> Void) {
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                let sizeInMB = Double(size) / 1024 / 1024
                completion(String(format: "%.2f MB", sizeInMB))
            case .failure:
                completion("Unknown")
            }
        }
    }
}

// MARK: - SwiftUI Image View Extension
// This demonstrates how Kingfisher would be used with SwiftUI

/// Custom image view that uses Kingfisher for efficient caching
/// Usage: CachedAsyncImage(url: URL(string: "https://..."))
struct CachedAsyncImage: View {
    let url: URL?
    let placeholder: String

    init(url: URL?, placeholder: String = "photo") {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        KFImage(url)
            .placeholder {
                Image(systemName: placeholder)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
            .retry(maxCount: 3, interval: .seconds(2))
            .fade(duration: 0.25)
            .resizable()
            .scaledToFill()
    }
}

// MARK: - Usage Example
/*

 To use this after adding Kingfisher via SPM:

 1. Add Kingfisher package in Xcode:
    - File > Add Package Dependencies
    - Search: https://github.com/onevcat/Kingfisher.git
    - Add to project

 2. Uncomment the import and implementation above

 3. Use in your views:
    CachedAsyncImage(url: place.photoURL)
        .frame(width: 100, height: 100)
        .cornerRadius(8)

 4. Clear cache in SettingsView:
    Button("Clear Image Cache") {
        ImageCacheManager.shared.clearCache()
    }

 Benefits of Kingfisher:
 - Automatic memory and disk caching
 - Prefetching support
 - Cancellable downloads
 - Image processors (resize, blur, etc.)
 - SwiftUI support with KFImage
 - GIF and WebP support

 */

#Preview {
    CachedAsyncImage(
        url: URL(string: "https://picsum.photos/200"),
        placeholder: "photo"
    )
    .frame(width: 200, height: 200)
    .cornerRadius(12)
    .padding()
}

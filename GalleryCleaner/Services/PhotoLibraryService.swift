//
//  PhotoLibraryService.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Photos
import UIKit

final class PhotoLibraryService: @unchecked Sendable {
    nonisolated static let shared = PhotoLibraryService()

    let imageManager = PHCachingImageManager()
    private var sizeCache: [String: Int64] = [:]
    private let queue = DispatchQueue(label: "com.gallerycleaner.sizecache", attributes: .concurrent)

    private init() {
        imageManager.allowsCachingHighQualityImages = false
    }

    // MARK: - Authorization
    func currentAuthorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - Fast Fetching
    nonisolated func fetchScreenshots() -> [PHAsset] {
        var seenIDs = Set<String>()
        var screenshots: [PHAsset] = []

        // Method 1: Apple's Smart Album for Screenshots
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        smartAlbums.enumerateObjects { collection, _, _ in
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            assets.enumerateObjects { asset, _, _ in
                if seenIDs.insert(asset.localIdentifier).inserted {
                    screenshots.append(asset)
                }
            }
        }

        // Method 2: Official PhotoKit mediaSubtypes predicate (fixed plural 'mediaSubtypes')
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "(mediaSubtypes & %d) != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        fetchResult.enumerateObjects { asset, _, _ in
            if seenIDs.insert(asset.localIdentifier).inserted {
                screenshots.append(asset)
            }
        }

        // Method 3: Fallback for downloaded/imported screenshot images without system metadata flag
        let allImages = fetchAllImages()
        for asset in allImages where !seenIDs.contains(asset.localIdentifier) {
            let width = Double(asset.pixelWidth)
            let height = Double(asset.pixelHeight)
            guard width > 0 && height > 0 else { continue }
            let ratio = max(width, height) / min(width, height)
            // Smartphone portrait aspect ratios (19.5:9 ≈ 2.166, 16:9 ≈ 1.777, 20:9 ≈ 2.22)
            if (ratio >= 2.05 && ratio <= 2.25) || (ratio >= 1.75 && ratio <= 1.82) {
                if seenIDs.insert(asset.localIdentifier).inserted {
                    screenshots.append(asset)
                }
            }
        }

        return screenshots
    }

    nonisolated func fetchVideos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .video, options: options)
        return extractAssets(from: fetchResult)
    }

    nonisolated func fetchAllImages() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        return extractAssets(from: fetchResult)
    }

    nonisolated private func extractAssets(from fetchResult: PHFetchResult<PHAsset>) -> [PHAsset] {
        var result: [PHAsset] = []
        result.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { asset, _, _ in
            result.append(asset)
        }
        return result
    }

    // MARK: - File Size Query (Cached)
    nonisolated func fileSize(for asset: PHAsset) -> Int64 {
        var cached: Int64?
        queue.sync {
            cached = sizeCache[asset.localIdentifier]
        }
        if let cached = cached {
            return cached
        }

        let resources = PHAssetResource.assetResources(for: asset)
        var totalSize: Int64 = 0
        for resource in resources {
            if let unsignedSize = resource.value(forKey: "fileSize") as? UInt64 {
                totalSize += Int64(unsignedSize)
            }
        }

        // Fallback size estimation if PhotoKit returns 0
        if totalSize == 0 {
            totalSize = Int64(asset.pixelWidth * asset.pixelHeight * 3 / 8)
        }

        queue.async(flags: .barrier) { [weak self] in
            self?.sizeCache[asset.localIdentifier] = totalSize
        }
        return totalSize
    }

    // MARK: - Asset Deletion
    func deleteAssets(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            for asset in assets {
                self.sizeCache.removeValue(forKey: asset.localIdentifier)
            }
        }
    }
}

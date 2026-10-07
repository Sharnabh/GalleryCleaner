//
//  LargeVideoService.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Photos
import Foundation

struct LargeVideoService: Sendable {
    static let shared = LargeVideoService()

    /// Scans videos and sorts them descending by storage size (largest first)
    nonisolated func fetchLargeVideos(
        from assets: [PHAsset],
        progress: (@Sendable (Double) -> Void)? = nil
    ) async -> [MediaItem] {
        await Task.detached(priority: .userInitiated) {
            let total = Double(assets.count)
            guard total > 0 else { return [] }

            var items: [MediaItem] = []
            items.reserveCapacity(assets.count)

            for (index, asset) in assets.enumerated() {
                let size = PhotoLibraryService.shared.fileSize(for: asset)
                items.append(MediaItem(asset: asset, fileSize: size))

                if index % 15 == 0 {
                    progress?(Double(index) / total)
                }
            }

            // Sort largest videos first
            items.sort { $0.fileSize > $1.fileSize }
            progress?(1.0)
            return items
        }.value
    }
}

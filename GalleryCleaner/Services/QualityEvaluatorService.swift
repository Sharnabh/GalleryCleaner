//
//  QualityEvaluatorService.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Photos
import Foundation

struct QualityEvaluatorService: Sendable {
    nonisolated static let shared = QualityEvaluatorService()

    /// Rapidly ranks media items in a cluster so the highest quality/best shot is placed at index 0.
    /// Runs in O(N) using instant metadata without blocking the UI.
    nonisolated func rankBestItems(in items: [MediaItem]) -> [MediaItem] {
        guard items.count > 1 else { return items }

        var scoredItems: [(item: MediaItem, score: Double)] = []
        for item in items {
            var score: Double = 0.0

            // 1. User favorites always get top priority (+10,000 pts)
            if item.asset.isFavorite {
                score += 10000.0
            }

            // 2. Resolution bonus (higher resolution = crisper master copy)
            let megaPixels = Double(item.pixelWidth * item.pixelHeight) / 1_000_000.0
            score += megaPixels * 10.0

            // 3. File size bonus (larger file = higher dynamic range / less compression)
            let megaBytes = Double(item.fileSize) / (1024.0 * 1024.0)
            score += megaBytes * 2.0

            // 4. Chronological tie-breaker: earlier original capture gets slight preference
            if let date = item.creationDate {
                score += (1.0 / (date.timeIntervalSince1970 / 1_000_000_000.0))
            }

            scoredItems.append((item, score))
        }

        // Sort descending: highest quality at index 0
        scoredItems.sort { $0.score > $1.score }
        return scoredItems.map { $0.item }
    }
}

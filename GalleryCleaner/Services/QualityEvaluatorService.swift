//
//  QualityEvaluatorService.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Photos
import Vision
import UIKit

struct QualityEvaluatorService: Sendable {
    nonisolated static let shared = QualityEvaluatorService()

    /// Evaluates a cluster of media items and sorts them so the highest quality/best shot is at index 0
    nonisolated func rankBestItems(in items: [MediaItem]) -> [MediaItem] {
        guard items.count > 1 else { return items }

        var scoredItems: [(item: MediaItem, score: Float)] = []
        for item in items {
            var score: Float = 0.0

            // 1. User favorites always get top priority (+1000 pts)
            if item.asset.isFavorite {
                score += 1000.0
            }

            // 2. Resolution bonus (higher megapixels = crisper image)
            let megaPixels = Float(item.pixelWidth * item.pixelHeight) / 1_000_000.0
            score += megaPixels * 5.0

            // 3. File size bonus (larger file = higher fidelity / less compression)
            let megaBytes = Float(item.fileSize) / (1024.0 * 1024.0)
            score += megaBytes * 2.0

            // 4. Apple Vision Aesthetics Score on supported iOS versions
            if item.mediaType == .image, #available(iOS 18.0, *) {
                let aestheticScore = calculateVisionAestheticsScore(for: item.asset)
                score += (aestheticScore + 1.0) * 20.0
            }

            scoredItems.append((item, score))
        }

        // Sort descending by calculated quality score
        scoredItems.sort { $0.score > $1.score }
        return scoredItems.map { $0.item }
    }

    @available(iOS 18.0, *)
    nonisolated private func calculateVisionAestheticsScore(for asset: PHAsset) -> Float {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        var score: Float = 0.0
        PhotoLibraryService.shared.imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 256, height: 256),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            guard let cgImage = image?.cgImage else { return }
            let request = VNCalculateImageAestheticsScoresRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                if let result = request.results?.first {
                    score = result.overallScore
                }
            } catch {
                score = 0.0
            }
        }
        return score
    }
}

//
//  SimilarPhotoDetectorService.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Photos
import Vision
import UIKit

struct SimilarPhotoDetectorService: Sendable {
    static let shared = SimilarPhotoDetectorService()

    /// Maximum visual distance considered "similar" by Apple Vision (0.0 = identical, 1.0+ = completely different)
    private let similarityDistanceThreshold: Float = 0.38

    /// Finds visually similar photos using Apple's Vision Framework (`VNGenerateImageFeaturePrintRequest`)
    nonisolated func findSimilarPhotos(
        from assets: [PHAsset],
        timeWindow: TimeInterval = 45.0,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async -> [MediaCluster] {
        await Task.detached(priority: .userInitiated) {
            var clusters: [MediaCluster] = []
            let total = Double(assets.count)
            guard total > 1 else { return [] }

            // Filter assets with creation dates and sort chronologically
            let datedAssets = assets.compactMap { asset -> (PHAsset, Date)? in
                guard let date = asset.creationDate else { return nil }
                return (asset, date)
            }.sorted { $0.1 < $1.1 }

            guard !datedAssets.isEmpty else { return [] }

            // Cache of Vision feature prints to avoid redundant neural network passes
            var featurePrintCache: [String: VNFeaturePrintObservation] = [:]

            // Helper to generate or retrieve feature print
            func getFeaturePrint(for asset: PHAsset) -> VNFeaturePrintObservation? {
                if let cached = featurePrintCache[asset.localIdentifier] {
                    return cached
                }

                guard let cgImage = SimilarPhotoDetectorService.fetchThumbnailCGImage(for: asset) else {
                    return nil
                }

                let request = VNGenerateImageFeaturePrintRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    if let observation = request.results?.first as? VNFeaturePrintObservation {
                        featurePrintCache[asset.localIdentifier] = observation
                        return observation
                    }
                } catch {
                    return nil
                }
                return nil
            }

            var currentCluster: [PHAsset] = []
            var currentAnchorPrint: VNFeaturePrintObservation?
            var clusterIndex = 1
            var bestDistanceInCluster: Float = 1.0

            for (index, item) in datedAssets.enumerated() {
                let currentAsset = item.0
                let currentDate = item.1

                if currentCluster.isEmpty {
                    // Start candidate group
                    if let print = getFeaturePrint(for: currentAsset) {
                        currentCluster.append(currentAsset)
                        currentAnchorPrint = print
                    }
                } else if let lastAsset = currentCluster.last,
                          let lastDate = lastAsset.creationDate,
                          abs(currentDate.timeIntervalSince(lastDate)) <= timeWindow,
                          let anchorPrint = currentAnchorPrint,
                          let candidatePrint = getFeaturePrint(for: currentAsset) {

                    // Compare neural feature prints using Apple Vision
                    var distance: Float = 1.0
                    do {
                        try anchorPrint.computeDistance(&distance, to: candidatePrint)
                    } catch {
                        distance = 1.0
                    }

                    if distance <= similarityDistanceThreshold {
                        currentCluster.append(currentAsset)
                        bestDistanceInCluster = min(bestDistanceInCluster, distance)
                    } else {
                        // Vision confirmed photos are visually distinct, flush current cluster if valid
                        if currentCluster.count > 1 {
                            clusters.append(
                                SimilarPhotoDetectorService.makeCluster(
                                    from: currentCluster,
                                    index: clusterIndex,
                                    distance: bestDistanceInCluster
                                )
                            )
                            clusterIndex += 1
                        }
                        // Start next candidate
                        currentCluster = [currentAsset]
                        currentAnchorPrint = candidatePrint
                        bestDistanceInCluster = 1.0
                    }
                } else {
                    // Time window elapsed or missing print, flush current cluster
                    if currentCluster.count > 1 {
                        clusters.append(
                            SimilarPhotoDetectorService.makeCluster(
                                from: currentCluster,
                                index: clusterIndex,
                                distance: bestDistanceInCluster
                            )
                        )
                        clusterIndex += 1
                    }
                    currentCluster = [currentAsset]
                    currentAnchorPrint = getFeaturePrint(for: currentAsset)
                    bestDistanceInCluster = 1.0
                }

                if index % 15 == 0 {
                    progress?(Double(index) / total)
                }
            }

            // Flush final cluster if valid
            if currentCluster.count > 1 {
                clusters.append(
                    SimilarPhotoDetectorService.makeCluster(
                        from: currentCluster,
                        index: clusterIndex,
                        distance: bestDistanceInCluster
                    )
                )
            }

            // Sort clusters by reclaimable storage descending
            clusters.sort { $0.reclaimableSize > $1.reclaimableSize }
            progress?(1.0)
            return clusters
        }.value
    }

    nonisolated private static func fetchThumbnailCGImage(for asset: PHAsset) -> CGImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        var result: CGImage?
        PhotoLibraryService.shared.imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 256, height: 256),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            result = image?.cgImage
        }
        return result
    }

    nonisolated private static func makeCluster(from assets: [PHAsset], index: Int, distance: Float) -> MediaCluster {
        let rawItems = assets.map { asset in
            let size = PhotoLibraryService.shared.fileSize(for: asset)
            return MediaItem(asset: asset, fileSize: size)
        }

        // Rank by quality so index 0 is always the best shot
        let rankedItems = QualityEvaluatorService.shared.rankBestItems(in: rawItems)

        let similarityPercentage = max(Int((1.0 - distance) * 100), 75)
        let firstDateStr = ByteFormatter.formatDate(rankedItems.first?.creationDate)

        return MediaCluster(
            title: "Similar Shot Set #\(index)",
            matchReason: "Apple Vision AI: \(similarityPercentage)% Visual Match (\(firstDateStr))",
            items: rankedItems
        )
    }
}

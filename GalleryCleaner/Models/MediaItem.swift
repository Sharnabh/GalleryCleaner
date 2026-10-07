//
//  MediaItem.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Photos
import Foundation

struct MediaItem: Identifiable, Hashable, @unchecked Sendable {
    let id: String
    let asset: PHAsset
    var fileSize: Int64
    let duration: TimeInterval
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let mediaType: PHAssetMediaType

    nonisolated init(asset: PHAsset, fileSize: Int64 = 0) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.fileSize = fileSize
        self.duration = asset.duration
        self.creationDate = asset.creationDate
        self.pixelWidth = asset.pixelWidth
        self.pixelHeight = asset.pixelHeight
        self.mediaType = asset.mediaType
    }

    nonisolated var formattedSize: String {
        ByteFormatter.format(fileSize)
    }

    nonisolated var formattedDuration: String {
        ByteFormatter.formatDuration(duration)
    }

    nonisolated var formattedDate: String {
        ByteFormatter.formatDate(creationDate)
    }

    nonisolated var resolutionString: String {
        "\(pixelWidth) × \(pixelHeight)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

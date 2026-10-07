//
//  MediaCluster.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Foundation

struct MediaCluster: Identifiable, Hashable, @unchecked Sendable {
    let id: UUID
    let title: String
    let matchReason: String
    var items: [MediaItem]

    nonisolated init(id: UUID = UUID(), title: String, matchReason: String, items: [MediaItem]) {
        self.id = id
        self.title = title
        self.matchReason = matchReason
        self.items = items
    }

    /// Total storage occupied by all items in this cluster
    nonisolated var totalSize: Int64 {
        items.reduce(0) { $0 + $1.fileSize }
    }

    /// Storage that can be freed by deleting all copies except the first/best one
    nonisolated var reclaimableSize: Int64 {
        guard items.count > 1 else { return 0 }
        return items.dropFirst().reduce(0) { $0 + $1.fileSize }
    }

    nonisolated var formattedTotalSize: String {
        ByteFormatter.format(totalSize)
    }

    nonisolated var formattedReclaimableSize: String {
        ByteFormatter.format(reclaimableSize)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MediaCluster, rhs: MediaCluster) -> Bool {
        lhs.id == rhs.id
    }
}

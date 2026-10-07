//
//  ByteFormatter.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import Foundation

enum ByteFormatter: Sendable {
    /// Formats raw byte count to human-readable string (e.g. "24.5 MB", "1.2 GB")
    nonisolated static func format(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Formats video duration in seconds to "mm:ss" or "hh:mm:ss"
    nonisolated static func formatDuration(_ duration: TimeInterval) -> String {
        guard duration > 0 && !duration.isNaN else { return "00:00" }
        let totalSeconds = Int(duration.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Formats creation date to readable string
    nonisolated static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

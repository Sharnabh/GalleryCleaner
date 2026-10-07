//
//  MediaCategory.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI

enum MediaCategory: String, CaseIterable, Identifiable {
    case screenshots = "Screenshots"
    case videos = "Videos"
    case duplicatePhotos = "Duplicate Photos"
    case similarPhotos = "Similar Photos"
    case duplicateVideos = "Duplicate Videos"
    case largeVideos = "Large Videos"

    var id: String { rawValue }

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .screenshots:
            return "Screenshots taken on device"
        case .videos:
            return "All video recordings"
        case .duplicatePhotos:
            return "Exact copies of photos"
        case .similarPhotos:
            return "Photos that look nearly identical"
        case .duplicateVideos:
            return "Exact copies of videos"
        case .largeVideos:
            return "Heavy storage videos, biggest first"
        }
    }

    var iconName: String {
        switch self {
        case .screenshots:
            return "camera.viewfinder"
        case .videos:
            return "video.fill"
        case .duplicatePhotos:
            return "doc.on.doc.fill"
        case .similarPhotos:
            return "photo.stack.fill"
        case .duplicateVideos:
            return "film.stack.fill"
        case .largeVideos:
            return "arrow.up.arrow.down.square.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .screenshots:
            return Color.Theme.screenshots
        case .videos:
            return Color.Theme.videos
        case .duplicatePhotos:
            return Color.Theme.duplicatePhotos
        case .similarPhotos:
            return Color.Theme.similarPhotos
        case .duplicateVideos:
            return Color.Theme.duplicateVideos
        case .largeVideos:
            return Color.Theme.largeVideos
        }
    }

    /// Whether this category presents items grouped into duplicate/similar clusters
    var isGrouped: Bool {
        switch self {
        case .duplicatePhotos, .similarPhotos, .duplicateVideos:
            return true
        case .screenshots, .videos, .largeVideos:
            return false
        }
    }
}

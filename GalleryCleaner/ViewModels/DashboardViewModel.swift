//
//  DashboardViewModel.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI
import Photos
import Combine

@MainActor
final class DashboardViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var authStatus: PHAuthorizationStatus = .notDetermined
    @Published var categoryCounts: [MediaCategory: Int] = [:]
    @Published var categorySizes: [MediaCategory: Int64] = [:]
    @Published var isLoadingCounts: Bool = true
    @Published var totalPhotoCount: Int = 0
    @Published var totalVideoCount: Int = 0

    override init() {
        super.init()
        self.authStatus = PhotoLibraryService.shared.currentAuthorizationStatus()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            await self.loadQuickCounts()
        }
    }

    func checkAndRequestPermission() async {
        let current = PhotoLibraryService.shared.currentAuthorizationStatus()
        if current == .notDetermined {
            let status = await PhotoLibraryService.shared.requestAuthorization()
            self.authStatus = status
            if status == .authorized || status == .limited {
                await loadQuickCounts()
            }
        } else {
            self.authStatus = current
            if current == .authorized || current == .limited {
                await loadQuickCounts()
            }
        }
    }

    /// Fetches initial instant counts without reading disk resources
    func loadQuickCounts() async {
        isLoadingCounts = true

        await Task.detached(priority: .userInitiated) {
            let screenshots = PhotoLibraryService.shared.fetchScreenshots()
            let videos = PhotoLibraryService.shared.fetchVideos()
            let allImages = PhotoLibraryService.shared.fetchAllImages()

            await MainActor.run {
                self.categoryCounts[.screenshots] = screenshots.count
                self.categoryCounts[.videos] = videos.count
                self.categoryCounts[.largeVideos] = videos.count
                self.totalPhotoCount = allImages.count
                self.totalVideoCount = videos.count
                self.isLoadingCounts = false
            }
        }.value
    }
}

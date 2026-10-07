//
//  CategoryDetailViewModel.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI
import Photos
import Combine

@MainActor
final class CategoryDetailViewModel: ObservableObject {
    let category: MediaCategory

    @Published var items: [MediaItem] = []
    @Published var clusters: [MediaCluster] = []
    @Published var selectedItemIDs: Set<String> = []
    @Published var isLoading: Bool = true
    @Published var scanProgress: Double = 0.0
    @Published var errorMessage: String? = nil
    @Published var showDeleteAlert: Bool = false
    @Published var isDeleting: Bool = false

    init(category: MediaCategory) {
        self.category = category
    }

    var selectedCount: Int {
        selectedItemIDs.count
    }

    var selectedSize: Int64 {
        var size: Int64 = 0
        if category.isGrouped {
            for cluster in clusters {
                for item in cluster.items where selectedItemIDs.contains(item.id) {
                    size += item.fileSize
                }
            }
        } else {
            for item in items where selectedItemIDs.contains(item.id) {
                size += item.fileSize
            }
        }
        return size
    }

    var hasSelection: Bool {
        !selectedItemIDs.isEmpty
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        scanProgress = 0.0
        errorMessage = nil

        switch category {
        case .screenshots:
            await loadScreenshots()
        case .videos:
            await loadVideos()
        case .duplicatePhotos:
            await loadDuplicatePhotos()
        case .similarPhotos:
            await loadSimilarPhotos()
        case .duplicateVideos:
            await loadDuplicateVideos()
        case .largeVideos:
            await loadLargeVideos()
        }

        isLoading = false
    }

    private func loadScreenshots() async {
        let assets = PhotoLibraryService.shared.fetchScreenshots()
        let mapped = assets.map { asset in
            let size = PhotoLibraryService.shared.fileSize(for: asset)
            return MediaItem(asset: asset, fileSize: size)
        }
        self.items = mapped
        self.scanProgress = 1.0
    }

    private func loadVideos() async {
        let assets = PhotoLibraryService.shared.fetchVideos()
        let mapped = assets.map { asset in
            let size = PhotoLibraryService.shared.fileSize(for: asset)
            return MediaItem(asset: asset, fileSize: size)
        }
        self.items = mapped
        self.scanProgress = 1.0
    }

    private func loadDuplicatePhotos() async {
        let allImages = PhotoLibraryService.shared.fetchAllImages()
        let detected = await DuplicateDetectorService.shared.findDuplicatePhotos(
            from: allImages
        ) { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.scanProgress = progress
            }
        }
        self.clusters = detected
    }

    private func loadSimilarPhotos() async {
        let allImages = PhotoLibraryService.shared.fetchAllImages()
        let detected = await SimilarPhotoDetectorService.shared.findSimilarPhotos(
            from: allImages
        ) { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.scanProgress = progress
            }
        }
        self.clusters = detected
    }

    private func loadDuplicateVideos() async {
        let allVideos = PhotoLibraryService.shared.fetchVideos()
        let detected = await DuplicateDetectorService.shared.findDuplicateVideos(
            from: allVideos
        ) { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.scanProgress = progress
            }
        }
        self.clusters = detected
    }

    private func loadLargeVideos() async {
        let allVideos = PhotoLibraryService.shared.fetchVideos()
        let sortedVideos = await LargeVideoService.shared.fetchLargeVideos(
            from: allVideos
        ) { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.scanProgress = progress
            }
        }
        self.items = sortedVideos
    }

    // MARK: - Selection Actions
    func toggleSelection(for item: MediaItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    func autoSelectDuplicates(for cluster: MediaCluster) {
        guard cluster.items.count > 1 else { return }
        // Keep the first item, toggle the rest
        let duplicateIDs = cluster.items.dropFirst().map { $0.id }
        let allAlreadySelected = Set(duplicateIDs).isSubset(of: selectedItemIDs)

        if allAlreadySelected {
            // Deselect them
            for id in duplicateIDs {
                selectedItemIDs.remove(id)
            }
        } else {
            // Select them
            for id in duplicateIDs {
                selectedItemIDs.insert(id)
            }
        }
    }

    var isAllRedundantSelected: Bool {
        guard !clusters.isEmpty else { return false }
        let allRedundantIDs = Set(clusters.flatMap { $0.items.dropFirst() }.map { $0.id })
        return !allRedundantIDs.isEmpty && allRedundantIDs.isSubset(of: selectedItemIDs)
    }

    var isAllItemsSelected: Bool {
        if category.isGrouped {
            guard !clusters.isEmpty else { return false }
            let allIDs = Set(clusters.flatMap { $0.items }.map { $0.id })
            return !allIDs.isEmpty && allIDs.isSubset(of: selectedItemIDs)
        } else {
            guard !items.isEmpty else { return false }
            return selectedItemIDs.count == items.count
        }
    }

    func toggleSmartKeepBest() {
        if isAllRedundantSelected {
            let redundantIDs = clusters.flatMap { $0.items.dropFirst() }.map { $0.id }
            for id in redundantIDs {
                selectedItemIDs.remove(id)
            }
        } else {
            selectAllRedundantInAllClusters()
        }
    }

    func toggleSelectAll() {
        if isAllItemsSelected {
            deselectAll()
        } else {
            selectAllItems()
        }
    }

    func selectAllRedundantInAllClusters() {
        for cluster in clusters {
            for item in cluster.items.dropFirst() {
                selectedItemIDs.insert(item.id)
            }
        }
    }

    func selectAllItems() {
        if category.isGrouped {
            for cluster in clusters {
                for item in cluster.items {
                    selectedItemIDs.insert(item.id)
                }
            }
        } else {
            for item in items {
                selectedItemIDs.insert(item.id)
            }
        }
    }

    func deselectAll() {
        selectedItemIDs.removeAll()
    }

    // MARK: - Deletion
    func confirmDelete() {
        showDeleteAlert = true
    }

    func executeDelete() async {
        guard !selectedItemIDs.isEmpty else { return }
        isDeleting = true

        var assetsToDelete: [PHAsset] = []
        if category.isGrouped {
            for cluster in clusters {
                for item in cluster.items where selectedItemIDs.contains(item.id) {
                    assetsToDelete.append(item.asset)
                }
            }
        } else {
            for item in items where selectedItemIDs.contains(item.id) {
                assetsToDelete.append(item.asset)
            }
        }

        do {
            try await PhotoLibraryService.shared.deleteAssets(assetsToDelete)

            // Update local state smoothly
            let deletedIDs = selectedItemIDs
            selectedItemIDs.removeAll()

            if category.isGrouped {
                var updatedClusters: [MediaCluster] = []
                for var cluster in clusters {
                    cluster.items.removeAll { deletedIDs.contains($0.id) }
                    // Only retain cluster if it still has multiple items
                    if cluster.items.count > 1 {
                        updatedClusters.append(cluster)
                    }
                }
                self.clusters = updatedClusters
            } else {
                self.items.removeAll { deletedIDs.contains($0.id) }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isDeleting = false
    }
}

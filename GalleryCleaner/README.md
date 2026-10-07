# Gallery Cleaner (iOS)

A high-performance, polished iOS application built with **SwiftUI** and **PhotoKit** that analyzes the device photo library and categorizes items into six dedicated storage-clearing options with zero UI freezing, lazy loading, and modern skeleton loaders.

---

## 📱 Features & 6 Core Categories

1. **Screenshots**: Displays all device screenshots (`PHAssetMediaSubtype.photoScreenshot`).
2. **Videos**: Displays all video recordings in the library.
3. **Duplicate Photos**: Multi-stage detection matching exact dimensions, raw byte size, and cryptographic **SHA256 checksums** (`CryptoKit`) into 100% verified duplicate clusters.
4. **Similar Photos**: Identifies visually similar photos using **Apple's Vision Framework (`VNGenerateImageFeaturePrintRequest`)** powered by the Apple Neural Engine to detect retakes, pose variations, and burst shots.
5. **Duplicate Videos**: Discovers exact copies of video files matching duration, resolution, and byte size.
6. **Large Videos**: Sorts videos descending by storage footprint (largest first) to free up significant space quickly.

---

## 🏗 Architecture & Design Patterns (MVVM)

The app follows strict **MVVM (Model-View-ViewModel)** architecture:

- **`Models/`**:
  - `MediaCategory.swift`: 6 options enum with titles, subtitles, SF symbols, and accent colors.
  - `MediaItem.swift`: Lightweight, sendable wrapper around `PHAsset` with cached file sizes and formatted duration/dimensions.
  - `MediaCluster.swift`: Cluster model grouping duplicate and similar assets with calculated potential storage savings.
- **`ViewModels/`**:
  - `DashboardViewModel.swift`: Fast PhotoKit permission handling and instant count calculation.
  - `CategoryDetailViewModel.swift`: Asynchronous scanning, scan progress tracking, selection state, and batch deletion.
- **`Views/`**:
  - `DashboardView.swift`: Overview hub with photo/video statistics and interactive category cards.
  - `CategoryDetailView.swift`: Displays flat lazy grids for individual media and grouped card lists for duplicate clusters.
- **`Components/`**:
  - `ShimmerPlaceholderView.swift`: Modern shimmering skeleton loaders powered by **ShimmerKit**.
  - `CategoryCardView.swift`: Dashboard category card with gradient accents.
  - `AssetThumbnailView.swift`: Reusable lazy thumbnail loader with `PHCachingImageManager`.
  - `ClusterCardView.swift`: Card showing duplicate sets with "Keep First / Auto-Select Others" shortcuts.
  - `DeletionActionBar.swift`: Floating bar displaying selected item count and reclaimable space with confirmation.
  - `EmptyStateView.swift`: Reusable empty state view.
- **`Helpers/`**:
  - `Color+Hex.swift`: Hex string (`#RRGGBB`, `#RRGGBBAA`) and integer hex initializer for SwiftUI `Color`.
  - `ByteFormatter.swift`: Human-readable file size and duration formatter.
- **`Services/`**:
  - `PhotoLibraryService.swift`: PhotoKit permission handling, image caching, and asset deletion.
  - `DuplicateDetectorService.swift`: Multi-pass dimension & byte-size duplicate clustering.
  - `SimilarPhotoDetectorService.swift`: Chronological time-window similarity clustering.
  - `LargeVideoService.swift`: Resource size querying and descending sort.

---

## ⚡ Performance Optimizations

- **Zero UI Freezes**: All scanning, metadata extraction, and clustering occur in background tasks (`Task.detached`), maintaining fluid 60/120 fps.
- **Memory Efficiency**: Thumbnails are fetched opportunistically with `PHCachingImageManager`. Full-resolution images are never held in memory.
- **Instant Dashboard**: Initial counts use instant `PHFetchResult` metadata queries without waiting for deep disk scans.
- **ShimmerKit Integration**: Integrated with [ShimmerKit](https://github.com/Sharnabh/ShimmerKit.git) for skeleton loading during asset resolution.

---

## 🛠 Requirements & Setup

- **iOS 17.0+**
- **Xcode 16.0+** / Swift 5.9+
- Open `GalleryCleaner.xcodeproj` in Xcode and run on a physical iPhone or iOS Simulator.

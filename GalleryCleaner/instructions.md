# OS Intern Task: Gallery Cleaner — Project Specifications & Instructions

## 1. Overview
The goal of this project is to develop a high-performance, polished iOS application in **Swift (SwiftUI)** that scans the user's photo gallery (`PhotoKit`) and provides 6 categorized cleaning / review options. The application must handle large photo libraries (thousands to tens of thousands of items) smoothly without blocking the main UI thread.

---

## 2. Core Functional Requirements

The main screen presents **six distinct options**. Tapping an option displays its items in a dedicated view with intuitive navigation and management:

| # | Option | Description & Criteria |
|---|---|---|
| **1** | **Screenshots** | All media items identified as screenshots (`PHAssetMediaSubtype.photoScreenshot`). |
| **2** | **Videos** | All video assets in the library (`PHAssetMediaType.video`). |
| **3** | **Duplicate Photos** | Exact copies of photos (identical file size, dimensions, or exact perceptual/cryptographic hash). Grouped by duplicate clusters. |
| **4** | **Similar Photos** | Photos taken around the same time or with high visual similarity (e.g. burst shots, consecutive angles, or Vision `VNGenerateImageFeaturePrintRequest` similarity). Grouped by similar clusters. |
| **5** | **Duplicate Videos** | Exact copies of videos (identical duration, dimensions, file size, or resource hash). Grouped by duplicate clusters. |
| **6** | **Large Videos** | Videos that consume the most device storage, sorted descending by file size (largest first). |

---

## 3. Non-Functional & Performance Requirements

1. **Non-Blocking UI (Zero Freezes)**:
   - Scanning, metadata extraction, hashing, and sorting must run on background threads (`Task.detached` / background `DispatchQueue`).
   - The main UI thread must remain fluid at 60/120 fps even when processing libraries with 10,000+ items.
2. **Lazy Loading & Effective Memory Management**:
   - Use `LazyVGrid` / `LazyVStack` or reusable collection cells.
   - Employ `PHCachingImageManager` for fast thumbnail caching, preheating, and minimal memory overhead.
   - Avoid loading full-resolution images into memory all at once.
3. **Progress & Loading Indicators (ShimmerKit)**:
   - Use the **ShimmerKit** package (`https://github.com/Sharnabh/ShimmerKit.git`) to implement modern, shimmering skeleton loaders while assets, thumbnails, or scan results are being fetched or computed.
   - Maintain a polished loading state with ShimmerKit placeholder cards/grids rather than generic spinners whenever content is preparing to render.
4. **Visual Design & UX**:
   - Clear, modern visual hierarchy so users can tell at a glance what each category represents.
   - Modern iOS styling (card layouts, SF Symbols, clear badges/counts, formatted storage sizes).

---

## 4. Technical Strategy & Implementation Details

### A. Dependencies & Packages
- **ShimmerKit**:
  - Repository: `https://github.com/Sharnabh/ShimmerKit.git`
  - Integration: Swift Package Manager (SPM).
  - Purpose: Native shimmering skeleton loaders for asset cards, thumbnail grids, and category loading views.

### B. Photo Library Permissions
- Add `NSPhotoLibraryUsageDescription` to `Info.plist` (or project build settings).
- Handle all authorization states gracefully (`authorized`, `limited`, `denied`, `restricted`, `notDetermined`).

### C. Category Detection Logic
- **Screenshots**:
  - Filter using `PHAsset.fetchAssets(with: .image, options: ...)` with predicate `(mediaSubtypes & %d) != 0` where mask is `PHAssetMediaSubtype.photoScreenshot.rawValue`.
- **Videos**:
  - Fetch using `PHAsset.fetchAssets(with: .video, options: ...)`.
- **Duplicate Photos**:
  - Fast pass: Prune non-duplicates by grouping exact pixel dimensions (`pixelWidth`, `pixelHeight`) and byte size (`PHAssetResource`).
  - Strict pass: Cryptographic SHA256 verification via `CryptoKit` on candidate groups to guarantee 100% exact duplicates.
- **Similar Photos (Apple Vision AI)**:
  - Uses Apple's Neural Engine-powered **Vision Framework** (`VNGenerateImageFeaturePrintRequest`).
  - Generates compact neural visual feature prints (`VNFeaturePrintObservation`).
  - Computes cosine distance with `computeDistance(&distance, to: otherPrint)` (threshold $\le 0.38$). Accurately detects smiles/blinks, burst takes, pose shifts, and retakes.
- **Duplicate Videos**:
  - Match videos sharing exact duration (within 0.1s tolerance), resolution, and raw byte size.
- **Large Videos**:
  - Query `PHAssetResource.assetResources(for: asset)` to fetch `fileSize`.
  - Cache sizes and sort in descending order (`$0.fileSize > $1.fileSize`).

### D. MVVM Architecture & Project Structure
The project strictly follows the **MVVM (Model-View-ViewModel)** architectural pattern. Code is modular, clean, scalable, and organized into dedicated folders:

```
GalleryCleaner/
├── Models/                     # Data structures & domain models
│   ├── MediaCategory.swift     # Enum / model representing the 6 categories
│   ├── MediaItem.swift         # Wrapper around PHAsset with metadata & size
│   └── AssetCluster.swift      # Cluster model for duplicate/similar groups
├── ViewModels/                 # Observable ViewModels handling business logic
│   ├── DashboardViewModel.swift       # Fetches category counts & overview stats
│   └── CategoryDetailViewModel.swift # Loads category items, duplicates & large videos
├── Views/                      # Screen layouts & container views
│   ├── DashboardView.swift            # Main hub displaying the 6 category cards
│   ├── CategoryDetailView.swift       # Screen displaying items for a selected category
│   └── ClusterDetailView.swift        # Screen for comparing and reviewing duplicates/similars
├── Components/                 # Shared, reusable UI components
│   ├── CategoryCardView.swift         # Card representing a category on the dashboard
│   ├── AssetThumbnailView.swift       # Reusable thumbnail loader with caching
│   ├── ShimmerPlaceholderView.swift   # ShimmerKit-backed skeleton loader
│   ├── ClusterSectionHeader.swift     # Header for duplicate / similar groups
│   └── EmptyStateView.swift           # Reusable empty/loading state banner
├── Helpers/                    # Utility extensions & formatters
│   ├── Color+Hex.swift                # Color extension to convert hex strings to SwiftUI Color
│   └── Formatters.swift               # Byte size formatters (MB/GB) and date/duration formatters
└── Services/                   # PhotoKit and scanning engine services
    ├── PhotoLibraryService.swift      # PhotoKit permissions, queries, and fetch results
    ├── DuplicateDetector.swift        # Exact duplicate detection algorithm
    └── SimilarPhotoDetector.swift     # Visual & timestamp-based similarity clustering
```

### E. Reusable Components & Helper Specifications
- **Components Folder (`Components/`)**: Any UI element used across multiple screens (e.g. `AssetThumbnailView`, `ShimmerPlaceholderView`, badges, card items) must reside in `Components/`.
- **Helpers Folder (`Helpers/`)**:
  - `Color+Hex.swift`: Swift extension on `Color` (and `UIColor` if needed) supporting 6-digit (`#RRGGBB`) and 8-digit (`#RRGGBBAA`) hex representations.
  - Formatter utilities for file size display (Bytes $\to$ KB/MB/GB) and video duration display (`mm:ss`).

## 5. Submission Deliverables Checklist

- [ ] **Git Repository**: Clean commit history with an informative `README.md` covering setup, architecture, and feature explanation.
- [ ] **Screen Recording**: High-quality video demo running on a physical iOS device showing all 6 categories, smooth loading, and navigation.
- [ ] **AI Prompts Log**: Google Sheet / documented log detailing all AI prompts and context provided during development to assess prompt engineering methodology.

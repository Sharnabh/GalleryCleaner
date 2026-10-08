//
//  CategoryDetailView.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI

struct CategoryDetailView: View {
    @StateObject private var viewModel: CategoryDetailViewModel
    @State private var previewItem: MediaItem?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    init(category: MediaCategory) {
        _viewModel = StateObject(wrappedValue: CategoryDetailViewModel(category: category))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.Theme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Progress bar when scanning large galleries
                if viewModel.isLoading && viewModel.scanProgress > 0 && viewModel.scanProgress < 1 {
                    VStack(spacing: 4) {
                        ProgressView(value: viewModel.scanProgress, total: 1.0)
                            .tint(viewModel.category.accentColor)
                            .padding(.horizontal)
                        Text("Analyzing gallery... \(Int(viewModel.scanProgress * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    .padding(.top, 8)
                }

                if viewModel.isLoading {
                    // ShimmerKit powered skeleton placeholder
                    if viewModel.category.isGrouped {
                        ShimmerClusterPlaceholder()
                    } else {
                        ShimmerGridPlaceholder()
                    }
                } else if viewModel.category.isGrouped {
                    groupedContentView
                } else {
                    flatGridView
                }
            }

            // Bottom Deletion Action Bar
            if viewModel.hasSelection {
                DeletionActionBar(
                    selectedCount: viewModel.selectedCount,
                    selectedSize: viewModel.selectedSize,
                    onDelete: {
                        viewModel.confirmDelete()
                    },
                    onDeselectAll: {
                        viewModel.deselectAll()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.hasSelection)
        .navigationTitle(viewModel.category.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.Theme.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !viewModel.isLoading {
                    Menu {
                        if viewModel.category.isGrouped {
                            Button("Auto-Select All Duplicates") {
                                viewModel.selectAllRedundantInAllClusters()
                            }
                        } else {
                            Button("Select All") {
                                viewModel.selectAllItems()
                            }
                        }

                        if viewModel.hasSelection {
                            Button("Deselect All", role: .destructive) {
                                viewModel.deselectAll()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await viewModel.loadData()
            }
        }
        .alert("Confirm Deletion", isPresented: $viewModel.showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.executeDelete()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(viewModel.selectedCount) item(s)? This will free up \(ByteFormatter.format(viewModel.selectedSize)) of storage.")
        }
    }

    // MARK: - Flat Grid View (Screenshots, Videos, Large Videos)
    @ViewBuilder
    private var flatGridView: some View {
        if viewModel.items.isEmpty {
            EmptyStateView(
                icon: viewModel.category.iconName,
                title: "No \(viewModel.category.title) Found",
                message: "Your library does not contain any items matching this category.",
                accentColor: viewModel.category.accentColor
            )
        } else {
            ScrollView {
                // Header summary banner
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.items.count) items found")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.Theme.secondaryText)
                            .lineLimit(1)

                        let totalSize = viewModel.items.reduce(0) { $0 + $1.fileSize }
                        if totalSize > 0 {
                            Text(ByteFormatter.format(totalSize))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(viewModel.category.accentColor)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button(action: {
                        viewModel.toggleSelectAll()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.isAllItemsSelected ? "checkmark.square.fill" : "square")
                                .font(.system(size: 12))
                            Text(viewModel.isAllItemsSelected ? "Deselect All" : "Select All")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .contentShape(Rectangle())

                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(viewModel.items) { item in
                        AssetThumbnailView(
                            item: item,
                            isSelected: viewModel.selectedItemIDs.contains(item.id),
                            showSelection: true,
                            onTap: {
                                viewModel.toggleSelection(for: item)
                            }
                        )
                        .clipped()
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, viewModel.hasSelection ? 90 : 20)
            }
        }
    }

    // MARK: - Grouped View (Duplicates & Similars)
    @ViewBuilder
    private var groupedContentView: some View {
        if viewModel.clusters.isEmpty {
            EmptyStateView(
                icon: "checkmark.seal.fill",
                title: "No Duplicates Found",
                message: "Congratulations! There are no \(viewModel.category.title.lowercased()) taking up extra storage.",
                accentColor: Color.Theme.accentGreen
            )
        } else {
            ScrollView {
                // Header summary banner
                let totalClusters = viewModel.clusters.count
                let totalReclaimable = viewModel.clusters.reduce(0) { $0 + $1.reclaimableSize }

                VStack(spacing: 10) {
                    HStack {
                        Text("\(totalClusters) Duplicate Sets Found")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                    }

                    if totalReclaimable > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color.Theme.accentGreen)
                            Text("Potential Storage Savings: ")
                                .foregroundColor(Color.Theme.secondaryText)
                            Text(ByteFormatter.format(totalReclaimable))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color.Theme.accentGreen)
                            Spacer()
                        }
                        .font(.system(size: 13))
                        .lineLimit(1)
                    }

                    // Smart Select (Keep Best) & Select All Action Row
                    HStack(spacing: 10) {
                        Button(action: {
                            viewModel.toggleSmartKeepBest()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.isAllRedundantSelected ? "checkmark.circle.fill" : "wand.and.stars")
                                    .font(.system(size: 12, weight: .bold))
                                Text(viewModel.isAllRedundantSelected ? "Best Kept" : "Auto-Select (Keep Best)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: viewModel.isAllRedundantSelected
                                        ? [Color.blue, Color(hex: "#2563EB")]
                                        : [Color.blue, Color(hex: "#6366F1")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewModel.toggleSelectAll()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: viewModel.isAllItemsSelected ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 12))
                                Text(viewModel.isAllItemsSelected ? "Deselect All" : "Select All")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .contentShape(Rectangle())

                LazyVStack(spacing: 14) {
                    ForEach(viewModel.clusters) { cluster in
                        ClusterCardView(
                            cluster: cluster,
                            selectedItemIDs: viewModel.selectedItemIDs,
                            onToggleItem: { item in
                                viewModel.toggleSelection(for: item)
                            },
                            onAutoSelectDuplicates: {
                                viewModel.autoSelectDuplicates(for: cluster)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, viewModel.hasSelection ? 90 : 20)
            }
        }
    }
}

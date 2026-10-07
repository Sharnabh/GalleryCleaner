//
//  DashboardView.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI
import Photos

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background deep slate / midnight
                Color.Theme.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Banner
                        headerSection

                        // Permission Notice if needed
                        if viewModel.authStatus != .authorized && viewModel.authStatus != .limited {
                            permissionPromptSection
                        }

                        // Six Primary Categories
                        categoriesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Gallery Cleaner")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.Theme.appBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.checkAndRequestPermission()
            }
            .refreshable {
                await viewModel.loadQuickCounts()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await viewModel.loadQuickCounts()
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Library")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Select a category to inspect & optimize storage")
                        .font(.system(size: 13))
                        .foregroundColor(Color.Theme.secondaryText)
                }
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.Theme.screenshots.opacity(0.3), Color.Theme.videos.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }

            // Quick Stats Pill
            HStack(spacing: 12) {
                statPill(title: "Photos", count: viewModel.totalPhotoCount, icon: "photo.fill", color: Color.Theme.screenshots)
                statPill(title: "Videos", count: viewModel.totalVideoCount, icon: "video.fill", color: Color.Theme.videos)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func statPill(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.Theme.secondaryText)
                Text(viewModel.isLoadingCounts ? "..." : "\(count)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(spacing: 12) {
            ForEach(MediaCategory.allCases) { category in
                NavigationLink(destination: CategoryDetailView(category: category)) {
                    CategoryCardView(
                        category: category,
                        count: viewModel.categoryCounts[category],
                        estimatedSize: viewModel.categorySizes[category],
                        isLoading: viewModel.isLoadingCounts
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Permission Prompt Section
    private var permissionPromptSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo Access Required")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Grant photo library access so Gallery Cleaner can scan your media.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.Theme.secondaryText)
                }
                Spacer()
            }

            Button(action: {
                Task {
                    await viewModel.checkAndRequestPermission()
                }
            }) {
                Text("Grant Access")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

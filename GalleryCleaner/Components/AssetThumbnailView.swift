//
//  AssetThumbnailView.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI
import Photos

struct AssetThumbnailView: View {
    let item: MediaItem
    let isSelected: Bool
    let showSelection: Bool
    let targetSize: CGSize
    let onTap: (() -> Void)?

    @State private var thumbnail: UIImage?
    @State private var requestID: PHImageRequestID?

    init(
        item: MediaItem,
        isSelected: Bool = false,
        showSelection: Bool = true,
        targetSize: CGSize = CGSize(width: 250, height: 250),
        onTap: (() -> Void)? = nil
    ) {
        self.item = item
        self.isSelected = isSelected
        self.showSelection = showSelection
        self.targetSize = targetSize
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            ZStack(alignment: .bottomLeading) {
                // Background thumbnail image strictly clamped to 1:1 square
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Group {
                            if let thumbnail = thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.Theme.cardBackground
                                    .overlay(
                                        ProgressView()
                                            .tint(.white.opacity(0.6))
                                    )
                            }
                        }
                    )
                    .clipped()

                // Overlay gradient for badge readability
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Bottom metadata info (size & duration)
                HStack(spacing: 4) {
                    if item.fileSize > 0 {
                        Text(item.formattedSize)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 2)

                    if item.mediaType == .video {
                        HStack(spacing: 3) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 8))
                            Text(item.formattedDuration)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Capsule())
                    }
                }
                .padding(6)

                // Top right selection checkbox
                if showSelection {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.blue : Color.black.opacity(0.45))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1.5)
                                    )

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: isSelected ? 2.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            cancelThumbnail()
        }
    }

    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        requestID = PhotoLibraryService.shared.imageManager.requestImage(
            for: item.asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                self.thumbnail = image
            }
        }
    }

    private func cancelThumbnail() {
        if let requestID = requestID {
            PhotoLibraryService.shared.imageManager.cancelImageRequest(requestID)
            self.requestID = nil
        }
    }
}

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
                // Background thumbnail image
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.Theme.cardBackground)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            ProgressView()
                                .tint(.white.opacity(0.6))
                        )
                }

                // Overlay gradient for badge readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Bottom metadata info (size & duration)
                HStack(spacing: 4) {
                    if item.fileSize > 0 {
                        Text(item.formattedSize)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if item.mediaType == .video {
                        HStack(spacing: 3) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 9))
                            Text(item.formattedDuration)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
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
                                    .fill(isSelected ? Color.blue : Color.black.opacity(0.4))
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1.5)
                                    )

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.08), lineWidth: isSelected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
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

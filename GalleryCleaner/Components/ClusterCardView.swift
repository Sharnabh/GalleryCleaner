//
//  ClusterCardView.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI

struct ClusterCardView: View {
    let cluster: MediaCluster
    let selectedItemIDs: Set<String>
    let onToggleItem: (MediaItem) -> Void
    let onAutoSelectDuplicates: () -> Void

    var isAllExceptFirstSelected: Bool {
        guard cluster.items.count > 1 else { return false }
        let duplicateIDs = Set(cluster.items.dropFirst().map { $0.id })
        return duplicateIDs.isSubset(of: selectedItemIDs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header info
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(cluster.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(cluster.matchReason)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.Theme.secondaryText)
                }

                Spacer()

                // Auto Select duplicates shortcut button
                Button(action: onAutoSelectDuplicates) {
                    HStack(spacing: 4) {
                        Image(systemName: isAllExceptFirstSelected ? "checkmark.circle.fill" : "wand.and.stars")
                            .font(.system(size: 11))
                        Text(isAllExceptFirstSelected ? "Selected" : "Select Duplicates")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(isAllExceptFirstSelected ? .white : Color.Theme.duplicatePhotos)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        isAllExceptFirstSelected
                            ? Color.blue
                            : Color.Theme.duplicatePhotos.opacity(0.18)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .fixedSize()
            }

            // Thumbnail items list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(cluster.items.enumerated()), id: \.element.id) { index, item in
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack(alignment: .topLeading) {
                                AssetThumbnailView(
                                    item: item,
                                    isSelected: selectedItemIDs.contains(item.id),
                                    showSelection: index != 0,
                                    targetSize: CGSize(width: 180, height: 180),
                                    onTap: {
                                        if index != 0 {
                                            onToggleItem(item)
                                        }
                                    }
                                )
                                .frame(width: 115, height: 115)

                                if index == 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 7))
                                        Text("KEEP")
                                            .font(.system(size: 9, weight: .black, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                                    .padding(6)
                                }
                            }
                        }
                    }
                }
            }

            // Footer storage summary
            HStack {
                Text("\(cluster.items.count) files (\(cluster.formattedTotalSize))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.Theme.secondaryText)

                Spacer()

                if cluster.reclaimableSize > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                        Text("Reclaim \(cluster.formattedReclaimableSize)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color.Theme.accentGreen)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

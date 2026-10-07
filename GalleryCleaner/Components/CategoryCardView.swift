//
//  CategoryCardView.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI

struct CategoryCardView: View {
    let category: MediaCategory
    let count: Int?
    let estimatedSize: Int64?
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Glowing category icon
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                category.accentColor.opacity(0.85),
                                category.accentColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: category.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: category.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Category text details
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(category.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.Theme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Count & Size Badges
            VStack(alignment: .trailing, spacing: 4) {
                if isLoading {
                    ProgressView()
                        .tint(category.accentColor)
                        .scaleEffect(0.8)
                } else if let count = count {
                    Text("\(count)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if let size = estimatedSize, size > 0 {
                        Text(ByteFormatter.format(size))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(category.accentColor)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

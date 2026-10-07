//
//  DeletionActionBar.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI

struct DeletionActionBar: View {
    let selectedCount: Int
    let selectedSize: Int64
    let onDelete: () -> Void
    let onDeselectAll: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedCount) items selected")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if selectedSize > 0 {
                    Text("Free up \(ByteFormatter.format(selectedSize))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.Theme.accentGreen)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Button(action: onDeselectAll) {
                Text("Deselect")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.Theme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .fixedSize()

            Button(action: onDelete) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Clean")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color(hex: "#DC2626")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .fixedSize()
            .layoutPriority(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "#1E293B").opacity(0.98))
                .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

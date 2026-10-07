//
//  EmptyStateView.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let accentColor: Color

    init(
        icon: String = "sparkles",
        title: String = "All Clean!",
        message: String = "No items found in this category.",
        accentColor: Color = .blue
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(Color.Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}

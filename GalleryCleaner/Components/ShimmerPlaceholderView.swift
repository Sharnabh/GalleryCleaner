//
//  ShimmerPlaceholderView.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI
import ShimmerKit

struct ShimmerGridPlaceholder: View {
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<18, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.Theme.cardBackground)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            VStack(alignment: .leading) {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 12)
                                    .padding(8)
                            }
                        )
                }
            }
            .padding()
        }
        .smartSkeleton(true, config: ShimmerKit.config(.feedLoading))
    }
}

struct ShimmerClusterPlaceholder: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: 140, height: 14)
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: 90, height: 10)
                            }
                            Spacer()
                        }

                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 10)
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(height: 100)
                            }
                        }
                    }
                    .padding()
                    .background(Color.Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .smartSkeleton(true, config: ShimmerKit.config(.detailPage))
    }
}

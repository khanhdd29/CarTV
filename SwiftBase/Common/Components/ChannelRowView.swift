//
//  ChannelRowView.swift
//  SwiftBase
//
//  A channel row rendered as a dark glass card. Used by Search, Favorites and
//  Recents (Home uses the poster-style ChannelCard instead).
//

import SwiftUI

struct ChannelRowView: View {
    let channel: Channel
    let isFavourite: Bool
    var showFavourite: Bool = true
    let onPlay: () -> Void
    var onToggleFavourite: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    logo
                    VStack(alignment: .leading, spacing: 3) {
                        Text(channel.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                        if let group = channel.groupTitle, !group.isEmpty {
                            Text(group)
                                .font(.caption)
                                .foregroundStyle(AppColors.textTertiary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showFavourite {
                Button(action: onToggleFavourite) {
                    Image(systemName: isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavourite ? AppColors.favorite : AppColors.textTertiary)
                        .font(.body)
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.white, AppColors.primary.opacity(0.9))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface.opacity(0.75))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColors.border, lineWidth: 1))
        )
    }

    private var logo: some View {
        CachedAsyncImage(url: channel.logoImageURL) {
            Image(systemName: "tv")
                .font(.title3)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(width: 58, height: 42)
        .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

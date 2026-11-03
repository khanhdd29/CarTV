//
//  ChannelCard.swift
//  SwiftBase
//
//  Poster-style channel tile used in the Home rails, and a large featured hero.
//

import SwiftUI
import Factory

struct ChannelCard: View {
    @InjectedObject(\.healthCenter) private var health: HealthCenter
    let channel: Channel
    var isFavourite: Bool = false
    var onPlay: () -> Void
    var onToggleFavourite: (() -> Void)? = nil

    private let width: CGFloat = 138

    var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 8) {
                tile
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
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var tile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )

            CachedAsyncImage(url: channel.logoImageURL) {
                Image(systemName: "tv")
                    .font(.title)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(18)

            if let onToggleFavourite {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onToggleFavourite) {
                            Image(systemName: isFavourite ? "heart.fill" : "heart")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(isFavourite ? AppColors.favorite : .white)
                                .padding(7)
                                .background(.black.opacity(0.35), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(7)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, AppColors.primary)
                        .shadow(radius: 4)
                }
            }
            .padding(8)
        }
        .frame(width: width, height: 94)
        .overlay(alignment: .topLeading) {
            HealthDot(status: health.status(for: channel.streamURL)).padding(8)
        }
    }
}

/// Large featured card shown at the top of Home.
struct HeroChannelCard: View {
    let channel: Channel
    var onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.surface)
                    .overlay(AppColors.coolGradient.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppColors.borderStrong, lineWidth: 1)
                    )

                // Faint large logo as artwork.
                CachedAsyncImage(url: channel.logoImageURL) { EmptyView() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.22)
                    .blur(radius: 2)

                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AppColors.heroScrim)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("featured".localized.uppercased())
                            .font(.caption2.weight(.heavy))
                            .tracking(1.5)
                            .foregroundStyle(AppColors.secondary)
                        Text(channel.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Label("play_now".localized, systemImage: "play.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(AppColors.brandGradient, in: Capsule())
                            if let group = channel.groupTitle, !group.isEmpty {
                                Text(group)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(20)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

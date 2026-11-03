//
//  ChannelsScreen.swift
//  SwiftBase
//
//  Cinematic Home: featured hero + horizontal rails of channel cards.
//

import SwiftUI
import Factory

struct ChannelsScreen: View {
    @StateObject private var viewModel = ChannelsViewModel()
    @InjectedObject(\.appFlow) private var appFlow: AppFlowCoordinator
    @InjectedObject(\.app) private var app: AppManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                topBar

                if !viewModel.hasAnyChannel {
                    emptyState
                } else {
                    if let hero = viewModel.hero {
                        HeroChannelCard(channel: hero) { viewModel.play(hero, in: heroQueue) }
                            .padding(.horizontal, 16)
                    }
                    rail(title: "recents".localized, icon: "clock.fill", channels: viewModel.recentsRail)
                    rail(title: "favorites".localized, icon: "heart.fill", channels: viewModel.favouritesRail)
                    ForEach(viewModel.rails) { r in
                        rail(title: r.title, icon: "tv.fill", channels: r.channels)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .cinematicBackground()
        .onAppear { viewModel.onAppear() }
        .onChange(of: app.activeTab) { if $0 == .home { viewModel.onAppear() } }
        .onChange(of: app.dataVersion) { _ in viewModel.onAppear() }
        .trackScreen(.home)
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Klyra IPTV")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(AppColors.secondary)
                Text("channels".localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
            Button { viewModel.openAddPlaylist() } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColors.brandGradient, in: Circle())
                    .shadow(color: AppColors.primary.opacity(0.5), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Rail

    @ViewBuilder
    private func rail(title: String, icon: String, channels: [Channel]) -> some View {
        if !channels.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title, systemImage: icon)
                    .padding(.horizontal, 16)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(channels, id: \.streamURL) { channel in
                            ChannelCard(
                                channel: channel,
                                isFavourite: viewModel.isFavourite(channel),
                                onPlay: { viewModel.play(channel, in: channels) },
                                onToggleFavourite: { viewModel.toggleFavourite(channel) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var heroQueue: [Channel] {
        if !viewModel.favouritesRail.isEmpty { return viewModel.favouritesRail }
        if !viewModel.recentsRail.isEmpty { return viewModel.recentsRail }
        return viewModel.rails.first?.channels ?? []
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 60)
            ZStack {
                Circle().fill(AppColors.brandGradient).frame(width: 110, height: 110)
                    .blur(radius: 24).opacity(0.6)
                Image(systemName: "tv.badge.wifi")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("no_channels_title".localized)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
            Text("no_channels_message".localized)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            GradientButton("add_playlist", systemImage: "plus") { viewModel.openAddPlaylist() }
                .padding(.horizontal, 44)
                .padding(.top, 6)
            Button { viewModel.openGuide() } label: {
                Label("guide".localized, systemImage: "questionmark.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, 2)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

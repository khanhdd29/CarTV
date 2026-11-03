//
//  FavoritesScreen.swift
//  SwiftBase
//

import SwiftUI
import Factory

struct FavoritesScreen: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @InjectedObject(\.appFlow) private var appFlow: AppFlowCoordinator
    @InjectedObject(\.app) private var app: AppManager

    var body: some View {
        VStack(spacing: 14) {
            CinematicHeader("favorites".localized, eyebrow: "KLYRA")
                .padding(.top, 10)

            if viewModel.favourites.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.favourites) { favourite in
                            ChannelRowView(
                                channel: favourite.asChannel,
                                isFavourite: true,
                                onPlay: { viewModel.play(favourite) },
                                onToggleFavourite: { viewModel.remove(favourite) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
        }
        .cinematicBackground()
        .onAppear { viewModel.onAppear() }
        .onChange(of: app.activeTab) { if $0 == .favorites { viewModel.onAppear() } }
        .onChange(of: app.dataVersion) { _ in viewModel.onAppear() }
        .trackScreen(.favorites)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "heart.slash.fill").font(.system(size: 46)).foregroundStyle(AppColors.textTertiary)
            Text("nothing_saved_yet".localized).font(.subheadline).foregroundStyle(AppColors.textSecondary)
            Spacer(); Spacer()
        }
    }
}

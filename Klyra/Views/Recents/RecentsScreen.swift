//
//  RecentsScreen.swift
//  SwiftBase
//

import SwiftUI
import Factory

struct RecentsScreen: View {
    @StateObject private var viewModel = RecentsViewModel()
    @InjectedObject(\.appFlow) private var appFlow: AppFlowCoordinator
    @InjectedObject(\.app) private var app: AppManager
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 14) {
            CinematicHeader("recents".localized, eyebrow: "KLYRA IPTV") {
                if !viewModel.recents.isEmpty {
                    CircleIconButton(systemName: "trash") { showClearConfirm = true }
                }
            }
            .padding(.top, 10)

            if viewModel.recents.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.recents) { item in
                            ChannelRowView(
                                channel: item.asChannel,
                                isFavourite: false,
                                showFavourite: false,
                                onPlay: { viewModel.play(item) }
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
        .onChange(of: app.activeTab) { if $0 == .recents { viewModel.onAppear() } }
        .onChange(of: app.dataVersion) { _ in viewModel.onAppear() }
        .alert("clear_recents_q".localized, isPresented: $showClearConfirm) {
            Button("cancel".localized, role: .cancel) {}
            Button("clear_all".localized, role: .destructive) { viewModel.clearAll() }
        } message: {
            Text("clear_recents_msg".localized)
        }
        .trackScreen(.recents)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "clock.badge.questionmark").font(.system(size: 46)).foregroundStyle(AppColors.textTertiary)
            Text("no_recents".localized).font(.subheadline).foregroundStyle(AppColors.textSecondary)
            Spacer(); Spacer()
        }
    }
}

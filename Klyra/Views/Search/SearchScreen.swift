//
//  SearchScreen.swift
//  SwiftBase
//

import SwiftUI
import Factory

struct SearchScreen: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var voice = VoiceSearch()
    @InjectedObject(\.appFlow) private var appFlow: AppFlowCoordinator
    @InjectedObject(\.app) private var app: AppManager

    var body: some View {
        VStack(spacing: 16) {
            CinematicHeader("search".localized, eyebrow: "KLYRA IPTV")
                .padding(.top, 10)

            searchField.padding(.horizontal, 16)

            if viewModel.query.isEmpty {
                placeholder("search_channels".localized, icon: "magnifyingglass")
            } else if viewModel.results.isEmpty && !viewModel.isSearching {
                placeholder(String(format: "no_results_for".localized, viewModel.query), icon: "tv.slash")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.results) { channel in
                            ChannelRowView(
                                channel: channel,
                                isFavourite: viewModel.isFavourite(channel),
                                onPlay: { viewModel.play(channel) },
                                onToggleFavourite: { viewModel.toggleFavourite(channel) }
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
        .onChange(of: app.activeTab) { if $0 == .search { viewModel.onAppear() } else { voice.stop() } }
        .onChange(of: voice.transcript) { if !$0.isEmpty { viewModel.query = $0 } }
        .task(id: viewModel.query) {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
        .trackScreen(.search)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColors.textTertiary)
            TextField("", text: $viewModel.query, prompt: Text("search_placeholder".localized).foregroundColor(AppColors.textTertiary))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(AppColors.textPrimary)
            if !viewModel.query.isEmpty {
                Button { viewModel.query = ""; voice.stop() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            if voice.isAvailable {
                Button { voice.toggle() } label: {
                    Image(systemName: voice.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(voice.isListening ? AppColors.favorite : AppColors.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(13)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColors.border, lineWidth: 1))
    }

    private func placeholder(_ text: String, icon: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon).font(.system(size: 42)).foregroundStyle(AppColors.textTertiary)
            Text(text).font(.subheadline).foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer(); Spacer()
        }
    }
}

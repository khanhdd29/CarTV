//
//  ManagePlaylistsScreen.swift
//  SwiftBase
//

import SwiftUI

struct ManagePlaylistsScreen: View {
    @StateObject private var viewModel = ManagePlaylistsViewModel()
    @State private var pendingDelete: PlaylistRef?

    var body: some View {
        VStack(spacing: 16) {
            header

            if viewModel.playlists.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.playlists) { playlist in
                            card(playlist)
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
        .alert(
            "delete_playlist_q".localized,
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
        ) {
            Button("cancel".localized, role: .cancel) { pendingDelete = nil }
            Button("delete".localized, role: .destructive) {
                if let p = pendingDelete { viewModel.delete(p) }
                pendingDelete = nil
            }
        } message: {
            Text("delete_playlist_msg".localized)
        }
        .trackScreen(.managePlaylists)
    }

    private var header: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left") { viewModel.back() }
            VStack(alignment: .leading, spacing: 2) {
                Text("CARTV").font(.caption.weight(.heavy)).tracking(2).foregroundStyle(AppColors.secondary)
                Text("manage_playlists".localized)
                    .font(.title2.weight(.bold)).foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
            CircleIconButton(systemName: "plus", gradient: true) { viewModel.addPlaylist() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private func card(_ playlist: PlaylistRef) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "list.and.film")
                .font(.headline)
                .foregroundStyle(AppColors.primary)
                .frame(width: 42, height: 42)
                .background(AppColors.primarySoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name).font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary).lineLimit(1)
                Text(String(format: "channel_count".localized, playlist.channelCount))
                    .font(.caption).foregroundStyle(AppColors.textTertiary)
            }
            Spacer()

            if viewModel.refreshingId == playlist.id {
                ProgressView().tint(AppColors.secondary)
            } else {
                Button { viewModel.refresh(playlist) } label: {
                    Image(systemName: "arrow.clockwise").foregroundStyle(AppColors.secondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            Button { pendingDelete = playlist } label: {
                Image(systemName: "trash").foregroundStyle(AppColors.destructive)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface.opacity(0.75))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColors.border, lineWidth: 1))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "list.and.film").font(.system(size: 44)).foregroundStyle(AppColors.textTertiary)
            Text("no_channels_message".localized)
                .font(.subheadline).foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer(); Spacer()
        }
    }
}

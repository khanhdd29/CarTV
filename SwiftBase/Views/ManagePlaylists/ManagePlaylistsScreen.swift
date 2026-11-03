//
//  ManagePlaylistsScreen.swift
//  SwiftBase
//

import SwiftUI

/// Identifiable wrapper so a URL can drive a `.sheet(item:)`.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// UIActivityViewController bridge for the share sheet.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct ManagePlaylistsScreen: View {
    @StateObject private var viewModel = ManagePlaylistsViewModel()
    @State private var pendingDelete: PlaylistRef?
    @State private var renameTarget: PlaylistRef?
    @State private var renameText = ""
    @State private var shareItem: ShareItem?

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
        .alert("rename_playlist".localized, isPresented: Binding(
            get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("playlist_name".localized, text: $renameText)
            Button("cancel".localized, role: .cancel) { renameTarget = nil }
            Button("save".localized) {
                if let t = renameTarget { viewModel.rename(t, to: renameText) }
                renameTarget = nil
            }
        }
        .sheet(item: $shareItem) { item in ActivityView(items: [item.url]) }
        .trackScreen(.managePlaylists)
    }

    private var header: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left") { viewModel.back() }
            VStack(alignment: .leading, spacing: 2) {
                Text("KLYRA").font(.caption.weight(.heavy)).tracking(2).foregroundStyle(AppColors.secondary)
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
        VStack(alignment: .leading, spacing: 10) {
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

                if viewModel.checkingId == playlist.id {
                    ProgressView().tint(AppColors.violet).frame(width: 36, height: 36)
                } else {
                    Button { viewModel.checkHealth(playlist) } label: {
                        Image(systemName: "waveform.path.ecg").foregroundStyle(AppColors.violet)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.checkingId != nil)
                }

                if viewModel.refreshingId == playlist.id {
                    ProgressView().tint(AppColors.secondary).frame(width: 36, height: 36)
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

            if viewModel.checkingId == playlist.id {
                Text("health_checking".localized)
                    .font(.caption).foregroundStyle(AppColors.textTertiary)
            } else if let s = viewModel.healthSummary[playlist.id] {
                healthSummaryRow(s)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface.opacity(0.75))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColors.border, lineWidth: 1))
        )
        .contextMenu {
            Button {
                renameText = playlist.name; renameTarget = playlist
            } label: { Label("rename_playlist".localized, systemImage: "pencil") }
            Button {
                Task { if let url = await viewModel.exportM3U(playlist) { shareItem = ShareItem(url: url) } }
            } label: { Label("export_m3u".localized, systemImage: "square.and.arrow.up") }
        }
    }

    private func healthSummaryRow(_ s: (online: Int, offline: Int)) -> some View {
        HStack(spacing: 14) {
            countPill(AppColors.success, String(format: "health_online_n".localized, s.online))
            countPill(AppColors.favorite, String(format: "health_offline_n".localized, s.offline))
            Spacer()
        }
        .font(.caption.weight(.medium))
    }

    private func countPill(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).foregroundStyle(AppColors.textSecondary)
        }
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

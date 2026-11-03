//
//  AddPlaylistScreen.swift
//  SwiftBase
//
//  Cinematic add sheet: custom source pills, dark fields, gradient CTAs.
//  Four sources: URL · File · Stream · Device.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddPlaylistScreen: View {
    @StateObject private var viewModel = AddPlaylistViewModel()

    @State private var showFileImporter = false
    @State private var pickedVideos: [PhotosPickerItem] = []
    @State private var showQRScanner = false

    var body: some View {
        VStack(spacing: 0) {
            handle
            header
            modePills
                .padding(.horizontal, 20)
                .padding(.top, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch viewModel.mode {
                    case .url:    urlSection
                    case .xtream: xtreamSection
                    case .file:   fileSection
                    case .stream: streamSection
                    case .device: deviceSection
                    }

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(AppColors.destructive)
                    }
                    if viewModel.isWorking {
                        HStack(spacing: 10) {
                            ProgressView().tint(AppColors.secondary)
                            Text(String(format: "parsing_channels".localized, viewModel.importedCount))
                                .font(.subheadline).foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .cinematicBackground()
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.m3uPlaylist, .plainText, .text, .data],
            allowsMultipleSelection: false
        ) { viewModel.importFile($0) }
        .onChange(of: pickedVideos) { items in
            viewModel.importVideos(items)
            pickedVideos = []
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerSheet { scanned in
                viewModel.urlText = scanned
                showQRScanner = false
            } onCancel: { showQRScanner = false }
        }
        .trackScreen(.addPlaylist)
    }

    // MARK: Header

    private var handle: some View {
        Capsule().fill(AppColors.borderStrong)
            .frame(width: 40, height: 5)
            .padding(.top, 10)
    }

    private var header: some View {
        HStack {
            Text("add_playlist".localized)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Button { viewModel.cancel() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(AppColors.surface, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var modePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AddPlaylistViewModel.Mode.allCases) { mode in
                    let active = viewModel.mode == mode
                    Button { withAnimation(.easeInOut(duration: 0.2)) { viewModel.mode = mode } } label: {
                        Text(mode.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(active ? .white : AppColors.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background {
                                if active {
                                    Capsule().fill(AppColors.brandGradient)
                                } else {
                                    Capsule().fill(AppColors.surface).overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Sections

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldLabel("playlist_url".localized)
            darkField("https://…/playlist.m3u", text: $viewModel.urlText, axis: true)
            Button { showQRScanner = true } label: {
                Label("scan_qr".localized, systemImage: "qrcode.viewfinder")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.secondary)
            }
            .buttonStyle(.plain)
            fieldLabel("playlist_name".localized)
            darkField("playlist_name".localized, text: $viewModel.nameText)
            GradientButton("add", systemImage: "arrow.down.circle.fill") { viewModel.addURL() }
                .opacity(viewModel.canSubmitURL ? 1 : 0.5)
                .disabled(!viewModel.canSubmitURL)
                .padding(.top, 4)
        }
    }

    private var xtreamSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldLabel("xtream_server".localized)
            darkField("http://host:port", text: $viewModel.xtreamURL, axis: true)
            fieldLabel("xtream_username".localized)
            plainField("xtream_username".localized, text: $viewModel.xtreamUser)
            fieldLabel("xtream_password".localized)
            secureField("xtream_password".localized, text: $viewModel.xtreamPass)
            Text("xtream_hint".localized).font(.footnote).foregroundStyle(AppColors.textTertiary)
            GradientButton("add", systemImage: "arrow.down.circle.fill") { viewModel.addXtream() }
                .opacity(viewModel.canSubmitXtream ? 1 : 0.5)
                .disabled(!viewModel.canSubmitXtream)
                .padding(.top, 4)
        }
    }

    private var fileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("source_file_hint".localized)
                .font(.subheadline).foregroundStyle(AppColors.textSecondary)
            fieldLabel("playlist_name".localized)
            darkField("playlist_name".localized, text: $viewModel.nameText)
            GradientButton("choose_file", systemImage: "folder.fill") { showFileImporter = true }
                .disabled(viewModel.isWorking)
                .padding(.top, 4)
        }
    }

    private var streamSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldLabel("stream_url".localized)
            darkField("https://…/stream.m3u8", text: $viewModel.streamText, axis: true)
            fieldLabel("playlist_name".localized)
            darkField("playlist_name".localized, text: $viewModel.streamNameText)
            GradientButton("play_now", systemImage: "play.fill") { viewModel.playStreamNow() }
                .opacity(viewModel.canSubmitStream ? 1 : 0.5)
                .disabled(!viewModel.canSubmitStream)
                .padding(.top, 4)
            Button { viewModel.saveStream() } label: {
                Label("save".localized, systemImage: "square.and.arrow.down")
                    .font(.headline).foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmitStream)
        }
    }

    private var deviceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("source_device_hint".localized)
                .font(.subheadline).foregroundStyle(AppColors.textSecondary)
            PhotosPicker(selection: $pickedVideos, maxSelectionCount: 50, matching: .videos) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.stack.fill")
                    Text("select_videos".localized)
                }
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(AppColors.brandGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppColors.primary.opacity(0.45), radius: 16, y: 8)
            }
            .disabled(viewModel.isWorking)
        }
    }

    // MARK: Field building blocks

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.footnote.weight(.semibold)).foregroundStyle(AppColors.textTertiary)
    }

    private func darkField(_ placeholder: String, text: Binding<String>, axis: Bool = false) -> some View {
        Group {
            if axis {
                TextField(placeholder, text: text, axis: .vertical).lineLimit(1...3)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .keyboardType(.URL)
        .foregroundStyle(AppColors.textPrimary)
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColors.border, lineWidth: 1))
    }

    private func plainField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .foregroundStyle(AppColors.textPrimary)
            .padding(14)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColors.border, lineWidth: 1))
    }

    private func secureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .foregroundStyle(AppColors.textPrimary)
            .padding(14)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColors.border, lineWidth: 1))
    }
}

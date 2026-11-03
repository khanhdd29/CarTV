//
//  EPGSourceScreen.swift
//  SwiftBase
//
//  Enter an XMLTV program-guide link. The guide is parsed + cached locally and
//  matched to channels by `tvg-id`; the Player then shows "now / next".
//

import SwiftUI
import Factory

struct EPGSourceScreen: View {
    @Injected(\.app) private var app: AppManager
    @StateObject private var viewModel = EPGSourceViewModel()
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    introCard
                    fieldCard
                    GradientButton("epg_load".localized, systemImage: "arrow.down.circle.fill") {
                        fieldFocused = false
                        viewModel.load()
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1)

                    if viewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView().tint(AppColors.secondary)
                            Text("epg_loading".localized)
                                .font(.footnote).foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    if let status = viewModel.statusMessage {
                        statusLabel(status, icon: "checkmark.circle.fill", tint: AppColors.success)
                    }
                    if let error = viewModel.errorMessage {
                        statusLabel(error, icon: "exclamationmark.triangle.fill", tint: Color(hex: 0xF5A623))
                    }

                    if viewModel.hasSource {
                        Button(role: .destructive) { viewModel.clear() } label: {
                            Text("epg_clear".localized)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppColors.favorite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AppColors.favorite.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
        }
        .cinematicBackground()
        .trackScreen(.epg)
        .onAppear { viewModel.onAppear() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left") { app.navi.pop() }
            VStack(alignment: .leading, spacing: 2) {
                Text("KLYRA").font(.caption.weight(.heavy)).tracking(2).foregroundStyle(AppColors.secondary)
                Text("epg_title".localized).font(.title2.weight(.bold)).foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "tv.and.hifispeaker.fill")
                    .font(.subheadline.weight(.bold)).foregroundStyle(AppColors.primary)
                    .frame(width: 34, height: 34)
                    .background(AppColors.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text("epg_what_title".localized).font(.headline).foregroundStyle(AppColors.textPrimary)
            }
            Text("epg_what_body".localized)
                .font(.subheadline).foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    private var fieldCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("epg_url_label".localized)
                .font(.caption.weight(.semibold)).foregroundStyle(AppColors.textTertiary)
            TextField("https://…/epg.xml", text: $viewModel.urlText, axis: .vertical)
                .focused($fieldFocused)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .tint(AppColors.secondary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.background.opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppColors.border, lineWidth: 1))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    private func statusLabel(_ text: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.footnote.weight(.bold)).foregroundStyle(tint)
            Text(text).font(.footnote).foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppColors.surface.opacity(0.75))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppColors.border, lineWidth: 1))
    }
}

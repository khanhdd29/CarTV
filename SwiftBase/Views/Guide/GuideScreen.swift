//
//  GuideScreen.swift
//  SwiftBase
//
//  A short "how to use CarTV" guide for new users — tied to the app's own flow
//  (add sources → browse/save → watch). Opened from Settings and the empty state.
//

import SwiftUI
import Factory

struct GuideScreen: View {
    @Injected(\.app) private var app: AppManager

    var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    addSourcesCard
                    card(icon: "key.fill", tint: AppColors.violet,
                         title: "guide_xtream_title".localized, body: "guide_xtream_body".localized)
                    card(icon: "magnifyingglass", tint: AppColors.secondary,
                         title: "guide_links_title".localized, body: "guide_links_body".localized)
                    card(icon: "heart.fill", tint: AppColors.favorite,
                         title: "guide_browse_title".localized, body: "guide_browse_body".localized)
                    card(icon: "play.rectangle.fill", tint: AppColors.primary,
                         title: "guide_watch_title".localized, body: "guide_watch_body".localized)
                    card(icon: "sparkles", tint: AppColors.secondary,
                         title: "guide_more_title".localized, body: "guide_more_body".localized)
                    card(icon: "waveform.path.ecg", tint: AppColors.success,
                         title: "guide_health_title".localized, body: "guide_health_body".localized)
                    card(icon: "lightbulb.fill", tint: Color(hex: 0xF5A623),
                         title: "guide_tip_title".localized, body: "guide_tip_body".localized)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
        }
        .cinematicBackground()
        .trackScreen(.guide)
    }

    private var header: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left") { app.navi.pop() }
            VStack(alignment: .leading, spacing: 2) {
                Text("CARTV").font(.caption.weight(.heavy)).tracking(2).foregroundStyle(AppColors.secondary)
                Text("guide".localized).font(.title2.weight(.bold)).foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var addSourcesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader(icon: "plus.circle.fill", tint: AppColors.primary, title: "guide_add_title".localized)
            Text("guide_add_body".localized)
                .font(.subheadline).foregroundStyle(AppColors.textSecondary)
            sourceRow("link", "guide_src_url".localized)
            sourceRow("qrcode.viewfinder", "guide_src_qr".localized)
            sourceRow("folder.fill", "guide_src_file".localized)
            sourceRow("dot.radiowaves.left.and.right", "guide_src_stream".localized)
            sourceRow("photo.stack.fill", "guide_src_device".localized)
            sourceRow("person.badge.key.fill", "guide_src_xtream".localized)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    private func card(icon: String, tint: Color, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeader(icon: icon, tint: tint, title: title)
            Text(body).font(.subheadline).foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    private func cardHeader(icon: String, tint: Color, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold)).foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title).font(.headline).foregroundStyle(AppColors.textPrimary)
        }
    }

    private func sourceRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold)).foregroundStyle(AppColors.primary)
                .frame(width: 20)
            Text(text).font(.footnote).foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppColors.surface.opacity(0.75))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppColors.border, lineWidth: 1))
    }
}

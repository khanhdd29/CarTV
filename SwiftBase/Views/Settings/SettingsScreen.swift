//
//  SettingsScreen.swift
//  SwiftBase
//

import SwiftUI
import Factory

struct SettingsScreen: View {
    @StateObject private var viewModel = SettingsViewModel()
    @InjectedObject(\.app) private var app: AppManager
    @InjectedObject(\.appLock) private var appLock: AppLock
    @EnvironmentObject private var coordinator: AppFlowCoordinator
    @Environment(\.openURL) private var openURL
    @State private var pinMode: ParentalPinSheet.Mode?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CinematicHeader("settings".localized, eyebrow: "CARTV")
                    .padding(.top, 10)

                VStack(spacing: 10) {
                    row("manage_playlists".localized, icon: "list.and.film", tint: AppColors.primary) {
                        viewModel.openManagePlaylists()
                    }
                    row("epg_title".localized, icon: "tv.and.hifispeaker.fill", tint: AppColors.violet) {
                        viewModel.openEPG()
                    }
                    row("guide".localized, icon: "questionmark.circle.fill", tint: AppColors.secondary) {
                        viewModel.openGuide()
                    }
                    toggleRow("hide_dead_channels".localized, icon: "eye.slash.fill",
                              tint: AppColors.favorite, isOn: $app.hideDeadChannels)
                    toggleRow("sort_az".localized, icon: "textformat.abc",
                              tint: AppColors.secondary, isOn: Binding(
                                get: { app.sortAZ },
                                set: { app.sortAZ = $0; app.bumpData() }))
                    toggleRow("data_saver".localized, icon: "speedometer",
                              tint: AppColors.success, isOn: $app.dataSaver)
                    Button {
                        pinMode = appLock.isEnabled ? .disable : .set
                    } label: {
                        rowContent("parental_lock".localized, icon: "lock.shield.fill", tint: AppColors.violet) {
                            HStack(spacing: 6) {
                                Text((appLock.isEnabled ? "pin_on" : "pin_off").localized)
                                    .font(.subheadline).foregroundStyle(AppColors.textSecondary)
                                chevron
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    Button { viewModel.openLanguage() } label: {
                        rowContent("language".localized, icon: "globe", tint: AppColors.secondary) {
                            HStack(spacing: 6) {
                                coordinator.language.flagImageView
                                    .resizable().scaledToFill()
                                    .frame(width: 22, height: 15)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                Text(coordinator.language.displayName)
                                    .font(.subheadline).foregroundStyle(AppColors.textSecondary)
                                chevron
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    row("rate".localized, icon: "star.fill", tint: Color(hex: 0xF5A623)) { viewModel.rateApp() }

                    ShareLink(item: viewModel.shareMessage) {
                        rowContent("share".localized, icon: "square.and.arrow.up", tint: AppColors.success) { chevron }
                    }
                    .buttonStyle(.plain)

                    row("privacy_policy".localized, icon: "lock.shield.fill", tint: AppColors.textSecondary) {
                        if let url = viewModel.policyURL { openURL(url) }
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .cinematicBackground()
        .sheet(item: $pinMode) { mode in
            ParentalPinSheet(mode: mode) { pinMode = nil }
        }
        .trackScreen(.settings)
    }

    // MARK: Row building

    private func row(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowContent(title, icon: icon, tint: tint) { chevron }
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, icon: String, tint: Color, isOn: Binding<Bool>) -> some View {
        rowContent(title, icon: icon, tint: tint) {
            Toggle("", isOn: isOn).labelsHidden().tint(AppColors.primary)
        }
    }

    private func rowContent<Trailing: View>(_ title: String, icon: String, tint: Color, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            trailing()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface.opacity(0.75))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppColors.border, lineWidth: 1))
        )
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppColors.textTertiary)
    }
}

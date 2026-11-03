//
//  FloatingTabBar.swift
//  SwiftBase
//
//  A floating glass navigation bar — replaces the stock tab bar for a more
//  distinctive, "wow" feel. Active tab gets a gradient pill.
//

import SwiftUI

struct FloatingTabBar: View {
    @Binding var selection: HomeTab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                item(tab)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 22, x: 0, y: 10)
        .padding(.horizontal, 16)
    }

    private func item(_ tab: HomeTab) -> some View {
        let isActive = selection == tab
        return Button {
            guard selection != tab else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 9.5, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? Color.white : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppColors.brandGradient)
                            .shadow(color: AppColors.primary.opacity(0.5), radius: 10, y: 4)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

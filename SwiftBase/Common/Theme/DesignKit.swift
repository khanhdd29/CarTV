//
//  DesignKit.swift
//  SwiftBase
//
//  Reusable cinematic building blocks: an ambient background, glass cards,
//  section headers and a gradient CTA. Keeps the look consistent and "wow"
//  without repeating styling in every screen.
//

import SwiftUI

// MARK: - Ambient cinematic background

/// A dark background with two soft colored glows — use as the base layer of a
/// screen: `ZStack { CinematicBackground(); content }`.
struct CinematicBackground: View {
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            Circle()
                .fill(AppColors.primary.opacity(0.22))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -140, y: -260)
            Circle()
                .fill(AppColors.violet.opacity(0.20))
                .frame(width: 320, height: 320)
                .blur(radius: 130)
                .offset(x: 160, y: -120)
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Lay the cinematic background behind this view.
    func cinematicBackground() -> some View {
        ZStack { CinematicBackground(); self }
    }

    /// Glass card surface: translucent fill, hairline border, soft shadow.
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat? = nil) -> some View {
        self
            .padding(padding ?? 0)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.surface.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
    }
}

// MARK: - Section header (rail title + optional action)

struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.secondary)
            }
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Gradient CTA

struct GradientButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title.localized)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.brandGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppColors.primary.opacity(0.45), radius: 16, x: 0, y: 8)
        }
    }
}

// MARK: - Cinematic screen header (big left title + eyebrow + trailing)

struct CinematicHeader<Trailing: View>: View {
    let title: String
    var eyebrow: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, eyebrow: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.eyebrow = eyebrow
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(.caption.weight(.heavy)).tracking(2)
                        .foregroundStyle(AppColors.secondary)
                }
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Circular icon button

struct CircleIconButton: View {
    let systemName: String
    var gradient: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline.weight(.bold))
                .foregroundStyle(gradient ? .white : AppColors.textSecondary)
                .frame(width: 44, height: 44)
                .background {
                    if gradient {
                        Circle().fill(AppColors.brandGradient)
                            .shadow(color: AppColors.primary.opacity(0.5), radius: 10, y: 4)
                    } else {
                        Circle().fill(AppColors.surface).overlay(Circle().stroke(AppColors.border, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Live badge

struct LiveBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(.white).frame(width: 5, height: 5)
            Text("live".localized)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(AppColors.live, in: Capsule())
    }
}

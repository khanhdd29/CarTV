//
//  PinLockViews.swift
//  SwiftBase
//
//  The parental PIN screens: a reusable numeric pad, the full-screen lock gate,
//  and the set/disable flow presented from Settings.
//

import SwiftUI
import Factory

/// A 4-digit numeric pad. `onComplete` returns true to accept (parent moves on)
/// or false to reject (the dots shake and clear).
struct PinPadView: View {
    let title: String
    var subtitle: String? = nil
    let onComplete: (String) -> Bool

    @State private var entry = ""
    @State private var shake: CGFloat = 0

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40)).foregroundStyle(AppColors.primary)
                Text(title).font(.title3.weight(.bold)).foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(AppColors.textSecondary)
                }
            }
            dots
            keypad
        }
        .padding(24)
    }

    private var dots: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < entry.count ? AppColors.primary : Color.clear)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(AppColors.border, lineWidth: 1.5))
            }
        }
        .modifier(ShakeEffect(travel: 10, shakes: 3, animatableData: shake))
    }

    private var keypad: some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 3), spacing: 18) {
            ForEach(keys.indices, id: \.self) { idx in keyButton(keys[idx]) }
        }
        .frame(maxWidth: 300)
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(height: 72)
        } else {
            Button { press(key) } label: {
                Group {
                    if key == "⌫" { Image(systemName: "delete.left") }
                    else { Text(key).font(.title.weight(.medium)) }
                }
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity).frame(height: 72)
                .background(key == "⌫" ? Color.clear : AppColors.surface.opacity(0.7),
                            in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func press(_ key: String) {
        if key == "⌫" { if !entry.isEmpty { entry.removeLast() }; return }
        guard entry.count < 4 else { return }
        entry.append(key)
        guard entry.count == 4 else { return }
        let value = entry
        if onComplete(value) {
            entry = ""   // accepted; parent swaps the view
        } else {
            withAnimation(.default) { shake += 1 }
            entry = ""
        }
    }
}

/// Side-to-side shake for a rejected PIN.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 10
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = travel * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

/// Full-screen lock gate shown while the app is locked.
struct AppLockGate: View {
    @InjectedObject(\.appLock) private var lock: AppLock

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            PinPadView(title: "pin_enter".localized) { lock.unlock($0) }
        }
    }
}

/// Set a new PIN (enter twice) or disable the existing one (enter to confirm).
struct ParentalPinSheet: View {
    enum Mode: Identifiable { case set, disable; var id: Int { self == .set ? 0 : 1 } }
    let mode: Mode
    let onDone: () -> Void

    @InjectedObject(\.appLock) private var lock: AppLock
    @State private var firstPIN: String?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .disable:
            PinPadView(title: "pin_enter".localized, subtitle: "pin_disable_hint".localized) { pin in
                if lock.disable(withPIN: pin) { onDone(); return true }
                return false
            }
        case .set:
            if let first = firstPIN {
                PinPadView(title: "pin_confirm".localized) { pin in
                    guard pin == first else { return false }
                    lock.setPIN(pin); onDone(); return true
                }
                .id("confirm")
            } else {
                PinPadView(title: "pin_set".localized, subtitle: "pin_set_hint".localized) { pin in
                    firstPIN = pin; return true
                }
                .id("first")
            }
        }
    }
}

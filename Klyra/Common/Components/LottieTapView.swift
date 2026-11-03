//
//  LottieTapView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  The original Lottie-based view is preserved under `MONETIZATION_ENABLED`
//  (Lottie arrives transitively with the ad SDK). v1 uses a pure-SwiftUI
//  stand-in with the same API so call sites are unchanged.
//

import SwiftUI

#if MONETIZATION_ENABLED
import Lottie

struct LottieTapView: UIViewRepresentable {
    /// File name (without extension) of the animation in the bundle.
    let name: String

    /// Optional recolor. When set, every colored layer of the animation is
    /// tinted to this color — used to match the app's accent / brand color.
    var tint: Color? = nil

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        // Try the bundle root first, then the `Json` subdirectory (depends on how
        // the build copies the resource folder).
        view.animation = LottieAnimation.named(name)
            ?? LottieAnimation.named(name, subdirectory: "Json")
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore

        applyTint(to: view)

        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        view.play()
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        applyTint(to: uiView)
        if !uiView.isAnimationPlaying {
            uiView.play()
        }
    }

    /// Recolor every fill/stroke (`**.Color`) of the animation to `tint`.
    private func applyTint(to view: LottieAnimationView) {
        guard let tint else { return }
        let provider = ColorValueProvider(UIColor(tint).lottieColorValue)
        view.setValueProvider(provider, keypath: AnimationKeypath(keypath: "**.Color"))
    }
}

#else

/// Pure-SwiftUI stand-in for the looping "tap here" hint (same API).
struct LottieTapView: View {
    let name: String
    var tint: Color? = nil

    @State private var animating = false

    var body: some View {
        Image(systemName: "hand.tap.fill")
            .resizable()
            .scaledToFit()
            .padding(10)
            .foregroundStyle(tint ?? .accentColor)
            .scaleEffect(animating ? 0.82 : 1.0)
            .opacity(animating ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animating)
            .onAppear { animating = true }
    }
}

#endif

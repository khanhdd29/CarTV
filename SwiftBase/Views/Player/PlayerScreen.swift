//
//  PlayerScreen.swift
//  SwiftBase
//
//  Full-screen playback with fully custom controls (no AVKit native buttons to
//  overlap ours). Tap toggles the controls; they auto-hide after a few seconds.
//

import SwiftUI
import AVKit
import Factory

struct PlayerScreen: View {
    @InjectedObject(\.playerController) private var controller: PlayerController
    @InjectedObject(\.app) private var app: AppManager

    @StateObject private var pip = PiPManager()
    @State private var controlsShown = true
    @State private var hideWorkItem: DispatchWorkItem?
    @State private var scrub: Double = 0
    @State private var isScrubbing = false

    private var engine: AVPlayerEngine { controller.avEngine }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            videoSurface.ignoresSafeArea()

            // Tap layer toggles the controls.
            Color.black.opacity(controlsShown ? 0.28 : 0.001)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { toggleControls() }

            if controlsShown { controls.transition(.opacity) }

            statusOverlay
        }
        .onAppear { scheduleHide(); OrientationGate.allowAll() }
        .onDisappear { controller.stop(); OrientationGate.lockPortrait() }
        .statusBarHidden()
        .trackScreen(.player)
    }

    // MARK: Surface

    @ViewBuilder
    private var videoSurface: some View {
        #if canImport(MobileVLCKit)
        if controller.usingFallback {
            VLCVideoSurface(engine: controller.vlcEngine)
        } else {
            PlayerLayerView(player: engine.player, pip: pip)
        }
        #else
        PlayerLayerView(player: engine.player, pip: pip)
        #endif
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 0) {
            topBar
            if let remaining = controller.sleepRemaining { sleepBadge(remaining) }
            if let now = controller.nowNext.now, !app.carMode { epgStrip(now) }
            Spacer()
            if app.carMode {
                carControls
            } else {
                if !controller.usingFallback { centerControls }
                Spacer()
                bottomBar
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: Car mode — oversized, glance-and-tap controls for driving.

    private var carControls: some View {
        VStack(spacing: 22) {
            Text(controller.current?.name ?? "")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(2).multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 24)

            HStack(spacing: 48) {
                carButton("backward.end.fill", enabled: controller.hasPrevious) { controller.previous() }
                Button {
                    engine.togglePlayPause(); scheduleHide()
                } label: {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 150, height: 150)
                        .background(AppColors.brandGradient, in: Circle())
                        .shadow(color: AppColors.primary.opacity(0.6), radius: 20, y: 8)
                }
                .buttonStyle(.plain)
                carButton("forward.end.fill", enabled: controller.hasNext) { controller.next() }
            }
            Spacer().frame(height: 0)
        }
    }

    private func carButton(_ name: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button { if enabled { action(); scheduleHide() } } label: {
            Image(systemName: name)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white.opacity(enabled ? 1 : 0.25))
                .frame(width: 96, height: 96)
                .background(.white.opacity(enabled ? 0.14 : 0.05), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            circleButton("xmark") { app.navi.pop() }
            Spacer(minLength: 8)
            Text(controller.current?.name ?? "")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white).lineLimit(1)
            if controller.isLive { LiveBadge() }
            Spacer(minLength: 8)
            optionsMenu
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { app.carMode.toggle() }
                scheduleHide()
            } label: {
                Image(systemName: app.carMode ? "car.fill" : "car")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(app.carMode ? AppColors.secondary : .white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            AirPlayButton().frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
    }

    private func trackButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button { action(); scheduleHide() } label: {
            if selected { Label(label, systemImage: "checkmark") } else { Text(label) }
        }
    }

    private static let speeds: [(Float, String)] =
        [(0.5, "0.5x"), (0.75, "0.75x"), (1.0, "1x"), (1.25, "1.25x"), (1.5, "1.5x"), (2.0, "2x")]

    private var optionsMenu: some View {
        Menu {
            if pip.isPossible {
                Button {
                    pip.toggle(); scheduleHide()
                } label: { Label("player_pip".localized, systemImage: "pip.enter") }
            }
            if !engine.subtitleOptions.isEmpty {
                Menu("player_subtitles".localized) {
                    trackButton(label: "player_off".localized, selected: engine.selectedSubtitle() == nil) {
                        engine.selectSubtitle(nil)
                    }
                    ForEach(engine.subtitleOptions, id: \.self) { opt in
                        trackButton(label: opt.displayName, selected: engine.selectedSubtitle() == opt) {
                            engine.selectSubtitle(opt)
                        }
                    }
                }
            }
            if engine.audioOptions.count > 1 {
                Menu("player_audio".localized) {
                    ForEach(engine.audioOptions, id: \.self) { opt in
                        trackButton(label: opt.displayName, selected: engine.selectedAudio() == opt) {
                            engine.selectAudio(opt)
                        }
                    }
                }
            }
            if !controller.isLive {
                Menu("player_speed".localized) {
                    ForEach(Self.speeds, id: \.1) { rate, label in
                        Button {
                            engine.setRate(rate); scheduleHide()
                        } label: {
                            if engine.playbackRate == rate { Label(label, systemImage: "checkmark") }
                            else { Text(label) }
                        }
                    }
                }
            }
            Menu("player_sleep".localized) {
                Button {
                    controller.setSleepTimer(minutes: nil); scheduleHide()
                } label: {
                    if controller.sleepRemaining == nil { Label("player_off".localized, systemImage: "checkmark") }
                    else { Text("player_off".localized) }
                }
                ForEach([15, 30, 45, 60], id: \.self) { m in
                    Button {
                        controller.setSleepTimer(minutes: m); scheduleHide()
                    } label: { Text(String(format: "player_minutes".localized, m)) }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body.weight(.semibold)).foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
    }

    private var centerControls: some View {
        HStack(spacing: 40) {
            iconButton("gobackward.10", size: 26) { engine.skip(-10); scheduleHide() }
                .opacity(controller.isLive ? 0 : 1)
            Button {
                engine.togglePlayPause(); scheduleHide()
            } label: {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            iconButton("goforward.10", size: 26) { engine.skip(10); scheduleHide() }
                .opacity(controller.isLive ? 0 : 1)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 14) {
            // Previous — shown always (dimmed when unavailable) so it isn't lonely.
            navButton("backward.end.fill", enabled: controller.hasPrevious) { controller.previous() }

            if controller.isLive {
                Spacer()
                Text("live".localized)
                    .font(.caption.weight(.heavy)).foregroundStyle(.white.opacity(0.9))
                Spacer()
            } else {
                Text(timeText(isScrubbing ? scrub : engine.currentTime))
                    .font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.85))
                    .frame(width: 42)
                Slider(
                    value: Binding(
                        get: { isScrubbing ? scrub : engine.currentTime },
                        set: { scrub = $0 }
                    ),
                    in: 0...max(engine.duration, 1),
                    onEditingChanged: { editing in
                        isScrubbing = editing
                        if editing { cancelHide() }
                        else { engine.seek(to: scrub); scheduleHide() }
                    }
                )
                .tint(AppColors.primary)
                Text(timeText(engine.duration))
                    .font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.6))
                    .frame(width: 42)
            }

            navButton("forward.end.fill", enabled: controller.hasNext) { controller.next() }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    // MARK: EPG now/next strip

    private func epgStrip(_ now: EPGEntry) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text("epg_now".localized)
                    .font(.caption2.weight(.heavy)).tracking(0.5)
                    .foregroundStyle(AppColors.secondary)
                Text(now.title)
                    .font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                Spacer(minLength: 8)
                Text("\(clock(now.start))–\(clock(now.stop))")
                    .font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.6))
            }
            ProgressView(value: now.progress())
                .tint(AppColors.secondary)
                .scaleEffect(x: 1, y: 0.55, anchor: .center)
            if let next = controller.nowNext.next {
                HStack(spacing: 6) {
                    Text("epg_next".localized)
                        .font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.45))
                    Text(next.title)
                        .font(.caption2).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func sleepBadge(_ seconds: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill").font(.caption2)
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.caption2.monospacedDigit().weight(.semibold))
        }
        .foregroundStyle(AppColors.secondary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(.black.opacity(0.42), in: Capsule())
        .padding(.top, 8)
    }

    private func clock(_ date: Date) -> String {
        Self.clockFormatter.string(from: date)
    }

    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    // MARK: Status overlays

    @ViewBuilder
    private var statusOverlay: some View {
        if !controller.usingFallback {
            switch controller.state {
            case .loading, .idle:
                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("loading_stream".localized).font(.footnote).foregroundStyle(.white.opacity(0.8))
                }
            case .failed(let message):
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.yellow)
                    Text("playback_error".localized).font(.headline).foregroundStyle(.white)
                    Text(message).font(.caption).foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                    HStack(spacing: 12) {
                        Button("try_again".localized) { controller.retry() }.buttonStyle(.borderedProminent)
                        if controller.hasNext {
                            Button("next_channel".localized) { controller.next() }.buttonStyle(.bordered).tint(.white)
                        }
                    }
                }
            case .playing:
                EmptyView()
            }
        }
    }

    // MARK: Buttons

    private func circleButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.body.weight(.semibold)).foregroundStyle(.white)
                .padding(10).background(.black.opacity(0.4), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func iconButton(_ name: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.system(size: size, weight: .semibold)).foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func navButton(_ name: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button { if enabled { action(); scheduleHide() } } label: {
            Image(systemName: name).font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(enabled ? 1 : 0.28))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Helpers

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) { controlsShown.toggle() }
        if controlsShown { scheduleHide() } else { cancelHide() }
    }

    private func scheduleHide() {
        cancelHide()
        let item = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) { controlsShown = false }
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: item)
    }

    private func cancelHide() { hideWorkItem?.cancel(); hideWorkItem = nil }

    private func timeText(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// Native AirPlay route picker.
private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = UIColor(AppColors.primary)
        return view
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

//
//  VoiceSearch.swift
//  SwiftBase
//
//  On-device speech-to-text for the search box (SFSpeechRecognizer +
//  AVAudioEngine). Lets the user dictate a channel name instead of typing.
//
//  Nothing touches the microphone — no permission prompt, no audio engine — until
//  the user taps the mic button (`toggle`/`start`). The engine is created on that
//  tap and torn down on stop.
//

import Speech
import AVFoundation

@MainActor
final class VoiceSearch: ObservableObject {
    @Published private(set) var isListening = false
    @Published var transcript = ""

    private let recognizer = SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    /// Created lazily when the user taps the mic, so no audio input (and no mic
    /// permission prompt) is set up just by opening Search.
    private var engine: AVAudioEngine?

    /// Whether speech recognition is available. Reading this does not prompt.
    var isAvailable: Bool { recognizer?.isAvailable ?? false }

    func toggle() { isListening ? stop() : start() }

    /// Requests permission (on the tap) and, if granted, starts listening.
    func start() {
        SFSpeechRecognizer.requestAuthorization { status in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    guard status == .authorized, granted else { return }
                    self.beginSession()
                }
            }
        }
    }

    private func beginSession() {
        guard let recognizer, recognizer.isAvailable, !isListening else { return }
        transcript = ""
        let engine = AVAudioEngine()
        self.engine = engine
        do {
            let session = AVAudioSession.sharedInstance()
            // `.playAndRecord`/`.default` keeps the mic input valid; `.record`+`.measurement`
            // could hand back a 0 Hz / 0-channel format on some devices and crash the tap.
            try session.setCategory(.playAndRecord, mode: .default,
                                    options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = engine.inputNode
            input.removeTap(onBus: 0)                     // never install a second tap on the bus
            let format = input.inputFormat(forBus: 0)     // hardware format, valid once the session is active
            guard format.sampleRate > 0, format.channelCount > 0 else { stop(); return }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                req.append(buffer)
            }
            engine.prepare()
            try engine.start()
            isListening = true

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let result { self.transcript = result.bestTranscription.formattedString }
                if error != nil || (result?.isFinal ?? false) { self.stop() }
            }
        } catch {
            stop()
        }
    }

    func stop() {
        let hadEngine = engine != nil
        if let engine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        engine = nil
        isListening = false
        // Only restore the player's playback session if we actually took the mic.
        if hadEngine {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        }
    }
}

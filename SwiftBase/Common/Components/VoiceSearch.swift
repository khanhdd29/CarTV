//
//  VoiceSearch.swift
//  SwiftBase
//
//  On-device speech-to-text for the search box (SFSpeechRecognizer +
//  AVAudioEngine). Lets the user dictate a channel name instead of typing.
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
    private let engine = AVAudioEngine()

    var isAvailable: Bool { recognizer?.isAvailable ?? false }

    func toggle() { isListening ? stop() : start() }

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
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
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
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isListening = false
        // Restore the playback audio session the player relies on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    }
}

//
//  QRScannerView.swift
//  SwiftBase
//
//  A camera QR-code scanner (AVFoundation). Reads a playlist/stream link from a
//  QR code so the user doesn't have to type a long URL. Camera only — no network.
//

import SwiftUI
import AVFoundation

/// Full-screen QR scanner with a viewfinder frame and a cancel button.
struct QRScannerSheet: View {
    let onFound: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            QRScannerView(onFound: onFound).ignoresSafeArea()
            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                            .padding(12).background(.black.opacity(0.5), in: Circle())
                    }
                    Spacer()
                }
                .padding()
                Spacer()
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 3)
                    .frame(width: 240, height: 240)
                Text("scan_qr_hint".localized)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 24)
                Spacer()
            }
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    /// Called once with the decoded string, then scanning stops.
    let onFound: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.onFound = onFound
        return vc
    }
    func updateUIViewController(_ vc: ScannerVC, context: Context) {}

    final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onFound: ((String) -> Void)?
        private let session = AVCaptureSession()
        private var preview: AVCaptureVideoPreviewLayer?
        private var didFind = false

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { if granted { self?.configure() } }
            }
        }

        private func configure() {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            view.layer.addSublayer(layer)
            preview = layer

            Task.detached { [session] in session.startRunning() }
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            preview?.frame = view.bounds
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if session.isRunning { session.stopRunning() }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput objects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !didFind,
                  let obj = objects.first as? AVMetadataMachineReadableCodeObject,
                  let value = obj.stringValue, !value.isEmpty else { return }
            didFind = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            session.stopRunning()
            onFound?(value)
        }
    }
}

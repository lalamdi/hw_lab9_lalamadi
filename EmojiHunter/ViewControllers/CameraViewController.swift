//
//  CameraViewController.swift
//  EmojiHunter
//
//  Created by lama alemadi on 08/11/2026.
//

import UIKit
@preconcurrency import AVFoundation
@preconcurrency import Vision
import CoreML
@preconcurrency import CoreVideo

// The camera frame is retained and used only for reading during classification.
private struct CameraFrame: @unchecked Sendable {
    let pixelBuffer: CVPixelBuffer
}

class CameraViewController: UIViewController,
    AVCaptureVideoDataOutputSampleBufferDelegate {

    // The coordinator receives the result when an object matches.
    weak var delegate: EmojiFoundDelegate?

    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera_session_queue")
    private let frameQueue = DispatchQueue(label: "camera_frame_processing_queue")
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // This is the label to look for, such as "laptop".
    let emojiString: String

    init(emoji: String) {
        emojiString = emoji
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Use the camera as the video source.
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            showCameraUnavailableMessage()
            return
        }

        captureSession.addInput(input)

        // Send camera frames to the delegate for classification.
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: frameQueue)

        guard captureSession.canAddOutput(videoDataOutput) else {
            showCameraUnavailableMessage()
            return
        }

        captureSession.addOutput(videoDataOutput)

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func showCameraUnavailableMessage() {
        let label = UILabel(frame: view.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.text = "📷 Camera not available\n(Run on a real device)"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = .black
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        view.addSubview(label)
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let frame = CameraFrame(pixelBuffer: pixelBuffer)
        Task { @MainActor in
            self.updateClassifications(in: frame)
        }
    }

    // Start and stop on the same background queue.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard previewLayer != nil else { return }

        let session = captureSession
        sessionQueue.async {
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard previewLayer != nil else { return }

        let session = captureSession
        sessionQueue.async {
            session.stopRunning()
        }
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    // Run Vision on a background queue, one frame at a time.
    private let classificationQueue = DispatchQueue(
        label: "emoji_classification_queue",
        qos: .userInitiated
    )
    private var isClassifying = false

    // Load MobileNetV2 the first time the camera sends a frame.
    private lazy var classificationRequest: VNCoreMLRequest? = {
        do {
            let coreMLModel = try MobileNetV2(configuration: MLModelConfiguration())
            let visionModel = try VNCoreMLModel(for: coreMLModel.model)
            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            print("Failed to load MobileNetV2: \(error)")
            return nil
        }
    }()

    private func updateClassifications(in frame: CameraFrame) {
        guard !isClassifying, let request = classificationRequest else { return }
        isClassifying = true

        classificationQueue.async { [weak self] in
            let handler = VNImageRequestHandler(
                cvPixelBuffer: frame.pixelBuffer,
                orientation: .right,
                options: [:]
            )

            var identifier: String?
            var confidence: Float = 0

            do {
                try handler.perform([request])

                // Vision returns the most likely prediction first.
                if let top = (request.results as? [VNClassificationObservation])?.first {
                    identifier = top.identifier
                    confidence = top.confidence
                }
            } catch {
                print("Failed to classify camera frame: \(error)")
            }

            // Report the result on the main thread so SwiftUI can update.
            DispatchQueue.main.async { [weak self, identifier, confidence] in
                guard let self else { return }
                self.isClassifying = false

                guard let identifier else { return }
                self.processClassifications(identifier: identifier, confidence: confidence)
            }
        }
    }

    private func processClassifications(identifier: String, confidence: Float) {
        guard confidence > 0.5 else { return }

        print("Classification: Identifier \(identifier); Confidence \(confidence)")

        // Compare the prediction with the label for the current emoji.
        if identifier.contains(emojiString) {
            delegate?.emojiWasFound(result: true)
        }
    }
}

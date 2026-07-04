@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Speech

final class SpeechRecognitionService: @unchecked Sendable {
    enum SpeechError: LocalizedError {
        case microphoneDenied
        case speechDenied
        case recognizerUnavailable
        case audioInputUnavailable

        var errorDescription: String? {
            switch self {
            case .microphoneDenied:
                "Microphone permission is required"
            case .speechDenied:
                "Speech recognition permission is required"
            case .recognizerUnavailable:
                "Speech recognizer is unavailable"
            case .audioInputUnavailable:
                "No audio input is available"
            }
        }
    }

    private let recognizer = SFSpeechRecognizer()
    nonisolated(unsafe) private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var task: SFSpeechRecognitionTask?

    static func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        DiagnosticLog.speech.info("requestMicrophonePermission currentStatus=\(String(describing: status), privacy: .public)")
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        DiagnosticLog.speech.info("requestMicrophonePermission returned granted=\(granted, privacy: .public)")
        return granted
    }

    func requestPermissions() async throws {
        let currentSpeechStatus = SFSpeechRecognizer.authorizationStatus()
        DiagnosticLog.speech.info("requestPermissions speechAuthorization currentStatus=\(String(describing: currentSpeechStatus), privacy: .public)")
        let speechStatus: SFSpeechRecognizerAuthorizationStatus
        if currentSpeechStatus == .notDetermined {
            DiagnosticLog.speech.info("requestPermissions speechAuthorization request begin")
            speechStatus = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        } else {
            speechStatus = currentSpeechStatus
        }

        DiagnosticLog.speech.info("requestPermissions speechStatus=\(String(describing: speechStatus), privacy: .public)")
        guard speechStatus == .authorized else {
            throw SpeechError.speechDenied
        }

        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        DiagnosticLog.speech.info("requestPermissions microphoneStatusBefore=\(String(describing: microphoneStatus), privacy: .public)")
        let microphoneGranted = await AVCaptureDevice.requestAccess(for: .audio)
        DiagnosticLog.speech.info("requestPermissions microphoneGranted=\(microphoneGranted, privacy: .public)")
        guard microphoneGranted else {
            throw SpeechError.microphoneDenied
        }
    }

    func start(
        contextualStrings: [String],
        onTranscript: @escaping @MainActor (String) -> Void
    ) throws {
        DiagnosticLog.speech.info("SpeechRecognitionService.start begin recognizerExists=\(self.recognizer != nil, privacy: .public) recognizerAvailable=\(self.recognizer?.isAvailable ?? false, privacy: .public)")
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        DiagnosticLog.audio.info("audioEngine input format sampleRate=\(format.sampleRate, privacy: .public) channels=\(format.channelCount, privacy: .public)")
        guard format.channelCount > 0 else {
            throw SpeechError.audioInputUnavailable
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        recognitionRequest.contextualStrings = contextualStrings
        DiagnosticLog.speech.info("recognitionRequest contextualStrings=\(contextualStrings.count, privacy: .public)")
        if #available(macOS 13.0, *) {
            recognitionRequest.addsPunctuation = true
        }

        var tapBufferCount = 0
        var maxObservedRMS: Float = 0
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            tapBufferCount += 1
            let rms = Self.rmsLevel(buffer)
            maxObservedRMS = max(maxObservedRMS, rms)
            if tapBufferCount == 1 || tapBufferCount % 100 == 0 {
                DiagnosticLog.audio.info("audioTap buffers=\(tapBufferCount, privacy: .public) rms=\(rms, privacy: .public) maxRMS=\(maxObservedRMS, privacy: .public)")
            }
            recognitionRequest.append(buffer)
        }

        task = recognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let error {
                DiagnosticLog.speech.error("recognitionTask callback error=\(error.localizedDescription, privacy: .public)")
                return
            }
            guard let text = result?.bestTranscription.formattedString else { return }
            DiagnosticLog.speech.info("recognitionTask callback textLength=\(text.count, privacy: .public) isFinal=\(result?.isFinal ?? false, privacy: .public)")
            Task { @MainActor in
                onTranscript(text)
            }
        }

        engine.prepare()
        DiagnosticLog.audio.info("audioEngine prepared")
        try engine.start()
        DiagnosticLog.audio.info("audioEngine start success")
        audioEngine = engine
        request = recognitionRequest
    }

    func stop() {
        DiagnosticLog.speech.info("SpeechRecognitionService.stop")
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    deinit {
        task?.cancel()
        audioEngine?.stop()
    }

    private static func rmsLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else { return 0 }
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard channelCount > 0, frameLength > 0 else { return 0 }

        var sum: Float = 0
        var sampleCount = 0
        for channel in 0..<channelCount {
            let samples = channels[channel]
            for frame in 0..<frameLength {
                let sample = samples[frame]
                sum += sample * sample
                sampleCount += 1
            }
        }
        guard sampleCount > 0 else { return 0 }
        return sqrt(sum / Float(sampleCount))
    }
}

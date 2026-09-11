import Foundation
import Speech
import AVFoundation

/// Transcribes Swedish speech to text, live, using the Speech framework.
@MainActor
@Observable
final class SpeechRecognitionService {

    /// Text transcribed so far. Observed by the view (RF-26).
    private(set) var transcript: String = ""
    private(set) var isRecording: Bool = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "sv-SE"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?

    private let silenceSeconds: TimeInterval = 2.0

    /// Checks Swedish availability and requests permissions. Throws when something is missing.
    func prepare() async throws {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechRecognitionError.swedishUnavailable   // RF-31
        }

        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechAuthorized else { throw SpeechRecognitionError.permissionDenied }

        let micAuthorized = await AVAudioApplication.requestRecordPermission()
        guard micAuthorized else { throw SpeechRecognitionError.permissionDenied }   // RF-30
    }

    /// Starts dictation. The transcript is published as it comes in.
    func start() throws {
        stop()
        transcript = ""

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true   // RF-26
        request = newRequest

        let node = audioEngine.inputNode
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            newRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        restartSilenceTimer()

        task = recognizer?.recognitionTask(with: newRequest) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let finished = error != nil || result?.isFinal == true

            Task { @MainActor [weak self] in
                guard let self else { return }
                if let text {
                    self.transcript = text
                    self.restartSilenceTimer()   // RF-28
                }
                if finished {
                    self.stop()
                }
            }
        }
    }

    /// Stops recording and releases audio resources.
    func stop() {
        silenceTimer?.invalidate()
        silenceTimer = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        isRecording = false
    }

    /// RF-28: each partial result resets the countdown; silence lets it expire.
    private func restartSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceSeconds, repeats: false) { _ in
            Task { @MainActor [weak self] in
                self?.stop()
            }
        }
    }
}

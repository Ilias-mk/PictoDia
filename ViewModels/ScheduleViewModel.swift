import Foundation

/// Screen state for schedule creation: input text, loading, errors and results.
@MainActor
@Observable
final class ScheduleViewModel {

    var inputText: String = ""
    var events: [Event] = []
    var pictograms: [Pictogram] = []
    var errorMessage: String?
    var isLoading: Bool = false
    var showingSchedule: Bool = false
    var dictationError: SpeechRecognitionError?

    private let extraction: EventExtractionService
    private let builder: ScheduleBuilder
    private let speech = SpeechRecognitionService()

    init(extraction: EventExtractionService = EventExtractionService(),
         builder: ScheduleBuilder = ScheduleBuilder()) {
        self.extraction = extraction
        self.builder = builder
    }

    var isDictating: Bool { speech.isRecording }

    /// RF-02: sending is only enabled when there is real text.
    var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    /// Extracts the events and builds the full visual schedule.
    func generateSchedule() async {
        guard canSubmit else { return }

        isLoading = true
        errorMessage = nil
        events = []
        pictograms = []

        do {
            let extracted = try await extraction.extractEvents(from: inputText)
            events = extracted
            pictograms = try await builder.build(from: extracted)
        } catch let error as EventExtractionError {
            errorMessage = error.errorDescription      // RF-05, RF-06
        } catch let error as PictogramError {
            errorMessage = error.errorDescription       // RF-14
            events = []                                 // no partial results
        } catch {
            errorMessage = "Ett oväntat fel uppstod."
        }

        showingSchedule = !pictograms.isEmpty
        isLoading = false
    }

    /// Starts or stops dictation, checking permissions first (RF-30, RF-31).
    func toggleDictation() async {
        if speech.isRecording {
            speech.stop()
            return
        }

        do {
            try await speech.prepare()
            try speech.start()
            observeTranscript()
        } catch let error as SpeechRecognitionError {
            dictationError = error
        } catch {
            dictationError = .recognitionFailed
        }
    }

    /// Mirrors the transcript into the text field while dictating (RF-26, RF-27).
    private func observeTranscript() {
        Task { @MainActor in
            var lastText = ""
            while speech.isRecording {
                if !speech.transcript.isEmpty {
                    lastText = speech.transcript
                    inputText = lastText   // RF-27
                }
                try? await Task.sleep(for: .milliseconds(150))
            }
            if !speech.transcript.isEmpty {
                lastText = speech.transcript
            }
            inputText = lastText
        }
    }
}

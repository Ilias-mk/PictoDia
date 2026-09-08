import Foundation
import Speech
import AVFoundation

/// Transcribe voz en sueco a texto, en vivo, usando el framework Speech de iOS.
@MainActor
@Observable
final class SpeechRecognitionService {
    
    /// Texto transcrito hasta el momento. La vista lo observa (RF-26).
    private(set) var transcripcion: String = ""
    private(set) var estaGrabando: Bool = false
    
    private let reconocedor = SFSpeechRecognizer(locale: Locale(identifier: "se-SV"))
    private let motorAudio = AVAudioEngine()
    private var peticion: SFSpeechAudioBufferRecognitionRequest?
    private var tarea: SFSpeechRecognitionTask?
    private var temporizadorSilencio: Timer?
    
    private let segundosDeSilencio: TimeInterval = 2.0
    
    /// Comprueba disponibilidad de sueco y solicita permisos. Lanza si algo falta.
    func prepararse() async throws {
        guard let reconocedor, reconocedor.isAvailable else {
            throw SpeechRecognitionError.suecoNoDisponible   // RF-31
        }
        
        let autorizado = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { estado in
                continuation.resume(returning: estado == .authorized)
            }
        }
        guard autorizado else { throw SpeechRecognitionError.permisoDenegado }
        
        let micAutorizado = await AVAudioApplication.requestRecordPermission()
        guard micAutorizado else { throw SpeechRecognitionError.permisoDenegado }   // RF-30
    }
    
    /// Inicia el dictado. La transcripción se va publicando en `transcripcion`.
    func iniciar() throws {
        detener()
        transcripcion = ""
        
        let sesion = AVAudioSession.sharedInstance()
        try sesion.setCategory(.record, mode: .measurement, options: .duckOthers)
        try sesion.setActive(true, options: .notifyOthersOnDeactivation)
        
        let nuevaPeticion = SFSpeechAudioBufferRecognitionRequest()
        nuevaPeticion.shouldReportPartialResults = true   // RF-26
        peticion = nuevaPeticion
        
        let nodo = motorAudio.inputNode
        let formato = nodo.outputFormat(forBus: 0)
        nodo.installTap(onBus: 0, bufferSize: 1024, format: formato) { buffer, _ in
            nuevaPeticion.append(buffer)
        }
        
        motorAudio.prepare()
        try motorAudio.start()
        estaGrabando = true
        print("VOZ: motor iniciado")
        reiniciarTemporizadorSilencio()
        
        tarea = reconocedor?.recognitionTask(with: nuevaPeticion) { [weak self] resultado, error in
            let texto = resultado?.bestTranscription.formattedString
            let terminado = error != nil || resultado?.isFinal == true
            let descripcionError = error?.localizedDescription

            Task { @MainActor [weak self] in
                guard let self else { return }
                print("VOZ: resultado =", texto ?? "nil", "| terminado =", terminado, "| error =", descripcionError ?? "ninguno")
                if let texto {
                    self.transcripcion = texto
                    self.reiniciarTemporizadorSilencio()
                }
                if terminado {
                    self.detener()
                }
            }
        }
    }
    
    /// Detiene la grabación y libera los recursos de audio.
    func detener() {
        print("VOZ: deteniendo, grabando =", estaGrabando)
        temporizadorSilencio?.invalidate()
        temporizadorSilencio = nil
        
        if motorAudio.isRunning {
            motorAudio.stop()
            motorAudio.inputNode.removeTap(onBus: 0)
        }
        peticion?.endAudio()
        peticion = nil
        tarea?.cancel()
        tarea = nil
        estaGrabando = false
    }
    
    /// RF-28: cada resultado parcial reinicia la cuenta atrás; el silencio la deja expirar.
    /// RF-28: cada resultado parcial reinicia la cuenta atrás; el silencio la deja expirar.
    private func reiniciarTemporizadorSilencio() {
        temporizadorSilencio?.invalidate()
        temporizadorSilencio = Timer.scheduledTimer(withTimeInterval: segundosDeSilencio, repeats: false) { _ in
            Task { @MainActor [weak self] in
                self?.detener()
            }
        }
    }
}

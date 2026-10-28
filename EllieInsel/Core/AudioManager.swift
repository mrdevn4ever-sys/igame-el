import AVFoundation
import Foundation

enum SoundEffect: CaseIterable {
    case success, gentle, tap, snap, flip, complete, bump, munch

    var data: Data {
        switch self {
        case .success: return ToneGenerator.success
        case .gentle: return ToneGenerator.gentle
        case .tap: return ToneGenerator.tap
        case .snap: return ToneGenerator.snap
        case .flip: return ToneGenerator.flip
        case .complete: return ToneGenerator.complete
        case .bump: return ToneGenerator.bump
        case .munch: return ToneGenerator.munch
        }
    }
}

extension Notification.Name {
    /// Wird gesendet, wenn das System die Audiowiedergabe unterbricht (z. B. Anruf, Siri).
    static let ellieAudioInterrupted = Notification.Name("ellieAudioInterrupted")
}

/// Verwaltet die vier Tonbereiche: Erzählerstimme, Tiergeräusche, Rückmeldungen und Musik.
///
/// Sprache: Zuerst wird eine mitgelieferte Aufnahme gesucht (`<slug>.m4a`, siehe README).
/// Fehlt sie, spricht die beste installierte deutsche Systemstimme.
@MainActor
final class AudioManager: NSObject {
    static let shared = AudioManager()

    private(set) var settings = SoundSettings()
    private let synth = AVSpeechSynthesizer()
    private var voicePlayer: AVAudioPlayer?
    private var animalPlayer: AVAudioPlayer?
    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var voice: AVSpeechSynthesisVoice?

    private var queue: [String] = []
    private var worker: Task<Void, Never>?
    private var generation = 0

    override init() {
        super.init()
        configureSession()
        voice = Self.bestGermanVoice()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [])
        try? session.setActive(true)
    }

    @objc nonisolated private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        Task { @MainActor in
            if type == .began {
                self.stopVoice()
                self.stopAnimal()
                NotificationCenter.default.post(name: .ellieAudioInterrupted, object: nil)
            } else {
                try? AVAudioSession.sharedInstance().setActive(true)
                self.updateMusic()
            }
        }
    }

    static func bestGermanVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix("de") && !$0.voiceTraits.contains(.isNoveltyVoice)
        }
        func score(_ v: AVSpeechSynthesisVoice) -> Int {
            var s = 0
            switch v.quality {
            case .premium: s += 30
            case .enhanced: s += 20
            default: break
            }
            if v.language == "de-CH" { s += 5 }
            if v.language == "de-DE" { s += 3 }
            return s
        }
        return voices.max(by: { score($0) < score($1) }) ?? AVSpeechSynthesisVoice(language: "de-DE")
    }

    // MARK: - Einstellungen

    func apply(_ newSettings: SoundSettings) {
        let old = settings
        settings = newSettings
        if !newSettings.voiceAudible && old.voiceAudible { stopVoice() }
        if !newSettings.animalAudible { stopAnimal() }
        voicePlayer?.volume = Float(newSettings.voiceVolume)
        updateMusic()
    }

    // MARK: - Stimme

    /// Spricht einen Satz und bricht laufende Ansagen ab.
    func say(_ text: String) {
        stopVoice()
        enqueue(text)
    }

    /// Hängt einen Satz an (z. B. Zahlwörter beim Zählen), damit sie geordnet nacheinander erklingen.
    func enqueue(_ text: String) {
        guard settings.voiceAudible, !text.isEmpty else { return }
        queue.append(text)
        if worker == nil {
            let gen = generation
            worker = Task { @MainActor [weak self] in
                await self?.runQueue(gen: gen)
            }
        }
    }

    /// Spricht und wartet, bis die Ansage beendet ist.
    func sayAndWait(_ text: String) async {
        say(text)
        await waitUntilQuiet()
    }

    func waitUntilQuiet() async {
        var waited = 0
        while (worker != nil || isVoiceBusy) && waited < 300 {
            try? await Task.sleep(nanoseconds: 80_000_000)
            waited += 1
        }
    }

    var isVoiceBusy: Bool {
        synth.isSpeaking || (voicePlayer?.isPlaying ?? false)
    }

    func stopVoice() {
        generation += 1
        queue.removeAll()
        worker?.cancel()
        worker = nil
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        voicePlayer?.stop()
        voicePlayer = nil
    }

    private func runQueue(gen: Int) async {
        while gen == generation, !queue.isEmpty {
            let text = queue.removeFirst()
            startSpeaking(text)
            try? await Task.sleep(nanoseconds: 120_000_000)
            var waited = 0
            while gen == generation && isVoiceBusy && waited < 250 {
                try? await Task.sleep(nanoseconds: 60_000_000)
                waited += 1
            }
        }
        if gen == generation { worker = nil }
    }

    private func startSpeaking(_ text: String) {
        if let url = Self.bundledVoiceURL(for: text), let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = Float(settings.voiceVolume)
            player.prepareToPlay()
            player.play()
            voicePlayer = player
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Float(settings.speechRate)
        utterance.pitchMultiplier = 1.05
        utterance.volume = Float(settings.voiceVolume)
        utterance.postUtteranceDelay = 0.05
        synth.speak(utterance)
    }

    static func bundledVoiceURL(for text: String) -> URL? {
        let slug = text.voiceSlug
        guard !slug.isEmpty else { return nil }
        for ext in ["m4a", "mp3", "wav", "aac", "caf"] {
            if let url = Bundle.main.url(forResource: slug, withExtension: ext) { return url }
        }
        return nil
    }

    // MARK: - Tiergeräusche

    /// Spielt eine Tieraufnahme. Fehlt die Datei, wird das Geräusch nachgesprochen.
    func playAnimal(file: String, imitation: String, pitch: Float) async {
        stopVoice()
        stopAnimal()
        guard settings.animalAudible else { return }
        var url: URL?
        for ext in ["m4a", "mp3", "wav", "caf"] {
            if let u = Bundle.main.url(forResource: file, withExtension: ext) { url = u; break }
        }
        if let url, let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = Float(settings.animalVolume)
            player.play()
            animalPlayer = player
            var waited = 0
            while player.isPlaying && waited < 100 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                waited += 1
            }
        } else {
            let gen = generation
            let utterance = AVSpeechUtterance(string: imitation)
            utterance.voice = voice
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
            utterance.pitchMultiplier = pitch
            utterance.volume = Float(settings.animalVolume)
            synth.speak(utterance)
            try? await Task.sleep(nanoseconds: 150_000_000)
            var waited = 0
            while gen == generation && synth.isSpeaking && waited < 100 {
                try? await Task.sleep(nanoseconds: 60_000_000)
                waited += 1
            }
        }
    }

    func stopAnimal() {
        animalPlayer?.stop()
        animalPlayer = nil
    }

    // MARK: - Rückmeldungen

    func effect(_ effect: SoundEffect) {
        guard settings.effectsAudible else { return }
        let player: AVAudioPlayer
        if let existing = effectPlayers[effect] {
            player = existing
        } else {
            guard let p = try? AVAudioPlayer(data: effect.data) else { return }
            effectPlayers[effect] = p
            player = p
        }
        player.volume = Float(settings.effectsVolume)
        player.currentTime = 0
        player.play()
    }

    // MARK: - Musik

    private func updateMusic() {
        if settings.musicAudible {
            if musicPlayer == nil {
                musicPlayer = try? AVAudioPlayer(data: ToneGenerator.music)
                musicPlayer?.numberOfLoops = -1
            }
            musicPlayer?.volume = Float(settings.musicVolume)
            if musicPlayer?.isPlaying == false { musicPlayer?.play() }
        } else {
            musicPlayer?.stop()
            musicPlayer = nil
        }
    }

    /// Hält während einer Höraufgabe die Musik an, damit sich nichts überlagert.
    func setMusicSuspended(_ suspended: Bool) {
        guard let musicPlayer else { return }
        if suspended {
            musicPlayer.pause()
        } else if settings.musicAudible {
            musicPlayer.play()
        }
    }

    func stopAll() {
        stopVoice()
        stopAnimal()
    }
}

import Foundation

/// Erzeugt kurze, sanfte Klänge als WAV-Daten, damit keine Audiodateien nötig sind.
enum ToneGenerator {
    struct Note {
        var frequency: Double
        var start: Double
        var duration: Double
        var gain: Double = 1
    }

    static let sampleRate = 44_100.0

    static func wav(notes: [Note], length: Double, softness: Double = 1) -> Data {
        let count = Int(length * sampleRate)
        var samples = [Double](repeating: 0, count: count)
        for note in notes {
            let startIndex = Int(note.start * sampleRate)
            let n = Int(note.duration * sampleRate)
            for i in 0..<n {
                let idx = startIndex + i
                guard idx < count else { break }
                let t = Double(i) / sampleRate
                // Weiche Hüllkurve: kurzer Anstieg, exponentielles Ausklingen.
                let attack = min(1, t / 0.012)
                let release = exp(-t * 4.5 / max(note.duration, 0.05))
                let env = attack * release * note.gain
                let base = sin(2 * .pi * note.frequency * t)
                let overtone = 0.25 * sin(2 * .pi * note.frequency * 2 * t) * softness
                samples[idx] += (base + overtone) * env
            }
        }
        let peak = max(samples.map { abs($0) }.max() ?? 1, 1)
        let pcm: [Int16] = samples.map { Int16(max(-1, min(1, $0 / peak * 0.8)) * Double(Int16.max)) }
        return encodeWAV(pcm)
    }

    private static func encodeWAV(_ pcm: [Int16]) -> Data {
        var d = Data()
        func append<T: FixedWidthInteger>(_ v: T) {
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { d.append(contentsOf: $0) }
        }
        let dataSize = UInt32(pcm.count * 2)
        d.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36) + dataSize)
        d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8))
        append(UInt32(16))
        append(UInt16(1)) // PCM
        append(UInt16(1)) // Mono
        append(UInt32(sampleRate))
        append(UInt32(sampleRate) * 2)
        append(UInt16(2))
        append(UInt16(16))
        d.append(contentsOf: Array("data".utf8))
        append(dataSize)
        for s in pcm { append(s) }
        return d
    }

    // Tonhöhen
    static let c5 = 523.25, d5 = 587.33, e5 = 659.25, g5 = 783.99, a5 = 880.0
    static let c6 = 1046.5, e6 = 1318.5, g6 = 1568.0
    static let g4 = 392.0, a4 = 440.0, c4 = 261.63, e4 = 329.63

    static let success = wav(notes: [
        Note(frequency: c6, start: 0, duration: 0.35),
        Note(frequency: e6, start: 0.09, duration: 0.35),
        Note(frequency: g6, start: 0.18, duration: 0.5)
    ], length: 0.75)

    static let gentle = wav(notes: [
        Note(frequency: e5, start: 0, duration: 0.3, gain: 0.8),
        Note(frequency: c5, start: 0.14, duration: 0.4, gain: 0.8)
    ], length: 0.6, softness: 0.3)

    static let tap = wav(notes: [Note(frequency: a5, start: 0, duration: 0.12, gain: 0.7)], length: 0.15, softness: 0.2)

    static let snap = wav(notes: [
        Note(frequency: g5, start: 0, duration: 0.12),
        Note(frequency: c6, start: 0.06, duration: 0.2)
    ], length: 0.3)

    static let flip = wav(notes: [Note(frequency: d5, start: 0, duration: 0.1, gain: 0.6)], length: 0.12, softness: 0)

    static let complete = wav(notes: [
        Note(frequency: c5, start: 0, duration: 0.4),
        Note(frequency: e5, start: 0.12, duration: 0.4),
        Note(frequency: g5, start: 0.24, duration: 0.4),
        Note(frequency: c6, start: 0.36, duration: 0.8)
    ], length: 1.3)

    static let bump = wav(notes: [
        Note(frequency: g4, start: 0, duration: 0.25, gain: 0.8),
        Note(frequency: e4, start: 0.1, duration: 0.35, gain: 0.8)
    ], length: 0.5, softness: 0)

    static let munch = wav(notes: [
        Note(frequency: e5, start: 0, duration: 0.08),
        Note(frequency: g5, start: 0.07, duration: 0.12)
    ], length: 0.22)

    /// Ruhige Pentatonik-Melodie als Hintergrundmusik (Schleife).
    static let music: Data = {
        let melody: [Double] = [c5, e5, g5, a5, g5, e5, d5, c5, e5, g5, c6, a5, g5, e5, d5, e5]
        var notes: [Note] = []
        let beat = 0.55
        for (i, f) in melody.enumerated() {
            notes.append(Note(frequency: f, start: Double(i) * beat, duration: beat * 1.6, gain: 0.5))
            if i % 4 == 0 {
                notes.append(Note(frequency: f / 2, start: Double(i) * beat, duration: beat * 3.5, gain: 0.35))
            }
        }
        return wav(notes: notes, length: Double(melody.count) * beat, softness: 0.2)
    }()
}

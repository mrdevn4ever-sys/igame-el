import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Ein Bild aus dem freien Malen.
struct Artwork: Codable, Identifiable, Equatable {
    var id = UUID()
    var created = Date()
    var modified = Date()
    var background: String
    /// Bearbeitbare Striche (PencilKit-Datenrepräsentation).
    var drawing: Data
    /// PNG-Vorschau.
    var thumbnail: Data
    /// Breite der Zeichenfläche beim Speichern (zum Skalieren nach einer Drehung).
    var canvasWidth: Double?
}

/// Inhalt einer Sicherungsdatei.
struct BackupFile: Codable {
    var format: String = "ellies-entdeckerinsel-backup"
    var version: Int = 1
    var created = Date()
    var app: AppData
    var gallery: [Artwork]
}

enum Persistence {
    private static let queue = DispatchQueue(label: "ellie.persistence", qos: .utility)

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("EllieInsel", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static var dataURL: URL { directory.appendingPathComponent("insel.json") }
    static var galleryURL: URL { directory.appendingPathComponent("galerie.json") }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func loadData() -> AppData? {
        guard let raw = try? Data(contentsOf: dataURL) else { return nil }
        return try? decoder.decode(AppData.self, from: raw)
    }

    static func loadGallery() -> [Artwork] {
        guard let raw = try? Data(contentsOf: galleryURL) else { return [] }
        return (try? decoder.decode([Artwork].self, from: raw)) ?? []
    }

    static func write(_ data: AppData) {
        guard let raw = try? encoder.encode(data) else { return }
        let url = dataURL
        queue.async { try? raw.write(to: url, options: .atomic) }
    }

    static func write(_ gallery: [Artwork]) {
        guard let raw = try? encoder.encode(gallery) else { return }
        let url = galleryURL
        queue.async { try? raw.write(to: url, options: .atomic) }
    }

    /// Wartet, bis alle ausstehenden Schreibvorgänge erledigt sind.
    static func flush() {
        queue.sync {}
    }
}

/// Dokumenttyp für Export und Import der Sicherung.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var backup: BackupFile

    init(backup: BackupFile) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let raw = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        backup = try Persistence.decoder.decode(BackupFile.self, from: raw)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try enc.encode(backup))
    }
}

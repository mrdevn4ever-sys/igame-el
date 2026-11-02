import CoreGraphics

/// Feste Plätze in den Szenen (Koordinaten 0…1, y = Bodenlinie).
enum WorldLayout {
    // Hausgarten
    static let beds: [CGPoint] = [CGPoint(x: 0.25, y: 0.62), CGPoint(x: 0.41, y: 0.66), CGPoint(x: 0.57, y: 0.6), CGPoint(x: 0.2, y: 0.44)]
    static let bedSize: Double = 0.15
    static let treeSize: Double = 0.24
    static let blanket = CGPoint(x: 0.76, y: 0.53)
    static let kitchenDoor = CGPoint(x: 0.8, y: 0.38)
    static let workbench = CGPoint(x: 0.36, y: 0.37)
    static let basket = CGPoint(x: 0.92, y: 0.62)

    // Bach
    static let gridOrigin = CGPoint(x: 0.17, y: 0.3)
    static let gridCell: CGFloat = 0.105 // in Szenenbreite
    static let gridCols = 6
    static let gridRows = 4
    static let bridge = CGPoint(x: 0.5, y: 0.17)
    static let dock = CGPoint(x: 0.9, y: 0.95)

    // Baumhaus
    static let platform = CGPoint(x: 0.55, y: 0.38)
    static let lift = CGPoint(x: 0.66, y: 0.7)

    // Wunderlichtung
    static let chimeSlots: [CGPoint] = [CGPoint(x: 0.24, y: 0.86), CGPoint(x: 0.41, y: 0.9), CGPoint(x: 0.58, y: 0.9), CGPoint(x: 0.75, y: 0.86)]
    static let fantasySlots: [CGPoint] = [CGPoint(x: 0.16, y: 0.56), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.84, y: 0.56)]
    static let crystal = CGPoint(x: 0.9, y: 0.32)
    static let cloud = CGPoint(x: 0.12, y: 0.18)

    /// Stellflächen für gebaute Dinge.
    static func spots(_ a: WorldArea) -> [CGPoint] {
        switch a {
        case .haus: return [CGPoint(x: 0.28, y: 0.86), CGPoint(x: 0.47, y: 0.44), CGPoint(x: 0.62, y: 0.44), CGPoint(x: 0.88, y: 0.66),
                            CGPoint(x: 0.16, y: 0.64), CGPoint(x: 0.66, y: 0.58), CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.86, y: 0.46)]
        case .lichtung: return [CGPoint(x: 0.15, y: 0.82), CGPoint(x: 0.4, y: 0.92), CGPoint(x: 0.62, y: 0.5), CGPoint(x: 0.86, y: 0.84),
                                CGPoint(x: 0.88, y: 0.48), CGPoint(x: 0.7, y: 0.66), CGPoint(x: 0.3, y: 0.5)]
        case .baumhaus: return [CGPoint(x: 0.12, y: 0.86), CGPoint(x: 0.34, y: 0.92), CGPoint(x: 0.84, y: 0.82), CGPoint(x: 0.2, y: 0.6), CGPoint(x: 0.55, y: 0.24)]
        case .bach: return [bridge, dock]
        case .wunder: return []
        }
    }

    /// Bereich, in dem sich Figuren bewegen (x, y, Breite, Höhe).
    static func walkArea(_ a: WorldArea, resident: Resident?) -> CGRect {
        if let r = resident {
            if r == .ente || r == .fisch || r == .frosch { return CGRect(x: 0.74, y: 0.8, width: 0.2, height: 0.14) }
            if r.flies { return CGRect(x: 0.08, y: 0.18, width: 0.84, height: 0.45) }
        }
        switch a {
        case .haus: return CGRect(x: 0.16, y: 0.46, width: 0.5, height: 0.26)
        case .bach: return CGRect(x: 0.04, y: 0.86, width: 0.1, height: 0.1)
        case .lichtung: return CGRect(x: 0.08, y: 0.6, width: 0.84, height: 0.32)
        case .baumhaus: return CGRect(x: 0.08, y: 0.78, width: 0.8, height: 0.16)
        case .wunder: return CGRect(x: 0.1, y: 0.62, width: 0.8, height: 0.18)
        }
    }

    /// Mittelpunkt einer Rasterzelle am Bach.
    static func cellCenter(col: Int, row: Int) -> CGPoint {
        CGPoint(x: gridOrigin.x + gridCell * (CGFloat(col) + 0.5),
                y: gridOrigin.y + gridCell * 4 / 3 * (CGFloat(row) + 0.5))
    }

    /// Zellhöhe in Szenenhöhe (Szene ist 4:3).
    static var cellHeight: CGFloat { gridCell * 4 / 3 }

    static let source = CGPoint(x: gridOrigin.x - 0.05, y: cellCenter(col: 0, row: 0).y)
    static let pond = CGPoint(x: gridOrigin.x + gridCell * 6 + 0.07, y: cellCenter(col: 5, row: 3).y)
    static let streamBed = CGPoint(x: gridOrigin.x + gridCell * 6 + 0.07, y: cellCenter(col: 5, row: 0).y + 0.06)
}

import CoreGraphics

/// Breite Orte: Mit Panoramabild wird ein Ort mehrere Bildschirme breit und lässt sich wischen.
/// Koordinaten bleiben im Grundbild: x 0…1 ist der bisherige Bildschirm, links davon negativ, rechts > 1.
@MainActor
enum WorldPanorama {
    static func isActive(_ a: WorldArea) -> Bool {
        guard a.panoramaExtent != (0, 1) else { return false }
        return ImageCache.image(a.panorama(evening: false)) != nil || DemoMode.flag("-panotest")
    }

    /// Sichtbarer Bereich in Grundbild-Einheiten.
    static func extent(_ a: WorldArea) -> (min: Double, max: Double) {
        isActive(a) ? a.panoramaExtent : (0, 1)
    }

    /// Anzahl Beete im Hausgarten (3 Beete + Baumplatz, im Panorama 3 weitere).
    static var bedCount: Int { isActive(.haus) ? WorldLayout.beds.count : 4 }
}

/// Feste Plätze in den Szenen (Koordinaten im Grundbild, y = Bodenlinie).
@MainActor
enum WorldLayout {
    // Hausgarten
    // Die drei Beete stehen ordentlich in einer Reihe (gleiche Bodenlinie, gleiche Abstände).
    static let beds: [CGPoint] = [CGPoint(x: 0.25, y: 0.63), CGPoint(x: 0.42, y: 0.63), CGPoint(x: 0.59, y: 0.63), CGPoint(x: 0.2, y: 0.44),
                                  // nur im Panorama: Obstgarten links, Blumenwiese rechts
                                  CGPoint(x: -0.62, y: 0.63), CGPoint(x: -0.42, y: 0.63), CGPoint(x: 1.38, y: 0.63)]
    static let bedSize: Double = 0.15
    static let treeSize: Double = 0.24
    static let blanket = CGPoint(x: 0.76, y: 0.53)
    static let kitchenDoor = CGPoint(x: 0.8, y: 0.38)
    static let workbench = CGPoint(x: 0.36, y: 0.37)
    static let basket = CGPoint(x: 0.92, y: 0.62)

    // Bach
    // Raster passt auf die gemalten Erdfelder in gw_szene_bach_teich
    static let gridOrigin = CGPoint(x: 0.3, y: 0.19)
    static let gridCell: CGFloat = 0.0787 // in Szenenbreite
    /// Im Panorama reicht der Wasserbaukasten über zwei Bildschirme.
    static var gridCols: Int { WorldPanorama.isActive(.bach) ? 11 : 6 }
    static let gridRows = 4
    static let bridge = CGPoint(x: 0.16, y: 0.7)
    /// Freie Wiese oben links beim Wasserfall (unter der Quellrinne, links vom Raster).
    static let bachUpperMeadow = CGRect(x: 0.07, y: 0.32, width: 0.2, height: 0.24)
    static var dock: CGPoint { WorldPanorama.isActive(.bach) ? CGPoint(x: pond.x + 0.05, y: 0.95) : CGPoint(x: 0.77, y: 0.82) }

    // Baumhaus
    static let platform = CGPoint(x: 0.55, y: 0.38)
    static let lift = CGPoint(x: 0.66, y: 0.7)

    // Wunderlichtung
    static let chimeSlots: [CGPoint] = [CGPoint(x: 0.3, y: 0.86), CGPoint(x: 0.43, y: 0.9), CGPoint(x: 0.57, y: 0.9), CGPoint(x: 0.7, y: 0.86)]
    static let fantasySlots: [CGPoint] = [CGPoint(x: 0.2, y: 0.56), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.8, y: 0.56)]
    static let crystal = CGPoint(x: 0.72, y: 0.38)
    static let cloud = CGPoint(x: 0.32, y: 0.2)

    /// Stellflächen für gebaute Dinge.
    static func spots(_ a: WorldArea) -> [CGPoint] {
        switch a {
        case .haus:
            var list = [CGPoint(x: 0.28, y: 0.86), CGPoint(x: 0.47, y: 0.44), CGPoint(x: 0.62, y: 0.44), CGPoint(x: 0.88, y: 0.66),
                        CGPoint(x: 0.16, y: 0.64), CGPoint(x: 0.66, y: 0.58), CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.86, y: 0.46)]
            if WorldPanorama.isActive(.haus) {
                list += [CGPoint(x: -0.85, y: 0.86), CGPoint(x: -0.5, y: 0.48), CGPoint(x: -0.2, y: 0.84),
                         CGPoint(x: 1.2, y: 0.86), CGPoint(x: 1.55, y: 0.5), CGPoint(x: 1.75, y: 0.8), CGPoint(x: 1.15, y: 0.46)]
            }
            return list
        case .lichtung:
            var list = [CGPoint(x: 0.15, y: 0.82), CGPoint(x: 0.4, y: 0.92), CGPoint(x: 0.62, y: 0.5), CGPoint(x: 0.8, y: 0.74),
                        CGPoint(x: 0.88, y: 0.48), CGPoint(x: 0.7, y: 0.66), CGPoint(x: 0.3, y: 0.5)]
            if WorldPanorama.isActive(.lichtung) {
                list += [CGPoint(x: 1.2, y: 0.84), CGPoint(x: 1.45, y: 0.5), CGPoint(x: 1.7, y: 0.88), CGPoint(x: 1.85, y: 0.52)]
            }
            return list
        case .baumhaus: return [CGPoint(x: 0.12, y: 0.86), CGPoint(x: 0.34, y: 0.92), CGPoint(x: 0.84, y: 0.82), CGPoint(x: 0.16, y: 0.66), CGPoint(x: 0.86, y: 0.64)]
        case .bach: return [bridge, dock]
        case .wunder: return []
        }
    }

    /// Bereich, in dem sich Figuren bewegen (x, y, Breite, Höhe).
    static func walkArea(_ a: WorldArea, resident: Resident?) -> CGRect {
        let ext = WorldPanorama.extent(a)
        if let r = resident {
            if r == .ente || r == .fisch || r == .frosch {
                return WorldPanorama.isActive(.bach) ? CGRect(x: pond.x - 0.1, y: 0.8, width: 0.2, height: 0.14) : CGRect(x: 0.7, y: 0.78, width: 0.24, height: 0.14)
            }
            if r.flies { return CGRect(x: ext.min + 0.08, y: 0.18, width: ext.max - ext.min - 0.16, height: 0.45) }
        }
        if WorldPanorama.isActive(a) {
            switch a {
            case .haus: return CGRect(x: -0.85, y: 0.46, width: 2.7, height: 0.26)
            case .lichtung: return CGRect(x: 0.08, y: 0.6, width: 1.84, height: 0.32)
            default: break
            }
        }
        switch a {
        case .haus: return CGRect(x: 0.16, y: 0.46, width: 0.5, height: 0.26)
        case .bach: return CGRect(x: 0.08, y: 0.66, width: 0.42, height: 0.22)
        case .lichtung: return CGRect(x: 0.08, y: 0.6, width: 0.84, height: 0.32)
        case .baumhaus: return CGRect(x: 0.08, y: 0.78, width: 0.8, height: 0.16)
        case .wunder: return CGRect(x: 0.1, y: 0.62, width: 0.8, height: 0.18)
        }
    }

    /// Mittelpunkt einer Rasterzelle am Bach.
    static func cellCenter(col: Int, row: Int) -> CGPoint {
        CGPoint(x: gridOrigin.x + gridCell * (CGFloat(col) + 0.5),
                y: gridOrigin.y + cellHeight * (CGFloat(row) + 0.5))
    }

    /// Zellhöhe in Szenenhöhe (Szene ist 4:3).
    static var cellHeight: CGFloat { 0.1007 }

    /// Wo das Boot im Teich ankommt.
    static var pond: CGPoint {
        WorldPanorama.isActive(.bach) ? CGPoint(x: gridOrigin.x + gridCell * CGFloat(gridCols) + 0.07, y: cellCenter(col: 0, row: 3).y)
                                      : CGPoint(x: 0.84, y: 0.8)
    }
    /// Einlauf vom Raster in den Teich (rechts neben der untersten Reihe).
    static var pondInlet: CGPoint { CGPoint(x: gridOrigin.x + gridCell * (CGFloat(gridCols) + 0.5), y: cellCenter(col: 0, row: 3).y + 0.04) }
    static var streamBed: CGPoint { CGPoint(x: gridOrigin.x + gridCell * CGFloat(gridCols) + 0.07, y: cellCenter(col: 0, row: 0).y + 0.06) }
    static let source = CGPoint(x: 0.3 - 0.0787 / 2, y: 0.19 + 0.1007 / 2)
}

import CoreGraphics

/// Breite Orte: Mit Panoramabild wird ein Ort mehrere Bildschirme breit und lässt sich wischen.
/// Koordinaten bleiben im Grundbild: x 0…1 ist der bisherige Bildschirm, links davon negativ, rechts > 1.
@MainActor
enum WorldPanorama {
    static func isActive(_ a: WorldArea) -> Bool {
        guard a.panoramaExtent != (0, 1) else { return false }
        return ImageCache.image(name(a, evening: false)) != nil || DemoMode.flag("-panotest")
    }

    /// Sichtbarer Bereich in Grundbild-Einheiten.
    /// Neuer Garten: rechts vom Hausgarten liegt eine Spielwiese für Bauten und Gartenschmuck.
    static func extent(_ a: WorldArea) -> (min: Double, max: Double) {
        guard isActive(a) else { return (0, 1) }
        if a == .haus, WorldLayout.garden3 { return (0, 2) }
        return a.panoramaExtent
    }

    /// Name des breiten Bildes, passend zum aktiven Garten.
    static func name(_ a: WorldArea, evening: Bool) -> String {
        if a == .haus, WorldLayout.garden3 { return evening ? "gw_szene_garten_panorama_abend" : "gw_szene_garten_panorama_tag" }
        return a.panorama(evening: evening)
    }

    /// Anzahl Beete im Hausgarten (3 Beete + Baumplatz; im Panorama und im neuen Garten 3 weitere).
    static var bedCount: Int { isActive(.haus) || WorldLayout.garden3 ? WorldLayout.beds.count : 4 }
}

/// Feste Plätze in den Szenen (Koordinaten im Grundbild, y = Bodenlinie).
@MainActor
enum WorldLayout {
    // MARK: Neuer Garten («Garten 3»)

    /// Der neue Garten mit grossem Haus, Schuppen, Gemüsebeet und Gartentor (assets/skizzen/garten_layout.png).
    /// Er wird aktiv, sobald das neue Szenenbild im Bundle liegt; im Simulator-Test auch mit «-garten3»
    /// (dann mit gezeichnetem Platzhalter).
    static var garden3: Bool {
        ImageCache.image("gw_szene_garten_tag") != nil || DemoMode.flag("-garten3")
    }

    /// Flache Pflanzhügel statt Hochbeeten (neuer Garten, sobald die Bilder gw_erde_* da sind).
    static var flatBeds: Bool { garden3 && ImageCache.image("gw_erde_leer") != nil }

    /// Hintergrundbild eines Ortes, passend zum aktiven Garten.
    static func sceneName(_ a: WorldArea, evening: Bool) -> String {
        if a == .haus, garden3 { return evening ? "gw_szene_garten_abend" : "gw_szene_garten_tag" }
        return a.scene(evening: evening)
    }

    /// Tippfläche der Haustür (im alten Garten das ganze Haus, weil die Tür dort winzig ist).
    static var houseDoor: CGRect {
        garden3 ? CGRect(x: 0.165, y: 0.27, width: 0.13, height: 0.25) : CGRect(x: 0.66, y: 0.03, width: 0.3, height: 0.3)
    }
    /// Mitte der Türschwelle (dorthin läuft Printatops, dort blinkt der Hinweis).
    static var houseDoorStep: CGPoint { garden3 ? CGPoint(x: 0.23, y: 0.53) : CGPoint(x: 0.8, y: 0.36) }
    /// Schuppen mit der Werkstatt (nur im neuen Garten).
    static let shed = CGRect(x: 0.70, y: 0.14, width: 0.25, height: 0.34)
    /// Gartentor zur Inselkarte (nur im neuen Garten).
    static let gate = CGRect(x: 0.0, y: 0.54, width: 0.09, height: 0.28)

    // Hausgarten
    private static let oldBeds: [CGPoint] = [CGPoint(x: 0.25, y: 0.63), CGPoint(x: 0.42, y: 0.63), CGPoint(x: 0.59, y: 0.63), CGPoint(x: 0.2, y: 0.44),
                                             // nur im Panorama: Obstgarten links, Blumenwiese rechts
                                             CGPoint(x: -0.62, y: 0.63), CGPoint(x: -0.42, y: 0.63), CGPoint(x: 1.38, y: 0.63)]
    /// Neuer Garten: sechs Pflanzplätze im Gemüsebeet (hintere und vordere Reihe), Platz 3 ist der Baumplatz.
    private static let newBeds: [CGPoint] = [CGPoint(x: 0.36, y: 0.705), CGPoint(x: 0.52, y: 0.705), CGPoint(x: 0.68, y: 0.705), CGPoint(x: 0.89, y: 0.68),
                                             CGPoint(x: 0.33, y: 0.83), CGPoint(x: 0.52, y: 0.83), CGPoint(x: 0.71, y: 0.83)]
    /// Beetplätze (Index 3 ist immer der Baumplatz).
    static var beds: [CGPoint] { garden3 ? newBeds : oldBeds }
    static var bedSize: Double { garden3 ? 0.13 : 0.15 }
    static let treeSize: Double = 0.24
    static var blanket: CGPoint { garden3 ? CGPoint(x: 0.56, y: 0.5) : CGPoint(x: 0.76, y: 0.53) }
    static let workbench = CGPoint(x: 0.36, y: 0.37)
    static var basket: CGPoint { garden3 ? CGPoint(x: 0.93, y: 0.9) : CGPoint(x: 0.92, y: 0.62) }
    /// Wo Printatops beim Betreten des Hausgartens steht.
    static var dinoHome: CGPoint { garden3 ? CGPoint(x: 0.24, y: 0.93) : CGPoint(x: 0.34, y: 0.74) }

    /// Abenteuer-Stellen im neuen Garten (Schlüssel «Abenteuer:Schritt»); die Stellen im Katalog gelten für den alten.
    private static let garden3Steps: [String: CGPoint] = [
        "schmetterling:0": CGPoint(x: 0.52, y: 0.62), "schmetterling:1": CGPoint(x: 0.96, y: 0.56),
        "vogelhaus:0": CGPoint(x: 0.74, y: 0.575), "vogelhaus:1": CGPoint(x: 0.74, y: 0.43),
        "hase:0": CGPoint(x: 0.05, y: 0.92), "hase:1": CGPoint(x: 0.14, y: 0.93),
        "schnecke:0": CGPoint(x: 0.4, y: 0.96),
        "lichter:1": CGPoint(x: 0.5, y: 0.45),
        "fest:0": CGPoint(x: 0.56, y: 0.52), "fest:1": CGPoint(x: 0.48, y: 0.52),
        "fest:2": CGPoint(x: 0.56, y: 0.38), "fest:3": CGPoint(x: 0.65, y: 0.54)
    ]

    /// Stelle eines Abenteuer-Schritts im Hausgarten, passend zum aktiven Garten.
    static func stepPoint(adventure: String, index: Int, area: WorldArea, fallback: CGPoint) -> CGPoint {
        guard area == .haus, garden3 else { return fallback }
        return garden3Steps["\(adventure):\(index)"] ?? fallback
    }

    // Bach
    // Raster liegt im Sandfeld von gw_szene_bach_teich (innen x 32,5–74,5 %, y 24,5–55,7 %)
    static let gridOrigin = CGPoint(x: 0.325, y: 0.245)
    static let gridCell: CGFloat = 0.07 // in Szenenbreite
    /// Im Panorama reicht der Wasserbaukasten über zwei Bildschirme.
    static var gridCols: Int { WorldPanorama.isActive(.bach) ? 11 : 6 }
    static let gridRows = 4
    static let bridge = CGPoint(x: 0.16, y: 0.7)
    /// Zweite Wiese am Bach: rechts vom Sandfeld (links fliesst jetzt der echte Bach).
    static let bachUpperMeadow = CGRect(x: 0.8, y: 0.36, width: 0.14, height: 0.2)
    static var dock: CGPoint { WorldPanorama.isActive(.bach) ? CGPoint(x: pond.x + 0.05, y: 0.95) : CGPoint(x: 0.77, y: 0.82) }

    // Baumhaus
    static let platform = CGPoint(x: 0.55, y: 0.38)
    static let lift = CGPoint(x: 0.66, y: 0.7)

    // Wunderlichtung
    static let chimeSlots: [CGPoint] = [CGPoint(x: 0.3, y: 0.86), CGPoint(x: 0.43, y: 0.9), CGPoint(x: 0.57, y: 0.9), CGPoint(x: 0.7, y: 0.86)]
    static let fantasySlots: [CGPoint] = [CGPoint(x: 0.2, y: 0.56), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.8, y: 0.56)]
    static let crystal = CGPoint(x: 0.72, y: 0.38)
    static let cloud = CGPoint(x: 0.32, y: 0.2)

    /// Tiefenstaffelung: Was weiter hinten steht (kleineres y), erscheint kleiner, was vorne steht, grösser.
    /// Bezugslinie ist die Beetreihe (y = 0,63, Faktor 1). Der Bach wird von oben gesehen und staffelt nicht.
    static func depthScale(_ a: WorldArea, y: Double) -> CGFloat {
        guard a != .bach else { return 1 }
        return CGFloat(min(max(1 + (y - 0.63) * 0.8, 0.72), 1.25))
    }

    /// Stellflächen für gebaute Dinge.
    static func spots(_ a: WorldArea) -> [CGPoint] {
        switch a {
        case .haus:
            if garden3, WorldPanorama.isActive(.haus) {
                // Mit Spielwiese: am Haus nur wenige Plätze, der Rest steht rechts auf der Wiese (3 Reihen).
                var list = [CGPoint(x: 0.74, y: 0.575), CGPoint(x: 0.38, y: 0.575), CGPoint(x: 0.92, y: 0.82)]
                for y in [0.94, 0.78, 0.62] {
                    for i in 0..<5 { list.append(CGPoint(x: 1.14 + 0.18 * Double(i), y: y)) }
                }
                return list
            }
            if garden3 {
                // Freie Wiese vorne, zwischen Haus und Schuppen und rechts neben dem Beet
                return [CGPoint(x: 0.13, y: 0.96), CGPoint(x: 0.74, y: 0.575), CGPoint(x: 0.38, y: 0.575), CGPoint(x: 0.92, y: 0.8),
                        CGPoint(x: 0.4, y: 0.995), CGPoint(x: 0.62, y: 0.995), CGPoint(x: 0.8, y: 0.985), CGPoint(x: 0.15, y: 0.86)]
            }
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
            case .haus: return garden3 ? CGRect(x: 0.1, y: 0.9, width: 1.8, height: 0.08) : CGRect(x: -0.85, y: 0.46, width: 2.7, height: 0.26)
            case .lichtung: return CGRect(x: 0.08, y: 0.6, width: 1.84, height: 0.32)
            default: break
            }
        }
        switch a {
        case .haus: return garden3 ? CGRect(x: 0.1, y: 0.9, width: 0.8, height: 0.07) : CGRect(x: 0.16, y: 0.46, width: 0.5, height: 0.26)
        case .bach: return CGRect(x: 0.26, y: 0.66, width: 0.3, height: 0.24)
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
    static var cellHeight: CGFloat { 0.078 }

    /// Wo das Boot im Teich ankommt.
    static var pond: CGPoint {
        WorldPanorama.isActive(.bach) ? CGPoint(x: gridOrigin.x + gridCell * CGFloat(gridCols) + 0.07, y: cellCenter(col: 0, row: 3).y)
                                      : CGPoint(x: 0.84, y: 0.8)
    }
    /// Einlauf vom Raster in den Teich (rechts neben der untersten Reihe).
    static var pondInlet: CGPoint { CGPoint(x: gridOrigin.x + gridCell * (CGFloat(gridCols) + 0.5), y: cellCenter(col: 0, row: 3).y + 0.04) }
    /// Rechte Kante des Rasters.
    static var gridRight: CGFloat { gridOrigin.x + gridCell * CGFloat(gridCols) }
    /// Beet am Bach: direkt rechts neben der obersten Reihe.
    static var streamBed: CGPoint { CGPoint(x: gridRight + 0.075, y: cellCenter(col: 0, row: 0).y) }
    /// Zulauf: vom Becken des Wasserfalls bis zum ersten Feld.
    static var sourceRun: [CGPoint] {
        let y = cellCenter(col: 0, row: 0).y
        return [CGPoint(x: 0.215, y: y), CGPoint(x: gridOrigin.x, y: y)]
    }
    /// Rinne von der obersten Reihe zum Beet am Bach.
    static var bedRun: [CGPoint] {
        let y = cellCenter(col: 0, row: 0).y
        return [CGPoint(x: gridRight, y: y), CGPoint(x: gridRight + 0.04, y: y)]
    }
    /// Auslauf: von der untersten Reihe im Bogen hinunter in den Teich.
    static var pondRun: [CGPoint] {
        let y = cellCenter(col: 0, row: 3).y
        // Der Auslauf endet rechts neben dem Steg im offenen Wasser, nicht auf dem Steg.
        return [CGPoint(x: gridRight, y: y), CGPoint(x: gridRight + 0.08, y: y), CGPoint(x: gridRight + 0.1, y: y + 0.02),
                CGPoint(x: gridRight + 0.11, y: y + 0.055), CGPoint(x: gridRight + 0.11, y: 0.73)]
    }
    static var source: CGPoint { CGPoint(x: gridOrigin.x - gridCell / 2, y: gridOrigin.y + cellHeight / 2) }
}

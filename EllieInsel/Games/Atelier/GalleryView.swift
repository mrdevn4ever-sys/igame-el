import SwiftUI

/// Einfache Bildergalerie der gemalten Bilder.
struct GalleryView: View {
    @Environment(AppModel.self) private var app
    @State private var toDelete: Artwork?

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 24)]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CircleIconButton(systemName: "house.fill", label: "Zu deinen Spielen") {
                    app.audio.effect(.tap)
                    app.goHome()
                }
                Text("🖼️ Meine Bilder")
                    .font(Theme.rounded(32, .heavy))
                    .foregroundStyle(Theme.darkGreen)
                Spacer()
                Button {
                    app.audio.effect(.tap)
                    app.open(.atelier)
                } label: {
                    Label("Ins Atelier", systemImage: "paintpalette.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.lightYellow, foreground: Theme.darkGreen))
            }
            .padding(.horizontal, 24)

            if app.gallery.isEmpty {
                Spacer()
                Text("Noch keine Bilder. Im Atelier kannst du malen.")
                    .font(Theme.rounded(24, .semibold))
                    .foregroundStyle(Theme.darkGreen)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(app.gallery) { art in
                            VStack(spacing: 10) {
                                thumbnail(art)
                                    .onTapGesture { edit(art) }
                                HStack {
                                    Button {
                                        edit(art)
                                    } label: {
                                        Label("Weitermalen", systemImage: "pencil")
                                    }
                                    .font(Theme.rounded(18, .semibold))
                                    .frame(minHeight: 48)
                                    Spacer()
                                    Button {
                                        toDelete = art
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 22))
                                            .frame(width: 52, height: 52)
                                    }
                                    .accessibilityLabel("Bild löschen")
                                }
                                .foregroundStyle(Theme.darkGreen)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 24).fill(.white))
                        }
                    }
                    .padding(24)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Theme.cream.ignoresSafeArea())
        .sheet(item: $toDelete) { art in
            DeleteArtworkSheet(art: art) {
                app.deleteArtwork(art.id)
                toDelete = nil
            } cancel: {
                toDelete = nil
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ art: Artwork) -> some View {
        if let img = UIImage(data: art.thumbnail) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.creamDark)
                .aspectRatio(4 / 3, contentMode: .fit)
        }
    }

    private func edit(_ art: Artwork) {
        app.audio.effect(.tap)
        app.editArtworkID = art.id
        app.clearGame(.atelier)
        app.open(.atelier)
    }
}

/// Löschen mit Vorschau bestätigen.
private struct DeleteArtworkSheet: View {
    let art: Artwork
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Dieses Bild löschen?")
                .font(Theme.rounded(30, .heavy))
                .foregroundStyle(Theme.darkGreen)
            if let img = UIImage(data: art.thumbnail) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .frame(maxWidth: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            HStack(spacing: 20) {
                Button("Behalten", action: cancel)
                    .buttonStyle(BigButtonStyle(color: Theme.success))
                Button("Löschen", action: confirm)
                    .buttonStyle(BigButtonStyle(color: Theme.gentleRed))
            }
        }
        .padding(40)
        .background(Theme.cream)
    }
}

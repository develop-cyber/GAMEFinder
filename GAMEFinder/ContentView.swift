import SwiftUI

private enum AppStyle {
    static let navy = Color(red: 0.04, green: 0.07, blue: 0.18)
    static let blue = Color(red: 0.05, green: 0.55, blue: 1)
    static let purple = Color(red: 0.67, green: 0.30, blue: 0.98)
}

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        TabView {
            NavigationStack { DiscoverView() }
                .tabItem { Label("Discover", systemImage: "sparkles.tv") }
            NavigationStack { SearchView() }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            NavigationStack { FavoritesView() }
                .tabItem { Label("Favorites", systemImage: "heart.fill") }
        }
        .tint(AppStyle.purple)
    }
}

struct DiscoverView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Group {
            if store.isLoading && store.games.isEmpty {
                ProgressView("Finding games...")
            } else if store.games.isEmpty {
                ContentUnavailableView {
                    Label("Games unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(store.errorMessage ?? "No games found.")
                } actions: {
                    Button("Retry") { Task { await store.loadGames() } }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Find your next favorite game")
                                .font(.largeTitle.bold()).foregroundStyle(.white)
                            Text("Explore free games tailored to your favorite genres.")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(LinearGradient(colors: [AppStyle.navy, AppStyle.blue, AppStyle.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        Text("Recommended for you").font(.title2.bold())
                        if !store.favoriteIDs.isEmpty {
                            Text("Based on genres of games you've saved")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        ForEach(store.recommendedGames) { game in
                            NavigationLink(value: game) { GameRow(game: game) }
                                .buttonStyle(.plain)
                        }
                        Text("Game data: FreeToGame.com")
                            .font(.caption).foregroundStyle(.secondary)
                        Link("Visit FreeToGame", destination: URL(string: "https://www.freetogame.com")!)
                            .font(.caption)
                    }.padding()
                }
            }
        }
        .navigationTitle("GAMEFinder")
        .navigationDestination(for: Game.self) { GameDetailView(game: $0) }
        .refreshable { await store.loadGames() }
    }
}

struct SearchView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        List {
            Section("Genre") {
                Picker("Genre", selection: $store.selectedGenre) {
                    ForEach(store.genres, id: \.self) { Text($0).tag($0) }
                }
            }
            Section("Games (\(store.filteredGames.count))") {
                ForEach(store.filteredGames) { game in
                    NavigationLink(value: game) { GameRow(game: game) }
                }
            }
        }
        .overlay {
            if store.games.isEmpty && !store.isLoading {
                ContentUnavailableView("No games loaded", systemImage: "wifi.slash", description: Text(store.errorMessage ?? "Check your internet connection."))
            } else if !store.games.isEmpty && store.filteredGames.isEmpty {
                ContentUnavailableView.search(text: store.searchText)
            }
        }
        .searchable(text: $store.searchText, prompt: "Game title or genre")
        .navigationTitle("Search Games")
        .navigationDestination(for: Game.self) { GameDetailView(game: $0) }
    }
}

struct FavoritesView: View {
    @EnvironmentObject private var store: GameStore

    private var favorites: [Game] { store.games.filter { store.favoriteIDs.contains($0.id) } }

    var body: some View {
        List(favorites) { game in
            NavigationLink(value: game) { GameRow(game: game) }
        }
        .overlay {
            if favorites.isEmpty {
                ContentUnavailableView("No favorites yet", systemImage: "heart", description: Text("Tap the heart on a game to save it here."))
            }
        }
        .navigationTitle("My Favorites")
        .navigationDestination(for: Game.self) { GameDetailView(game: $0) }
    }
}

struct GameRow: View {
    let game: Game
    @EnvironmentObject private var store: GameStore

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: game.thumbnail)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(AppStyle.navy)
                    .overlay { Image(systemName: "gamecontroller.fill").foregroundStyle(.white) }
            }
            .frame(width: 100, height: 75).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 5) {
                Text(game.title).font(.headline).lineLimit(2)
                Text(game.genre).font(.caption).foregroundStyle(AppStyle.purple)
                Text(game.platform).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(systemName: store.isFavorite(game) ? "heart.fill" : "chevron.right")
                .foregroundStyle(store.isFavorite(game) ? AppStyle.purple : .secondary)
        }
        .padding(.vertical, 4)
    }
}

struct GameDetailView: View {
    let game: Game
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: game.thumbnail)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16).fill(AppStyle.navy)
                        .frame(height: 220)
                        .overlay { ProgressView().tint(.white) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                Text(game.title).font(.largeTitle.bold())
                Label(game.genre, systemImage: "tag.fill").foregroundStyle(AppStyle.purple)
                Label(game.platform, systemImage: "desktopcomputer")
                Text(game.shortDescription).font(.body)
                Button {
                    store.toggleFavorite(game)
                } label: {
                    Label(store.isFavorite(game) ? "Remove from Favorites" : "Save to Favorites",
                          systemImage: store.isFavorite(game) ? "heart.slash" : "heart.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppStyle.purple)
                if let url = URL(string: game.gameURL), ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                    Link(destination: url) {
                        Label("View Game Website", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                Text("Game information provided by FreeToGame.com")
                    .font(.caption).foregroundStyle(.secondary)
                Link("FreeToGame.com", destination: URL(string: "https://www.freetogame.com")!)
                    .font(.caption)
            }.padding()
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

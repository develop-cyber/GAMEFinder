import Foundation
import SwiftUI

// Real games from FreeToGame. Some results may omit optional fields.
struct Game: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let thumbnail: String
    let shortDescription: String
    let gameURL: String
    let genre: String
    let platform: String
    let publisher: String?

    enum CodingKeys: String, CodingKey {
        case id, title, thumbnail, genre, platform, publisher
        case shortDescription = "short_description"
        case gameURL = "game_url"
    }
}

@MainActor
final class GameStore: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedGenre = "All"
    @Published var searchText = ""
    @Published var favoriteIDs: Set<Int> = [] {
        didSet { saveFavorites() }
    }

    private let favoritesKey = "GAMEFinder.favoriteIDs.v1"

    init() {
        favoriteIDs = Set(UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? [])
    }

    var genres: [String] {
        ["All"] + Array(Set(games.map(\.genre))).sorted()
    }

    var filteredGames: [Game] {
        games.filter { game in
            let matchesGenre = selectedGenre == "All" || game.genre == selectedGenre
            let matchesSearch = searchText.isEmpty ||
                game.title.localizedCaseInsensitiveContains(searchText) ||
                game.genre.localizedCaseInsensitiveContains(searchText) ||
                game.shortDescription.localizedCaseInsensitiveContains(searchText)
            return matchesGenre && matchesSearch
        }
    }

    var recommendedGames: [Game] {
        // Suggest games in the same genres as saved favorites; otherwise show popular catalog entries.
        let preferredGenres = Set(games.filter { favoriteIDs.contains($0.id) }.map(\.genre))
        let candidates = games.filter { !favoriteIDs.contains($0.id) }
        if preferredGenres.isEmpty { return Array(candidates.prefix(15)) }
        return Array(candidates.sorted { a, b in
            let aScore = preferredGenres.contains(a.genre) ? 1 : 0
            let bScore = preferredGenres.contains(b.genre) ? 1 : 0
            if aScore == bScore { return a.title < b.title }
            return aScore > bScore
        }.prefix(15))
    }

    func isFavorite(_ game: Game) -> Bool { favoriteIDs.contains(game.id) }

    func toggleFavorite(_ game: Game) {
        if favoriteIDs.contains(game.id) { favoriteIDs.remove(game.id) }
        else { favoriteIDs.insert(game.id) }
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs).sorted(), forKey: favoritesKey)
    }

    func loadGames() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let url = URL(string: "https://www.freetogame.com/api/games")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            games = try JSONDecoder().decode([Game].self, from: data)
            if games.isEmpty { errorMessage = "The game catalog is currently empty." }
        } catch {
            errorMessage = "Couldn't load games. Check your internet connection and tap Retry. (\(error.localizedDescription))"
        }
    }
}

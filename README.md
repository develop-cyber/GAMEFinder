# GAMEFinder

A SwiftUI iOS app demonstrating game discovery, local title/genre search, genre-based recommendations, game details, and favorites saved in UserDefaults. Uses the public FreeToGame API (free games only, not Steam/Metacritic ratings).

## Open in Xcode
Double-click `GAMEFinder.xcodeproj`. Choose an iPhone simulator and press Cmd+R. Requires Xcode with iOS 17+ SDK. Set your own signing team if deploying to an iPhone.

## GitHub upload
From the project folder in macOS Terminal, use:
```
git init
git add .
git commit -m "Initial GAMEFinder SwiftUI app"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```
If the repository already contains work, clone it first and copy the GAMEFinder project into the clone instead of overwriting it. Commit and push from the cloned folder.

## API credit
Game data is provided by [FreeToGame](https://www.freetogame.com/) and retrieved from https://www.freetogame.com/api/games . API access requires an internet connection. FreeToGame requires attribution and avoids more than 10 calls/second.

## Notes
Recommendations are simple genre matching against locally saved favorites, **not** a machine learning recommender. Saved favorites are persisted by IDs in UserDefaults; on restart the catalog is fetched again. The simulator build must be tested in Xcode on macOS.

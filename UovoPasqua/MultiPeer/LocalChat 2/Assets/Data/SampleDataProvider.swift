import Foundation

// all mock content — replace bodies with real API calls later
enum SampleDataProvider {

    // MARK: categories
    static let categories: [Category] = [
        Category(id: "action",      name: "Action",       tagline: "High-octane thrills",    symbolName: "bolt.fill",          gradientStart: "crimson",  gradientEnd: "amber"),
        Category(id: "drama",       name: "Drama",        tagline: "Stories that stay",      symbolName: "theatermasks.fill",   gradientStart: "indigo",   gradientEnd: "violet"),
        Category(id: "documentary", name: "Documentary",  tagline: "Truth stranger than fiction", symbolName: "camera.fill",   gradientStart: "forest",   gradientEnd: "teal"),
        Category(id: "scifi",       name: "Sci-Fi",       tagline: "Beyond the horizon",     symbolName: "star.fill",          gradientStart: "ocean",    gradientEnd: "indigo"),
        Category(id: "thriller",    name: "Thriller",     tagline: "Edge of your seat",      symbolName: "eye.fill",           gradientStart: "slate",    gradientEnd: "midnight"),
        Category(id: "comedy",      name: "Comedy",       tagline: "Life is funny",          symbolName: "face.smiling.fill",  gradientStart: "amber",    gradientEnd: "rose"),
    ]

    // MARK: all items
    static let allItems: [MediaItem] = films + series + docs

    static let films: [MediaItem] = [
        MediaItem(id: "f01", title: "Iron Meridian",    subtitle: "2024 · PG-13 · 2h 14m", description: "A disgraced engineer uncovers a conspiracy beneath the arctic ice that could reshape geopolitics forever.",     categoryID: "action",   durationSeconds: 8040,  progressSeconds: 0,    artworkColorTop: "crimson",  artworkColorBottom: "amber",   artworkSymbol: "bolt.fill",         relatedIDs: ["f02","f05","s01"]),
        MediaItem(id: "f02", title: "The Quiet Shore",  subtitle: "2023 · PG · 1h 52m",    description: "A lighthouse keeper and a stranded marine biologist form an unlikely bond during a week-long storm.",          categoryID: "drama",    durationSeconds: 6720,  progressSeconds: 2100, artworkColorTop: "ocean",    artworkColorBottom: "teal",    artworkSymbol: "water.waves",       relatedIDs: ["f03","f06"]),
        MediaItem(id: "f03", title: "Pale Signal",      subtitle: "2024 · R · 2h 01m",     description: "Deep-space relay station crew intercepts a transmission that slowly erodes their grip on reality.",            categoryID: "scifi",    durationSeconds: 7260,  progressSeconds: 0,    artworkColorTop: "indigo",   artworkColorBottom: "violet",  artworkSymbol: "antenna.radiowaves.left.and.right", relatedIDs: ["f01","f04","s02"]),
        MediaItem(id: "f04", title: "Last Harvest",     subtitle: "2022 · R · 1h 45m",     description: "Climate journalist embedded with survivalist farmers discovers their radical plan for the coming drought.",     categoryID: "thriller", durationSeconds: 6300,  progressSeconds: 6300, artworkColorTop: "forest",   artworkColorBottom: "amber",   artworkSymbol: "leaf.fill",         relatedIDs: ["f02","f06","d01"]),
        MediaItem(id: "f05", title: "Neon Leverage",    subtitle: "2025 · R · 2h 22m",     description: "A fixer in near-future Taipei navigates three criminal factions while protecting a data broker's daughter.",   categoryID: "action",   durationSeconds: 8520,  progressSeconds: 1800, artworkColorTop: "violet",   artworkColorBottom: "rose",    artworkSymbol: "hexagon.fill",      relatedIDs: ["f01","f03"]),
        MediaItem(id: "f06", title: "A Perfect Season", subtitle: "2023 · PG · 1h 58m",    description: "A retired chef returns to his hometown to save the restaurant his grandmother built from nothing.",           categoryID: "drama",    durationSeconds: 7080,  progressSeconds: 0,    artworkColorTop: "amber",    artworkColorBottom: "gold",    artworkSymbol: "fork.knife",        relatedIDs: ["f02","f04"]),
        MediaItem(id: "f07", title: "Recursion Gate",   subtitle: "2024 · PG-13 · 2h 08m", description: "A physicist discovers that every major historical event was authored by a single recursive algorithm.",       categoryID: "scifi",    durationSeconds: 7680,  progressSeconds: 3200, artworkColorTop: "teal",     artworkColorBottom: "indigo",  artworkSymbol: "arrow.triangle.2.circlepath", relatedIDs: ["f03","s02"]),
        MediaItem(id: "f08", title: "Hollow Frequency", subtitle: "2025 · R · 1h 55m",     description: "A radio journalist tracking urban myths becomes part of the story she was trying to debunk.",                 categoryID: "thriller", durationSeconds: 6900,  progressSeconds: 0,    artworkColorTop: "slate",    artworkColorBottom: "midnight", artworkSymbol: "waveform",         relatedIDs: ["f04","s03"]),
    ]

    static let series: [MediaItem] = [
        MediaItem(id: "s01", title: "Cascade",          subtitle: "2024 · TV-MA · S1E1 · 52m", description: "A resilience consultant embedded at a crumbling megacity infrastructure project faces impossible choices every episode.", categoryID: "drama",    durationSeconds: 3120,  progressSeconds: 0,    artworkColorTop: "ocean",   artworkColorBottom: "slate",  artworkSymbol: "building.2.fill",    relatedIDs: ["f02","f06","s03"]),
        MediaItem(id: "s02", title: "Event Horizon PD", subtitle: "2023 · TV-14 · S2E3 · 48m", description: "A precinct policing the first permanent moon settlement grapples with jurisdiction, ethics and isolation.",            categoryID: "scifi",    durationSeconds: 2880,  progressSeconds: 900,  artworkColorTop: "indigo",  artworkColorBottom: "midnight", artworkSymbol: "moon.fill",         relatedIDs: ["f03","f07"]),
        MediaItem(id: "s03", title: "Undercurrent",     subtitle: "2025 · TV-MA · S1E5 · 44m", description: "Crime journalist and rogue detective investigate a series of disappearances tied to a city's water authority.",        categoryID: "thriller", durationSeconds: 2640,  progressSeconds: 2640, artworkColorTop: "teal",    artworkColorBottom: "forest", artworkSymbol: "drop.fill",          relatedIDs: ["f04","f08","s01"]),
        MediaItem(id: "s04", title: "Bright Margin",    subtitle: "2024 · TV-PG · S1E2 · 38m", description: "Ensemble comedy set inside a chaotic independent bookshop fighting to survive a relentless chain store.",             categoryID: "comedy",   durationSeconds: 2280,  progressSeconds: 1100, artworkColorTop: "amber",   artworkColorBottom: "rose",   artworkSymbol: "books.vertical.fill", relatedIDs: ["f06","s01"]),
    ]

    static let docs: [MediaItem] = [
        MediaItem(id: "d01", title: "Soil & Circuit",   subtitle: "2023 · TV-PG · 1h 28m", description: "How a generation of farmers in West Africa is using satellite data and community apps to restore degraded land.",   categoryID: "documentary", durationSeconds: 5280, progressSeconds: 2000, artworkColorTop: "forest", artworkColorBottom: "amber", artworkSymbol: "leaf.fill",       relatedIDs: ["f04","d02"]),
        MediaItem(id: "d02", title: "Frequency Deep",   subtitle: "2024 · TV-PG · 1h 42m", description: "A team of oceanographers deploys the world's largest underwater microphone array to listen to the planet's pulse.",  categoryID: "documentary", durationSeconds: 6120, progressSeconds: 0,    artworkColorTop: "ocean",  artworkColorBottom: "teal",  artworkSymbol: "waveform.badge.mic", relatedIDs: ["d01","f03"]),
        MediaItem(id: "d03", title: "After the Lights", subtitle: "2022 · TV-MA · 1h 18m", description: "Three countries, six power grids, one storm. An hour-by-hour reconstruction of the biggest blackout in modern history.", categoryID: "documentary", durationSeconds: 4680, progressSeconds: 0,    artworkColorTop: "slate",  artworkColorBottom: "midnight", artworkSymbol: "bolt.slash.fill", relatedIDs: ["d01","f01"]),
    ]

    // MARK: hero item shown at top of home
    static var heroItem: MediaItem { films[2] }  // Pale Signal

    // MARK: home shelves
    static var trendingShelf: ShelfSection {
        ShelfSection(id: "trending", title: "Trending Now", subtitle: nil,
                     items: [films[0], films[4], series[1], films[6], docs[1], series[2]])
    }

    static var continueWatchingShelf: ShelfSection {
        ShelfSection(id: "continue", title: "Continue Watching", subtitle: nil,
                     items: allItems.filter { $0.isInProgress })
    }

    static var recommendedShelf: ShelfSection {
        ShelfSection(id: "recommended", title: "Recommended for You", subtitle: nil,
                     items: [films[5], series[3], docs[0], films[7], films[3], series[0]])
    }

    static var categoriesShelf: ShelfSection {
        // using mock MediaItems that represent categories visually — CatalogView receives real Category
        ShelfSection(id: "categories", title: "Browse Categories", subtitle: "Find your next favourite",
                     items: [])   // home renders categories separately via their own view
    }

    // MARK: related items lookup
    static func relatedItems(for item: MediaItem) -> [MediaItem] {
        let lookup = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        return item.relatedIDs.compactMap { lookup[$0] }
    }

    // MARK: search
    static func search(query: String) -> [MediaItem] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return allItems.filter {
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q) ||
            $0.categoryID.lowercased().contains(q)
        }
    }

    static var searchSuggestions: [String] {
        ["Action", "Documentary", "Sci-Fi", "Drama", "Thriller", "Comedy", "New Releases"]
    }
}

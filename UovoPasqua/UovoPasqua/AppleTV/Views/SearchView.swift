import SwiftUI

struct SearchView: View {
    @State private var query: String = ""
    @FocusState private var searchFieldFocused: Bool

    private var results: [MediaItem] { SampleDataProvider.search(query: query) }
    private var isSearching: Bool { !query.isEmpty }

    private let columns = Array(
        repeating: GridItem(.fixed(AppTheme.catalogItemWidth), spacing: AppTheme.spacingMD),
        count: AppTheme.catalogColumns
    )

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                // search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.6))

                    TextField("Search films, series, documentaries…", text: $query)
                        .focused($searchFieldFocused)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()

                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.spacingSM)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD))
                .padding(.horizontal, AppTheme.spacingXL)

                if isSearching {
                    // results grid
                    if results.isEmpty {
                        emptyState
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: AppTheme.spacingMD) {
                                ForEach(results) { item in
                                    NavigationLink(destination: DetailView(item: item)) {
                                        LockupCardView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppTheme.spacingXL)
                            .padding(.bottom, AppTheme.spacingXXL)
                        }
                    }
                } else {
                    // suggestions when idle
                    suggestionsSection
                }
            }
            .padding(.top, AppTheme.spacingMD)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Search")
            .onAppear { searchFieldFocused = true }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.2))
            Text("No results for \"\(query)\"")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AppTheme.spacingXXL)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            Text("Suggestions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.spacingXL)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingSM) {
                    ForEach(SampleDataProvider.searchSuggestions, id: \.self) { suggestion in
                        Button {
                            query = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.subheadline)
                                .padding(.horizontal, AppTheme.spacingSM)
                                .padding(.vertical, AppTheme.spacingXS)
                                .background(Color.white.opacity(0.12))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.spacingXL)
            }

            Spacer()
        }
    }
}

#Preview {
    SearchView()
        .environment(AppState())
}

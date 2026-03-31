import SwiftUI

struct CatalogView: View {
    var initialCategory: Category? = nil

    @State private var selectedCategoryID: String? = nil
    @FocusState private var filterFocused: String?

    private let categories = SampleDataProvider.categories
    private let columns = Array(
        repeating: GridItem(.fixed(AppTheme.catalogItemWidth), spacing: AppTheme.spacingMD),
        count: AppTheme.catalogColumns
    )

    private var filteredItems: [MediaItem] {
        guard let id = selectedCategoryID else { return SampleDataProvider.allItems }
        return SampleDataProvider.allItems.filter { $0.categoryID == id }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // filter chips row
                filterRow
                    .padding(.top, AppTheme.spacingSM)
                    .padding(.bottom, AppTheme.spacingMD)

                // grid
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: AppTheme.spacingMD) {
                        ForEach(filteredItems) { item in
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
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Catalog")
            .onAppear {
                // respect deep-link category passed from home
                if let cat = initialCategory, selectedCategoryID == nil {
                    selectedCategoryID = cat.id
                }
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                filterChip(label: "All", id: nil)
                ForEach(categories) { cat in
                    filterChip(label: cat.name, id: cat.id)
                }
            }
            .padding(.horizontal, AppTheme.spacingXL)
        }
    }

    private func filterChip(label: String, id: String?) -> some View {
        let isSelected = selectedCategoryID == id
        return Button {
            selectedCategoryID = id
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, AppTheme.spacingSM)
                .padding(.vertical, AppTheme.spacingXS)
                .background(isSelected ? Color.white : Color.white.opacity(0.12))
                .foregroundStyle(isSelected ? Color.black : Color.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .focused($filterFocused, equals: label)
    }
}

#Preview {
    CatalogView()
        .environment(AppState())
}

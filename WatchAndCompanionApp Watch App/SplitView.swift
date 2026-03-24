import SwiftUI

struct SplitView: View {
    // Spostato in una costante per pulizia, List preferisce identificatori chiari
    let cities = ["Palermo", "Rome", "Venice", "Florence", "Naples", "Bari"]
    
    @State private var selection: String?
    
    var body: some View {
        NavigationSplitView {
            // Rimosso VStack: List è già un contenitore primario, il VStack è ridondante
            List(cities, id: \.self, selection: $selection) { city in
                // NavigationLink con 'value' è il modo corretto di gestire la selezione
                // in un NavigationSplitView
                NavigationLink(city.capitalized, value: city)
            }
            .navigationTitle("Città")
        } detail: {
            DetailView(selection: $selection)
        }
        .onAppear {
            if selection == nil {
                selection = cities.first
            }
        }
    }
}

// Definizione della DetailView mancante
struct DetailView: View {
    @Binding var selection: String?
    
    var body: some View {
        Group {
            if let city = selection {
                VStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.largeTitle)
                        .foregroundStyle(.tint)
                    
                    Text(city.capitalized)
                        .font(.headline)
                    
                    Text("Dettagli sulla città...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Seleziona una città")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(selection ?? "Dettaglio")
        // Nasconde il titolo nel dettaglio per massimizzare lo spazio su Watch
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SplitView()
}

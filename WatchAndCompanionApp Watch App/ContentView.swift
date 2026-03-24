import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1: La navigazione a elenco/dettaglio
            SplitView()
                .tabItem {
                    Label("Città", systemImage: "map")
                }
            
            // Tab 2: Il controllo con Digital Crown
            CrownRotationView()
                .tabItem {
                    Label("Crown", systemImage: "digitalcrown.arrow.clockwise")
                }
        }
    }
}

// Estrazione del componente Crown in una vista separata per modularità
struct CrownRotationView: View {
    @State private var number: Double = 0.0
    
    var body: some View {
        VStack {
            Text("\(number, specifier: "%.1f")")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable() // Indispensabile: abilita la ricezione degli eventi della Crown
        .digitalCrownRotation(
            $number,
            from: 0.0,
            through: 12.0,
            by: 0.1,
            sensitivity: .high,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }
}

// Ricordati di mantenere la SplitView definita precedentemente

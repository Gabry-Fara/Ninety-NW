import SwiftUI

// MARK: - Theme-aware accent color

extension Color {
    /// Returns `.orange` in light mode, `.blue` in dark mode — matching the settings theme preview.
    static func themeAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? .orange : .blue
    }
}

struct HorizonBackground: View {
    @Environment(\.colorScheme) var colorScheme
    var isActive: Bool = true
    
    private var accent: Color { .themeAccent(for: colorScheme) }
    
    var body: some View {
        ZStack {
            (colorScheme == .light ? Color(white: 0.95) : Color.black)
                .ignoresSafeArea()
            
            // Subtle top gradient
            LinearGradient(
                colors: colorScheme == .light ?
                    [Color(white: 0.95), Color(white: 0.9)] :
                    [.black, Color(white: 0.05)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                
                // The glowing arc (The Horizon)
                ZStack {
                    // Outer glow
                    Ellipse()
                        .fill(isActive
                              ? accent.opacity(colorScheme == .light ? 0.2 : 0.3)
                              : Color.gray.opacity(colorScheme == .light ? 0.05 : 0.1))
                        .frame(width: 600, height: 300)
                        .blur(radius: 60)
                        .offset(y: 150)
                        .animation(.easeInOut(duration: 1.0), value: isActive)
                    
                    // Main arc
                    if isActive {
                        Ellipse()
                            .stroke(
                                LinearGradient(
                                    colors: [.clear, accent.opacity(colorScheme == .light ? 0.6 : 0.8), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 500, height: 250)
                            .offset(y: 125)
                            .blur(radius: 1)
                            .transition(.opacity)
                    }
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: isActive)
        }
    }
}

#Preview {
    HorizonBackground()
}

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


struct GlassPill<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color(white: 0.1).opacity(0.4))
                        .background(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct FuturisticButton: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let action: () -> Void
    var isProminent: Bool = true
    
    private var accent: Color { .themeAccent(for: colorScheme) }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background {
                    if isProminent {
                        Capsule()
                            .fill(accent.opacity(0.2))
                            .background(Capsule().stroke(accent.opacity(0.5), lineWidth: 1))
                            .background(.ultraThinMaterial)
                    } else {
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .background(.ultraThinMaterial)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        HorizonBackground()
        
        VStack(spacing: 40) {
            GlassPill {
                Text("7:30")
                    .font(.system(size: 60, weight: .light, design: .rounded))
                    .foregroundColor(.white)
            }
            
            FuturisticButton(title: "Toggle") { }
        }
    }
}

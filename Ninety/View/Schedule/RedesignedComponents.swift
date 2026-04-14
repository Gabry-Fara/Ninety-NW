import SwiftUI

struct HorizonBackground: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Subtle top gradient
            LinearGradient(colors: [.black, Color(white: 0.05)], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

            VStack {
                Spacer()
                
                // The glowing blue arc (The Horizon)
                ZStack {
                    // Outer glow
                    Ellipse()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 600, height: 300)
                        .blur(radius: 60)
                        .offset(y: 150)
                    
                    // Main arc
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [.clear, .blue.opacity(0.8), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 500, height: 250)
                        .offset(y: 125)
                        .blur(radius: 1)
                }
            }
            .ignoresSafeArea()
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
    let title: String
    let action: () -> Void
    var isProminent: Bool = true
    
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
                            .fill(Color.blue.opacity(0.2))
                            .background(Capsule().stroke(Color.blue.opacity(0.5), lineWidth: 1))
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

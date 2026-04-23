import SwiftUI
import WatchKit

struct AlarmView: View {
    @ObservedObject var hapticManager = HapticWakeUpManager.shared
    @State private var pulseScale: CGFloat = 1.0
    
    private var copy: WatchCopy {
        WatchCopy(localeIdentifier: Locale.autoupdatingCurrent.identifier)
    }
    
    var body: some View {
        ZStack {
            // Solid background to completely hide the view below
            Color.black.ignoresSafeArea()
            
            // Opaque pulsing gradient
            LinearGradient(
                colors: [.red, .orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(0.95)
            
            VStack(spacing: 0) {
                // Header-like top spacing
                Spacer(minLength: 20)
                
                // Animated Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .scaleEffect(pulseScale)
                    
                    Image(systemName: "alarm.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, options: .repeating, value: hapticManager.isPlaying)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulseScale = 1.15
                    }
                }
                
                Spacer(minLength: 8)
                
                // Text Info
                VStack(spacing: 2) {
                    Text(copy.text(.alarm).uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .kerning(1)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text(Date().formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer(minLength: 12)
                
                // Action Button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    WatchSensorManager.shared.stopAlarmAndNotifyiPhone()
                }) {
                    Text(copy.text(.stop))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                
                Spacer(minLength: 8)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    AlarmView()
}

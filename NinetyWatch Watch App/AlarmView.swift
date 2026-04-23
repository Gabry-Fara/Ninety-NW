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
            // Pulsing background gradient
            LinearGradient(
                colors: [.red.opacity(0.8), .orange.opacity(0.6), .red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .scaleEffect(pulseScale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            }
            
            VStack(spacing: 16) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                    
                    Image(systemName: "alarm.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, options: .repeating, value: hapticManager.isPlaying)
                }
                
                VStack(spacing: 4) {
                    Text(copy.text(.alarm))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(Date().formatted(date: .omitted, time: .shortened))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    WatchSensorManager.shared.stopAlarmAndNotifyiPhone()
                }) {
                    Text(copy.text(.stop))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.white.opacity(0.2))
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
            }
            .padding()
        }
    }
}

#Preview {
    AlarmView()
}

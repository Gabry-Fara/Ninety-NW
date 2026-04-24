import SwiftUI

struct AlarmView: View {
    @ObservedObject var hapticManager = HapticWakeUpManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "alarm.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
                .symbolEffect(.bounce, options: .repeating, value: hapticManager.isPlaying)
            
            Text("Sveglia")
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: {
                hapticManager.stop()
            }) {
                Text("STOP")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .containerBackground(Color.red.gradient, for: .navigation)
    }
}

#Preview {
    AlarmView()
}

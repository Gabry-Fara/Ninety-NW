import SwiftUI

struct ContentView: View {
    
    @State private var name: String = ""
    @State private var isNavigating: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Inserisci nome: ", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                Button {
                    if !name.isEmpty {
                        isNavigating = true
                    }
                } label: {
                    HStack {
                        Text("Join Room").fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.secondary)
                    .padding(.all, 20)
                    .background(Color.primary)
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $isNavigating) {
                ChattingView()
            }
        }
    }
}

#Preview {
    ContentView()
}

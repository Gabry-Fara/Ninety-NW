import SwiftUI

struct ChattingView: View {
    @State private var message: String = ""
    @State var viewModel = ChattingViewModel()
    var body: some View {
        NavigationView{
            VStack{
                ZStack(alignment: .leading){
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                    Text("Gruppo ....")
                        .padding(.horizontal, 15)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                }
                .frame(height: 60)
               
                ScrollView(.vertical){
                    ForEach(viewModel.receivedMessages.indices, id: \.self) {
                        Text(viewModel.receivedMessages[$0])
                    }
                }
                HStack{
                    TextField("Message", text: $message)
                    Button(action: {
                        viewModel.sendMessage()
                        message = ""
                    }, label: {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 32))
                    })
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    ChattingView()
}

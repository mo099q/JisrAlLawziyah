import SwiftUI

@main
struct JisrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .white]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("جسر اللوزية")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .padding(.top, 50)
                    
                    Image(systemName: "cloud.sun.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack { Image(systemName: "mappin.circle.fill"); Text("الطائف - الشفا") }
                        HStack { Image(systemName: "thermometer"); Text("أجواء باردة وضبابية") }
                        HStack { Image(systemName: "leaf.fill"); Text("مزارع اللوز") }
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .padding()
                    
                    Spacer()
                    Text("Developed by LEX-Q").font(.caption).foregroundColor(.gray)
                }
            }
        }
    }
}

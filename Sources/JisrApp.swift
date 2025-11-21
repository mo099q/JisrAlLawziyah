import SwiftUI
import Foundation

// --- مدير الطقس ---
struct WeatherResponse: Codable {
    let current_weather: CurrentWeather
}
struct CurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int
}

class WeatherManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var icon: String = "cloud"
    
    func fetchWeather() {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.06&longitude=40.36&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode(WeatherResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.temperature = "\(Int(decoded.current_weather.temperature))°C"
                    self.icon = decoded.current_weather.temperature > 25 ? "sun.max.fill" : "cloud.fog.fill"
                }
            }
        }.resume()
    }
}

// --- نقطة الانطلاق ---
@main
struct JisrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// --- الواجهة الرئيسية ---
struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    
    // الروابط الجديدة
    let locationURL = URL(string: "https://tr.ee/eE3_QytVnQ")!
    let whatsappURL = URL(string: "https://wa.me/966549949745")!
    let snapchatURL = URL(string: "https://www.snapchat.com/add/jsrlawzia?share_id=ul-_YNESh_4&locale=en-EG")!
    let tiktokURL = URL(string: "https://www.tiktok.com/@jsrlawzia")!
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("SkyBlue"), Color.white]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // صورة تعبيرية
                        Image(systemName: "mountain.2.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .foregroundColor(.blue.opacity(0.8))
                            .padding(.top, 40)
                            .shadow(radius: 10)
                        
                        Text("جسر اللوزية")
                            .font(.system(size: 32, weight: .heavy))
                        
                        // بطاقة الطقس
                        HStack {
                            VStack(alignment: .leading) {
                                Text("الطقس الآن")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(weatherManager.temperature)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Image(systemName: weatherManager.icon)
                                .resizable().frame(width: 40, height: 40).foregroundColor(.orange)
                        }
                        .padding().background(Color.white).cornerRadius(15).padding(.horizontal).shadow(radius: 2)
                        
                        // معلومات العمل
                        VStack(alignment: .leading, spacing: 15) {
                            InfoRow(icon: "ticket.fill", title: "الدخول", value: "مجاني")
                            Divider()
                            Text("أوقات العمل").font(.headline)
                            TimeRow(day: "الأحد - الأربعاء", time: "3:30 م - 12:00 ص")
                            TimeRow(day: "الخميس - الجمعة", time: "3:30 م - 1:00 ص")
                        }
                        .padding().background(Color.white).cornerRadius(15).padding(.horizontal).shadow(radius: 2)
                        
                        // --- قسم التواصل (الجديد) ---
                        VStack(spacing: 15) {
                            Text("تواصل معنا")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 15) {
                                // زر واتساب
                                SocialButton(url: whatsappURL, icon: "phone.circle.fill", color: .green, text: "WhatsApp")
                                // زر سناب
                                SocialButton(url: snapchatURL, icon: "camera.circle.fill", color: .yellow, text: "Snapchat")
                            }
                            // زر تيك توك
                            SocialButton(url: tiktokURL, icon: "play.circle.fill", color: .black, text: "TikTok")
                        }
                        .padding()
                        
                        // زر الموقع
                        Link(destination: locationURL) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("مـوقـع الجسـر (الخريطة)")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .onAppear { weatherManager.fetchWeather() }
            .navigationBarHidden(true)
        }
    }
}

// --- تصميم الأزرار ---
struct SocialButton: View {
    let url: URL
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        Link(destination: url) {
            HStack {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(text)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(color == .yellow ? .black : .white) // لون النص أسود للسناب
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

struct InfoRow: View {
    let icon: String, title: String, value: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.green)
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.bold)
        }
    }
}

struct TimeRow: View {
    let day: String, time: String
    var body: some View {
        HStack {
            Text(day).font(.subheadline)
            Spacer()
            Text(time).font(.subheadline).bold().foregroundColor(.blue)
        }
    }
}
extension Color {
    static let skyBlue = Color(red: 0.6, green: 0.8, blue: 1.0)
}

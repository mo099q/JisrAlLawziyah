import SwiftUI
import Foundation

// --- نموذج بيانات الطقس (لجلب البيانات من الإنترنت) ---
struct WeatherResponse: Codable {
    let current_weather: CurrentWeather
}
struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
}

// --- الكلاس المسؤول عن جلب الطقس ---
class WeatherManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var icon: String = "cloud"
    
    func fetchWeather() {
        // إحداثيات الشفا، الطائف
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.06&longitude=40.36&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode(WeatherResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.temperature = "\(Int(decoded.current_weather.temperature))°C"
                    // تحديد الأيقونة بناءً على الكود ببساطة
                    self.icon = decoded.current_weather.temperature > 25 ? "sun.max.fill" : "cloud.fog.fill"
                }
            }
        }.resume()
    }
}

// --- نقطة انطلاق التطبيق ---
@main
struct JisrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// --- واجهة المستخدم الرئيسية ---
struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    
    // رابط الموقع الصحيح (بحث مباشر في الخرائط)
    let mapsURL = URL(string: "https://www.google.com/maps/search/?api=1&query=Jisr+Al-Lawziyah+Taif")!
    
    var body: some View {
        NavigationView {
            ZStack {
                // خلفية متدرجة توحي بالطبيعة والضباب
                LinearGradient(gradient: Gradient(colors: [Color("SkyBlue"), Color.white]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 1. صورة الهيدر
                        Image(systemName: "mountain.2.fill") // صورة تعبيرية حتى يتم وضع صور حقيقية
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .foregroundColor(.gray)
                            .padding(.top)
                        
                        Text("جسر اللوزية")
                            .font(.system(size: 35, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        // 2. بطاقة الطقس (ميزة جديدة)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("طقس الشفا الآن")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(weatherManager.temperature)
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Image(systemName: weatherManager.icon)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .shadow(radius: 3)
                        
                        // 3. بطاقة المعلومات (السعر والاوقات)
                        VStack(alignment: .leading, spacing: 15) {
                            InfoRow(icon: "ticket.fill", title: "سعر الدخول", value: "مجاني (بدون تذكرة)")
                            
                            Divider()
                            
                            Text("أوقات العمل")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            TimeRow(day: "الأحد - الأربعاء", time: "3:30 م - 12:00 ص")
                            TimeRow(day: "الخميس - الجمعة", time: "3:30 م - 1:00 ص")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .shadow(radius: 3)
                        
                        // 4. زر الموقع
                        Link(destination: mapsURL) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("افتـح المـوقـع في Google Maps")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)

                        Spacer()
                        Text("تحديث البيانات تلقائي - LEX-Q")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                    }
                }
            }
            .onAppear {
                weatherManager.fetchWeather()
            }
            .navigationBarHidden(true)
        }
        // تعريف لون مخصص (اختياري لكي لا يحدث خطأ)
    }
}

// --- مكونات التصميم الفرعية ---
struct InfoRow: View {
    let icon: String, title: String, value: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.green).frame(width: 25)
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

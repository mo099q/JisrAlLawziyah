import SwiftUI
import MapKit
import CoreLocation
import Foundation

// --- 1. نماذج البيانات ---
struct WeatherResponse: Codable { let current_weather: CurrentWeather }
struct CurrentWeather: Codable { let temperature: Double; let weathercode: Int }

struct LocationPoint: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct Review: Identifiable {
    let id = UUID()
    let name: String
    let comment: String
    let stars: Int
}

// --- 2. مدير الطقس ---
class WeatherManager: ObservableObject {
    @Published var temperature: String = "..."
    @Published var icon: String = "cloud.fill"
    
    func fetchWeather() {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.0641&longitude=40.3603&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let decoded = try? JSONDecoder().decode(WeatherResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.temperature = "\(Int(decoded.current_weather.temperature))°C"
                self.icon = decoded.current_weather.temperature > 25 ? "sun.max.fill" : "cloud.fog.fill"
            }
        }.resume()
    }
}

// --- 3. مدير الموقع ---
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var distanceText: String = "حساب المسافة..."
    
    // إحداثيات الجسر
    let targetLocation = CLLocation(latitude: 21.0641, longitude: 40.3603)
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let distanceInMeters = location.distance(from: targetLocation)
        let distanceInKm = distanceInMeters / 1000
        
        DispatchQueue.main.async {
            if distanceInKm < 1.0 {
                self.distanceText = "أنت في الموقع"
            } else {
                self.distanceText = String(format: "يبعد %.1f كم", distanceInKm)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
    }
}

// --- 4. التطبيق الرئيسي ---
@main
struct JisrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

// --- 5. الواجهة ---
struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.0641, longitude: 40.3603),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let locations = [LocationPoint(name: "جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.0641, longitude: 40.3603))]
    
    // متغيرات الحجز
    @State private var guestName = ""
    @State private var guestCount = ""
    @State private var bookingDate = Date()
    
    // بيانات العرض
    let reviews = [
        Review(name: "عبدالله", comment: "مكان جميل جداً", stars: 5),
        Review(name: "سارة", comment: "القهوة ممتازة", stars: 5),
        Review(name: "فهد", comment: "يستحق الزيارة", stars: 4)
    ]
    
    let galleryImages = [
        "https://i.imgur.com/8d9wXgD.jpeg",
        "https://i.imgur.com/Pj5s4Zc.jpeg",
        "https://i.imgur.com/Lq8y6kE.jpeg"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // الصور
                        TabView {
                            ForEach(galleryImages, id: \.self) { imgURL in
                                AsyncImage(url: URL(string: imgURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.gray.opacity(0.3)
                                    }
                                }
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(PageTabViewStyle())
                        .overlay(Text("جسر اللوزية").font(.largeTitle).bold().foregroundColor(.white).padding(), alignment: .bottomTrailing)
                        
                        // المعلومات
                        HStack(spacing: 15) {
                            StatusBox(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            StatusBox(icon: "location.fill", title: "المسافة", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        
                        // الحجز (خلفية داكنة للكتابة)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("احجز جلستك الآن").font(.headline).foregroundColor(.white)
                            
                            TextField("الاسم", text: $guestName)
                                .padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                            
                            TextField("العدد", text: $guestCount)
                                .padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                                .keyboardType(.numberPad)
                            
                            DatePicker("الوقت", selection: $bookingDate).colorScheme(.dark)
                            
                            Button(action: sendBooking) {
                                Text("تأكيد الحجز (واتساب)")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.3))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // الخريطة
                        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { loc in
                            MapMarker(coordinate: loc.coordinate, tint: .red)
                        }
                        .frame(height: 200)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // التواصل
                        HStack(spacing: 20) {
                            SocialBtn(icon: "phone.circle.fill", color: .green, url: "https://wa.me/966549949745")
                            SocialBtn(icon: "camera.circle.fill", color: .yellow, url: "https://www.snapchat.com/add/jsrlawzia")
                            SocialBtn(icon: "play.circle.fill", color: .white, url: "https://www.tiktok.com/@jsrlawzia")
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .onAppear { weatherManager.fetchWeather() }
            .navigationBarHidden(true)
        }
    }
    
    func sendBooking() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let msg = "مرحباً، أريد حجز: الاسم \(guestName)، العدد \(guestCount)، الوقت \(formatter.string(from: bookingDate))"
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/966549949745?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

struct StatusBox: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).foregroundColor(color).font(.title2)
            Text(value).bold().foregroundColor(.white)
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(10)
    }
}

struct SocialBtn: View {
    let icon: String, color: Color, url: String
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                Image(systemName: icon).resizable().frame(width: 45, height: 45).foregroundColor(color)
            }
        }
    }
}

import SwiftUI
import MapKit
import CoreLocation

// --- نماذج البيانات ---
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

// --- 1. مدير الطقس ---
class WeatherManager: ObservableObject {
    @Published var temperature: String = "..."
    @Published var icon: String = "cloud.fill"
    
    func fetchWeather() {
        // إحداثيات جسر اللوزية
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.0647&longitude=40.3612&current_weather=true"
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

// --- 2. مدير الموقع والمسافة ---
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var distanceText: String = "حساب المسافة..."
    
    // 📍 الإحداثيات الدقيقة المستخرجة من الكود 48C9+XJW
    let targetCoordinate = CLLocationCoordinate2D(latitude: 21.0647, longitude: 40.3612)
    
    var targetLocation: CLLocation {
        CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
    }
    
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
            if distanceInKm < 0.3 {
                self.distanceText = "وصلت للموقع 📍"
            } else {
                self.distanceText = String(format: "يبعد %.1f كم", distanceInKm)
            }
        }
    }
}

@main
struct JisrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // الوضع الليلي
        }
    }
}

// --- 3. الواجهة الرئيسية ---
struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    // إحداثيات الخريطة الداخلية
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.0647, longitude: 40.3612),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    let locations = [LocationPoint(name: "جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.0647, longitude: 40.3612))]
    
    // متغيرات الحجز
    @State private var guestName = ""
    @State private var guestCount = ""
    @State private var bookingDate = Date()
    
    // صور المعرض
    let galleryImages = [
        "https://i.imgur.com/8d9wXgD.jpeg",
        "https://i.imgur.com/Pj5s4Zc.jpeg",
        "https://i.imgur.com/Lq8y6kE.jpeg"
    ]
    
    // رابط التوجيه المباشر
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=21.0647,40.3612")!

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // --- 1. السلايدر ---
                        TabView {
                            ForEach(galleryImages, id: \.self) { imgURL in
                                AsyncImage(url: URL(string: imgURL)) { phase in
                                    if let image = phase.image { image.resizable().scaledToFill() }
                                    else { Color.gray.opacity(0.2) }
                                }
                            }
                        }
                        .frame(height: 280)
                        .tabViewStyle(PageTabViewStyle())
                        .overlay(
                            LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                        )
                        .overlay(
                            Text("جسر اللوزية")
                                .font(.system(size: 35, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .padding(),
                            alignment: .bottomTrailing
                        )
                        
                        // --- 2. المعلومات ---
                        HStack(spacing: 15) {
                            StatusBox(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            StatusBox(icon: "location.fill", title: "المسافة", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        
                        // --- 3. زر التوجيه (قوقل ماب) ---
                        Link(destination: googleMapsLink) {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.title2)
                                Text("اتجه للموقع الآن (Google Maps)")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        
                        // --- 4. الحجز ---
                        VStack(alignment: .leading, spacing: 15) {
                            Text("احجز جلستك").font(.headline).foregroundColor(.white)
                            
                            TextField("الاسم", text: $guestName)
                                .padding().background(Color.white).foregroundColor(.black).cornerRadius(12)
                            
                            TextField("العدد", text: $guestCount)
                                .keyboardType(.numberPad)
                                .padding().background(Color.white).foregroundColor(.black).cornerRadius(12)
                            
                            HStack {
                                Text("الوقت").foregroundColor(.gray)
                                Spacer()
                                DatePicker("", selection: $bookingDate).labelsHidden().colorScheme(.dark)
                            }
                            
                            Button(action: sendBooking) {
                                Text("إرسال الحجز (واتساب)")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // --- 5. الخريطة الداخلية ---
                        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { loc in
                            MapMarker(coordinate: loc.coordinate, tint: .red)
                        }
                        .frame(height: 200)
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2)))
                        .padding(.horizontal)
                        
                        // --- 6. التواصل (الصور الصحيحة) ---
                        Text("تواصل معنا")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 30) {
                            // واتساب (صورة رسمية)
                            SocialLogo(
                                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1024px-WhatsApp.svg.png",
                                url: "https://wa.me/966549949745"
                            )
                            
                            // سناب شات (صورة رسمية)
                            SocialLogo(
                                imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/c/c4/Snapchat_logo.svg/1024px-Snapchat_logo.svg.png",
                                url: "https://www.snapchat.com/add/jsrlawzia"
                            )
                            
                            // تيك توك (صورة رسمية)
                            SocialLogo(
                                imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a9/TikTok_logo.svg/1024px-TikTok_logo.svg.png",
                                url: "https://www.tiktok.com/@jsrlawzia"
                            )
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
        let msg = "مرحباً، حجز جديد:\nالاسم: \(guestName)\nالعدد: \(guestCount)\nالوقت: \(formatter.string(from: bookingDate))"
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/966549949745?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// --- مكونات التصميم ---

struct SocialLogo: View {
    let imageURL: String
    let url: String
    
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .scaledToFit()
                             .frame(width: 55, height: 55)
                             // خلفية بيضاء خفيفة لبروز الشعار إذا لزم الأمر
                             .background(Color.white)
                             .clipShape(RoundedRectangle(cornerRadius: 12))
                             .shadow(color: .white.opacity(0.2), radius: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 55, height: 55)
                    }
                }
            }
        }
    }
}

struct StatusBox: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).bold().foregroundColor(.white)
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color(UIColor.systemGray6).opacity(0.2)).cornerRadius(15)
    }
}

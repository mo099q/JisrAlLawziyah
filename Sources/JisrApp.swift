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

struct GamePackage: Identifiable {
    let id = UUID()
    let pay: String
    let get: String
    let color: Color
}

// --- 1. مدير الطقس ---
class WeatherManager: ObservableObject {
    @Published var temperature: String = "..."
    @Published var icon: String = "cloud.fill"
    
    func fetchWeather() {
        // الإحداثيات الجديدة الصحيحة
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.1224&longitude=40.3190&current_weather=true"
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
    
    // 📍 الإحداثيات الجديدة (21.1224671, 40.3190809)
    let targetCoordinate = CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809)
    
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
            if distanceInKm < 0.5 {
                self.distanceText = "أنت في المنتجع 📍"
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
                .preferredColorScheme(.dark)
        }
    }
}

// --- 3. الواجهة الرئيسية ---
struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    // إعدادات الخريطة (محدثة)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    let locations = [LocationPoint(name: "منتجع جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809))]
    
    // بكجات الألعاب (المعلومات التي حفظناها)
    let packages = [
        GamePackage(pay: "100", get: "110", color: .purple),
        GamePackage(pay: "200", get: "230", color: .blue),
        GamePackage(pay: "300", get: "350", color: .orange),
        GamePackage(pay: "500", get: "600", color: .green),
        GamePackage(pay: "750", get: "1000", color: .red) // العرض الأقوى
    ]
    
    // صور المعرض
    let galleryImages = [
        "https://i.imgur.com/8d9wXgD.jpeg",
        "https://i.imgur.com/Pj5s4Zc.jpeg",
        "https://i.imgur.com/Lq8y6kE.jpeg"
    ]
    
    // رابط جوجل ماب للإحداثيات الجديدة
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=21.1224671,40.3190809")!

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // --- 1. الهيدر والسلايدر ---
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
                        .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                        .overlay(
                            VStack(alignment: .leading) {
                                Text("منتجع جسر اللوزية")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("مطاعم • كافيهات • ألعاب • إطلالة")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(),
                            alignment: .bottomLeading
                        )
                        
                        // --- 2. حالة الطقس والمسافة ---
                        HStack(spacing: 15) {
                            StatusBox(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            StatusBox(icon: "location.fill", title: "المسافة", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        
                        // --- 3. أسعار الدخول (جديد) ---
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "ticket.fill").foregroundColor(.yellow)
                                Text("تذاكر الدخول").font(.headline).foregroundColor(.white)
                                Spacer()
                            }
                            
                            HStack {
                                Text("سعر التذكرة للفرد")
                                Spacer()
                                Text("15 ريال").bold().foregroundColor(.yellow)
                            }
                            Divider().background(Color.gray)
                            HStack {
                                Text("الدخول المجاني")
                                Spacer()
                                Text("أطفال < سنتين + ذوي الهمم").font(.caption).foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // --- 4. بكجات الألعاب (جديد) ---
                        VStack(alignment: .leading) {
                            Text("🎉 عروض شحن الرصيد (الألعاب)").font(.headline).foregroundColor(.white).padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(packages) { pkg in
                                        VStack {
                                            Text("ادفع").font(.caption2).foregroundColor(.white.opacity(0.7))
                                            Text(pkg.pay).font(.title).bold().foregroundColor(.white)
                                            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
                                            Text("تحصل على").font(.caption2).foregroundColor(.white.opacity(0.7))
                                            Text(pkg.get).font(.title2).bold().foregroundColor(.white)
                                        }
                                        .frame(width: 100, height: 120)
                                        .background(pkg.color.opacity(0.8))
                                        .cornerRadius(15)
                                        .shadow(radius: 5)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // --- 5. مرافق المنتجع ---
                        VStack(alignment: .leading, spacing: 15) {
                            Text("🏰 مرافق المنتجع").font(.headline).foregroundColor(.white).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    FacilityCard(icon: "fork.knife", title: "مطاعم متنوعة")
                                    FacilityCard(icon: "cup.and.saucer.fill", title: "كافيهات")
                                    FacilityCard(icon: "gamecontroller.fill", title: "صالة ألعاب")
                                    FacilityCard(icon: "camera.macro", title: "الجسر المطل")
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // --- 6. التوجيه والخريطة ---
                        VStack(spacing: 15) {
                            Link(destination: googleMapsLink) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("اتجه للموقع (خرائط جوجل)")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            
                            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { loc in
                                MapMarker(coordinate: loc.coordinate, tint: .red)
                            }
                            .frame(height: 200)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2)))
                        }
                        .padding(.horizontal)
                        
                        // --- 7. التواصل ---
                        Text("تواصل معنا").font(.headline).foregroundColor(.gray)
                        HStack(spacing: 30) {
                            SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1024px-WhatsApp.svg.png", url: "https://wa.me/966549949745")
                            SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/c/c4/Snapchat_logo.svg/1024px-Snapchat_logo.svg.png", url: "https://www.snapchat.com/add/jsrlawzia")
                            SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a9/TikTok_logo.svg/1024px-TikTok_logo.svg.png", url: "https://www.tiktok.com/@jsrlawzia")
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .onAppear { weatherManager.fetchWeather() }
            .navigationBarHidden(true)
        }
    }
}

// --- مكونات التصميم ---

struct FacilityCard: View {
    let icon: String, title: String
    var body: some View {
        VStack {
            Image(systemName: icon).font(.largeTitle).foregroundColor(.white)
            Text(title).font(.caption).bold().foregroundColor(.white)
        }
        .frame(width: 100, height: 90)
        .background(Color(UIColor.systemGray6).opacity(0.3))
        .cornerRadius(15)
    }
}

struct SocialLogo: View {
    let imageURL: String, url: String
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit().frame(width: 55, height: 55)
                             .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).frame(width: 55, height: 55)
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

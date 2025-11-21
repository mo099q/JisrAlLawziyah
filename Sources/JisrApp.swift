import SwiftUI
import MapKit
import CoreLocation
import Foundation

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

// --- مدير الطقس ---
class WeatherManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var icon: String = "cloud"
    
    func fetchWeather() {
        // إحداثيات الشفا الدقيقة
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.0635&longitude=40.3589&current_weather=true"
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

// --- مدير الموقع والمسافة (جديد) ---
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var distanceText: String = "حساب المسافة..."
    
    // إحداثيات جسر اللوزية
    let targetLocation = CLLocation(latitude: 21.0635, longitude: 40.3589)
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization() // طلب الإذن
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        // حساب المسافة بالكيلومتر
        let distanceInMeters = userLocation.distance(from: targetLocation)
        let distanceInKm = distanceInMeters / 1000
        
        DispatchQueue.main.async {
            self.distanceText = String(format: "يبعد %.1f كم", distanceInKm)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("خطأ في تحديد الموقع: \(error.localizedDescription)")
        DispatchQueue.main.async { self.distanceText = "الموقع غير متاح" }
    }
}

@main
struct JisrApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager() // تفعيل مدير الموقع
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.0635, longitude: 40.3589),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    let locations = [LocationPoint(name: "جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.0635, longitude: 40.3589))]
    
    // متغيرات الحجز
    @State private var guestName = ""
    @State private var guestCount = ""
    @State private var bookingDate = Date()
    
    // آراء الزوار
    let reviews = [
        Review(name: "محمد العمري", comment: "المكان رائع جداً والأجواء خيالية وسط الضباب.", stars: 5),
        Review(name: "سارة فهد", comment: "القهوة ممتازة، أنصح بزيارته وقت العصر للاستمتاع بالغروب.", stars: 5),
        Review(name: "خالد", comment: "تجربة الجسر المعلق كانت ممتعة وفريدة من نوعها.", stars: 4)
    ]
    
    let galleryImages = [
        "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80",
        "https://images.unsplash.com/photo-1519681393784-d8e5b56524dd?w=800&q=80",
        "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // السلايدر
                        TabView {
                            ForEach(galleryImages, id: \.self) { imgURL in
                                AsyncImage(url: URL(string: imgURL)) { phase in
                                    if let image = phase.image { image.resizable().scaledToFill() }
                                    else { Color.gray.opacity(0.3) }
                                }
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(PageTabViewStyle())
                        .overlay(Text("جسر اللوزية").font(.largeTitle).bold().foregroundColor(.white).shadow(radius: 5).padding(), alignment: .bottomTrailing)
                        
                        // البطاقات (الطقس + المسافة)
                        HStack(spacing: 15) {
                            StatusCard(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            // هنا تظهر المسافة تلقائياً
                            StatusCard(icon: "location.fill", title: "المسافة منك", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        
                        // قسم الحجز
                        VStack(alignment: .leading, spacing: 15) {
                            HStack { Image(systemName: "calendar.badge.plus"); Text("حجز جلسة / كوخ").font(.headline) }
                            
                            TextField("الاسم الكريم", text: $guestName)
                                .padding().background(Color.white).cornerRadius(10)
                            
                            TextField("عدد الأشخاص", text: $guestCount)
                                .keyboardType(.numberPad)
                                .padding().background(Color.white).cornerRadius(10)
                            
                            DatePicker("وقت الوصول", selection: $bookingDate, displayedComponents: [.date, .hourAndMinute])
                                .environment(\.locale, Locale(identifier: "ar_SA")) // تعريب التاريخ
                                .padding(5)
                            
                            Button(action: sendWhatsAppBooking) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("إرسال طلب الحجز (واتساب)")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // الخريطة
                        VStack(alignment: .leading) {
                            Text("📍 موقعنا على الخريطة").font(.headline).padding(.horizontal)
                            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { location in
                                MapMarker(coordinate: location.coordinate, tint: .red)
                            }
                            .frame(height: 200)
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                        
                        // الآراء
                        VStack(alignment: .leading) {
                            Text("⭐️ آراء الزوار").font(.headline).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(reviews) { review in
                                        ReviewCard(review: review)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // التواصل
                        HStack {
                            SocialLink(icon: "phone.circle.fill", color: .green, url: "https://wa.me/966549949745")
                            SocialLink(icon: "camera.circle.fill", color: .yellow, url: "https://www.snapchat.com/add/jsrlawzia")
                            SocialLink(icon: "play.circle.fill", color: .black, url: "https://www.tiktok.com/@jsrlawzia")
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .onAppear { weatherManager.fetchWeather() }
            .navigationBarHidden(true)
        }
    }
    
    func sendWhatsAppBooking() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "ar_SA")
        let dateStr = formatter.string(from: bookingDate)
        
        let message = """
        مرحباً إدارة جسر اللوزية، أرغب بحجز:
        👤 الاسم: \(guestName)
        👥 العدد: \(guestCount)
        📅 الوقت: \(dateStr)
        """
        
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://wa.me/966549949745?text=\(encodedMessage)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// --- المكونات ---
struct StatusCard: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(.system(size: 16, weight: .bold)).lineLimit(1).minimumScaleFactor(0.5)
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(15)
    }
}

struct ReviewCard: View {
    let review: Review
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.name).bold().font(.caption)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<review.stars, id: \.self) { _ in
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
                    }
                }
            }
            Text(review.comment)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(width: 200, height: 100)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SocialLink: View {
    let icon: String, color: Color, url: String
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(color)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
        }
    }
}

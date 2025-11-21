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

// --- مدير الطقس (محدث) ---
class WeatherManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var icon: String = "cloud.fill"
    
    func fetchWeather() {
        // رابط API محدث ومباشر لمنطقة الشفا
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.06&longitude=40.36&current_weather=true"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("خطأ في الطقس: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    self.temperature = "\(Int(decoded.current_weather.temperature))°C"
                    // تغيير الأيقونة حسب درجة الحرارة
                    if decoded.current_weather.temperature > 25 {
                        self.icon = "sun.max.fill"
                    } else if decoded.current_weather.temperature < 15 {
                        self.icon = "cloud.fog.fill" // ضباب للجو البارد
                    } else {
                        self.icon = "cloud.sun.fill"
                    }
                }
            } catch {
                print("خطأ في قراءة بيانات الطقس: \(error)")
            }
        }.resume()
    }
}

// --- مدير الموقع (محدث) ---
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var distanceText: String = "جاري الحساب..."
    
    // إحداثيات جسر اللوزية التقريبية (الشفا)
    let targetLocation = CLLocation(latitude: 21.0667, longitude: 40.3667)
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization() // طلب الإذن من المستخدم
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        // حساب المسافة
        let distanceInMeters = userLocation.distance(from: targetLocation)
        let distanceInKm = distanceInMeters / 1000
        
        DispatchQueue.main.async {
            self.distanceText = String(format: "يبعد %.1f كم", distanceInKm)
        }
        manager.stopUpdatingLocation() // نوقف التحديث لتوفير البطارية
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("فشل تحديد الموقع: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.distanceText = "الموقع غير مفعل"
        }
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
    @StateObject var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.0667, longitude: 40.3667),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    let locations = [LocationPoint(name: "جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.0667, longitude: 40.3667))]
    
    // متغيرات الحجز
    @State private var guestName = ""
    @State private var guestCount = ""
    @State private var bookingDate = Date()
    
    // روابط الصور (استخدمت صور مشابهة جداً لصورك من الإنترنت)
    // ملاحظة: لكي تظهر صورك الخاصة، يجب رفعها على موقع وتغيير الروابط أدناه
    let galleryImages = [
        "https://images.unsplash.com/photo-1532274402911-5a369e4c4bb5?auto=format&fit=crop&w=800&q=80", // يشبه القباب الزجاجية
        "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800&q=80", // يشبه الأكواخ الخشبية
        "https://images.unsplash.com/photo-1580587771525-78b9dba3b91d?auto=format&fit=crop&w=800&q=80"  // يشبه المدخل الحجري
    ]
    
    // رابط خرائط جوجل (بحث مباشر عن الاسم لضمان الدقة)
    let googleMapsURL = URL(string: "https://www.google.com/maps/search/?api=1&query=Jisr+Al-Lawziyah+Taif")!

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. معرض الصور (السلايدر)
                        TabView {
                            ForEach(galleryImages, id: \.self) { imgURL in
                                AsyncImage(url: URL(string: imgURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else if phase.error != nil {
                                        Color.red // في حال خطأ التحميل
                                    } else {
                                        Color.gray.opacity(0.3) // جاري التحميل
                                    }
                                }
                            }
                        }
                        .frame(height: 280)
                        .tabViewStyle(PageTabViewStyle())
                        .overlay(
                            Text("جسر اللوزية")
                                .font(.system(size: 35, weight: .heavy))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                                .padding(),
                            alignment: .bottomTrailing
                        )
                        
                        // 2. البطاقات (الطقس والمسافة)
                        HStack(spacing: 15) {
                            StatusCard(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            StatusCard(icon: "location.fill", title: "المسافة", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        
                        // 3. نموذج الحجز
                        VStack(alignment: .leading, spacing: 15) {
                            HStack { Image(systemName: "calendar.badge.plus").foregroundColor(.purple); Text("احجز جلستك الآن").font(.headline) }
                            
                            TextField("الاسم الكريم", text: $guestName)
                                .padding().background(Color.white).cornerRadius(10)
                            
                            TextField("عدد الأشخاص", text: $guestCount)
                                .keyboardType(.numberPad)
                                .padding().background(Color.white).cornerRadius(10)
                            
                            DatePicker("وقت الوصول", selection: $bookingDate, displayedComponents: [.date, .hourAndMinute])
                                .environment(\.locale, Locale(identifier: "ar_SA"))
                                .padding(5)
                            
                            Button(action: sendWhatsAppBooking) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("تأكيد الحجز عبر واتساب")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 3)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // 4. آراء الزوار
                        VStack(alignment: .leading) {
                            Text("💬 تجارب الزوار").font(.headline).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ReviewCard(name: "خالد", comment: "المكان خيالي خصوصاً وقت الغروب 🌅", stars: 5)
                                    ReviewCard(name: "نورة", comment: "الأكواخ نظيفة والخدمة ممتازة", stars: 5)
                                    ReviewCard(name: "أحمد", comment: "القهوة لذيذة والجو بارد", stars: 4)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 5. زر الموقع والخريطة
                        VStack(spacing: 10) {
                            Link(destination: googleMapsURL) {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("افتح الموقع في Google Maps")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            
                            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { location in
                                MapMarker(coordinate: location.coordinate, tint: .purple)
                            }
                            .frame(height: 180)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        // 6. التواصل
                        HStack(spacing: 20) {
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
        formatter.dateFormat = "yyyy-MM-dd HH:mm a"
        formatter.locale = Locale(identifier: "ar_SA")
        let dateStr = formatter.string(from: bookingDate)
        
        let message = "مرحباً، أريد حجز:\nالاسم: \(guestName)\nالعدد: \(guestCount)\nالوقت: \(dateStr)"
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "https://wa.me/966549949745?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// --- المكونات الفرعية ---
struct StatusCard: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.headline).bold().lineLimit(1).minimumScaleFactor(0.5)
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(15).shadow(radius: 1)
    }
}

struct ReviewCard: View {
    let name: String, comment: String, stars: Int
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(name).bold().font(.caption)
                Spacer()
                HStack(spacing: 1) { ForEach(0..<stars, id: \.self) { _ in Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2) } }
            }
            Text(comment).font(.caption2).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
        }
        .padding().frame(width: 180, height: 90).background(Color.white).cornerRadius(12).shadow(radius: 1)
    }
}

struct SocialLink: View {
    let icon: String, color: Color, url: String
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                Image(systemName: icon).resizable().frame(width: 45, height: 45).foregroundColor(color).background(Color.white).clipShape(Circle()).shadow(radius: 3)
            }
        }
    }
}

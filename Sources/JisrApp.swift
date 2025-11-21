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
    @Published var temperature: String = "جاري التحميل..."
    @Published var icon: String = "cloud.fill"
    
    func fetchWeather() {
        // إحداثيات دقيقة لجسر اللوزية - الشفا
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.0641&longitude=40.3603&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let decoded = try? JSONDecoder().decode(WeatherResponse.self, from: data) else {
                DispatchQueue.main.async { self.temperature = "غير متاح" }
                return
            }
            DispatchQueue.main.async {
                self.temperature = "\(Int(decoded.current_weather.temperature))°C"
                self.icon = decoded.current_weather.temperature > 25 ? "sun.max.fill" : "cloud.fog.fill"
            }
        }.resume()
    }
}

// --- مدير الموقع والمسافة ---
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var distanceText: String = "حساب المسافة..."
    @Published var userLocation: CLLocation? = nil // نحتفظ بموقع المستخدم للخريطة
    
    // الإحداثيات الدقيقة الجديدة للموقع
    let targetLocationCoordinate = CLLocationCoordinate2D(latitude: 21.0641, longitude: 40.3603)
    var targetLocation: CLLocation {
        CLLocation(latitude: targetLocationCoordinate.latitude, longitude: targetLocationCoordinate.longitude)
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // طلب الإذن مهم جداً لظهور المسافة
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
        
        // حساب المسافة
        let distanceInMeters = location.distance(from: targetLocation)
        let distanceInKm = distanceInMeters / 1000
        
        DispatchQueue.main.async {
            if distanceInKm < 1.0 {
                 self.distanceText = String(format: "قريب جداً (%.0f متر)", distanceInMeters)
            } else {
                 self.distanceText = String(format: "يبعد %.1f كم", distanceInKm)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("خطأ في الموقع: \(error.localizedDescription)")
        DispatchQueue.main.async { self.distanceText = "يرجى تفعيل الموقع" }
    }
}

@main
struct JisrApp: App {
    // تفعيل الوضع الداكن للتطبيق بالكامل
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    // إعدادات الخريطة
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.0641, longitude: 40.3603),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    // نقطة الجسر على الخريطة
    let locations = [LocationPoint(name: "جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.0641, longitude: 40.3603))]
    
    // متغيرات الحجز
    @State private var guestName = ""
    @State private var guestCount = ""
    @State private var bookingDate = Date()
    
    // آراء الزوار
    let reviews = [
        Review(name: "عبدالله الشهري", comment: "مكان جميل جداً والأجواء باردة، يستحق الزيارة.", stars: 5),
        Review(name: "أم ريان", comment: "تجربة الجسر ممتعة للأطفال والكبار، والقهوة لذيذة.", stars: 5),
        Review(name: "فهد", comment: "من أفضل الأماكن في الشفا، انصح بالذهاب وقت الغروب.", stars: 4)
    ]
    
    // روابط الصور المباشرة (تم استخراجها من ألبومك)
    let galleryImages = [
        "https://i.imgur.com/8d9wXgD.jpeg", // صورة الجسر
        "https://i.imgur.com/Pj5s4Zc.jpeg", // صورة ليلية
        "https://i.imgur.com/Lq8y6kE.jpeg"  // صورة نهارية
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // خلفية سوداء للتطبيق
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. سلايدر الصور (تم إصلاحه)
                        TabView {
                            ForEach(galleryImages, id: \.self) { imgURL in
                                AsyncImage(url: URL(string: imgURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else if phase.error != nil {
                                        Color.red // لون أحمر في حال خطأ التحميل
                                    } else {
                                        ZStack {
                                            Color.gray.opacity(0.3)
                                            ProgressView() // مؤشر تحميل
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 280)
                        .tabViewStyle(PageTabViewStyle())
                        .overlay(
                            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(
                            Text("جسر اللوزية")
                                .font(.system(size: 40, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(),
                            alignment: .bottomTrailing
                        )
                        
                        // 2. البطاقات (تظهر المعلومات تلقائياً)
                        HStack(spacing: 15) {
                            StatusCard(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            StatusCard(icon: "location.fill", title: "المسافة منك", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        
                        // 3. قسم الحجز (تم تعديل الألوان للوضوح)
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(.purple)
                                Text("احجز جلستك الآن")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            // حقل الاسم
                            TextField("الاسم الكريم", text: $guestName)
                                .padding()
                                .background(Color.white) // خلفية بيضاء للحقل
                                .foregroundColor(.black) // نص أسود داخل الحقل
                                .cornerRadius(12)
                            
                            // حقل العدد
                            TextField("عدد الأشخاص", text: $guestCount)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            
                            // اختيار الوقت
                            HStack {
                                Text("وقت الوصول")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                DatePicker("", selection: $bookingDate, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .colorScheme(.dark) // جعل منتقي التاريخ داكناً
                                    .accentColor(.purple)
                            }
                            .padding(.vertical, 5)
                            
                            // زر الإرسال
                            Button(action: sendWhatsAppBooking) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("تأكيد الحجز عبر واتساب")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                            }
                        }
                        .padding(20)
                        // *** هنا التغيير المهم للخلفية ***
                        .background(Color(UIColor.systemGray6).opacity(0.15)) // خلفية رمادية داكنة جداً وشفافة
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1) // إطار خفيف
                        )
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // 4. الخريطة
                        VStack(alignment: .leading) {
                            Text("📍 الموقع").font(.headline).foregroundColor(.white).padding(.horizontal)
                            
                            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { location in
                                MapMarker(coordinate: location.coordinate, tint: .red)
                            }
                            .frame(height: 200)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2)))
                            .padding(.horizontal)
                        }
                        
                        // 5. آراء الزوار
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("تجارب الزوار")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(reviews) { review in
                                        ReviewCard(review: review)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                        }
                        
                        // 6. التواصل
                        HStack(spacing: 25) {
                            SocialLink(icon: "phone.fill", color: .green, url: "https://wa.me/966549949745")
                            SocialLink(icon: "camera.fill", color: .yellow, url: "https://www.snapchat.com/add/jsrlawzia")
                            SocialLink(icon: "play.fill", color: .white, bgColor: .black, url: "https://www.tiktok.com/@jsrlawzia")
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .onAppear { weatherManager.fetchWeather() }
            .navigationBarHidden(true)
        }
    }
    
    // دالة إرسال واتساب
    func sendWhatsAppBooking() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm a"
        formatter.locale = Locale(identifier: "ar_SA")
        let dateStr = formatter.string(from: bookingDate)
        
        let message = """
        *طلب حجز جديد - جسر اللوزية* 🌉
        
        👤 الاسم: \(guestName)
        👥 العدد: \(guestCount)
        📅 الوقت: \(dateStr)
        
        يرجى تأكيد الحجز. شكراً!
        """
        
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://wa.me/966549949745?text=\(encodedMessage)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// --- المكونات الفرعية للتصميم ---

// بطاقة الحالة (طقس/مسافة)
struct StatusCard: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(height: 40)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(UIColor.systemGray6).opacity(0.15)) // خلفية داكنة
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// بطاقة التقييم
struct ReviewCard: View {
    let review: Review
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(review.name)
                    .bold()
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: "star.fill")
                            .foregroundColor(index < review.stars ? .yellow : .gray.opacity(0.3))
                            .font(.caption2)
                    }
                }
            }
            Text(review.comment)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
        .padding(15)
        .frame(width: 220)
        .background(Color(UIColor.systemGray6).opacity(0.15))
        .cornerRadius(15)
        .overlay(
             RoundedRectangle(cornerRadius: 15)
                 .stroke(Color.white.opacity(0.1), lineWidth: 1)
         )
    }
}

// زر التواصل الاجتماعي
struct SocialLink: View {
    let icon: String, color: Color, url: String
    var bgColor: Color = .white
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                ZStack {
                    Circle()
                        .fill(bgColor)
                        .frame(width: 55, height: 55)
                        .shadow(color: color.opacity(0.5), radius: 5)
                    
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(color)
                }
            }
        }
    }
}

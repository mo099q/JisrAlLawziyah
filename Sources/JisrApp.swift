import SwiftUI
import MapKit
import CoreLocation

// ==========================================
// MARK: - 1. نماذج البيانات (DATA MODELS)
// ==========================================

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

// نموذج أنواع الجلسات للحجز
struct SessionType: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let features: String
    let imageURL: String
}

// ==========================================
// MARK: - 2. المدراء (MANAGERS)
// ==========================================

class WeatherManager: ObservableObject {
    @Published var temperature: String = "..."
    @Published var icon: String = "cloud.fill"
    
    func fetchWeather() {
        // الإحداثيات الجديدة (21.1224, 40.3190)
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

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var distanceText: String = "حساب المسافة..."
    
    // الإحداثيات الدقيقة للمنتجع
    let targetCoordinate = CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809)
    var targetLocation: CLLocation { CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude) }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let distanceInKm = location.distance(from: targetLocation) / 1000
        DispatchQueue.main.async {
            self.distanceText = distanceInKm < 0.5 ? "أنت في المنتجع 📍" : String(format: "يبعد %.1f كم", distanceInKm)
        }
    }
}

// ==========================================
// MARK: - 3. التطبيق الرئيسي (MAIN APP)
// ==========================================
@main
struct JisrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().preferredColorScheme(.dark)
        }
    }
}

// ==========================================
// MARK: - 4. الشاشات (VIEWS)
// ==========================================

// --- الشاشة الرئيسية ---
struct ContentView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    let locations = [LocationPoint(name: "منتجع جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809))]
    
    // بيانات البكجات
    let packages = [
        GamePackage(pay: "100", get: "110", color: .purple),
        GamePackage(pay: "200", get: "230", color: .blue),
        GamePackage(pay: "300", get: "350", color: .orange),
        GamePackage(pay: "500", get: "600", color: .green),
        GamePackage(pay: "750", get: "1000", color: .red)
    ]
    
    // روابط الصور (مشابهة للوصف)
    let galleryImages = [
        "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80", // مدخل/عام
        "https://images.unsplash.com/photo-1445019980597-93fa8acb746c?w=800&q=80", // أكواخ
        "https://images.unsplash.com/photo-1533240332313-0db49b459ad6?w=800&q=80"  // القباب ليلاً
    ]
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=21.1224671,40.3190809")!

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. السلايدر
                        TabView {
                            ForEach(galleryImages, id: \.self) { imgURL in
                                AsyncImage(url: URL(string: imgURL)) { phase in
                                    if let image = phase.image { image.resizable().scaledToFill() }
                                    else { Color.gray.opacity(0.2) }
                                }
                            }
                        }
                        .frame(height: 300)
                        .tabViewStyle(PageTabViewStyle())
                        .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                        .overlay(
                            VStack(alignment: .leading) {
                                Text("منتجع جسر اللوزية").font(.system(size: 30, weight: .heavy)).foregroundColor(.white)
                                Text("ترفيه • إقامة • طبيعة").foregroundColor(.gray)
                            }.padding(), alignment: .bottomLeading
                        )
                        
                        // 2. الطقس والمسافة
                        HStack(spacing: 15) {
                            StatusBox(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            StatusBox(icon: "location.fill", title: "المسافة", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        
                        // 3. زر الحجز الكبير (ينقل لصفحة الاختيار)
                        NavigationLink(destination: BookingSelectionView()) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.title)
                                VStack(alignment: .leading) {
                                    Text("حجز الجلسات الخاصة").font(.headline)
                                    Text("بلورات - أكواخ - بيوت شعر").font(.caption)
                                }
                                Spacer()
                                Image(systemName: "chevron.left")
                            }
                            .padding()
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                        
                        // 4. رسوم الدخول
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "ticket.fill").foregroundColor(.yellow)
                                Text("تذاكر الدخول").font(.headline).foregroundColor(.white)
                                Spacer()
                            }
                            HStack { Text("سعر التذكرة").foregroundColor(.gray); Spacer(); Text("15 ريال").bold().foregroundColor(.yellow) }
                            Divider().background(Color.gray)
                            HStack { Text("دخول مجاني").foregroundColor(.gray); Spacer(); Text("أطفال < سنتين + ذوي الهمم").font(.caption).foregroundColor(.green) }
                        }
                        .padding().background(Color(UIColor.systemGray6).opacity(0.2)).cornerRadius(15).padding(.horizontal)
                        
                        // 5. بكجات الألعاب
                        VStack(alignment: .leading) {
                            Text("🎮 عروض شحن الرصيد").font(.headline).foregroundColor(.white).padding(.horizontal)
                            Text("الرصيد صالح لمدة سنة • المبلغ غير مسترد").font(.caption).foregroundColor(.gray).padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(packages) { pkg in
                                        VStack {
                                            Text("ادفع").font(.caption2).foregroundColor(.white.opacity(0.8))
                                            Text(pkg.pay).font(.title2).bold().foregroundColor(.white)
                                            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
                                            Text("تحصل على").font(.caption2).foregroundColor(.white.opacity(0.8))
                                            Text(pkg.get).font(.title).bold().foregroundColor(.white)
                                        }
                                        .frame(width: 110, height: 130)
                                        .background(pkg.color.opacity(0.8))
                                        .cornerRadius(15)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 6. التوجيه والخريطة
                        VStack(spacing: 15) {
                            Link(destination: googleMapsLink) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("اتجه للموقع (خرائط جوجل)")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(15)
                            }
                            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { loc in
                                MapMarker(coordinate: loc.coordinate, tint: .red)
                            }
                            .frame(height: 200).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2)))
                        }
                        .padding(.horizontal)
                        
                        // 7. التواصل
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

// --- صفحة اختيار نوع الجلسة ---
struct BookingSelectionView: View {
    let sessions = [
        SessionType(name: "البلورات (القباب)", price: "80 ريال/ساعة", features: "شاملة الضيافة • تكييف • إطلالة", imageURL: "https://images.unsplash.com/photo-1533240332313-0db49b459ad6?w=800&q=80"),
        SessionType(name: "بيوت الشعر", price: "90 ريال/ساعة", features: "شاملة الضيافة • جلسة تراثية", imageURL: "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=800&q=80"),
        SessionType(name: "الأكواخ الريفية", price: "100 ريال/ساعة", features: "شاملة الضيافة • إطلالة النهر", imageURL: "https://images.unsplash.com/photo-1445019980597-93fa8acb746c?w=800&q=80")
    ]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    Text("اختر نوع الجلسة").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                    
                    ForEach(sessions) { session in
                        NavigationLink(destination: BookingFormView(session: session)) {
                            ZStack(alignment: .bottom) {
                                AsyncImage(url: URL(string: session.imageURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill().frame(height: 200).clipped()
                                    } else {
                                        Color.gray.frame(height: 200)
                                    }
                                }
                                .overlay(Color.black.opacity(0.4))
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.name).font(.title2).bold().foregroundColor(.white)
                                        Text(session.features).font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text(session.price).padding(8).background(Color.yellow).foregroundColor(.black).cornerRadius(10)
                                }
                                .padding()
                            }
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// --- صفحة تعبئة بيانات الحجز ---
struct BookingFormView: View {
    let session: SessionType
    @State private var name = ""
    @State private var count = ""
    @State private var date = Date()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("تأكيد حجز \(session.name)").font(.title2).bold().foregroundColor(.white).padding()
                
                VStack(spacing: 15) {
                    TextField("الاسم الكريم", text: $name)
                        .padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                    TextField("عدد الأشخاص", text: $count)
                        .keyboardType(.numberPad).padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                    
                    HStack {
                        Text("وقت الوصول").foregroundColor(.gray)
                        Spacer()
                        DatePicker("", selection: $date).labelsHidden().colorScheme(.dark)
                    }
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.2)).cornerRadius(20).padding()
                
                Button(action: sendWhatsApp) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("إرسال الطلب للواتساب")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.green).foregroundColor(.white).cornerRadius(15)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    func sendWhatsApp() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let msg = """
        مرحباً، حجز جديد:
        🏡 النوع: \(session.name)
        💰 السعر: \(session.price)
        👤 الاسم: \(name)
        👥 العدد: \(count)
        📅 الوقت: \(formatter.string(from: date))
        """
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/966549949745?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// ==========================================
// MARK: - 5. مكونات التصميم (UI COMPONENTS)
// ==========================================

struct SocialLogo: View {
    let imageURL: String, url: String
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit().frame(width: 55, height: 55).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
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
ض

import SwiftUI
import MapKit
import CoreLocation

// ==========================================
// MARK: - App Configuration (قابل للتعديل)
// ==========================================
struct AppConfig {
    static let contactPhone = "966567963864"
    static let whatsappURL = "https://wa.me/\(966567963864)?text="
    static let snapchatURL = "https://www.snapchat.com/add/jsrlawzia"
    static let tiktokURL = "https://www.tiktok.com/@jsrlawzia"
    static let instagramURL = "https://instagram.com/jsrlawzia"
    static let headerImageURL = "https://images.unsplash.com/photo-1600607686527-6fb886090705?w=1800&q=80"
    static let logoAsset = "jisr_logo"
    static let targetLatitude = 21.1224671
    static let targetLongitude = 40.3190809
}

// ==========================================
// MARK: - 1. إعدادات الألوان الفاخرة
// ==========================================
extension Color {
    static let luxuryGold = Color(red: 0.83, green: 0.68, blue: 0.21) // ذهبي
    static let deepBlack = Color(red: 0.02, green: 0.02, blue: 0.03) // أسود عميق
    static let glass = Color.white.opacity(0.08) // زجاجي
}

// ==========================================
// MARK: - 2. نماذج البيانات
// ==========================================
struct WeatherResponse: Codable { let current_weather: CurrentWeather }
struct CurrentWeather: Codable { let temperature: Double; let weathercode: Int }

struct LocationPoint: Identifiable {
    let id = UUID(); let name: String; let coordinate: CLLocationCoordinate2D
}

struct GamePackage: Identifiable {
    let id = UUID(); let pay: Double; let get: Double
}

struct SessionType: Identifiable {
    let id = UUID(); let name: String; let price: Double; let features: String; let imageURL: String
}

struct ServiceItem: Identifiable {
    let id = UUID(); let name: String; let icon: String
}

// ==========================================
// MARK: - 3. المدراء (Logic)
// ==========================================
@MainActor
class WeatherManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var condition: String = ".."
    @Published var icon: String = "moon.stars.fill"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func fetchWeather() async {
        isLoading = true
        errorMessage = nil
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.1224&longitude=40.3190&current_weather=true"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "رابط الطقس غير صالح"
            self.isLoading = false
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
            let t = decoded.current_weather.temperature
            self.temperature = "\(Int(t))°"
            if t < 15 {
                self.condition = "أجواء باردة"
                self.icon = "thermometer.snowflake"
            } else {
                self.condition = "أجواء معتدلة"
                self.icon = "sun.max.fill"
            }
        } catch {
            self.errorMessage = "تعذّر جلب الطقس"
        }
        isLoading = false
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var distanceText: String = "..."
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    let targetLoc = CLLocation(latitude: AppConfig.targetLatitude, longitude: AppConfig.targetLongitude)
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    func start() {
        if CLLocationManager.locationServicesEnabled() {
            manager.startUpdatingLocation()
        }
    }
    
    func stop() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.startUpdatingLocation()
            } else {
                self.manager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let dist = loc.distance(from: targetLoc) / 1000
        DispatchQueue.main.async { self.distanceText = dist < 0.5 ? "وصلت" : String(format: "%.1f كم", dist) }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { self.distanceText = "خطأ بالموقع" }
    }
}

// ==========================================
// MARK: - 4. التطبيق والتبويبات
// ==========================================
@main
struct JisrApp: App {
    init() {
        // تخصيص البار السفلي ليكون شفافاً مع ضبابية (Blur)
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView().preferredColorScheme(.dark)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house") }
            
            BookingListView()
                .tabItem { Label("الحجوزات", systemImage: "calendar") }
            
            ServicesView()
                .tabItem { Label("الخدمات", systemImage: "bell") }
            
            BudgetView()
                .tabItem { Label("الألعاب", systemImage: "gamecontroller") }
        }
        .accentColor(.luxuryGold)
    }
}

// ==========================================
// MARK: - 5. الصفحات الرئيسية
// ==========================================

// --- 1. الرئيسية (Home) ---
struct HomeView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    let mainImage = AppConfig.headerImageURL
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=\(AppConfig.targetLatitude),\(AppConfig.targetLongitude)")!
    
    let packages = [
        GamePackage(pay: 100, get: 110), GamePackage(pay: 200, get: 230),
        GamePackage(pay: 500, get: 600), GamePackage(pay: 750, get: 1000)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.deepBlack.edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // الهيدر الفاخر
                        HeaderHero(imageURL: mainImage, title: "JISR RESORT", subtitle: "منتجع جسر اللوزية", logoAsset: AppConfig.logoAsset)
                        
                        VStack(spacing: 30) {
                            
                            // بطاقة الطقس البيضاء (Six Flags Style)
                            WeatherCard(manager: weatherManager)
                                .offset(y: -50)
                            
                            // زر التوجيه الذهبي
                            Link(destination: googleMapsLink) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("المسافة من موقعك").font(.caption).foregroundColor(.black.opacity(0.6))
                                        Text(locationManager.distanceText).font(.title3).bold().foregroundColor(.black)
                                    }
                                    Spacer()
                                    HStack {
                                        Text("توجيه").bold()
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .padding(.vertical, 8).padding(.horizontal, 15)
                                    .background(Color.black).foregroundColor(.luxuryGold).cornerRadius(20)
                                }
                                .padding()
                                .background(LinearGradient(colors: [.luxuryGold, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .cornerRadius(20)
                                .shadow(color: .luxuryGold.opacity(0.3), radius: 15)
                            }
                            .padding(.horizontal)
                            .offset(y: -30)
                            
                            // قسم التذاكر
                            VStack(alignment: .leading, spacing: 20) {
                                SectionTitle(title: "تذاكر الدخول")
                                HStack(spacing: 15) {
                                    TicketCard(title: "تذكرة فرد", price: "15 ﷼", subtitle: "للشخص الواحد")
                                    TicketCard(title: "دخول مجاني", price: "0 ﷼", subtitle: "أطفال < 2 / ذوي الهمم")
                                }
                            }
                            .padding(.horizontal)
                            
                            // قسم شحن الرصيد
                            VStack(alignment: .leading, spacing: 15) {
                                SectionTitle(title: "باقات الألعاب (VIP)")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        Spacer().frame(width: 5)
                                        ForEach(packages) { pkg in
                                            VStack {
                                                Text("ادفع").font(.caption2).foregroundColor(.gray)
                                                Text("\(Int(pkg.pay))").font(.title).bold().foregroundColor(.white)
                                                Divider().background(Color.gray)
                                                Text("رصيد").font(.caption2).foregroundColor(.luxuryGold)
                                                Text("\(Int(pkg.get))").font(.headline).foregroundColor(.luxuryGold)
                                            }
                                            .frame(width: 100, height: 120)
                                            .background(Color.glass) // خلفية زجاجية
                                            .cornerRadius(20)
                                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1)))
                                        }
                                    }
                                }
                            }
                            
                            // التواصل
                            SocialSection()
                                .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await weatherManager.fetchWeather()
                }
                locationManager.start()
            }
        }
    }
}

// --- 2. الحجوزات (Booking) ---
struct BookingListView: View {
    let sessions = [
        SessionType(name: "البلورات الملكية", price: 80, features: "إطلالة بانورامية • تكييف", imageURL: "https://images.unsplash.com/photo-1649170343284-5806dd601e3c?w=800&q=80"),
        SessionType(name: "أكواخ النهر", price: 100, features: "خصوصية تامة • صوت الماء", imageURL: "https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=800&q=80"),
        SessionType(name: "مجلس تراثي", price: 90, features: "أجواء دافئة • شبة نار", imageURL: "https://images.unsplash.com/photo-1550586678-f7b288a2983b?w=800&q=80")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.deepBlack.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        Text("حجز الجلسات")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .padding(.top, 40).padding(.horizontal)
                        
                        ForEach(sessions) { session in
                            NavigationLink(destination: BookingFormView(session: session)) {
                                LuxurySessionCard(session: session)
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 3. الخدمات (Services) ---
struct ServicesView: View {
    let services = [
        ServiceItem(name: "الضيافة", icon: "cup.and.saucer.fill"),
        ServiceItem(name: "تدفئة", icon: "flame.fill"),
        ServiceItem(name: "أغطية", icon: "bed.double.fill"),
        ServiceItem(name: "مساعدة", icon: "bell.fill")
    ]
    @State private var lostItem = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.deepBlack.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 35) {
                        Text("الخدمات").font(.system(size: 30, weight: .bold, design: .serif)).foregroundColor(.white).padding(.top, 40)
                        
                        // شبكة الخدمات
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(services) { item in
                                Button(action: { openWhatsApp(msg: "طلب خدمة: \(item.name)") }) {
                                    VStack {
                                        Image(systemName: item.icon).font(.largeTitle).foregroundColor(.luxuryGold)
                                        Text(item.name).font(.headline).foregroundColor(.white).padding(.top, 5)
                                    }
                                    .frame(height: 140).frame(maxWidth: .infinity)
                                    .background(Color.glass).cornerRadius(25)
                                    .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.05)))
                                }
                                .accessibilityLabel(Text("خدمة \(item.name)"))
                            }
                        }
                        
                        // المفقودات
                        VStack(alignment: .leading, spacing: 15) {
                            Text("المفقودات").font(.headline).foregroundColor(.gray)
                            HStack {
                                TextField("اكتب الغرض المفقود...", text: $lostItem)
                                    .padding().background(Color.glass).cornerRadius(15).foregroundColor(.white)
                                Button(action: { openWhatsApp(msg: "بلاغ مفقودات: \(lostItem)") }) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.largeTitle).foregroundColor(.luxuryGold)
                                }
                                .accessibilityLabel(Text("إرسال بلاغ المفقودات"))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 4. الميزانية (Calculator) ---
struct BudgetView: View {
    @State private var people = 1
    @State private var pkgCost = 0.0
    @State private var sessionCost = 0.0
    var total: Int { Int((Double(people) * 15.0) + pkgCost + sessionCost) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.deepBlack.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        Text("مخطط الرحلة").font(.system(size: 30, weight: .bold, design: .serif)).foregroundColor(.white).padding(.top, 40)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // الأشخاص
                            HStack {
                                Text("الزوار").foregroundColor(.gray)
                                Spacer()
                                Stepper("\(people)", value: $people, in: 1...30).labelsHidden().background(Color.white).cornerRadius(8)
                            }
                            // الجلسة
                            VStack(alignment: .leading) {
                                Text("نوع الجلسة").foregroundColor(.gray)
                                Picker("", selection: $sessionCost) {
                                    Text("بدون").tag(0.0)
                                    Text("بلورة (80)").tag(80.0)
                                    Text("بيت شعر (90)").tag(90.0)
                                    Text("كوخ (100)").tag(100.0)
                                }.pickerStyle(SegmentedPickerStyle()).colorScheme(.dark)
                            }
                            // الألعاب
                            VStack(alignment: .leading) {
                                Text("رصيد الألعاب").foregroundColor(.gray)
                                Picker("", selection: $pkgCost) {
                                    Text("بدون").tag(0.0)
                                    Text("100").tag(100.0)
                                    Text("300").tag(300.0)
                                    Text("750").tag(750.0)
                                }.pickerStyle(SegmentedPickerStyle()).colorScheme(.dark)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("التكلفة التقديرية")
                                Spacer()
                                Text("\(total) ريال").font(.largeTitle).bold().foregroundColor(.luxuryGold)
                            }
                        }
                        .padding(25)
                        .background(Color.glass).cornerRadius(25)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// ==========================================
// MARK: - 6. المكونات الفاخرة (UI Components)
// ==========================================

struct HeaderHero: View {
    let imageURL: String
    let title: String
    let subtitle: String
    let logoAsset: String?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.15)
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    Color.gray
                @unknown default:
                    Color.gray
                }
            }
            .frame(height: 420)
            .clipped()
            .overlay(LinearGradient(colors: [.deepBlack.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center))
            .cornerRadius(0)
            
            HStack(alignment: .center, spacing: 12) {
                if let logo = logoAsset, UIImage(named: logo) != nil {
                    Image(logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .background(Color.black.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.leading, 18)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 28, weight: .heavy, design: .serif))
                        .foregroundColor(.luxuryGold)
                        .tracking(2)
                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 18)
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .ignoresSafeArea(edges: .top)
    }
}

// بطاقة الطقس البيضاء (مثل Six Flags)
struct WeatherCard: View {
    @ObservedObject var manager: WeatherManager
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if manager.isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                }
                HStack {
                    Text(manager.temperature).font(.system(size: 50, weight: .light)).foregroundColor(.black)
                    Image(systemName: manager.icon).font(.largeTitle).foregroundColor(.luxuryGold)
                }
                Text(manager.condition).font(.caption).bold().foregroundColor(.gray)
                if let err = manager.errorMessage {
                    Text(err).font(.caption2).foregroundColor(.red)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("الطقس").font(.caption).foregroundColor(.gray)
                Text("الشفا").font(.title3).bold().foregroundColor(.black)
            }
        }
        .padding(25)
        .background(Color.white)
        .cornerRadius(25)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.2), radius: 20)
    }
}

struct TicketCard: View {
    let title: String, price: String, subtitle: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(price).font(.title).bold().foregroundColor(.white)
            Text(subtitle).font(.caption2).foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.glass)
        .cornerRadius(15)
    }
}

struct LuxurySessionCard: View {
    let session: SessionType
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: session.imageURL)) { p in
                if let i = p.image { i.resizable().scaledToFill() } else { Color.gray }
            }
            .frame(height: 240)
            .clipped()
            .overlay(LinearGradient(colors: [.deepBlack, .clear], startPoint: .bottom, endPoint: .center))
            
            HStack {
                VStack(alignment: .leading) {
                    Text(session.name).font(.title3).bold().foregroundColor(.white)
                    Text(session.features).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(session.price)) ﷼").font(.headline).foregroundColor(.black)
                    .padding(10).background(Color.luxuryGold).cornerRadius(10)
            }
            .padding()
        }
        .cornerRadius(25)
        .padding(.horizontal)
    }
}

struct BookingFormView: View {
    let session: SessionType
    @State private var name = ""; @State private var date = Date()
    var body: some View {
        ZStack {
            Color.deepBlack.edgesIgnoringSafeArea(.all)
            VStack(spacing: 25) {
                Text(session.name).font(.title).foregroundColor(.luxuryGold).padding(.top)
                VStack(spacing: 15) {
                    TextField("الاسم", text: $name).padding().background(Color.white).cornerRadius(10).foregroundColor(.black)
                    DatePicker("الموعد", selection: $date).colorScheme(.dark)
                }
                .padding().background(Color.glass).cornerRadius(20).padding()
                
                Button(action: {
                    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
                    let msg = "حجز جديد: \(session.name) - \(name) - \(f.string(from: date))"
                    openWhatsApp(msg: msg)
                }) {
                    Text("تأكيد الحجز").bold().frame(maxWidth: .infinity).padding().background(Color.luxuryGold).foregroundColor(.black).cornerRadius(15)
                }
                .padding(.horizontal)
                Spacer()
            }
        }
    }
}

// Social / Contact components
struct SocialIconView: View {
    let assetName: String?    // اسم الصورة في Assets (يفضل)
    let systemName: String?   // بديل SF Symbol
    let urlString: String
    let label: String         // للوصولية
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button(action: {
            guard let url = URL(string: urlString) else { return }
            openURL(url)
        }) {
            Group {
                if let asset = assetName, UIImage(named: asset) != nil {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                } else if let s = systemName {
                    Image(systemName: s)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "link")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                }
            }
            .frame(width: 36, height: 36)
            .padding(12)
            .background(Color.glass)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.luxuryGold.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
            .accessibilityLabel(Text(label))
        }
    }
}

struct SocialSection: View {
    let socials = [
        ("Snapchat", "snapchatIcon", AppConfig.snapchatURL, "سناب شات"),
        ("WhatsApp", "whatsappIcon", AppConfig.whatsappURL + "مرحبا", "واتساب"),
        ("TikTok", "tiktokIcon", AppConfig.tiktokURL, "تيك توك"),
        ("Instagram", "instagramIcon", AppConfig.instagramURL, "انستقرام"),
        ("X", "xIcon", "https://x.com/jsrlawzia", "X")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Divider().background(Color.white.opacity(0.1))
            Text("تواصل معنا").font(.caption).foregroundColor(.gray).tracking(2)
            HStack(spacing: 24) {
                ForEach(socials, id: \.0) { item in
                    SocialIconView(assetName: item.1, systemName: nil, urlString: item.2, label: item.3)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            Divider().background(Color.white.opacity(0.06))
        }
        .padding(.horizontal)
    }
}

struct SectionTitle: View {
    let title: String
    var body: some View {
        Text(title).font(.headline).foregroundColor(.white).padding(.leading, 5)
            .overlay(Rectangle().fill(Color.luxuryGold).frame(width: 3, height: 20).offset(x: -10), alignment: .leading)
    }
}

func openWhatsApp(msg: String) {
    let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    if let url = URL(string: AppConfig.whatsappURL + encoded) {
        UIApplication.shared.open(url)
    }
}

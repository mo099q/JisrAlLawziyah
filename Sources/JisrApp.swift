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

struct GamePackage: Identifiable, Hashable {
    let id = UUID()
    let pay: Double
    let get: Double
    let color: Color
    
    var title: String { "ادفع \(Int(pay))" }
}

struct SessionType: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let price: Double
    let features: String
    let imageURL: String
}

// ==========================================
// MARK: - 2. المدراء (MANAGERS)
// ==========================================

class WeatherManager: ObservableObject {
    @Published var temperature: String = ".."
    @Published var icon: String = "cloud.fill"
    
    func fetchWeather() {
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
    @Published var distanceText: String = "..."
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
            self.distanceText = distanceInKm < 0.5 ? "أنت في المنتجع" : String(format: "%.1f كم", distanceInKm)
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
            MainTabView().preferredColorScheme(.dark)
        }
    }
}

// ==========================================
// MARK: - 4. واجهة التبويبات (TAB VIEW)
// ==========================================
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }
            
            BookingView()
                .tabItem { Label("الحجوزات", systemImage: "calendar.badge.clock") }
            
            BudgetView()
                .tabItem { Label("ميزانيتي", systemImage: "banknote.fill") }
            
            LocationView()
                .tabItem { Label("الموقع", systemImage: "map.fill") }
        }
        .accentColor(.yellow) // لون الأيقونة النشطة
    }
}

// ==========================================
// MARK: - 5. الصفحات (SCREENS)
// ==========================================

// --- 1. الرئيسية ---
struct HomeView: View {
    @StateObject var weatherManager = WeatherManager()
    
    // صورة المدخل (حجرية)
    let mainImage = "https://images.unsplash.com/photo-1560626065-22d733475858?w=800&q=80"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 0) {
                        // شريط العروض المتحرك
                        TickerTape()
                        
                        // الصورة الرئيسية
                        ZStack(alignment: .bottom) {
                            AsyncImage(url: URL(string: mainImage)) { phase in
                                if let image = phase.image { image.resizable().scaledToFill() }
                                else { Color.gray.opacity(0.3) }
                            }
                            .frame(height: 300)
                            .clipped()
                            
                            LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                            
                            VStack(alignment: .leading) {
                                Text("منتجع جسر اللوزية")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("وجهتك الأولى في الشفا")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack(spacing: 20) {
                            // الطقس
                            HStack {
                                Image(systemName: weatherManager.icon)
                                    .font(.title)
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading) {
                                    Text("الطقس الآن")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(weatherManager.temperature)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Text("مفتوح الآن ✅")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6).opacity(0.3))
                            .cornerRadius(15)
                            
                            // أزرار سريعة
                            HStack(spacing: 15) {
                                NavigationLink(destination: BookingView()) {
                                    QuickActionCard(icon: "bed.double.fill", title: "حجز كوخ", color: .purple)
                                }
                                NavigationLink(destination: BudgetView()) {
                                    QuickActionCard(icon: "gamecontroller.fill", title: "شحن ألعاب", color: .blue)
                                }
                            }
                            
                            // التواصل الاجتماعي
                            VStack(alignment: .leading) {
                                Text("تواصل معنا").font(.headline).foregroundColor(.gray)
                                HStack(spacing: 30) {
                                    SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1024px-WhatsApp.svg.png", url: "https://wa.me/966549949745")
                                    SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/c/c4/Snapchat_logo.svg/1024px-Snapchat_logo.svg.png", url: "https://www.snapchat.com/add/jsrlawzia")
                                    SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a9/TikTok_logo.svg/1024px-TikTok_logo.svg.png", url: "https://www.tiktok.com/@jsrlawzia")
                                }
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { weatherManager.fetchWeather() }
        }
    }
}

// --- 2. الحجوزات ---
struct BookingView: View {
    let sessions = [
        SessionType(name: "البلورات (القباب)", price: 80, features: "شاملة الضيافة • إطلالة ", imageURL: "https://images.unsplash.com/photo-1533240332313-0db49b459ad6?w=800&q=80"),
        SessionType(name: "بيوت الشعر", price: 90, features: "شاملة الضيافة • جلسة شعبية", imageURL: "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=800&q=80"),
        SessionType(name: "الأكواخ الريفية", price: 100, features: "شاملة الضيافة • على البحيرة", imageURL: "https://images.unsplash.com/photo-1445019980597-93fa8acb746c?w=800&q=80")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        Text("اختر جلستك المفضلة")
                            .font(.title2).bold().foregroundColor(.white).padding(.top)
                        
                        ForEach(sessions) { session in
                            NavigationLink(destination: BookingFormView(session: session)) {
                                SessionCard(session: session)
                            }
                        }
                        
                        // التنبيهات
                        VStack(alignment: .leading, spacing: 10) {
                            HStack { Image(systemName: "exclamationmark.triangle.fill"); Text("سياسة الحجز") }
                                .foregroundColor(.yellow).font(.headline)
                            Text("• المبالغ المدفوعة غير مستردة")
                            Text("• يرجى الحضور قبل الموعد بـ 15 دقيقة")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(15)
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 3. الميزانية والألعاب (الحاسبة) ---
struct BudgetView: View {
    // البكجات
    let packages = [
        GamePackage(pay: 0, get: 0, color: .gray), // خيار "بدون"
        GamePackage(pay: 100, get: 110, color: .purple),
        GamePackage(pay: 200, get: 230, color: .blue),
        GamePackage(pay: 300, get: 350, color: .orange),
        GamePackage(pay: 500, get: 600, color: .green),
        GamePackage(pay: 750, get: 1000, color: .red)
    ]
    
    @State private var numberOfPeople = 0
    @State private var selectedPackage = 0 // Index
    @State private var sessionHours = 0
    @State private var sessionPrice: Double = 80 // Default to Crystals
    
    var totalCost: Double {
        let entry = Double(numberOfPeople * 15)
        let games = packages[selectedPackage].pay
        let session = sessionPrice * Double(sessionHours)
        return entry + games + session
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 25) {
                        Text("حاسبة الميزانية 🧮")
                            .font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                        
                        // 1. الدخول
                        VStack(alignment: .leading) {
                            Text("🎟 تذاكر الدخول (15 ريال/فرد)").bold().foregroundColor(.white)
                            Stepper("عدد الأشخاص: \(numberOfPeople)", value: $numberOfPeople, in: 0...20)
                                .padding().background(Color.white).cornerRadius(10).foregroundColor(.black)
                            Text("الأطفال < سنتين وذوي الهمم مجاناً").font(.caption).foregroundColor(.green)
                        }
                        .padding().background(Color(UIColor.systemGray6).opacity(0.2)).cornerRadius(15).padding(.horizontal)
                        
                        // 2. الألعاب
                        VStack(alignment: .leading) {
                            Text("🎮 رصيد الألعاب").bold().foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(0..<packages.count, id: \.self) { index in
                                        let pkg = packages[index]
                                        Button(action: { selectedPackage = index }) {
                                            VStack {
                                                if index == 0 { Text("بدون").bold() }
                                                else {
                                                    Text("\(Int(pkg.pay))").bold()
                                                    Text("تحصل \(Int(pkg.get))").font(.caption2)
                                                }
                                            }
                                            .frame(width: 80, height: 60)
                                            .background(selectedPackage == index ? Color.yellow : Color.gray.opacity(0.3))
                                            .foregroundColor(selectedPackage == index ? .black : .white)
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            if selectedPackage > 0 {
                                Text("✅ الرصيد صالح لمدة سنة كاملة").font(.caption).foregroundColor(.green).padding(.top, 5)
                            }
                        }
                        .padding().background(Color(UIColor.systemGray6).opacity(0.2)).cornerRadius(15).padding(.horizontal)
                        
                        // 3. الجلسة
                        VStack(alignment: .leading) {
                            Text("🏡 حجز الجلسة").bold().foregroundColor(.white)
                            Picker("نوع الجلسة", selection: $sessionPrice) {
                                Text("بلورات (80)").tag(80.0)
                                Text("بيت شعر (90)").tag(90.0)
                                Text("كوخ (100)").tag(100.0)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .background(Color.white).cornerRadius(8)
                            
                            Stepper("عدد الساعات: \(sessionHours)", value: $sessionHours, in: 0...12)
                                .padding().background(Color.white).cornerRadius(10).foregroundColor(.black)
                        }
                        .padding().background(Color(UIColor.systemGray6).opacity(0.2)).cornerRadius(15).padding(.horizontal)
                        
                        // النتيجة النهائية
                        VStack {
                            Text("الإجمالي المتوقع")
                                .font(.headline).foregroundColor(.gray)
                            Text("\(Int(totalCost)) ريال")
                                .font(.system(size: 50, weight: .heavy))
                                .foregroundColor(.yellow)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(20)
                        .padding()
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 4. الموقع ---
struct LocationView: View {
    @StateObject var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    let locations = [LocationPoint(name: "منتجع جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809))]
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=21.1224671,40.3190809")!

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    Text("موقعنا 📍").font(.title).bold().foregroundColor(.white).padding(.top)
                    
                    Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { loc in
                        MapMarker(coordinate: loc.coordinate, tint: .red)
                    }
                    .cornerRadius(20)
                    .padding()
                    
                    Text(locationManager.distanceText)
                        .font(.title2).bold().foregroundColor(.yellow)
                    
                    Link(destination: googleMapsLink) {
                        HStack {
                            Image(systemName: "car.fill")
                            Text("توجيه عبر Google Maps")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.blue).foregroundColor(.white).cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// ==========================================
// MARK: - 6. المكونات الفرعية (SUB-VIEWS)
// ==========================================

// شريط العروض المتحرك
struct TickerTape: View {
    @State private var offset: CGFloat = 300
    var body: some View {
        ZStack {
            Color.yellow
            Text("📣 عرض خاص: اشحن 750 واحصل على 1000 ريال رصيد! • الأجواء في الشفا الآن ساحرة 🌫️")
                .bold()
                .foregroundColor(.black)
                .lineLimit(1)
                .offset(x: offset)
                .onAppear {
                    withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                        offset = -400
                    }
                }
        }
        .frame(height: 35)
        .clipped()
    }
}

// بطاقة الجلسة
struct SessionCard: View {
    let session: SessionType
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: session.imageURL)) { phase in
                if let image = phase.image { image.resizable().scaledToFill().frame(height: 180).clipped() }
                else { Color.gray.frame(height: 180) }
            }
            .overlay(Color.black.opacity(0.5))
            
            HStack {
                VStack(alignment: .leading) {
                    Text(session.name).font(.title3).bold().foregroundColor(.white)
                    Text(session.features).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(session.price)) ﷼").bold().padding(8).background(Color.yellow).foregroundColor(.black).cornerRadius(8)
            }
            .padding()
        }
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// صفحة تعبئة بيانات الحجز
struct BookingFormView: View {
    let session: SessionType
    @State private var name = ""
    @State private var count = ""
    @State private var date = Date()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("تأكيد حجز \(session.name)").font(.title2).bold().foregroundColor(.white).padding(.top)
                
                VStack(spacing: 15) {
                    TextField("الاسم الكريم", text: $name)
                        .padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                    TextField("عدد الأشخاص", text: $count)
                        .keyboardType(.numberPad).padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                    DatePicker("وقت الوصول", selection: $date).colorScheme(.dark)
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15).padding()
                
                Button(action: sendWhatsApp) {
                    HStack { Image(systemName: "paperplane.fill"); Text("تأكيد وحجز (واتساب)") }
                        .bold().frame(maxWidth: .infinity).padding().background(Color.green).foregroundColor(.white).cornerRadius(15)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    func sendWhatsApp() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let msg = "طلب حجز:\n🏡 النوع: \(session.name)\n👤 الاسم: \(name)\n👥 العدد: \(count)\n📅 الوقت: \(formatter.string(from: date))"
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/966549949745?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// بطاقات وأزرار
struct QuickActionCard: View {
    let icon: String, title: String, color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).font(.largeTitle).foregroundColor(color)
            Text(title).font(.caption).bold().foregroundColor(.white)
        }
        .frame(width: 150, height: 100)
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
                    if let image = phase.image { image.resizable().scaledToFit().frame(width: 50, height: 50).background(Color.white).clipShape(Circle()) }
                    else { Circle().fill(Color.gray).frame(width: 50, height: 50) }
                }
            }
        }
    }
}

struct StatusBox: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).foregroundColor(color)
            Text(value).bold().foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.5)
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(10)
    }
}

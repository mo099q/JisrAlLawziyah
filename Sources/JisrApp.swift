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
    let pay: Double
    let get: Double
    let color: Color
}

struct SessionType: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let features: String
    let imageURL: String // رابط الصورة الخاص بها
}

struct ServiceItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

// ==========================================
// MARK: - 2. المدراء (MANAGERS)
// ==========================================

class WeatherManager: ObservableObject {
    @Published var temperature: String = ".."
    @Published var condition: String = "صافي"
    @Published var icon: String = "moon.stars.fill"
    
    func fetchWeather() {
        // إحداثيات المنتجع الدقيقة
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.1224&longitude=40.3190&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let decoded = try? JSONDecoder().decode(WeatherResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.temperature = "\(Int(decoded.current_weather.temperature))°C"
                // منطق بسيط لتحديد الحالة
                let code = decoded.current_weather.weathercode
                if code > 50 { self.condition = "ممطر/ضباب"; self.icon = "cloud.fog.fill" }
                else if decoded.current_weather.temperature < 15 { self.condition = "بارد جداً"; self.icon = "thermometer.snowflake" }
                else { self.condition = "أجواء معتدلة"; self.icon = "moon.stars.fill" }
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
            self.distanceText = distanceInKm < 0.5 ? "أنت في المنتجع 📍" : String(format: "%.1f كم", distanceInKm)
        }
    }
}

// ==========================================
// MARK: - 3. التطبيق الرئيسي
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
// MARK: - 4. هيكلة التبويبات (TAB BAR)
// ==========================================
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }
            
            BookingListView()
                .tabItem { Label("الحجوزات", systemImage: "calendar.badge.clock") }
            
            ServicesView()
                .tabItem { Label("الخدمات", systemImage: "bell.fill") }
            
            BudgetView()
                .tabItem { Label("الألعاب", systemImage: "gamecontroller.fill") }
        }
        .accentColor(.yellow)
    }
}

// ==========================================
// MARK: - 5. الصفحات (SCREENS)
// ==========================================

// --- 1. الصفحة الرئيسية ---
struct HomeView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    // صورة المدخل (بناءً على طلبك للصورة الرئيسية)
    // ملاحظة: استخدمت رابطاً لصورة مدخل حجري فاخر مشابه لصورتك لضمان عمل الكود فوراً
    let mainImage = "https://i.imgur.com/Lq8y6kE.jpeg" 
    
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=21.1224671,40.3190809")!

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 0) {
                        // صورة الهيدر (المدخل)
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: mainImage)) { phase in
                                if let image = phase.image { image.resizable().scaledToFill() }
                                else { Color.gray.opacity(0.3) }
                            }
                            .frame(height: 320)
                            .clipped()
                            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("منتجع جسر اللوزية")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("وجهتك السياحية المتكاملة في الشفا")
                                    .font(.subheadline).foregroundColor(.yellow)
                            }
                            .padding()
                        }
                        
                        VStack(spacing: 20) {
                            // شريط الحالة (طقس + مسافة)
                            HStack(spacing: 15) {
                                InfoTile(icon: weatherManager.icon, title: weatherManager.condition, value: weatherManager.temperature, color: .blue)
                                InfoTile(icon: "location.fill", title: "المسافة منك", value: locationManager.distanceText, color: .red)
                            }
                            
                            // رسوم الدخول
                            VStack(spacing: 10) {
                                HStack {
                                    Image(systemName: "ticket.fill").foregroundColor(.yellow)
                                    Text("تذاكر الدخول").bold()
                                    Spacer()
                                    Text("15 ريال").bold().foregroundColor(.yellow)
                                }
                                Divider().background(Color.gray)
                                HStack {
                                    Text("دخول مجاني:").font(.caption).foregroundColor(.gray)
                                    Spacer()
                                    Text("أطفال أقل من سنتين • ذوي الهمم").font(.caption).foregroundColor(.green)
                                }
                            }
                            .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
                            
                            // زر التوجيه
                            Link(destination: googleMapsLink) {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("اتجه للموقع (Google Maps)")
                                }
                                .bold()
                                .frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(15)
                            }
                            
                            // قوانين المنتجع (السلامة والممنوعات)
                            VStack(alignment: .leading, spacing: 15) {
                                Text("⚠️ تعليمات المنتجع").font(.headline).foregroundColor(.gray)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        RuleItem(icon: "fork.knife.circle.fill", text: "ممنوع الأكل\nوالشرب")
                                        RuleItem(icon: "flame.circle.fill", text: "ممنوع\nالشوي")
                                        RuleItem(icon: "pawprint.circle.fill", text: "ممنوع\nالحيوانات")
                                        RuleItem(icon: "bicycle.circle.fill", text: "ممنوع\nالسكوترات")
                                        RuleItem(icon: "bed.double.circle.fill", text: "ممنوع\nالفرش")
                                    }
                                }
                            }
                            .padding(.vertical)
                            
                            // التواصل
                            HStack(spacing: 30) {
                                SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1024px-WhatsApp.svg.png", url: "https://wa.me/966549949745")
                                SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/c/c4/Snapchat_logo.svg/1024px-Snapchat_logo.svg.png", url: "https://www.snapchat.com/add/jsrlawzia")
                                SocialLogo(imageURL: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a9/TikTok_logo.svg/1024px-TikTok_logo.svg.png", url: "https://www.tiktok.com/@jsrlawzia")
                            }
                            .padding(.bottom, 50)
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

// --- 2. صفحة الحجوزات (قائمة الجلسات) ---
struct BookingListView: View {
    // تم وضع الصور المطابقة للوصف هنا
    let sessions = [
        SessionType(name: "البلورات (القباب)", price: 80, features: "شاملة الضيافة • إطلالة مميزة • تكييف", imageURL: "https://i.imgur.com/Pj5s4Zc.jpeg"), // صورة القباب الليلية
        SessionType(name: "الأكواخ الريفية", price: 100, features: "شاملة الضيافة • إطلالة على البحيرة", imageURL: "https://i.imgur.com/8d9wXgD.jpeg"), // صورة الأكواخ
        SessionType(name: "بيوت الشعر", price: 90, features: "شاملة الضيافة • جلسة شعبية", imageURL: "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=800&q=80")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 25) {
                        Text("اختر جلستك").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                        
                        ForEach(sessions) { session in
                            // NavigationLink هنا يعمل بشكل صحيح داخل NavigationView
                            NavigationLink(destination: BookingFormView(session: session)) {
                                SessionCard(session: session)
                            }
                        }
                        
                        Text("📝 ملاحظة: الحجز غير مسترد • يرجى الحضور قبل الموعد")
                            .font(.caption).foregroundColor(.gray).padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 3. صفحة الخدمات (الجديدة) ---
struct ServicesView: View {
    @State private var showLostFound = false
    
    let services = [
        ServiceItem(name: "قهوة / شاي", icon: "cup.and.saucer.fill"),
        ServiceItem(name: "جمر إضافي", icon: "flame.fill"),
        ServiceItem(name: "بطانيات", icon: "bed.double.fill"),
        ServiceItem(name: "مساعدة", icon: "person.wave.2.fill")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 30) {
                        Text("الخدمات والرفاهية").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                        
                        // 1. خدمة الغرف (الجلسات)
                        VStack(alignment: .leading) {
                            Text("🛎 اطلب وأنت في جلستك").font(.headline).foregroundColor(.white)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                ForEach(services) { service in
                                    Button(action: { sendServiceRequest(item: service.name) }) {
                                        VStack {
                                            Image(systemName: service.icon).font(.title).foregroundColor(.yellow)
                                            Text(service.name).font(.caption).bold().foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(UIColor.systemGray6).opacity(0.3))
                                        .cornerRadius(15)
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        // 2. المفقودات
                        VStack(alignment: .leading) {
                            Text("🔍 المفقودات").font(.headline).foregroundColor(.white)
                            Button(action: { showLostFound.toggle() }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("الإبلاغ عن غرض مفقود")
                                }
                                .frame(maxWidth: .infinity).padding().background(Color.gray.opacity(0.3)).foregroundColor(.white).cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. الطوارئ
                        Link(destination: URL(string: "tel://911")!) { // رقم افتراضي للطوارئ
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("أرقام الطوارئ")
                            }
                            .foregroundColor(.red).padding()
                        }
                    }
                }
                
                // نافذة المفقودات المنبثقة
                if showLostFound {
                    LostFoundPopup(isPresented: $showLostFound)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func sendServiceRequest(item: String) {
        let msg = "مرحباً خدمة العملاء، أحتاج (\(item)) في جلستي.".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/966549949745?text=\(msg)") { UIApplication.shared.open(url) }
    }
}

// --- 4. صفحة الألعاب والميزانية ---
struct BudgetView: View {
    let packages = [
        GamePackage(pay: 100, get: 110, color: .purple),
        GamePackage(pay: 200, get: 230, color: .blue),
        GamePackage(pay: 300, get: 350, color: .orange),
        GamePackage(pay: 500, get: 600, color: .green),
        GamePackage(pay: 750, get: 1000, color: .red)
    ]
    
    @State private var people = 0
    @State private var selectedPkgIdx = 0
    @State private var sessionPrice: Double = 0
    
    var total: Double {
        let entry = Double(people * 15)
        let games = selectedPkgIdx >= 0 ? packages[selectedPkgIdx].pay : 0
        return entry + games + sessionPrice
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 25) {
                        Text("الألعاب والميزانية").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                        
                        // بكجات الألعاب
                        VStack(alignment: .leading) {
                            Text("🎮 عروض الشحن (صلاحية سنة)").font(.headline).foregroundColor(.white).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(0..<packages.count, id: \.self) { i in
                                        let pkg = packages[i]
                                        Button(action: { selectedPkgIdx = i }) {
                                            VStack {
                                                Text("ادفع \(Int(pkg.pay))").font(.caption).foregroundColor(.white)
                                                Text("رصيد \(Int(pkg.get))").bold().font(.title2).foregroundColor(.white)
                                            }
                                            .frame(width: 110, height: 100)
                                            .background(pkg.color.opacity(selectedPkgIdx == i ? 1.0 : 0.5))
                                            .cornerRadius(15)
                                            .overlay(selectedPkgIdx == i ? RoundedRectangle(cornerRadius: 15).stroke(Color.white, lineWidth: 2) : nil)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // الحاسبة
                        VStack(alignment: .leading, spacing: 15) {
                            Text("🧮 احسب تكلفتك").font(.headline).foregroundColor(.white)
                            
                            HStack { Text("عدد الأشخاص (15/فرد)"); Spacer(); Stepper("\(people)", value: $people, in: 1...50) }
                            HStack {
                                Text("سعر الجلسة")
                                Spacer()
                                Picker("", selection: $sessionPrice) {
                                    Text("لا يوجد").tag(0.0)
                                    Text("بلورة (80)").tag(80.0)
                                    Text("شعر (90)").tag(90.0)
                                    Text("كوخ (100)").tag(100.0)
                                }.pickerStyle(MenuPickerStyle()).accentColor(.yellow)
                            }
                            
                            Divider().background(Color.gray)
                            
                            HStack {
                                Text("الإجمالي المتوقع:")
                                Spacer()
                                Text("\(Int(total)) ريال").font(.largeTitle).bold().foregroundColor(.yellow)
                            }
                        }
                        .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15).padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// ==========================================
// MARK: - 6. المكونات الفرعية (SUB-COMPONENTS)
// ==========================================

struct BookingFormView: View {
    let session: SessionType
    @State private var name = ""
    @State private var count = ""
    @State private var date = Date()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 25) {
                Text("تأكيد حجز \(session.name)").font(.title2).bold().foregroundColor(.white)
                
                VStack(spacing: 15) {
                    TextField("الاسم", text: $name).padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                    TextField("العدد", text: $count).keyboardType(.numberPad).padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                    DatePicker("الوقت", selection: $date).colorScheme(.dark)
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15).padding()
                
                Button(action: sendWhatsApp) {
                    HStack { Image(systemName: "paperplane.fill"); Text("حجز (واتساب)") }
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
        if let url = URL(string: "https://wa.me/966549949745?text=\(encoded)") { UIApplication.shared.open(url) }
    }
}

struct LostFoundPopup: View {
    @Binding var isPresented: Bool
    @State private var item = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("مفقودات").font(.headline).foregroundColor(.white)
                TextField("وصف الغرض المفقود...", text: $item).padding().background(Color.white).foregroundColor(.black).cornerRadius(10)
                Button("إرسال بلاغ") {
                    let msg = "بلاغ مفقودات: \(item)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "https://wa.me/966549949745?text=\(msg)") { UIApplication.shared.open(url) }
                    isPresented = false
                }
                .padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
                
                Button("إلغاء") { isPresented = false }.foregroundColor(.red)
            }
            .padding(30).background(Color(UIColor.systemGray6)).cornerRadius(20).padding()
        }
    }
}

struct SessionCard: View {
    let session: SessionType
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: session.imageURL)) { phase in
                if let image = phase.image { image.resizable().scaledToFill().frame(height: 200).clipped() }
                else { Color.gray.frame(height: 200) }
            }
            .overlay(Color.black.opacity(0.4))
            HStack {
                VStack(alignment: .leading) {
                    Text(session.name).bold().foregroundColor(.white)
                    Text(session.features).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(session.price)) ﷼").bold().padding(8).background(Color.yellow).foregroundColor(.black).cornerRadius(8)
            }
            .padding()
        }
        .cornerRadius(15).padding(.horizontal)
    }
}

struct InfoTile: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).foregroundColor(color)
            Text(value).bold().foregroundColor(.white)
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(10)
    }
}

struct RuleItem: View {
    let icon: String, text: String
    var body: some View {
        VStack {
            Image(systemName: icon).font(.largeTitle).foregroundColor(.red)
            Text(text).font(.caption).multilineTextAlignment(.center).foregroundColor(.white)
        }
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

import SwiftUI
import MapKit
import CoreLocation

// ==========================================
// MARK: - 1. نماذج البيانات
// ==========================================

struct WeatherResponse: Codable { let current_weather: CurrentWeather }
struct CurrentWeather: Codable { let temperature: Double; let weathercode: Int }

struct LocationPoint: Identifiable {
    let id = UUID(); let name: String; let coordinate: CLLocationCoordinate2D
}

struct GamePackage: Identifiable {
    let id = UUID(); let pay: Double; let get: Double; let color: Color
}

struct SessionType: Identifiable {
    let id = UUID(); let name: String; let price: Double; let features: String; let imageURL: String
}

struct ServiceItem: Identifiable {
    let id = UUID(); let name: String; let icon: String
}

// ==========================================
// MARK: - 2. المدراء (Logic)
// ==========================================

class WeatherManager: ObservableObject {
    @Published var temperature: String = ".."
    @Published var icon: String = "moon.stars.fill"
    
    func fetchWeather() {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.1224&longitude=40.3190&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let decoded = try? JSONDecoder().decode(WeatherResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.temperature = "\(Int(decoded.current_weather.temperature))°"
                self.icon = decoded.current_weather.temperature > 25 ? "sun.max.fill" : "cloud.moon.fill"
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
        let dist = location.distance(from: targetLocation) / 1000
        DispatchQueue.main.async { self.distanceText = dist < 0.5 ? "وصلت" : String(format: "%.1f كم", dist) }
    }
}

// ==========================================
// MARK: - 3. التطبيق
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
// MARK: - 4. التبويبات (Tab Bar)
// ==========================================
struct MainTabView: View {
    
    // تخصيص شكل التبويبات ليكون مثل الآيفون الأصلي
    init() {
        UITabBar.appearance().backgroundColor = UIColor.systemGray6
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }
            
            BookingListView()
                .tabItem { Label("الحجوزات", systemImage: "calendar") }
            
            ServicesView()
                .tabItem { Label("الخدمات", systemImage: "bell.badge.fill") }
            
            BudgetView()
                .tabItem { Label("الألعاب", systemImage: "gamecontroller.fill") }
        }
        .accentColor(.yellow)
    }
}

// ==========================================
// MARK: - 5. الصفحات
// ==========================================

// --- الصفحة الرئيسية ---
struct HomeView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    // روابط صور ثابتة وموثوقة (Unsplash)
    let mainImage = "https://images.unsplash.com/photo-1600607686527-6fb886090705?w=800&q=80" // مدخل حجري فاخر
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=21.1224671,40.3190809")!

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // خلفية سوداء كاملة
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 1. صورة الهيدر (تصميم آيفون - يملأ الشاشة من الأعلى)
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: mainImage)) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Rectangle().fill(Color(UIColor.darkGray)) // لون مؤقت بدل رسالة الخطأ
                                }
                            }
                            .frame(height: 350)
                            .clipped()
                            .overlay(
                                LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("منتجع جسر اللوزية")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("وجهتك الأولى في أعالي الشفا")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                        // هذا السطر يجعل الصورة تدخل تحت النوتش
                        .ignoresSafeArea(edges: .top)
                        
                        // 2. معلومات سريعة (طقس ومسافة)
                        HStack(spacing: 15) {
                            InfoCardIOS(icon: weatherManager.icon, title: "الطقس", value: weatherManager.temperature, color: .blue)
                            InfoCardIOS(icon: "location.fill", title: "المسافة", value: locationManager.distanceText, color: .red)
                        }
                        .padding(.horizontal)
                        .offset(y: -20) // تداخل بسيط مع الصورة لجمالية التصميم
                        
                        // 3. تذاكر الدخول
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "ticket.fill").foregroundColor(.yellow)
                                Text("تذاكر الدخول").font(.headline).bold()
                                Spacer()
                                Text("15 ﷼").font(.title3).bold().foregroundColor(.yellow)
                            }
                            Divider().background(Color.white.opacity(0.2))
                            HStack {
                                Text("مجاناً:").font(.caption).foregroundColor(.gray)
                                Text("الأطفال < سنتين • ذوي الهمم").font(.caption).foregroundColor(.green)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.15))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // 4. زر التوجيه الكبير
                        Link(destination: googleMapsLink) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("اتجه للموقع (Google Maps)")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        
                        // 5. الممنوعات (أيقونات دائرية)
                        VStack(alignment: .leading) {
                            Text("⚠️ تعليمات المنتجع").font(.headline).foregroundColor(.gray).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    Spacer().frame(width: 10)
                                    RuleItem(icon: "fork.knife", text: "الأكل")
                                    RuleItem(icon: "flame", text: "الشوي")
                                    RuleItem(icon: "pawprint", text: "الحيوانات")
                                    RuleItem(icon: "bicycle", text: "السكوتر")
                                    RuleItem(icon: "bed.double", text: "الفرش")
                                }
                            }
                        }
                        
                        // 6. التواصل
                        VStack(spacing: 20) {
                            Text("تواصل معنا").font(.headline).foregroundColor(.gray)
                            HStack(spacing: 30) {
                                SocialBtn(img: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/120px-WhatsApp.svg.png", url: "https://wa.me/966549949745")
                                SocialBtn(img: "https://upload.wikimedia.org/wikipedia/en/thumb/c/c4/Snapchat_logo.svg/120px-Snapchat_logo.svg.png", url: "https://www.snapchat.com/add/jsrlawzia")
                                SocialBtn(img: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a9/TikTok_logo.svg/120px-TikTok_logo.svg.png", url: "https://www.tiktok.com/@jsrlawzia")
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { weatherManager.fetchWeather() }
        }
    }
}

// --- صفحة الحجوزات ---
struct BookingListView: View {
    // صور تعبيرية دقيقة (Unsplash)
    let sessions = [
        SessionType(name: "البلورات (القباب)", price: 80, features: "تكييف • إطلالة • ضيافة", imageURL: "https://images.unsplash.com/photo-1649170343284-5806dd601e3c?w=800&q=80"),
        SessionType(name: "الأكواخ الريفية", price: 100, features: "مطلة على النهر • خصوصية", imageURL: "https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=800&q=80"),
        SessionType(name: "بيوت الشعر", price: 90, features: "جلسة تراثية • دافئة", imageURL: "https://images.unsplash.com/photo-1550586678-f7b288a2983b?w=800&q=80")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        Text("اختر جلستك").font(.largeTitle).bold().foregroundColor(.white).padding(.top, 20)
                        
                        ForEach(sessions) { session in
                            NavigationLink(destination: BookingFormView(session: session)) {
                                SessionCardIOS(session: session)
                            }
                        }
                        Spacer().frame(height: 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- صفحة الخدمات ---
struct ServicesView: View {
    let services = [
        ServiceItem(name: "طلب قهوة/شاي", icon: "cup.and.saucer.fill"),
        ServiceItem(name: "طلب جمر", icon: "flame.fill"),
        ServiceItem(name: "طلب بطانيات", icon: "bed.double.fill"),
        ServiceItem(name: "مساعدة موظف", icon: "figure.wave")
    ]
    @State private var showLost = false
    @State private var lostItem = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        Text("الخدمات").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                        
                        // خدمة الغرف
                        VStack(alignment: .leading) {
                            Text("🛎 خدمة الجلسات").font(.headline).foregroundColor(.gray)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                                ForEach(services) { item in
                                    Button(action: { sendWhatsApp(msg: "أحتاج \(item.name) في جلستي") }) {
                                        VStack {
                                            Image(systemName: item.icon).font(.largeTitle).foregroundColor(.yellow).padding(.bottom, 5)
                                            Text(item.name).font(.subheadline).bold().foregroundColor(.white)
                                        }
                                        .frame(height: 100)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.systemGray6).opacity(0.2))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        
                        // المفقودات
                        VStack(alignment: .leading) {
                            Text("🔍 المفقودات").font(.headline).foregroundColor(.gray)
                            VStack(spacing: 15) {
                                TextField("ما الذي فقدته؟", text: $lostItem)
                                    .padding()
                                    .background(Color(UIColor.systemGray6).opacity(0.3))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                
                                Button(action: { sendWhatsApp(msg: "بلاغ مفقودات: \(lostItem)") }) {
                                    Text("إرسال بلاغ")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6).opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func sendWhatsApp(msg: String) {
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/966549949745?text=\(encoded)") { UIApplication.shared.open(url) }
    }
}

// --- صفحة الألعاب والميزانية ---
struct BudgetView: View {
    let packages = [
        GamePackage(pay: 100, get: 110, color: .purple),
        GamePackage(pay: 200, get: 230, color: .blue),
        GamePackage(pay: 300, get: 350, color: .orange),
        GamePackage(pay: 500, get: 600, color: .green),
        GamePackage(pay: 750, get: 1000, color: .red)
    ]
    @State private var people = 0
    @State private var selectedPkg = 0.0
    @State private var sessionPrice = 0.0
    
    var total: Int { Int((Double(people) * 15.0) + selectedPkg + sessionPrice) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 25) {
                        Text("الألعاب والميزانية").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                        
                        // البكجات
                        VStack(alignment: .leading) {
                            Text("🎮 بكجات الألعاب (سنة كاملة)").font(.headline).foregroundColor(.gray).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    Spacer().frame(width: 10)
                                    ForEach(packages) { pkg in
                                        Button(action: { selectedPkg = pkg.pay }) {
                                            VStack {
                                                Text("ادفع \(Int(pkg.pay))").font(.caption).foregroundColor(.white)
                                                Text("رصيد \(Int(pkg.get))").font(.title2).bold().foregroundColor(.white)
                                            }
                                            .frame(width: 100, height: 100)
                                            .background(pkg.color.opacity(0.7))
                                            .cornerRadius(16)
                                            .overlay(selectedPkg == pkg.pay ? RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 2) : nil)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // الحاسبة
                        VStack(alignment: .leading, spacing: 20) {
                            Text("🧮 حاسبة التكلفة").font(.headline).foregroundColor(.gray)
                            
                            HStack { Text("الدخول (15/فرد)"); Spacer(); Stepper("\(people)", value: $people, in: 1...50) }
                            HStack {
                                Text("الجلسة"); Spacer()
                                Picker("", selection: $sessionPrice) {
                                    Text("بدون").tag(0.0)
                                    Text("بلورة (80)").tag(80.0)
                                    Text("شعر (90)").tag(90.0)
                                    Text("كوخ (100)").tag(100.0)
                                }.pickerStyle(MenuPickerStyle()).accentColor(.yellow)
                            }
                            
                            Divider().background(Color.gray)
                            
                            HStack {
                                Text("الإجمالي:")
                                Spacer()
                                Text("\(total) ريال").font(.system(size: 40, weight: .bold)).foregroundColor(.yellow)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// ==========================================
// MARK: - 6. مكونات التصميم (UI Components)
// ==========================================

struct InfoCardIOS: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(value).font(.headline).bold().foregroundColor(.white)
                Text(title).font(.caption).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(16)
    }
}

struct RuleItem: View {
    let icon: String, text: String
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.red.opacity(0.15)).frame(width: 60, height: 60)
                Image(systemName: icon).font(.title2).foregroundColor(.red)
                Image(systemName: "line.diagonal").font(.largeTitle).foregroundColor(.red).opacity(0.7)
            }
            Text(text).font(.caption).multilineTextAlignment(.center).foregroundColor(.gray)
        }
    }
}

struct SessionCardIOS: View {
    let session: SessionType
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: session.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill().frame(height: 200).clipped()
                } else {
                    Color.gray.frame(height: 200)
                }
            }
            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text(session.name).font(.title3).bold().foregroundColor(.white)
                    Text(session.features).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(session.price)) ﷼").bold().padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.yellow).foregroundColor(.black).cornerRadius(8)
            }
            .padding()
        }
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct BookingFormView: View {
    let session: SessionType
    @State private var name = ""; @State private var count = ""; @State private var date = Date()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 25) {
                Text(session.name).font(.title).bold().foregroundColor(.white).padding(.top)
                
                VStack(spacing: 20) {
                    TextField("الاسم", text: $name).padding().background(Color(UIColor.systemGray6)).cornerRadius(10).foregroundColor(.white)
                    TextField("العدد", text: $count).keyboardType(.numberPad).padding().background(Color(UIColor.systemGray6)).cornerRadius(10).foregroundColor(.white)
                    DatePicker("الوقت", selection: $date).colorScheme(.dark)
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.1)).cornerRadius(20).padding()
                
                Button(action: {
                    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
                    let msg = "حجز جديد:\n🏠 \(session.name)\n👤 \(name)\n👥 \(count)\n📅 \(f.string(from: date))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "https://wa.me/966549949745?text=\(msg)") { UIApplication.shared.open(url) }
                }) {
                    Text("تأكيد الحجز (واتساب)").bold().frame(maxWidth: .infinity).padding().background(Color.green).foregroundColor(.white).cornerRadius(15)
                }
                .padding(.horizontal)
                Spacer()
            }
        }
    }
}

struct SocialBtn: View {
    let img: String, url: String
    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                AsyncImage(url: URL(string: img)) { p in
                    if let i = p.image { i.resizable().scaledToFit() } else { Circle().fill(.gray) }
                }
                .frame(width: 50, height: 50)
                .background(Color.white) // خلفية بيضاء للأيقونة لتبدو نظيفة
                .clipShape(Circle())
            }
        }
    }
}

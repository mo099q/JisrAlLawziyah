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
// MARK: - 2. المدراء (الطقس والموقع)
// ==========================================

class WeatherManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var condition: String = "جاري التحميل"
    @Published var icon: String = "moon.stars.fill"
    
    func fetchWeather() {
        // إحداثيات المنتجع (21.1224, 40.3190)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=21.1224&longitude=40.3190&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let decoded = try? JSONDecoder().decode(WeatherResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.temperature = "\(Int(decoded.current_weather.temperature))°"
                let code = decoded.current_weather.weathercode
                if code > 50 { self.condition = "ممطر/ضباب"; self.icon = "cloud.fog.fill" }
                else if decoded.current_weather.temperature < 15 { self.condition = "بارد جداً"; self.icon = "thermometer.snowflake" }
                else { self.condition = "أجواء صافية"; self.icon = "moon.stars.fill" }
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
        DispatchQueue.main.async { self.distanceText = dist < 0.5 ? "وصلت للموقع" : String(format: "%.1f كم", dist) }
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
// MARK: - 4. التبويبات
// ==========================================
struct MainTabView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().barTintColor = UIColor.black
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }
            
            BookingListView()
                .tabItem { Label("الحجوزات", systemImage: "calendar") }
            
            ServicesView()
                .tabItem { Label("الخدمات", systemImage: "bell.fill") }
            
            BudgetView()
                .tabItem { Label("الميزانية", systemImage: "banknote") }
        }
        .accentColor(.yellow)
    }
}

// ==========================================
// MARK: - 5. الشاشات
// ==========================================

// --- 1. الصفحة الرئيسية (المحدثة) ---
struct HomeView: View {
    @StateObject var weatherManager = WeatherManager()
    @StateObject var locationManager = LocationManager()
    
    let mainImage = "https://images.unsplash.com/photo-1600607686527-6fb886090705?w=800&q=80"
    let googleMapsLink = URL(string: "https://www.google.com/maps/search/?api=1&query=21.1224671,40.3190809")!
    
    // بكجات الألعاب
    let packages = [
        GamePackage(pay: 100, get: 110, color: .purple),
        GamePackage(pay: 200, get: 230, color: .blue),
        GamePackage(pay: 300, get: 350, color: .orange),
        GamePackage(pay: 500, get: 600, color: .green),
        GamePackage(pay: 750, get: 1000, color: .red)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // 1. صورة الهيدر
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: mainImage)) { phase in
                                if let image = phase.image { image.resizable().scaledToFill() }
                                else { Rectangle().fill(Color.gray.opacity(0.2)) }
                            }
                            .frame(height: 350)
                            .clipped()
                            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("منتجع جسر اللوزية")
                                    .font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                                Text("وجهتك الفاخرة في أعالي الشفا")
                                    .font(.subheadline).foregroundColor(.yellow)
                            }
                            .padding(20)
                            .padding(.bottom, 20)
                        }
                        .ignoresSafeArea(edges: .top)
                        
                        VStack(spacing: 25) {
                            
                            // 2. بطاقة الطقس الجديدة (Six Flags Style)
                            SixFlagsWeatherCard(weatherManager: weatherManager)
                                .offset(y: -50) // تداخل مع الصورة
                            
                            // 3. تذاكر الدخول
                            VStack(alignment: .leading, spacing: 15) {
                                Text("🎫 تذاكر الدخول").font(.headline).foregroundColor(.white)
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("تذكرة الفرد").foregroundColor(.gray).font(.caption)
                                        Text("15 ريال").font(.title3).bold().foregroundColor(.yellow)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("دخول مجاني").foregroundColor(.green).font(.caption)
                                        Text("الأطفال < سنتين & ذوي الهمم").font(.caption2).foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6).opacity(0.3))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .offset(y: -30)
                            
                            // 4. عروض شحن الألعاب (البكجات)
                            VStack(alignment: .leading, spacing: 15) {
                                Text("🎮 عروض شحن الرصيد").font(.headline).foregroundColor(.white).padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        Spacer().frame(width: 10)
                                        ForEach(packages) { pkg in
                                            VStack {
                                                Text("ادفع \(Int(pkg.pay))").font(.caption).foregroundColor(.white.opacity(0.7))
                                                Text("\(Int(pkg.get))").font(.title).bold().foregroundColor(.white)
                                                Text("رصيد").font(.caption2).foregroundColor(.white)
                                            }
                                            .padding()
                                            .frame(width: 110, height: 110)
                                            .background(pkg.color.opacity(0.6))
                                            .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                            .offset(y: -20)
                            
                            // 5. زر الموقع
                            Link(destination: googleMapsLink) {
                                HStack {
                                    Text("اتجه للموقع (Google Maps)")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "paperplane.fill")
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            Spacer().frame(height: 50)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { weatherManager.fetchWeather() }
        }
    }
}

// --- 2. صفحة الحجوزات ---
struct BookingListView: View {
    let sessions = [
        SessionType(name: "البلورات (القباب)", price: 80, features: "إطلالة بانورامية • تكييف", imageURL: "https://images.unsplash.com/photo-1649170343284-5806dd601e3c?w=800&q=80"),
        SessionType(name: "الأكواخ الريفية", price: 100, features: "مطلة على النهر • خصوصية", imageURL: "https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=800&q=80"),
        SessionType(name: "بيوت الشعر", price: 90, features: "جلسة تراثية • دافئة", imageURL: "https://images.unsplash.com/photo-1550586678-f7b288a2983b?w=800&q=80")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("حجز الجلسات").font(.largeTitle).bold().foregroundColor(.white).padding(.top, 30).padding(.horizontal)
                        
                        ForEach(sessions) { session in
                            NavigationLink(destination: BookingFormView(session: session)) {
                                SessionCardIOS(session: session)
                            }
                        }
                        Text("⚠️ الحجز غير مسترد").font(.caption).foregroundColor(.gray).padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 3. صفحة الميزانية والحاسبة ---
struct BudgetView: View {
    @State private var people = 1
    @State private var selectedPkg = 0.0
    @State private var sessionPrice = 0.0
    
    var total: Int { Int((Double(people) * 15.0) + selectedPkg + sessionPrice) }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        Text("حاسبة الميزانية").font(.largeTitle).bold().foregroundColor(.white).padding(.top, 30)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("عدد الزوار (15 ريال/فرد)").foregroundColor(.white)
                                Spacer()
                                Stepper("\(people)", value: $people, in: 1...50).labelsHidden().background(Color.white).cornerRadius(8)
                            }
                            
                            HStack {
                                Text("شحن الألعاب").foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $selectedPkg) {
                                    Text("بدون").tag(0.0)
                                    Text("100 (رصيد 110)").tag(100.0)
                                    Text("300 (رصيد 350)").tag(300.0)
                                    Text("750 (رصيد 1000)").tag(750.0)
                                }.pickerStyle(MenuPickerStyle()).accentColor(.yellow)
                            }
                            
                            HStack {
                                Text("الجلسة").foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $sessionPrice) {
                                    Text("بدون").tag(0.0)
                                    Text("بلورة (80)").tag(80.0)
                                    Text("شعر (90)").tag(90.0)
                                    Text("كوخ (100)").tag(100.0)
                                }.pickerStyle(MenuPickerStyle()).accentColor(.yellow)
                            }
                            
                            Divider().background(Color.gray)
                            
                            HStack {
                                Text("الإجمالي المتوقع:").font(.title2).bold().foregroundColor(.white)
                                Spacer()
                                Text("\(total) ريال").font(.largeTitle).bold().foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.3))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 4. صفحة الخدمات ---
struct ServicesView: View {
    let services = [
        ServiceItem(name: "قهوة/شاي", icon: "cup.and.saucer.fill"),
        ServiceItem(name: "جمر", icon: "flame.fill"),
        ServiceItem(name: "بطانيات", icon: "bed.double.fill"),
        ServiceItem(name: "مساعدة", icon: "person.wave.2.fill")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        Text("الخدمات").font(.largeTitle).bold().foregroundColor(.white).padding(.top, 30)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(services) { item in
                                Button(action: { 
                                    let msg = "طلب خدمة: \(item.name)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                    if let url = URL(string: "https://wa.me/966549949745?text=\(msg)") { UIApplication.shared.open(url) }
                                }) {
                                    VStack {
                                        Image(systemName: item.icon).font(.largeTitle).foregroundColor(.yellow)
                                        Text(item.name).bold().foregroundColor(.white).padding(.top, 5)
                                    }
                                    .frame(height: 100).frame(maxWidth: .infinity)
                                    .background(Color(UIColor.systemGray6).opacity(0.3))
                                    .cornerRadius(15)
                                }
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

// ==========================================
// MARK: - 6. المكونات (UI Components)
// ==========================================

// بطاقة الطقس البيضاء (Six Flags Style)
struct SixFlagsWeatherCard: View {
    @ObservedObject var weatherManager: WeatherManager
    let forecast = [
        (day: "الإثنين", icon: "sun.max.fill", temp: "26°", color: Color.orange),
        (day: "الثلاثاء", icon: "cloud.fill", temp: "22°", color: Color.blue),
        (day: "الأربعاء", icon: "cloud.rain.fill", temp: "19°", color: Color.gray),
        (day: "الخميس", icon: "cloud.fog.fill", temp: "18°", color: Color.purple)
    ]
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(weatherManager.temperature).font(.system(size: 45, weight: .bold)).foregroundColor(.black)
                        Image(systemName: weatherManager.icon).font(.system(size: 35)).foregroundColor(.orange)
                    }
                    Text(weatherManager.condition).font(.caption).bold().foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("الطقس اليوم").font(.caption).foregroundColor(.gray)
                    Text("الشفا").bold().foregroundColor(.black)
                }
            }
            Divider()
            HStack(spacing: 0) {
                ForEach(forecast, id: \.day) { item in
                    VStack(spacing: 5) {
                        Text(item.day).font(.caption2).foregroundColor(.gray)
                        Image(systemName: item.icon).foregroundColor(item.color)
                        Text(item.temp).font(.caption).bold().foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

struct SessionCardIOS: View {
    let session: SessionType
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: session.imageURL)) { phase in
                if let image = phase.image { image.resizable().scaledToFill().frame(height: 200).clipped() }
                else { Color.gray.frame(height: 200) }
            }
            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
            
            VStack(alignment: .leading) {
                HStack {
                    Text(session.name).bold().foregroundColor(.white)
                    Spacer()
                    Text("\(Int(session.price)) ﷼").font(.caption).bold().padding(6).background(Color.yellow).foregroundColor(.black).cornerRadius(8)
                }
                Text(session.features).font(.caption).foregroundColor(.gray)
            }
            .padding()
        }
        .cornerRadius(16).padding(.horizontal)
    }
}

struct BookingFormView: View {
    let session: SessionType
    @State private var name = ""; @State private var count = ""; @State private var date = Date()
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("حجز \(session.name)").font(.title).bold().foregroundColor(.white).padding(.top)
                TextField("الاسم", text: $name).padding().background(Color.white).cornerRadius(10).foregroundColor(.black).padding(.horizontal)
                TextField("العدد", text: $count).keyboardType(.numberPad).padding().background(Color.white).cornerRadius(10).foregroundColor(.black).padding(.horizontal)
                DatePicker("الوقت", selection: $date).colorScheme(.dark).padding(.horizontal)
                Button(action: {
                    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
                    let msg = "حجز:\n🏠 \(session.name)\n👤 \(name)\n👥 \(count)\n📅 \(f.string(from: date))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "https://wa.me/966549949745?text=\(msg)") { UIApplication.shared.open(url) }
                }) {
                    Text("تأكيد (واتساب)").bold().frame(maxWidth: .infinity).padding().background(Color.green).foregroundColor(.white).cornerRadius(15).padding()
                }
                Spacer()
            }
        }
    }
}

import SwiftUI
import MapKit
import CoreLocation

// ==========================================
// MARK: - 1. DATA MODELS
// ==========================================

struct MenuItem: Identifiable {
    let id = UUID(); let name: String; let price: Double; let image: String
}

struct SessionStatus: Identifiable {
    let id = UUID(); let name: String; let status: String; let color: Color
}

struct LocationPoint: Identifiable {
    let id = UUID(); let name: String; let coordinate: CLLocationCoordinate2D
}

// ==========================================
// MARK: - 2. MAIN APP SETUP
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
// MARK: - 3. TAB BAR NAVIGATION
// ==========================================
struct MainTabView: View {
    init() {
        // جعل البار السفلي أسود تماماً مثل Six Flags
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().barTintColor = UIColor.black
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "flag.fill") }
            
            TicketPassView() // ميزة جديدة (تذكرتي)
                .tabItem { Label("تذكرتي", systemImage: "qrcode") }
            
            FoodOrderView() // ميزة جديدة (الطلب المسبق)
                .tabItem { Label("الطلبات", systemImage: "cup.and.saucer.fill") }
            
            ResortMapView()
                .tabItem { Label("الخريطة", systemImage: "map.fill") }
        }
        .accentColor(.yellow) // اللون الأصفر المميز للمنتجعات
    }
}

// ==========================================
// MARK: - 4. SCREENS (الشاشات)
// ==========================================

// --- 1. الرئيسية (Home & Status) ---
struct HomeView: View {
    // حالة الجلسات (محاكاة لنظام Wait Times في Six Flags)
    let statuses = [
        SessionStatus(name: "البلورات", status: "متاح ✅", color: .green),
        SessionStatus(name: "الأكواخ", status: "مزدحم ⚠️", color: .orange),
        SessionStatus(name: "بيوت الشعر", status: "ممتلئ 🔴", color: .red)
    ]
    
    let headerImage = "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80" // صورة ليلية للمنتجع

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // صورة الهيدر الكبيرة
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: headerImage)) { phase in
                            if let image = phase.image { image.resizable().scaledToFill() }
                            else { Color.gray.opacity(0.3) }
                        }
                        .frame(height: 350)
                        .clipped()
                        .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                        
                        VStack(alignment: .leading) {
                            Text("أهلاً بك في جسر اللوزية")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                            Text("عيش المغامرة والاستجمام")
                                .font(.subheadline).foregroundColor(.yellow)
                        }
                        .padding()
                    }
                    .ignoresSafeArea()
                    
                    VStack(spacing: 25) {
                        
                        // شريط الحالة (Live Status)
                        VStack(alignment: .leading) {
                            Text("📊 حالة الجلسات الآن").font(.headline).foregroundColor(.gray)
                            HStack(spacing: 10) {
                                ForEach(statuses) { item in
                                    VStack {
                                        Text(item.name).font(.caption).bold()
                                        Text(item.status).font(.caption2).foregroundColor(item.color)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color(UIColor.systemGray6).opacity(0.3))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // الأزرار الكبيرة (Big Action Buttons)
                        HStack(spacing: 15) {
                            NavigationLink(destination: TicketPassView()) {
                                ActionCard(icon: "ticket.fill", title: "تذاكري", subtitle: "إظهار الباركود", color: .blue)
                            }
                            NavigationLink(destination: FoodOrderView()) {
                                ActionCard(icon: "fork.knife", title: "اطلب طعامك", subtitle: "تجاوز الانتظار", color: .orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        // زر الحجز السريع
                        Link(destination: URL(string: "https://wa.me/966549949745")!) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("حجز جلسة خاصة الآن")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity).padding().background(Color.yellow).foregroundColor(.black).cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // قسم الألعاب (Game Pass)
                        VStack(alignment: .leading) {
                            Text("🎮 بطاقة الألعاب").font(.headline).foregroundColor(.white)
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(15)
                                .overlay(
                                    Text("شحن الرصيد").font(.caption).bold().padding(5).background(Color.white).foregroundColor(.purple).cornerRadius(5).padding(),
                                    alignment: .bottomTrailing
                                )
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                    }
                }
                .background(Color.black)
            }
            .navigationBarHidden(true)
        }
    }
}

// --- 2. تذكرتي (Digital Pass - Six Flags Style) ---
struct TicketPassView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Text("تذكرة الدخول الرقمية").font(.headline).foregroundColor(.gray).padding(.top, 50)
                
                // تصميم الكرت
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "person.circle.fill").font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("ضيف المنتجع").font(.title2).bold()
                            Text("عضوية زائر").font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.yellow)
                    }
                    .padding(.bottom, 20)
                    
                    // الباركود الوهمي (محاكاة)
                    Image(systemName: "qrcode")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    
                    Text("امسح الكود عند البوابة للدخول")
                        .font(.caption).foregroundColor(.gray)
                    
                    Divider()
                    
                    HStack {
                        VStack {
                            Text("الرصيد").font(.caption).foregroundColor(.gray)
                            Text("0.00 ﷼").bold()
                        }
                        Spacer()
                        VStack {
                            Text("الصلاحية").font(.caption).foregroundColor(.gray)
                            Text("سارية").foregroundColor(.green).bold()
                        }
                    }
                }
                .padding(30)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
                .padding()
                .shadow(radius: 10)
                
                Spacer()
            }
        }
    }
}

// --- 3. الطلبات (Visual Menu) ---
struct FoodOrderView: View {
    // قائمة الطعام (صور ومسميات)
    let menuItems = [
        MenuItem(name: "لاتيه حار", price: 18, image: "https://images.unsplash.com/photo-1541167760496-1628856ab772?w=400"),
        MenuItem(name: "كيكة العسل", price: 25, image: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400"),
        MenuItem(name: "موهيتو", price: 20, image: "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400"),
        MenuItem(name: "برجر مشوي", price: 35, image: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400"),
        MenuItem(name: "بان كيك", price: 22, image: "https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=400"),
        MenuItem(name: "شاي بخار", price: 5, image: "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400")
    ]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("قائمة الطعام").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                        Text("اطلب الآن واستلم طلبك جاهزاً").font(.caption).foregroundColor(.gray)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(menuItems) { item in
                                Button(action: { sendOrder(item: item.name) }) {
                                    VStack {
                                        AsyncImage(url: URL(string: item.image)) { p in
                                            if let img = p.image { img.resizable().scaledToFill() }
                                            else { Color.gray }
                                        }
                                        .frame(height: 120)
                                        .clipped()
                                        
                                        VStack(alignment: .leading) {
                                            Text(item.name).bold().foregroundColor(.white)
                                            Text("\(Int(item.price)) ﷼").font(.caption).foregroundColor(.yellow)
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .background(Color(UIColor.systemGray6).opacity(0.3))
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func sendOrder(item: String) {
        let msg = "مرحباً، أرغب بطلب: \(item)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/966549949745?text=\(msg)") { UIApplication.shared.open(url) }
    }
}

// --- 4. الخريطة (Resort Map) ---
struct ResortMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809),
        span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
    )
    let locations = [LocationPoint(name: "منتجع جسر اللوزية", coordinate: CLLocationCoordinate2D(latitude: 21.1224671, longitude: 40.3190809))]
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: locations) { loc in
                MapMarker(coordinate: loc.coordinate, tint: .red)
            }
            .edgesIgnoringSafeArea(.top)
            
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text("موقع المنتجع").bold()
                        Text("الشفا، الطائف").font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Link(destination: URL(string: "https://www.google.com/maps/search/?api=1&query=21.1224671,40.3190809")!) {
                        Image(systemName: "car.fill")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .padding()
                .shadow(radius: 10)
            }
        }
    }
}

// ==========================================
// MARK: - 5. UI COMPONENTS
// ==========================================

struct ActionCard: View {
    let icon: String, title: String, subtitle: String, color: Color
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: icon).font(.largeTitle).foregroundColor(color).padding(.bottom, 5)
            Text(title).font(.headline).bold().foregroundColor(.white)
            Text(subtitle).font(.caption).foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6).opacity(0.3))
        .cornerRadius(15)
    }
}

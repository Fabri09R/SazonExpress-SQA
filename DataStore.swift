import Foundation
import SwiftUI

class DataStore: ObservableObject {

    // MARK: - Published State
    @Published var products: [Product] = []
    @Published var cartItems: [CartItem] = []
    @Published var favoriteIDs: [UUID] = []
    @Published var savedCards: [SavedCard] = []
    @Published var savedAddresses: [SavedAddress] = []
    @Published var categories: [String] = []
    @Published var registeredUsers: [RegisteredUser] = []

    @Published var isAdminLoggedIn: Bool = false
    @Published var isUserLoggedIn: Bool = false
    @Published var currentUserEmail: String = ""

    // Order state
    @Published var activeOrder: [CartItem] = []
    @Published var orderStage: Int = 0        // 0=none, 1=prep, 2=camino, 3=listo
    @Published var orderTotal: Int = 0
    @Published var orderDeliveryFee: Int = 0

    // Order timer — lives in DataStore so it survives tab switches
    private var orderTimer: Timer? = nil

    // Profile
    @Published var userName: String = ""
    @Published var isDarkMode: Bool = false
    @Published var tipPercent: Int = 10

    // Admin credentials (mutable)
    @Published var adminUsername: String = "admin"
    @Published var adminPassword: String = "sazon2026"

    // Keys
    private let productsKey   = "sazon_products"
    private let cartKey       = "sazon_cart"
    private let favKey        = "sazon_favorites"
    private let cardsKey      = "sazon_cards"
    private let addressesKey  = "sazon_addresses"
    private let categoriesKey = "sazon_categories"
    private let sessionKey    = "sazon_session"
    private let userNameKey   = "sazon_username"
    private let darkModeKey   = "sazon_darkmode"
    private let tipKey        = "sazon_tip"
    private let adminUserKey  = "sazon_admin_user"
    private let adminPassKey  = "sazon_admin_pass"
    private let usersKey      = "sazon_users"

    init() { loadAll() }

    func loadAll() {
        loadProducts(); loadCart(); loadFavorites()
        loadUsers()
        loadCards(); loadAddresses(); loadCategories(); loadSession()
        userName   = UserDefaults.standard.string(forKey: userNameKey) ?? "Usuario"
        isDarkMode = UserDefaults.standard.bool(forKey: darkModeKey)
        tipPercent = UserDefaults.standard.integer(forKey: tipKey) == 0 ? 10 : UserDefaults.standard.integer(forKey: tipKey)
        adminUsername = UserDefaults.standard.string(forKey: adminUserKey) ?? "admin"
        adminPassword = UserDefaults.standard.string(forKey: adminPassKey) ?? "sazon2026"
    }

    // MARK: - Session
    func loadSession() {
        let email = UserDefaults.standard.string(forKey: sessionKey) ?? ""
        if !email.isEmpty { isUserLoggedIn = true; currentUserEmail = email }
    }
    func saveSession(email: String) { UserDefaults.standard.set(email, forKey: sessionKey) }
    func clearSession() { UserDefaults.standard.removeObject(forKey: sessionKey) }

    // MARK: - Products
    func loadProducts() {
        if let data = UserDefaults.standard.data(forKey: productsKey),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            products = decoded
        } else { products = defaultProducts(); saveProducts() }
    }
    func saveProducts() {
        if let enc = try? JSONEncoder().encode(products) { UserDefaults.standard.set(enc, forKey: productsKey) }
    }

    // MARK: - Categories
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            categories = decoded
        } else { categories = defaultCategories; saveCategories() }
    }
    func saveCategories() {
        if let enc = try? JSONEncoder().encode(categories) { UserDefaults.standard.set(enc, forKey: categoriesKey) }
    }
    func addCategory(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, !categories.contains(name) else { return }
        categories.append(name); saveCategories()
    }
    func deleteCategory(at offsets: IndexSet) { categories.remove(atOffsets: offsets); saveCategories() }

    // MARK: - Cart
    func loadCart() {
        if let data = UserDefaults.standard.data(forKey: cartKey),
           let decoded = try? JSONDecoder().decode([CartItem].self, from: data) { cartItems = decoded }
    }
    func saveCart() {
        if let enc = try? JSONEncoder().encode(cartItems) { UserDefaults.standard.set(enc, forKey: cartKey) }
    }
    func addToCart(product: Product) {
        if let i = cartItems.firstIndex(where: { $0.product.id == product.id }) { cartItems[i].quantity += 1 }
        else { cartItems.append(CartItem(product: product, quantity: 1)) }
        saveCart()
    }
    func increaseQuantity(item: CartItem) {
        if let i = cartItems.firstIndex(where: { $0.id == item.id }) { cartItems[i].quantity += 1; saveCart() }
    }
    func decreaseQuantity(item: CartItem) {
        if let i = cartItems.firstIndex(where: { $0.id == item.id }) {
            if cartItems[i].quantity > 1 { cartItems[i].quantity -= 1 } else { cartItems.remove(at: i) }
            saveCart()
        }
    }
    func clearCart() { cartItems = []; saveCart() }
    var cartTotal: Int { cartItems.reduce(0) { $0 + $1.total } }
    var cartCount: Int { cartItems.reduce(0) { $0 + $1.quantity } }

    // MARK: - Order
    func placeOrder(deliveryFee: Int) {
        activeOrder = cartItems
        orderTotal = cartTotal
        orderDeliveryFee = deliveryFee
        orderStage = 1
        clearCart()
        startOrderTimer()
    }
    func finishOrder() {
        orderTimer?.invalidate()
        orderTimer = nil
        activeOrder = []
        orderStage = 0
        orderTotal = 0
        orderDeliveryFee = 0
    }
    func startOrderTimer() {
        // Only start if not already running and order is active
        guard orderTimer == nil, orderStage > 0, orderStage < 3 else { return }
        var elapsed = (orderStage - 1) * 30
        orderTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            elapsed += 1
            let newStage = min(elapsed / 30 + 1, 3)
            if newStage != self.orderStage {
                DispatchQueue.main.async {
                    withAnimation { self.orderStage = newStage }
                    if newStage == 3 {
                        self.orderTimer?.invalidate()
                        self.orderTimer = nil
                    }
                }
            }
        }
    }

    // MARK: - Favorites
    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favKey),
           let decoded = try? JSONDecoder().decode([UUID].self, from: data) { favoriteIDs = decoded }
    }
    func saveFavorites() {
        if let enc = try? JSONEncoder().encode(favoriteIDs) { UserDefaults.standard.set(enc, forKey: favKey) }
    }
    func toggleFavorite(product: Product) {
        if favoriteIDs.contains(product.id) { favoriteIDs.removeAll { $0 == product.id } }
        else { favoriteIDs.append(product.id) }
        saveFavorites()
    }
    func isFavorite(product: Product) -> Bool { favoriteIDs.contains(product.id) }
    var favoriteProducts: [Product] { products.filter { favoriteIDs.contains($0.id) } }

    // MARK: - Cards
    func loadCards() {
        if let data = UserDefaults.standard.data(forKey: cardsKey),
           let decoded = try? JSONDecoder().decode([SavedCard].self, from: data) { savedCards = decoded }
    }
    func saveCards() {
        if let enc = try? JSONEncoder().encode(savedCards) { UserDefaults.standard.set(enc, forKey: cardsKey) }
    }
    func addCard(_ card: SavedCard) { savedCards.append(card); saveCards() }
    func deleteCard(at offsets: IndexSet) { savedCards.remove(atOffsets: offsets); saveCards() }

    // MARK: - Addresses
    func loadAddresses() {
        if let data = UserDefaults.standard.data(forKey: addressesKey),
           let decoded = try? JSONDecoder().decode([SavedAddress].self, from: data) { savedAddresses = decoded }
    }
    func saveAddresses() {
        if let enc = try? JSONEncoder().encode(savedAddresses) { UserDefaults.standard.set(enc, forKey: addressesKey) }
    }
    func addAddress(_ addr: SavedAddress) { savedAddresses.append(addr); saveAddresses() }
    func deleteAddress(at offsets: IndexSet) { savedAddresses.remove(atOffsets: offsets); saveAddresses() }

    // MARK: - Admin
    func addProduct(_ p: Product) { products.append(p); saveProducts() }
    func updateProduct(_ p: Product) {
        if let i = products.firstIndex(where: { $0.id == p.id }) { products[i] = p; saveProducts() }
    }
    func deleteProduct(at offsets: IndexSet) { products.remove(atOffsets: offsets); saveProducts() }
    func toggleAvailability(product: Product) {
        if let i = products.firstIndex(where: { $0.id == product.id }) { products[i].isAvailable.toggle(); saveProducts() }
    }
    func updateAdminCredentials(username: String, password: String) {
        adminUsername = username; adminPassword = password
        UserDefaults.standard.set(username, forKey: adminUserKey)
        UserDefaults.standard.set(password, forKey: adminPassKey)
    }

    // MARK: - Auth
    func loginAdmin(username: String, password: String) -> Bool {
        if username == adminUsername && password == adminPassword { isAdminLoggedIn = true; return true }
        return false
    }
    func loginUser(email: String) { isUserLoggedIn = true; currentUserEmail = email; saveSession(email: email) }
    func logout() { isUserLoggedIn = false; isAdminLoggedIn = false; currentUserEmail = ""; clearSession() }

    // MARK: - Profile
    func saveUserName(_ name: String) { userName = name; UserDefaults.standard.set(name, forKey: userNameKey) }
    func saveDarkMode(_ val: Bool) { isDarkMode = val; UserDefaults.standard.set(val, forKey: darkModeKey) }
    func saveTip(_ val: Int) { tipPercent = val; UserDefaults.standard.set(val, forKey: tipKey) }

    // MARK: - User Registration
    func loadUsers() {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let decoded = try? JSONDecoder().decode([RegisteredUser].self, from: data) {
            registeredUsers = decoded
        }
    }
    func saveUsers() {
        if let enc = try? JSONEncoder().encode(registeredUsers) {
            UserDefaults.standard.set(enc, forKey: usersKey)
        }
    }
    func registerUser(name: String, email: String, password: String) {
        registeredUsers.append(RegisteredUser(name: name, email: email, password: password))
        saveUsers()
    }
    func findUser(email: String) -> RegisteredUser? {
        registeredUsers.first { $0.email == email }
    }

    // MARK: - Computed
    var promoProducts: [Product] { products.filter { $0.isPromo && $0.isAvailable } }
    var availableProducts: [Product] { products.filter { $0.isAvailable } }

    private func defaultProducts() -> [Product] {
        [
            Product(name: "Hamburguesa Clásica",
                    description: "Hamburguesa gourmet con jugoso medallón de res 115g, queso Provolone, cebolla caramelizada, arúgula fresca, tocino crujiente y mayonesa de ajo tostado, en pan brioche artesanal.",
                    price: 2000, imageName: "img_hamburguesa", category: "Hamburguesas", isPromo: true, promoLabel: "20% Off"),
            Product(name: "Wrap de Pollo",
                    description: "Wrap con tortilla suave, pollo sazonado y vegetales frescos.",
                    price: 1500, imageName: "img_wrap", category: "Wraps", isPromo: true, promoLabel: "2x1"),
            Product(name: "Pollo Frito",
                    description: "Pollo frito crujiente por fuera y jugoso por dentro, sazonado con especias especiales.",
                    price: 2000, imageName: "img_pollo", category: "Pollo"),
            Product(name: "Papas Fritas",
                    description: "Papas fritas crujientes con sal y especias.",
                    price: 800, imageName: "img_papas", category: "Acompañamientos"),
            Product(name: "Refresco de Naranja", description: "Refresco natural de naranja recién exprimido.",
                    price: 600, imageName: "img_refresco_naranja", category: "Bebidas"),
            Product(name: "Refresco de Limón", description: "Refresco natural de limón con un toque de menta.",
                    price: 600, imageName: "img_refresco_limon", category: "Bebidas"),
            Product(name: "Refresco de Piña", description: "Refresco natural de piña, fresco y tropical.",
                    price: 600, imageName: "img_refresco_pinia", category: "Bebidas"),
        ]
    }
}


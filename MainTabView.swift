import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        TabView {
            MenuView()
                .tabItem { Label("Menú", systemImage: "house.fill") }

            // Si hay pedido activo muestra estado, si no el carrito
            Group {
                if store.orderStage > 0 {
                    OrderStatusView()
                } else {
                    CartView()
                }
            }
            .tabItem { Label("Carrito", systemImage: "cart.fill") }
            .badge(store.orderStage == 0 && store.cartCount > 0 ? store.cartCount : 0)

            ProfileView()
                .tabItem { Label("Configuración", systemImage: "line.3.horizontal") }
        }
        .accentColor(.red)
    }
}

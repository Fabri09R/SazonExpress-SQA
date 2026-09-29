import SwiftUI
import MapKit
import CoreLocation

private let storeLocation = CLLocationCoordinate2D(latitude: 9.902759203810225, longitude: -84.10012767029829)
private let ratePerKm = 200.0

struct CartView: View {
    @EnvironmentObject var store: DataStore

    // Tarjeta
    @State private var useNewCard = false
    @State private var selectedCardID: UUID? = nil
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""

    // Ubicación
    @State private var useNewAddress = false
    @State private var selectedAddressID: UUID? = nil
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var region = MKCoordinateRegion(
        center: storeLocation,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var showErrors = false

    var deliveryFee: Int {
        // Si usa dirección guardada
        if let addrID = selectedAddressID,
           let addr = store.savedAddresses.first(where: { $0.id == addrID }) {
            let from = CLLocation(latitude: storeLocation.latitude, longitude: storeLocation.longitude)
            let to   = CLLocation(latitude: addr.latitude, longitude: addr.longitude)
            return Int(from.distance(from: to) / 1000.0 * ratePerKm)
        }
        // Si usa ubicación nueva en el mapa
        if let loc = userLocation {
            let from = CLLocation(latitude: storeLocation.latitude, longitude: storeLocation.longitude)
            let to   = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            return Int(from.distance(from: to) / 1000.0 * ratePerKm)
        }
        return 0
    }

    var grandTotal: Int { store.cartTotal + deliveryFee }

    var locationReady: Bool {
        selectedAddressID != nil || userLocation != nil
    }

    var cardReady: Bool {
        selectedCardID != nil || (cardNumber.count >= 19 && !expiryDate.isEmpty && cvv.count >= 3)
    }

    var body: some View {
        NavigationView {
            if store.cartItems.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cart").font(.system(size: 60)).foregroundColor(.gray)
                    Text("Tu carrito está vacío").font(.title3).foregroundColor(.secondary)
                    Text("Explorá el menú y agregá productos").font(.subheadline).foregroundColor(.secondary)
                }
                .navigationTitle("Carrito")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Header
                        HStack {
                            Button { store.clearCart() } label: {
                                Image(systemName: "xmark").foregroundColor(.primary)
                            }
                            Text("Productos en carrito:").font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal).padding(.top, 8)

                        // Items
                        VStack(spacing: 0) {
                            ForEach(store.cartItems) { item in
                                CartItemRow(item: item)
                                Divider().padding(.leading, 80)
                            }
                        }
                        .background(Color(.systemBackground)).cornerRadius(12)
                        .padding(.horizontal)

                        // Subtotal
                        HStack {
                            Text("Subtotal:").font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text("₡\(store.cartTotal)").font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                        }
                        .padding(.horizontal)

                        Divider().padding(.horizontal)

                        Text("Completar compra").font(.headline).padding(.horizontal)

                        // ── TARJETA ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Datos de tarjeta").font(.subheadline).foregroundColor(.secondary).padding(.horizontal)

                            // Selector tarjetas guardadas
                            if !store.savedCards.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(store.savedCards) { card in
                                        CardOptionRow(
                                            card: card,
                                            isSelected: selectedCardID == card.id && !useNewCard
                                        ) {
                                            selectedCardID = card.id
                                            useNewCard = false
                                        }
                                    }

                                    // Opción nueva tarjeta
                                    Button {
                                        useNewCard = true
                                        selectedCardID = nil
                                    } label: {
                                        HStack {
                                            Image(systemName: useNewCard ? "checkmark.circle.fill" : "plus.circle")
                                                .foregroundColor(.red)
                                            Text("Usar otra tarjeta")
                                                .font(.subheadline).foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(useNewCard ? Color.red.opacity(0.08) : Color(.systemGray6))
                                        .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Formulario nueva tarjeta
                            if store.savedCards.isEmpty || useNewCard {
                                VStack(spacing: 10) {
                                    TextField("Número de tarjeta", text: $cardNumber)
                                        .keyboardType(.numberPad).padding(12)
                                        .background(Color(.systemGray6)).cornerRadius(10)
                                        .onChange(of: cardNumber) { cardNumber = formatCard($0) }
                                    HStack(spacing: 10) {
                                        TextField("Fecha vencimiento", text: $expiryDate)
                                            .keyboardType(.numberPad).padding(12)
                                            .background(Color(.systemGray6)).cornerRadius(10)
                                        SecureField("CVV", text: $cvv)
                                            .keyboardType(.numberPad).padding(12)
                                            .background(Color(.systemGray6)).cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // ── UBICACIÓN ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ubicación").font(.subheadline).foregroundColor(.secondary).padding(.horizontal)

                            // Selector direcciones guardadas
                            if !store.savedAddresses.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(store.savedAddresses) { addr in
                                        AddressOptionRow(
                                            address: addr,
                                            isSelected: selectedAddressID == addr.id && !useNewAddress
                                        ) {
                                            selectedAddressID = addr.id
                                            useNewAddress = false
                                            userLocation = nil
                                        }
                                    }

                                    Button {
                                        useNewAddress = true
                                        selectedAddressID = nil
                                        userLocation = nil
                                    } label: {
                                        HStack {
                                            Image(systemName: useNewAddress ? "checkmark.circle.fill" : "plus.circle")
                                                .foregroundColor(.red)
                                            Text("Usar otra ubicación")
                                                .font(.subheadline).foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(useNewAddress ? Color.red.opacity(0.08) : Color(.systemGray6))
                                        .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Mapa nueva ubicación
                            if store.savedAddresses.isEmpty || useNewAddress {
                                ZStack(alignment: .bottomTrailing) {
                                    MapViewWithPin(region: $region, userLocation: $userLocation)
                                        .frame(height: 160).cornerRadius(12).padding(.horizontal)
                                    Text("Tocá el mapa para marcar tu dirección")
                                        .font(.caption2).foregroundColor(.white)
                                        .padding(6).background(Color.black.opacity(0.55)).cornerRadius(6)
                                        .padding(.trailing, 20).padding(.bottom, 8)
                                }
                            }

                            // Envío y total
                            HStack {
                                Text("Envío:").font(.subheadline).fontWeight(.semibold)
                                Spacer()
                                Text(locationReady ? "₡\(deliveryFee)" : "Seleccioná ubicación")
                                    .font(.subheadline).fontWeight(.bold)
                                    .foregroundColor(locationReady ? .red : .secondary)
                            }
                            .padding(.horizontal)

                            HStack {
                                Text("Total:").font(.subheadline).fontWeight(.bold)
                                Spacer()
                                Text("₡\(grandTotal)").font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }

                        if showErrors {
                            Text("Verificá los datos de tarjeta (fecha válida MM/AA) y seleccioná una ubicación.")
                                .font(.caption).foregroundColor(.red).padding(.horizontal)
                        }

                        Button { confirmOrder() } label: {
                            Text("Confirmar pedido — ₡\(grandTotal)")
                                .foregroundColor(.white).font(.headline)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color.red).cornerRadius(12)
                        }
                        .padding(.horizontal).padding(.bottom, 20)
                    }
                }
                .background(Color(.systemGray6))
                .navigationTitle("Carrito")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { preselectDefaults() }
            }
        }
    }

    func preselectDefaults() {
        if let first = store.savedCards.first { selectedCardID = first.id; useNewCard = false }
        if let first = store.savedAddresses.first { selectedAddressID = first.id; useNewAddress = false }
    }

    func confirmOrder() {
        // If using new card, validate expiry format and not expired
        if selectedCardID == nil {
            guard !isExpired(expiryDate) else { showErrors = true; return }
        }
        guard cardReady, locationReady else { showErrors = true; return }
        showErrors = false
        store.placeOrder(deliveryFee: deliveryFee)
    }

    func formatCard(_ value: String) -> String {
        let cleaned = String(value.filter { $0.isNumber }.prefix(16))
        var result = ""
        for (i, char) in cleaned.enumerated() {
            if i > 0 && i % 4 == 0 { result += " " }
            result.append(char)
        }
        return result
    }
}

// MARK: - Card Option Row
struct CardOptionRow: View {
    let card: SavedCard
    let isSelected: Bool
    let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.red)
                Image(systemName: "creditcard.fill").foregroundColor(.secondary)
                Text("•••• •••• •••• \(card.number)").font(.subheadline)
                Spacer()
                Text(card.expiry).font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(isSelected ? Color.red.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// MARK: - Address Option Row
struct AddressOptionRow: View {
    let address: SavedAddress
    let isSelected: Bool
    let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.red)
                Image(systemName: "mappin.circle.fill").foregroundColor(.secondary)
                Text(address.label).font(.subheadline)
                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.red.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    @EnvironmentObject var store: DataStore
    let item: CartItem
    var body: some View {
        HStack(spacing: 12) {
            ProductImage(product: item.product, width: 56, height: 56, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name).font(.subheadline).fontWeight(.semibold)
                Text("₡\(item.product.price)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 0) {
                Button { store.decreaseQuantity(item: item) } label: {
                    Image(systemName: "minus").foregroundColor(.white).font(.caption)
                        .frame(width: 28, height: 28).background(Color.red).clipShape(Capsule())
                }
                Text("\(item.quantity)").font(.subheadline).fontWeight(.bold)
                    .frame(minWidth: 28).multilineTextAlignment(.center)
                Button { store.increaseQuantity(item: item) } label: {
                    Image(systemName: "plus").foregroundColor(.white).font(.caption)
                        .frame(width: 28, height: 28).background(Color.red).clipShape(Capsule())
                }
            }
            Text("₡\(item.total)").font(.caption).fontWeight(.bold).foregroundColor(.red)
                .frame(minWidth: 50, alignment: .trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

// MARK: - Map with tap pin
struct MapViewWithPin: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var userLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.region = region
        map.delegate = context.coordinator
        let storePin = MKPointAnnotation()
        storePin.coordinate = storeLocation
        storePin.title = "Sazón Express"
        map.addAnnotation(storePin)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        map.addGestureRecognizer(tap)
        return map
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithPin
        var userPin: MKPointAnnotation?
        init(_ p: MapViewWithPin) { parent = p }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let map = g.view as? MKMapView else { return }
            let coord = map.convert(g.location(in: map), toCoordinateFrom: map)
            parent.userLocation = coord
            if let existing = userPin { map.removeAnnotation(existing) }
            let pin = MKPointAnnotation(); pin.coordinate = coord; pin.title = "Mi ubicación"
            map.addAnnotation(pin); userPin = pin
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation.title == "Sazón Express" else { return nil }
            let v = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "store")
            v.markerTintColor = .red; return v
        }
    }
}

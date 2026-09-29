import SwiftUI
import PhotosUI
import MapKit
import CoreLocation

struct ProfileView: View {
    @EnvironmentObject var store: DataStore
    @State private var showEditProfile = false
    @State private var showAdminLogin = false
    @State private var adminUser = ""
    @State private var adminPass = ""
    @State private var adminError = false

    var body: some View {
        NavigationView {
            List {

                // Header
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 54))
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("¡Hola! \(store.userName)")
                                .font(.title3).fontWeight(.bold)
                            Text(store.currentUserEmail)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preferencias
                Section(header: Text("Preferencias")) {

                    Button {
                        showEditProfile = true
                    } label: {
                        Label("Cambiar información de la cuenta", systemImage: "person")
                            .foregroundColor(.primary)
                    }

                    NavigationLink {
                        SavedCardsView().environmentObject(store)
                    } label: {
                        Label("Tarjetas Guardadas", systemImage: "creditcard")
                    }

                    NavigationLink {
                        SavedAddressesView().environmentObject(store)
                    } label: {
                        Label("Direcciones guardadas", systemImage: "mappin.and.ellipse")
                    }

                    HStack {
                        Label("Tema oscuro", systemImage: "moon.fill")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { store.isDarkMode },
                            set: { store.saveDarkMode($0) }
                        ))
                        .tint(.red)
                        .labelsHidden()
                    }
                }

                // Admin
                if store.isAdminLoggedIn {
                    Section {
                        NavigationLink {
                            AdminView().environmentObject(store)
                        } label: {
                            Label("Panel de administrador", systemImage: "slider.horizontal.3")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                    }
                } else {
                    Section {
                        Button {
                            showAdminLogin = true
                        } label: {
                            Label("Acceso administrador", systemImage: "lock.shield")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }

                // Cerrar sesión
                Section {
                    Button(role: .destructive) {
                        store.logout()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Configuración")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView().environmentObject(store)
            }
            .sheet(isPresented: $showAdminLogin) {
                adminSheet
            }
        }
    }

    var adminSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Credenciales de administrador")) {
                    TextField("Usuario", text: $adminUser).autocapitalization(.none)
                    SecureField("Contraseña", text: $adminPass)
                }
                if adminError {
                    Text("Usuario o contraseña incorrectos.")
                        .foregroundColor(.red).font(.caption)
                }
                Button("Ingresar") {
                    if store.loginAdmin(username: adminUser, password: adminPass) {
                        showAdminLogin = false
                    } else { adminError = true }
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Acceso Admin")
            .navigationBarItems(trailing: Button("Cancelar") { showAdminLogin = false })
        }
    }
}

// MARK: - Edit Profile
struct EditProfileView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var loginOption: String = "Google"
    let loginOptions = ["Google", "Apple", "Sin cuenta"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Foto de perfil")) {
                    HStack {
                        Spacer()
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    // Nota: cambio de foto real requiere PhotosPicker (iOS 16+)
                    // Para esta versión mostramos el ícono por defecto
                    Text("La foto de perfil usa tu ícono de cuenta")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Section(header: Text("Nombre")) {
                    TextField("Tu nombre", text: $name)
                }

                Section(header: Text("Método de inicio de sesión")) {
                    Picker("Inicio de sesión", selection: $loginOption) {
                        ForEach(loginOptions, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Editar perfil")
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() },
                trailing: Button("Guardar") {
                    if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        store.saveUserName(name)
                    }
                    dismiss()
                }.foregroundColor(.red).fontWeight(.bold)
            )
            .onAppear { name = store.userName }
        }
    }
}

// MARK: - Saved Cards
struct SavedCardsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddCard = false
    @State private var newNumber = ""
    @State private var newExpiry = ""
    @State private var newCVV = ""
    @State private var errorMsg = ""

    var body: some View {
        List {
            if !store.savedCards.isEmpty {
                Section(header: Text("Mis tarjetas")) {
                    ForEach(store.savedCards) { card in
                        HStack {
                            Image(systemName: "creditcard.fill").foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("•••• •••• •••• \(card.number)").fontWeight(.semibold)
                                Text("Vence: \(card.expiry)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { store.deleteCard(at: $0) }
                }
            }
            Section {
                Button { showAddCard = true } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.red)
                        Text("Agregar tarjeta").fontWeight(.semibold).foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Tarjetas Guardadas")
        .sheet(isPresented: $showAddCard) {
            NavigationView {
                Form {
                    Section(header: Text("Nueva tarjeta")) {
                        TextField("Número de tarjeta", text: $newNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: newNumber) { newNumber = formatCard($0) }
                        ExpiryPickerField(expiry: $newExpiry)
                        SecureField("Código de seguridad", text: $newCVV)
                            .keyboardType(.numberPad)
                    }
                    if !errorMsg.isEmpty {
                        Text(errorMsg).foregroundColor(.red).font(.caption)
                    }
                }
                .navigationTitle("Nueva tarjeta")
                .navigationBarItems(
                    leading: Button("Cancelar") { showAddCard = false; clearFields() },
                    trailing: Button("Guardar") { saveCard() }.foregroundColor(.red).fontWeight(.bold)
                )
            }
        }
    }

    func saveCard() {
        let last4 = String(newNumber.filter { $0.isNumber }.suffix(4))
        guard last4.count == 4 else { errorMsg = "Ingresá un número de tarjeta válido."; return }
        guard newExpiry.count == 5 else { errorMsg = "Ingresá la fecha en formato MM/AA."; return }
        guard newCVV.count >= 3 else { errorMsg = "El CVV debe tener al menos 3 dígitos."; return }
        guard !isExpired(newExpiry) else { errorMsg = "La tarjeta está vencida."; return }
        errorMsg = ""
        store.addCard(SavedCard(number: last4, expiry: newExpiry, fullNumber: newNumber))
        showAddCard = false; clearFields()
    }

    func clearFields() { newNumber = ""; newExpiry = ""; newCVV = ""; errorMsg = "" }

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

// MARK: - Saved Addresses
struct SavedAddressesView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddAddress = false
    @State private var newLabel = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 9.9281, longitude: -84.0907),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pickedLocation: CLLocationCoordinate2D? = nil
    @State private var showErrors = false

    var body: some View {
        List {
            if !store.savedAddresses.isEmpty {
                Section(header: Text("Mis direcciones")) {
                    ForEach(store.savedAddresses) { addr in
                        HStack {
                            Image(systemName: "mappin.circle.fill").foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text(addr.label).fontWeight(.semibold)
                                Text(String(format: "%.4f, %.4f", addr.latitude, addr.longitude))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { store.deleteAddress(at: $0) }
                }
            }

            Section {
                Button {
                    showAddAddress = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.red)
                        Text("Agregar dirección").fontWeight(.semibold).foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Direcciones guardadas")
        .sheet(isPresented: $showAddAddress) {
            NavigationView {
                VStack(spacing: 0) {
                    Form {
                        Section(header: Text("Nombre de la dirección")) {
                            TextField("Ej: Casa, Trabajo", text: $newLabel)
                        }
                        if showErrors {
                            Text("Ponele un nombre y marcá tu ubicación en el mapa.")
                                .foregroundColor(.red).font(.caption)
                        }
                    }
                    .frame(height: 160)

                    MapViewWithPin(region: $region, userLocation: $pickedLocation)
                        .ignoresSafeArea(edges: .bottom)
                }
                .navigationTitle("Nueva dirección")
                .navigationBarItems(
                    leading: Button("Cancelar") { showAddAddress = false },
                    trailing: Button("Guardar") {
                        guard !newLabel.trimmingCharacters(in: .whitespaces).isEmpty,
                              let loc = pickedLocation else { showErrors = true; return }
                        store.addAddress(SavedAddress(label: newLabel, latitude: loc.latitude, longitude: loc.longitude))
                        showAddAddress = false; newLabel = ""; pickedLocation = nil
                    }.foregroundColor(.red).fontWeight(.bold)
                )
            }
        }
    }
}


// MARK: - Shared card helpers (available globally in the module)
func formatExpiry(_ value: String) -> String {
    let digits = value.filter { $0.isNumber }
    let limited = String(digits.prefix(4))
    if limited.count > 2 {
        let month = String(limited.prefix(2))
        let year  = String(limited.suffix(limited.count - 2))
        return "\(month)/\(year)"
    }
    return limited
}

func isExpired(_ expiry: String) -> Bool {
    // Expects MM/AA
    let parts = expiry.split(separator: "/")
    guard parts.count == 2,
          let month = Int(parts[0]),
          let year  = Int(parts[1]),
          month >= 1, month <= 12 else { return true }

    let now = Date()
    let cal = Calendar.current
    let currentYear  = cal.component(.year,  from: now) % 100  // last 2 digits
    let currentMonth = cal.component(.month, from: now)

    if year < currentYear { return true }
    if year == currentYear && month < currentMonth { return true }
    return false
}

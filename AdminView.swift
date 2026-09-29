import SwiftUI
import PhotosUI

struct AdminView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddProduct = false
    @State private var productToEdit: Product? = nil
    @State private var showCategories = false
    @State private var showChangeCredentials = false

    var body: some View {
        List {
            ForEach(store.products) { product in
                AdminProductRow(product: product)
                    .onTapGesture { productToEdit = product }
            }
            .onDelete { store.deleteProduct(at: $0) }
        }
        .navigationTitle("Panel de Admin")
        .navigationBarItems(
            trailing: HStack(spacing: 14) {
                Button { showChangeCredentials = true } label: {
                    Image(systemName: "key.fill").foregroundColor(.red)
                }
                Button { showCategories = true } label: {
                    Image(systemName: "tag.fill").foregroundColor(.red)
                }
                Button { showAddProduct = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(.red).font(.title3)
                }
            }
        )
        .sheet(isPresented: $showAddProduct) {
            ProductFormView(product: nil).environmentObject(store)
        }
        .sheet(item: $productToEdit) { product in
            ProductFormView(product: product).environmentObject(store)
        }
        .sheet(isPresented: $showCategories) {
            CategoriesView().environmentObject(store)
        }
        .sheet(isPresented: $showChangeCredentials) {
            ChangeCredentialsView().environmentObject(store)
        }
    }
}

// MARK: - Change Credentials
struct ChangeCredentialsView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var newUser = ""
    @State private var newPass = ""
    @State private var confirmPass = ""
    @State private var showError = false
    @State private var errorMsg = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Credenciales actuales")) {
                    Text("Usuario: \(store.adminUsername)").foregroundColor(.secondary)
                    Text("Contraseña: \(String(repeating: "•", count: store.adminPassword.count))").foregroundColor(.secondary)
                }
                Section(header: Text("Nuevas credenciales")) {
                    TextField("Nuevo usuario", text: $newUser).autocapitalization(.none)
                    SecureField("Nueva contraseña", text: $newPass)
                    SecureField("Confirmar contraseña", text: $confirmPass)
                }
                if showError { Text(errorMsg).foregroundColor(.red).font(.caption) }
                if showSuccess { Text("¡Credenciales actualizadas!").foregroundColor(.green).font(.caption) }
            }
            .navigationTitle("Cambiar credenciales")
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() },
                trailing: Button("Guardar") { saveCredentials() }.foregroundColor(.red).fontWeight(.bold)
            )
            .onAppear { newUser = store.adminUsername }
        }
    }

    func saveCredentials() {
        guard !newUser.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMsg = "El usuario no puede estar vacío."; showError = true; return
        }
        guard newPass.count >= 6 else {
            errorMsg = "La contraseña debe tener al menos 6 caracteres."; showError = true; return
        }
        guard newPass == confirmPass else {
            errorMsg = "Las contraseñas no coinciden."; showError = true; return
        }
        showError = false
        store.updateAdminCredentials(username: newUser, password: newPass)
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}

// MARK: - Admin Product Row
struct AdminProductRow: View {
    @EnvironmentObject var store: DataStore
    let product: Product
    var body: some View {
        HStack(spacing: 12) {
            ProductImage(product: product, width: 56, height: 56, cornerRadius: 8)
                .opacity(product.isAvailable ? 1.0 : 0.4)
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name).font(.subheadline).fontWeight(.semibold).strikethrough(!product.isAvailable)
                Text(product.category).font(.caption).foregroundColor(.secondary)
                Text("₡\(product.price)").font(.caption).fontWeight(.bold).foregroundColor(.red)
            }
            Spacer()
            Button { store.toggleAvailability(product: product) } label: {
                VStack(spacing: 2) {
                    Image(systemName: product.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(product.isAvailable ? .green : .red).font(.title3)
                    Text(product.isAvailable ? "Activo" : "Inactivo")
                        .font(.caption2).foregroundColor(product.isAvailable ? .green : .red)
                }
            }
            Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Categories
struct CategoriesView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var newCategory = ""
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Categorías actuales")) {
                    ForEach(store.categories, id: \.self) { cat in Text(cat) }
                        .onDelete { store.deleteCategory(at: $0) }
                }
                Section(header: Text("Nueva categoría")) {
                    HStack {
                        TextField("Nombre", text: $newCategory)
                        Button("Agregar") { store.addCategory(newCategory); newCategory = "" }
                            .foregroundColor(.red)
                            .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Categorías")
            .navigationBarItems(trailing: Button("Listo") { dismiss() }.foregroundColor(.red))
        }
    }
}

// MARK: - Product Form
struct ProductFormView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let product: Product?

    @State private var name = ""
    @State private var description = ""
    @State private var priceText = ""
    @State private var selectedImage = availableImageNames[0]
    @State private var selectedCategory = ""
    @State private var isAvailable = true
    @State private var isPromo = false
    @State private var promoLabel = ""
    @State private var showErrors = false

    // Foto de galería
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var pickedUIImage: UIImage? = nil
    @State private var pickedBase64: String? = nil
    @State private var usePickedPhoto = false

    var isEditing: Bool { product != nil }

    // Preview de imagen actual
    var previewContent: AnyView {
        if usePickedPhoto, let img = pickedUIImage {
            return AnyView(
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 120, height: 120).clipped().cornerRadius(12)
            )
        } else {
            return AnyView(
                Image(selectedImage)
                    .resizable().scaledToFill()
                    .frame(width: 120, height: 120).clipped().cornerRadius(12)
            )
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información")) {
                    TextField("Nombre del producto", text: $name)
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty { Text("Descripción...").foregroundColor(.gray).padding(.top, 8) }
                        TextEditor(text: $description).frame(minHeight: 80)
                    }
                    HStack {
                        Text("Precio (₡)")
                        Spacer()
                        TextField("ej: 2000", text: $priceText)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    Picker("Categoría", selection: $selectedCategory) {
                        ForEach(store.categories, id: \.self) { cat in Text(cat).tag(cat) }
                    }
                }

                // ── IMAGEN ──
                Section(header: Text("Foto del producto")) {

                    // Preview centrado
                    HStack {
                        Spacer()
                        previewContent
                        Spacer()
                    }
                    .padding(.vertical, 6)

                    // Botón galería
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(
                            usePickedPhoto ? "Cambiar foto de la galería" : "Elegir foto de la galería",
                            systemImage: "photo.on.rectangle"
                        )
                        .foregroundColor(.red)
                    }
                    .onChange(of: pickerItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                // Comprimir para no saturar UserDefaults
                                if let uiImg = UIImage(data: data),
                                   let compressed = uiImg.jpegData(compressionQuality: 0.4) {
                                    await MainActor.run {
                                        pickedUIImage = uiImg
                                        pickedBase64 = compressed.base64EncodedString()
                                        usePickedPhoto = true
                                    }
                                }
                            }
                        }
                    }

                    // Si tiene foto de galería, opción de volver a assets
                    if usePickedPhoto {
                        Button("Usar imagen del proyecto en su lugar") {
                            usePickedPhoto = false
                            pickedUIImage = nil
                            pickedBase64 = nil
                        }
                        .font(.caption).foregroundColor(.secondary)
                    }

                    // Selector de assets (solo si no usa foto de galería)
                    if !usePickedPhoto {
                        Text("O elegí una imagen del proyecto:")
                            .font(.caption).foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableImageNames, id: \.self) { imgName in
                                    VStack(spacing: 4) {
                                        Image(imgName)
                                            .resizable().scaledToFill()
                                            .frame(width: 72, height: 72).clipped().cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedImage == imgName ? Color.red : Color.clear, lineWidth: 3)
                                            )
                                        Text(imgName.replacingOccurrences(of: "img_", with: ""))
                                            .font(.caption2)
                                            .foregroundColor(selectedImage == imgName ? .red : .secondary)
                                    }
                                    .onTapGesture { selectedImage = imgName }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }

                Section(header: Text("Estado")) {
                    Toggle("Disponible", isOn: $isAvailable).tint(.red)
                    Toggle("Es promoción", isOn: $isPromo).tint(.red)
                    if isPromo { TextField("Etiqueta (ej: 20% Off)", text: $promoLabel) }
                }

                if showErrors {
                    Section {
                        Text("Completá nombre, descripción y precio.").foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar producto" : "Nuevo producto")
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() },
                trailing: Button("Guardar") { saveProduct() }.foregroundColor(.red).fontWeight(.bold)
            )
            .onAppear { loadExisting() }
        }
    }

    func loadExisting() {
        if let p = product {
            name = p.name; description = p.description; priceText = "\(p.price)"
            selectedImage = p.imageName; selectedCategory = p.category
            isAvailable = p.isAvailable; isPromo = p.isPromo; promoLabel = p.promoLabel
            // Si tenía foto de galería, cargarla para mostrar
            if let b64 = p.imageBase64,
               let data = Data(base64Encoded: b64),
               let img = UIImage(data: data) {
                pickedUIImage = img
                pickedBase64 = b64
                usePickedPhoto = true
            }
        } else {
            selectedCategory = store.categories.first ?? ""
        }
    }

    func saveProduct() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !description.trimmingCharacters(in: .whitespaces).isEmpty,
              let price = Int(priceText), price > 0 else { showErrors = true; return }

        if isEditing, var updated = product {
            updated.name = name; updated.description = description; updated.price = price
            updated.category = selectedCategory; updated.isAvailable = isAvailable
            updated.isPromo = isPromo; updated.promoLabel = promoLabel
            if usePickedPhoto, let b64 = pickedBase64 {
                updated.imageBase64 = b64
                updated.imageName = "custom"
            } else {
                updated.imageName = selectedImage
                updated.imageBase64 = nil
            }
            store.updateProduct(updated)
        } else {
            var newProduct = Product(
                name: name, description: description, price: price,
                imageName: usePickedPhoto ? "custom" : selectedImage,
                category: selectedCategory,
                isAvailable: isAvailable, isPromo: isPromo, promoLabel: promoLabel
            )
            if usePickedPhoto { newProduct.imageBase64 = pickedBase64 }
            store.addProduct(newProduct)
        }
        dismiss()
    }
}

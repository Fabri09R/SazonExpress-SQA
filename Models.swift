import Foundation
import SwiftUI

// MARK: - Product Model
struct Product: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var price: Int
    var imageName: String       // asset name O "custom_UUID" para fotos de galería
    var imageBase64: String?    // foto de galería en Base64 (nil si usa asset)
    var category: String
    var isAvailable: Bool = true
    var isPromo: Bool = false
    var promoLabel: String = ""
}

// MARK: - Cart Item
struct CartItem: Identifiable, Codable {
    var id: UUID = UUID()
    var product: Product
    var quantity: Int
    var total: Int { product.price * quantity }
}

// MARK: - Saved Card
struct SavedCard: Identifiable, Codable {
    var id: UUID = UUID()
    var number: String
    var expiry: String
    var fullNumber: String = ""
}

// MARK: - Saved Address
struct SavedAddress: Identifiable, Codable {
    var id: UUID = UUID()
    var label: String
    var latitude: Double
    var longitude: Double
}

// MARK: - Available asset images
let availableImageNames: [String] = [
    "img_hamburguesa","img_pollo","img_wrap",
    "img_bebida","img_papas","img_combo","img_ensalada","img_postre"
]

let defaultCategories = ["Hamburguesas","Pollo","Wraps","Bebidas","Acompañamientos"]

// MARK: - Helper: muestra la imagen correcta según si tiene Base64 o asset
struct ProductImage: View {
    let product: Product
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat = 10

    var body: some View {
        Group {
            if let b64 = product.imageBase64,
               let data = Data(base64Encoded: b64),
               let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
            } else {
                Image(product.imageName)
                    .resizable().scaledToFill()
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(cornerRadius)
    }
}

// MARK: - Registered User
struct RegisteredUser: Codable {
    var name: String
    var email: String
    var password: String
}

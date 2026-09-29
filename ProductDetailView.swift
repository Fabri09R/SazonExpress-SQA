import SwiftUI

struct ProductDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let product: Product

    @State private var quantity = 1
    @State private var showAdded = false

    var isFav: Bool { store.isFavorite(product: product) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Imagen cuadrada — solo botón cerrar arriba izquierda
                ZStack(alignment: .topLeading) {
                    Group {
                        if let b64 = product.imageBase64,
                           let data = Data(base64Encoded: b64),
                           let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg).resizable().scaledToFill()
                        } else {
                            Image(product.imageName).resizable().scaledToFill()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.width)
                    .clipped()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary).padding(9)
                            .background(.ultraThinMaterial).clipShape(Circle())
                    }
                    .padding(16)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(product.name).font(.title2).fontWeight(.bold)
                        Spacer()
                        Text("₡\(product.price)").font(.title3).fontWeight(.bold).foregroundColor(.red)
                    }

                    Text(product.category)
                        .font(.caption).fontWeight(.semibold).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.red.opacity(0.85)).cornerRadius(6)

                    Text(product.description)
                        .font(.subheadline).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    // Cantidad
                    HStack {
                        Text("Cantidad").font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        HStack(spacing: 0) {
                            Button { if quantity > 1 { quantity -= 1 } } label: {
                                Image(systemName: "minus").foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.red).clipShape(Capsule())
                            }
                            Text("\(quantity)").font(.headline).frame(minWidth: 36).multilineTextAlignment(.center)
                            Button { quantity += 1 } label: {
                                Image(systemName: "plus").foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.red).clipShape(Capsule())
                            }
                        }
                    }

                    HStack {
                        Text("Total:").fontWeight(.semibold)
                        Text("₡\(product.price * quantity)").fontWeight(.bold).foregroundColor(.red)
                    }

                    Spacer(minLength: 20)

                    // Botones — Añadir al carrito y Guardar (favorito)
                    VStack(spacing: 10) {
                        Button {
                            for _ in 0..<quantity { store.addToCart(product: product) }
                            showAdded = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
                        } label: {
                            HStack {
                                Image(systemName: showAdded ? "checkmark" : "cart.badge.plus")
                                Text(showAdded ? "¡Agregado!" : "Añadir al carrito").fontWeight(.semibold)
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50)
                            .background(showAdded ? Color.green : Color.red).cornerRadius(12)
                        }
                        .animation(.easeInOut(duration: 0.3), value: showAdded)

                        // Guardar = toggle favorito
                        Button {
                            store.toggleFavorite(product: product)
                        } label: {
                            HStack {
                                Image(systemName: isFav ? "bookmark.fill" : "bookmark")
                                Text(isFav ? "Guardado" : "Guardar").fontWeight(.semibold)
                            }
                            .foregroundColor(isFav ? .white : .red)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(isFav ? Color.red : Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

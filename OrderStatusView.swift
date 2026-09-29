import SwiftUI

struct OrderStatusView: View {
    @EnvironmentObject var store: DataStore

    var currentStage: Int { store.orderStage }

    var stageInfo: (icon: String, title: String, description: String) {
        switch currentStage {
        case 1: return ("cooktop",    "Preparación", "Nuestros cocineros están preparando tu comida")
        case 2: return ("scooter",    "Camino:",     "El repartidor está en camino, no tardará en llegar")
        case 3: return ("house.fill", "Listo",       "El repartidor ya llegó a tu ubicación")
        default: return ("checkmark", "Listo",       "")
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                // Lista del pedido
                Text("Tu pedido:").font(.title3).fontWeight(.bold).padding(.horizontal)

                VStack(spacing: 8) {
                    ForEach(store.activeOrder) { item in
                        HStack(spacing: 14) {
                            ProductImage(product: item.product, width: 72, height: 72, cornerRadius: 10)
                            Text(item.product.name).font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text("₡\(item.total)").font(.subheadline).fontWeight(.bold)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }

                // Estado del pedido
                Text("Estado de pedido:").font(.title3).fontWeight(.bold).padding(.horizontal)

                // Tarjeta de estado actual
                HStack(spacing: 16) {
                    Image(systemName: stageInfo.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.primary)
                        .frame(width: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(stageInfo.title).font(.headline).fontWeight(.bold)
                        Text(stageInfo.description)
                            .font(.subheadline).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal)

                // Indicadores de etapas (sin barra de progreso)
                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { stage in
                        HStack(spacing: 0) {
                            Circle()
                                .fill(stage <= currentStage ? Color.red : Color(.systemGray4))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: stageIcon(stage))
                                        .font(.caption).foregroundColor(.white)
                                )
                            if stage < 3 {
                                Rectangle()
                                    .fill(stage < currentStage ? Color.red : Color(.systemGray4))
                                    .frame(height: 3)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Botón solo en etapa 3
                if currentStage == 3 {
                    Button {
                        store.finishOrder()
                    } label: {
                        Text("¡Pedido recibido! Volver al inicio")
                            .foregroundColor(.white).font(.headline)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.red).cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: currentStage)
                }
            }
            .navigationTitle("Estado de pedido")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.startOrderTimer() }
        }
    }

    func stageIcon(_ stage: Int) -> String {
        switch stage {
        case 1: return "cooktop"
        case 2: return "scooter"
        case 3: return "house.fill"
        default: return "checkmark"
        }
    }
}

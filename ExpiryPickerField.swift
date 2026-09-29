import SwiftUI

// Shared expiry picker used in CartView and SavedCardsView
struct ExpiryPickerField: View {
    @Binding var expiry: String  // stores as "MM/AA"

    private let months = (1...12).map { String(format: "%02d", $0) }
    private let years: [String] = {
        let current = Calendar.current.component(.year, from: Date()) % 100
        return (current...(current + 10)).map { String(format: "%02d", $0) }
    }()

    @State private var selectedMonth: String = ""
    @State private var selectedYear: String = ""

    var body: some View {
        HStack(spacing: 0) {
            // Month picker
            Picker("Mes", selection: $selectedMonth) {
                ForEach(months, id: \.self) { m in
                    Text(m).tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()

            
            // Year picker
            Picker("Año", selection: $selectedYear) {
                ForEach(years, id: \.self) { y in
                    Text(y).tag(y)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(height: 100)
        .onChange(of: selectedMonth) { _ in updateExpiry() }
        .onChange(of: selectedYear)  { _ in updateExpiry() }
        .onAppear { loadInitial() }
    }

    func loadInitial() {
        let current = Calendar.current
        let nowMonth = String(format: "%02d", current.component(.month, from: Date()))
        let nowYear  = String(format: "%02d", current.component(.year,  from: Date()) % 100)

        // If expiry already set, parse it
        let parts = expiry.split(separator: "/")
        if parts.count == 2 {
            selectedMonth = String(parts[0])
            selectedYear  = String(parts[1])
        } else {
            selectedMonth = nowMonth
            selectedYear  = nowYear
        }
    }

    func updateExpiry() {
        guard !selectedMonth.isEmpty, !selectedYear.isEmpty else { return }
        expiry = "\(selectedMonth)\(selectedYear)"
    }
}

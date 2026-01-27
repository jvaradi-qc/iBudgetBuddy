import SwiftUI

struct YearPicker: View {
    @Binding var year: Int

    private let years: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }()

    var body: some View {
        Picker("Year", selection: $year) {
            ForEach(years, id: \.self) { y in
                Text("\(y)").tag(y)
            }
        }
        .pickerStyle(.menu)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

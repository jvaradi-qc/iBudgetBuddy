import SwiftUI

struct MonthPicker: View {
    @Binding var month: Int

    private let months = Calendar.current.monthSymbols

    var body: some View {
        Picker("Month", selection: $month) {
            ForEach(1...12, id: \.self) { index in
                Text(months[index - 1]).tag(index)
            }
        }
        .pickerStyle(.menu)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

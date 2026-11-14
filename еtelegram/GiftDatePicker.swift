
import SwiftUI

/// The concept's birthday picker supports a month/day without an explicit year.
struct GiftDatePicker: View {
    @Binding var selection: Date
    @State private var day = 1
    @State private var month = 1
    @State private var year = 0
    private let months = Calendar.current.monthSymbols
    private let years = Array(1900...Calendar.current.component(.year, from: Date())) + [0]

    init(selection: Binding<Date>) {
        self._selection = selection
        let components = Calendar.current.dateComponents([.day, .month], from: selection.wrappedValue)
        self._day = State(initialValue: components.day ?? 1)
        self._month = State(initialValue: components.month ?? 1)
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Day", selection: $day) {
                ForEach(1...31, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .frame(maxWidth: .infinity)
            Picker("Month", selection: $month) {
                ForEach(1...12, id: \.self) { value in
                    Text(months[value - 1]).tag(value)
                }
            }
            .frame(maxWidth: .infinity)
            Picker("Year", selection: $year) {
                ForEach(years, id: \.self) { value in
                    Text(value == 0 ? "—" : String(value)).tag(value)
                }
            }
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .pickerStyle(.wheel)
        #else
        .pickerStyle(.menu)
        #endif
        .onChange(of: day) { _, _ in updateSelection() }
        .onChange(of: month) { _, _ in updateSelection() }
        .onChange(of: year) { _, _ in updateSelection() }
    }

    private func updateSelection() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var resolvedYear = year == 0 ? currentYear : year
        let components = DateComponents(year: resolvedYear, month: month, day: 1)
        guard let firstDay = calendar.date(from: components),
              let days = calendar.range(of: .day, in: .month, for: firstDay) else { return }
        let validDay = min(day, days.count)
        if day != validDay { day = validDay }
        guard var result = calendar.date(from: DateComponents(year: resolvedYear, month: month, day: validDay)) else { return }
        // Without a year, schedule the next occurrence of the selected birthday.
        if year == 0 && result < calendar.startOfDay(for: Date()) {
            resolvedYear += 1
            result = calendar.date(from: DateComponents(year: resolvedYear, month: month, day: validDay)) ?? result
        }
        selection = result
    }
}

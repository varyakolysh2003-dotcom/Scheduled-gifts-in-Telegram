
import SwiftUI

/// "Send Later" picker: a date wheel that starts at today ("Fri, 4 Dec") next to looping hour
/// and minute wheels, with the selected row behind a soft grey pill (Figma "Selection").
struct ScheduleDatePicker: View {
    @Binding var selection: Date

    /// Figma "Selection" fill (#F2F2F7).
    private static let pillColor = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF7 / 255)

    var body: some View {
        #if os(iOS)
        ScheduleWheel(selection: $selection)
            .background {
                // 36pt pill inset 37pt from the sheet edges (the picker itself is inset 25pt).
                Capsule().fill(Self.pillColor)
                    .frame(height: ScheduleWheel.rowHeight)
                    .padding(.horizontal, 12)
            }
        #else
        DatePicker("Send Later", selection: $selection, in: Date()...,
                   displayedComponents: [.date, .hourAndMinute])
            .labelsHidden()
        #endif
    }

}

#if os(iOS)
/// UIPickerView keeps native momentum, snapping, the 3D wheel curve and selection haptics.
private struct ScheduleWheel: UIViewRepresentable {
    static let rowHeight: CGFloat = 36
    @Binding var selection: Date

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = PillPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        picker.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        context.coordinator.show(context.coordinator.clamped(selection), in: picker, animated: false)
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.parent = self
        // Only follow outside changes; the wheel's own changes are already reflected.
        if selection != context.coordinator.shownDate {
            context.coordinator.show(context.coordinator.clamped(selection), in: picker, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: ScheduleWheel
        private(set) var shownDate = Date.distantPast

        // Days run from today through 10 years ahead (no past days); hours and minutes
        // repeat so they wrap around.
        private let dayCount = ProcessInfo.processInfo.environment["SHOWTIME_SCHEDULE_START"] == nil ? 3651 : 31
        private let repeats = ProcessInfo.processInfo.environment["SHOWTIME_SCHEDULE_START"] == nil ? 400 : 5
        private let calendar = Calendar.current
        private let today = Calendar.current.startOfDay(for: Date())
        private let dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("EEEdMMM")
            return formatter
        }()

        init(_ parent: ScheduleWheel) { self.parent = parent }

        // MARK: Data source

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: dayCount
            case 1: 24 * repeats
            default: 60 * repeats
            }
        }

        // MARK: Layout

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            // UIPickerView centres the columns as a group, so with the date flush left and the
            // minutes flush right their outer text edges sit equally far from the pill's ends.
            // The hour column is widened so the hours sit midway between date and minutes.
            switch component {
            case 0: 124
            case 1: 102
            default: 34
            }
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            ScheduleWheel.rowHeight
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.font = .systemFont(ofSize: 20.25)
            label.textAlignment = component == 0 ? .left : component == 2 ? .right : .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            switch component {
            case 0: label.text = day(at: row).map(dayFormatter.string(from:))
            case 1: label.text = String(format: "%02d", row % 24)
            default: label.text = String(format: "%02d", row % 60)
            }
            return label
        }

        // MARK: Selection

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            guard let picked = date(from: pickerView) else { return }
            let valid = clamped(picked)
            // Past moments spring back to the next minute, like UIDatePicker's minimum date.
            show(valid, in: pickerView, animated: valid != picked)
            parent.selection = valid
        }

        /// Earliest allowed moment is the start of the next minute.
        func clamped(_ date: Date) -> Date {
            let now = Date()
            let nextMinute = calendar.dateInterval(of: .minute, for: now).map(\.end) ?? now
            return date < nextMinute ? nextMinute : date
        }

        func show(_ date: Date, in picker: UIPickerView, animated: Bool) {
            shownDate = date
            let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
            let time = calendar.dateComponents([.hour, .minute], from: date)
            // Hours and minutes are re-centred in the middle block so they never hit an end.
            picker.selectRow(min(max(days, 0), dayCount - 1), inComponent: 0, animated: animated)
            picker.selectRow(24 * (repeats / 2) + (time.hour ?? 0), inComponent: 1, animated: animated)
            picker.selectRow(60 * (repeats / 2) + (time.minute ?? 0), inComponent: 2, animated: animated)
        }

        private func day(at row: Int) -> Date? {
            calendar.date(byAdding: .day, value: row, to: today)
        }

        private func date(from picker: UIPickerView) -> Date? {
            guard let day = day(at: picker.selectedRow(inComponent: 0)) else { return nil }
            return calendar.date(bySettingHour: picker.selectedRow(inComponent: 1) % 24,
                                 minute: picker.selectedRow(inComponent: 2) % 60,
                                 second: 0, of: day)
        }
    }
}

/// Hides UIPickerView's own selection pill; the Figma-sized grey pill is drawn in SwiftUI instead.
private final class PillPickerView: UIPickerView {
    override func layoutSubviews() {
        super.layoutSubviews()
        for view in subviews where view.bounds.height > 0 && view.bounds.height < bounds.height / 2 {
            view.backgroundColor = .clear
        }
    }
}
#endif

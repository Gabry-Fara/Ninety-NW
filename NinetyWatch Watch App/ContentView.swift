import SwiftUI

struct ContentView: View {
    @StateObject var sensorManager = WatchSensorManager.shared
    @StateObject var hapticManager = HapticWakeUpManager.shared

    var copy: WatchCopy {
        WatchCopy(localeIdentifier: Locale.autoupdatingCurrent.identifier)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WatchPageBackground()

                WatchAlarmSetupView(sensorManager: sensorManager, copy: copy)
                    .ignoresSafeArea()
                
                if hapticManager.isPlaying {
                    AlarmView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .containerBackground(.black.gradient, for: .navigation)
            .onAppear {
                sensorManager.refreshStoredAlarmStateIfNeeded()
                sensorManager.requestHealthPermissions { _ in }
            }
        }
    }
}

struct WatchStatusFooter: View {
    @ObservedObject var sensorManager: WatchSensorManager
    
    var isSynced: Bool {
        sensorManager.connectionStatus.contains("reachable") || sensorManager.connectionStatus.contains("enabled")
    }
    
    var statusText: String {
        if isSynced {
            return "Synced"
        } else if sensorManager.connectionStatus.contains("unavailable") {
            return "Phone Offline"
        } else {
            return "Connecting..."
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isSynced ? Color.green : Color.red)
                .frame(width: 6, height: 6)
                .shadow(color: (isSynced ? Color.green : Color.red).opacity(0.5), radius: 2)
            
            Text(statusText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(.white.opacity(0.04))
        }
    }
}

struct WatchPageBackground: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
    }
}

// MARK: - Alarm Setup

struct WatchAlarmSetupView: View {
    @ObservedObject var sensorManager: WatchSensorManager
    let copy: WatchCopy

    @State var wakeTime = WatchAlarmSetupView.defaultWakeTime()
    @State var internalHour = 7
    @State var internalMinute = 0
    @State var isApplyingSyncedAlarm = false
    @State var isEditingAlarm = false
    @State var isShowingDiagnostics = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                centerContent(in: proxy.size)
                    .frame(width: proxy.size.width, height: proxy.size.height)

                if isEditingAlarm {
                    editingCornerControls
                        .transition(.opacity)
                } else if sensorManager.nextAlarmDate != nil {
                    diagnosticsAccessButton
                        .transition(.opacity)
                }

                if isShowingDiagnostics {
                    WatchDiagnosticsView(
                        sensorManager: sensorManager,
                        onBack: { isShowingDiagnostics = false }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(5)
                }
            }
        }
        .onAppear {
            applySyncedNextAlarm()
            isEditingAlarm = false
        }
        .onChange(of: internalHour) {
            guard !isApplyingSyncedAlarm else { return }
            sensorManager.markNextAlarmDraftChanged()
        }
        .onChange(of: internalMinute) {
            guard !isApplyingSyncedAlarm else { return }
            sensorManager.markNextAlarmDraftChanged()
        }
        .onChange(of: sensorManager.nextAlarmDate) {
            applySyncedNextAlarm()
        }
        .animation(.snappy(duration: 0.22), value: isEditingAlarm)
    }

    func centerContent(in size: CGSize) -> some View {
        Group {
            if isEditingAlarm {
                alarmDialEditor(in: size)
            } else {
                alarmSummary
            }
        }
    }

    func alarmDialEditor(in size: CGSize) -> some View {
        let dialSide = max(size.width, 150)

        return ZStack {
            CircularAlarmDial(hour: $internalHour, minute: $internalMinute)
                .frame(width: dialSide, height: dialSide)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var alarmSummary: some View {
        Button {
            openEditor()
        } label: {
            VStack(spacing: 8) {
                Text(summaryTitle)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(summaryTitleColor)
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(timeText(for: displayedAlarmDate))
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundStyle(.white)

                if let date = displayedAlarmDate {
                    Text(dateText(for: date))
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Text("-")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var editingCornerControls: some View {
        VStack {
            HStack {
                cornerButton(
                    systemName: "xmark",
                    tint: .white.opacity(0.92),
                    background: .black.opacity(0.34),
                    accessibilityLabel: "Exit",
                    showsCircle: true,
                    action: exitAlarmSetup
                )

                Spacer()
            }

            Spacer()

            HStack {
                cornerButton(
                    systemName: "trash",
                    tint: .red.opacity(sensorManager.nextAlarmDate == nil ? 0.35 : 0.95),
                    background: .red.opacity(sensorManager.nextAlarmDate == nil ? 0.08 : 0.22),
                    accessibilityLabel: "Delete current alarm",
                    showsCircle: true,
                    action: deleteCurrentAlarm
                )
                .disabled(sensorManager.nextAlarmDate == nil)

                Spacer()

                cornerButton(
                    systemName: "checkmark",
                    tint: .green,
                    background: .green.opacity(0.24),
                    accessibilityLabel: buttonTitle,
                    showsCircle: true,
                    action: confirmAlarm
                )
                .disabled(sensorManager.weeklyAlarmSyncState == .saving)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    var diagnosticsAccessButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    isShowingDiagnostics = true
                } label: {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue.opacity(0.95))
                .background {
                    Circle()
                        .fill(.blue.opacity(0.14))
                        .overlay {
                            Circle()
                                .strokeBorder(.blue.opacity(0.3), lineWidth: 0.8)
                        }
                }
                .accessibilityLabel("Open processing diagnostics")
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
    }

    var summaryTitleColor: Color {
        sensorManager.nextAlarmDate == nil ? .secondary : .blue.opacity(0.92)
    }

    var summaryTitle: String {
        sensorManager.nextAlarmDate == nil ? "Sveglia" : "Sveglia impostata"
    }

    func cornerButton(
        systemName: String,
        tint: Color,
        background: Color,
        accessibilityLabel: String,
        showsCircle: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .foregroundStyle(tint)
        .background {
            if showsCircle {
                Circle()
                    .fill(background)
                    .overlay {
                        Circle()
                            .strokeBorder(tint.opacity(0.28), lineWidth: 0.8)
                    }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    var buttonTitle: String {
        switch sensorManager.weeklyAlarmSyncState {
        case .saving:
            return copy.text(.syncing)
        case .saved:
            return copy.text(.saved)
        case .pending:
            return copy.text(.syncPending)
        case .unreachable:
            return copy.text(.phoneUnavailable)
        case .failed:
            return copy.text(.syncFailed)
        case .synced:
            return copy.text(.save)
        }
    }

    var displayedAlarmDate: Date? {
        switch sensorManager.weeklyAlarmSyncState {
        case .saving, .pending, .unreachable:
            return wakeTime
        case .synced, .saved, .failed:
            return sensorManager.nextAlarmDate
        }
    }

    static func defaultWakeTime() -> Date {
        var components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        return Calendar.autoupdatingCurrent.date(from: components) ?? Date()
    }

    func applySyncedNextAlarm() {
        guard let nextAlarmDate = sensorManager.nextAlarmDate else {
            wakeTime = Self.defaultWakeTime()
            internalHour = 7
            internalMinute = 0
            return
        }

        let calendar = Calendar.autoupdatingCurrent
        let syncedHour = calendar.component(.hour, from: nextAlarmDate) % 12
        let syncedMinute = calendar.component(.minute, from: nextAlarmDate)

        isApplyingSyncedAlarm = true
        
        let newDate = Self.todayDate(hour: syncedHour, minute: syncedMinute)
        withAnimation(.snappy(duration: 0.22)) {
            wakeTime = newDate
            internalHour = syncedHour
            internalMinute = syncedMinute
        }

        DispatchQueue.main.async {
            isApplyingSyncedAlarm = false
        }
    }

    func updateWakeTimeFromInternal() {
        wakeTime = Self.todayDate(hour: internalHour, minute: internalMinute)
    }

    static func todayDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.autoupdatingCurrent.date(from: components) ?? Date()
    }

    func cancelEditing() {
        applySyncedNextAlarm()
        if sensorManager.nextAlarmDate == nil {
            withAnimation(.snappy(duration: 0.18)) {
                wakeTime = Self.defaultWakeTime()
                internalHour = 7
                internalMinute = 0
            }
        }
        withAnimation(.snappy(duration: 0.22)) {
            isEditingAlarm = false
        }
    }

    func exitAlarmSetup() {
        cancelEditing()
        dismiss()
    }

    func openEditor() {
        applySyncedNextAlarm()
        isShowingDiagnostics = false
        withAnimation(.snappy(duration: 0.22)) {
            isEditingAlarm = true
        }
    }

    func deleteCurrentAlarm() {
        sensorManager.stopActiveAlarmFromWatch()
        isShowingDiagnostics = false
        withAnimation(.snappy(duration: 0.22)) {
            wakeTime = Self.defaultWakeTime()
            internalHour = 7
            internalMinute = 0
            isEditingAlarm = false
        }
    }

    func confirmAlarm() {
        updateWakeTimeFromInternal()
        sensorManager.setNextAlarm(wakeTime: wakeTime)
        withAnimation(.snappy(duration: 0.22)) {
            isEditingAlarm = false
        }
    }


    func dateText(for date: Date) -> String {
        return date.formatted(
            .dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
                .locale(Locale.autoupdatingCurrent)
        )
    }

    func timeText(for date: Date?) -> String {
        guard let date else { return "--:--" }
        return date.formatted(
            Date.FormatStyle()
                .locale(Locale.autoupdatingCurrent)
                .hour()
                .minute()
        )
    }
}

// MARK: - Watch Diagnostics

struct WatchDiagnosticsView: View {
    @ObservedObject var sensorManager: WatchSensorManager
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 8) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .accessibilityLabel("Back")

                    Spacer()

                    Text("Processing")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Color.clear
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 10) {
                        diagnosticsSection("Status") {
                            diagnosticRow("Pipeline", sensorManager.sessionState)
                            diagnosticRow("Model", sensorManager.replayStatusText)
                            diagnosticRow("Connection", sensorManager.connectionStatus)
                            diagnosticRow("Payload", sensorManager.lastPayloadSent)
                            diagnosticRow("Epochs", "\(sensorManager.epochHistory.count)")
                            diagnosticRow("Buffered", "\(sensorManager.currentEpochPayloads.count)")
                            diagnosticRow("Confirm", "\(sensorManager.confirmationBuffer.count)/\(sensorManager.confirmationRequired)")
                        }

                        diagnosticsSection("Epoch Processing") {
                            if !sensorManager.recentEpochDiagnostics.isEmpty {
                                Button {
                                    sensorManager.clearRecentEpochDiagnostics()
                                } label: {
                                    Text("Clear logs")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red.opacity(0.95))
                                .padding(.vertical, 5)
                                .background {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(.red.opacity(0.12))
                                }
                                .accessibilityLabel("Clear epoch logs")
                            }

                            if sensorManager.recentEpochDiagnostics.isEmpty {
                                Text("No processed epoch yet.")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(alignment: .leading, spacing: 7) {
                                    ForEach(sensorManager.recentEpochDiagnostics) { epoch in
                                        epochRow(epoch)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 14)
                }
            }
        }
    }

    func diagnosticsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 0.8)
                    }
            }
        }
    }

    func diagnosticRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .frame(width: 56, alignment: .leading)

            Text(value)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    func epochRow(_ epoch: WatchEpochDiagnostic) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(epoch.timestamp.formatted(date: .omitted, time: .standard))
                    .foregroundStyle(.white)

                Spacer()

                Text(epoch.stageTitle)
                    .foregroundStyle(stageColor(for: epoch.stageTitle))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(spacing: 8) {
                metricText("HR", epoch.heartRateMean)
                metricText("M", epoch.motionMagMean)
                metricText("J", epoch.motionJerk)
            }
        }
        .font(.system(size: 10, design: .monospaced))
        .monospacedDigit()
        .padding(.vertical, 5)
        .padding(.horizontal, 7)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.black.opacity(0.24))
        }
    }

    func metricText(_ label: String, _ value: Double) -> some View {
        Text("\(label) \(String(format: "%.1f", value))")
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    func stageColor(for stage: String) -> Color {
        switch stage.lowercased() {
        case let value where value.contains("light"):
            return .green
        case let value where value.contains("wake"):
            return .yellow
        case let value where value.contains("deep"):
            return .blue
        case let value where value.contains("rem"):
            return .purple
        case let value where value.contains("warming"):
            return .orange
        default:
            return .secondary
        }
    }
}

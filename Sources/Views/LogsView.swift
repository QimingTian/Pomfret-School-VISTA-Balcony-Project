import SwiftUI
import UniformTypeIdentifiers

struct LogsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedModule: String = "all"
    @State private var selectedLevel: LogEntry.Level? = nil
    @State private var selectedControllerID: String = "all"
    @State private var expandedLog: LogEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Module", selection: $selectedModule) {
                    Text("All").tag("all")
                    Text("camera").tag("camera")
                    Text("weather").tag("weather")
                }
                .pickerStyle(.segmented)
                Picker("Level", selection: Binding(
                    get: { selectedLevel ?? .info },
                    set: { selectedLevel = $0 }
                )) {
                    Text("Info").tag(LogEntry.Level.info)
                    Text("Warn").tag(LogEntry.Level.warn)
                    Text("Error").tag(LogEntry.Level.error)
                }
                .pickerStyle(.segmented)
                Picker("Controller", selection: $selectedControllerID) {
                    Text("All Controllers").tag("all")
                    ForEach(appState.controllers) { controller in
                        Text(controller.name).tag(controller.id.uuidString)
                    }
                }
                Spacer()
                Button("Export CSV…") {
                    exportCSV()
                }
            }
            .padding(.bottom, 8)

            Table(filteredLogs) {
            TableColumn("Time") { item in
                Text("\(item.ts, style: .date) \(item.ts, style: .time)")
            }
                TableColumn("Controller") { item in
                    Text(item.controllerName ?? "—")
                }
                TableColumn("Module") { item in Text(item.module) }
                TableColumn("Level") { item in Text(item.level.rawValue.uppercased()) }
                TableColumn("Message") { item in
                    Text(item.message)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            expandedLog = item
                        }
                }
            }
        }
        .padding()
        .sheet(item: $expandedLog) { entry in
            VStack(alignment: .leading, spacing: 12) {
                Text("Log Detail").font(.headline)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        detailRow(title: "Time", value: "\(entry.ts)")
                        detailRow(title: "Controller", value: entry.controllerName ?? "—")
                        detailRow(title: "Module", value: entry.module)
                        detailRow(title: "Level", value: entry.level.rawValue.uppercased())
                        detailRow(title: "Message", value: entry.message)
                        if let extra = entry.extra {
                            detailRow(title: "Extra", value: extra)
                        }
                    }
                }
                HStack {
                    Spacer()
                    Button("Copy") {
                        let text = """
                        [\(entry.level.rawValue.uppercased())] \(entry.ts)
                        Controller: \(entry.controllerName ?? "—")
                        Module: \(entry.module)
                        Message: \(entry.message)
                        \(entry.extra ?? "")
                        """
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                    Button("Close") {
                        expandedLog = nil
                    }
                }
            }
            .padding()
            .frame(width: 500, height: 360)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    var filteredLogs: [LogEntry] {
        appState.logs.filter { e in
            (selectedModule == "all" || e.module == selectedModule)
            && (selectedLevel == nil || e.level == selectedLevel)
            && (selectedControllerID == "all" || e.controllerID?.uuidString == selectedControllerID)
        }
    }

    func exportCSV() {
        let header = "timestamp,controller,module,level,message,extra\n"
        let rows = filteredLogs.map { e in
            let ts = ISO8601DateFormatter().string(from: e.ts)
            let msg = e.message.replacingOccurrences(of: "\"", with: "\"\"")
            let extra = (e.extra ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let controller = (e.controllerName ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(ts)\",\"\(controller)\",\"\(e.module)\",\"\(e.level.rawValue)\",\"\(msg)\",\"\(extra)\""
        }
        let csv = header + rows.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "observatory-logs-\(Int(Date().timeIntervalSince1970)).csv"
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.data(using: .utf8)?.write(to: url)
        }
    }
}



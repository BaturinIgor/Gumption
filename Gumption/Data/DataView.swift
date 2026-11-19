import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// "Your data": iCloud status (D11), safety copies (D8), export and import (D10).
struct DataView: View {
    @Environment(\.modelContext) private var context
    @Query private var allTasks: [TaskItem]

    @State private var exportDocument: ExportDocument?
    @State private var exportType: UTType = .json
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var message: String?

    private var iCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: iCloudAvailable ? "checkmark.icloud" : "icloud.slash")
                        .font(.title2)
                        .foregroundStyle(iCloudAvailable ? Palette.saved : Palette.praise)
                        .frame(width: 44, height: 44)
                        .background((iCloudAvailable ? Palette.saved : Palette.praise).opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(iCloudAvailable ? String(localized: "Synced with iCloud") : String(localized: "Saved on this iPhone only"))
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                        Text(iCloudAvailable
                             ? String(localized: "\(allTasks.count) tasks. If you reinstall, everything comes back.")
                             : String(localized: "Turn on iCloud in Settings to keep a copy and get it back after a reinstall."))
                            .font(.callout).foregroundStyle(Palette.muted)
                        if !iCloudAvailable, let url = URL(string: UIApplication.openSettingsURLString) {
                            Link("Open Settings", destination: url).font(.callout.weight(.semibold))
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                let copies = safetyCopies
                if copies.isEmpty {
                    Text("A copy is made automatically before every update.")
                        .foregroundStyle(Palette.muted)
                }
                ForEach(copies, id: \.self) { date in
                    HStack {
                        Text("Before an update")
                        Spacer()
                        Text(date, style: .date).foregroundStyle(Palette.muted)
                    }
                }
            } header: {
                SectionLabel(text: "Safety copies on this iPhone")
            } footer: {
                Text("If an update can't open your data, Gumption puts the last copy back by itself.")
            }

            Section {
                Button("Export JSON") { export(.json) }
                Button("Export CSV") { export(.commaSeparatedText) }
                Button("Import from a file") { showImporter = true }
            } header: {
                SectionLabel(text: "Take it with you")
            } footer: {
                Text("Import adds tasks, it never replaces what you have. Export is always free.")
            }

            if let message {
                Section { Text(message).foregroundStyle(Palette.saved) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle("Your data")
        .fileExporter(isPresented: $showExporter, document: exportDocument,
                      contentType: exportType, defaultFilename: "Gumption") { result in
            if case .success = result { message = String(localized: "Exported.") }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            importFrom(result)
        }
    }

    private var safetyCopies: [Date] {
        let folders = (try? StoreBackup.backups(storeURL: Persistence.defaultStoreURL)) ?? []
        return folders.compactMap { TimeInterval($0.lastPathComponent) }
            .map(Date.init(timeIntervalSince1970:))
            .sorted(by: >)
    }

    private func export(_ type: UTType) {
        do {
            let file = try DataTransfer.snapshot(context)
            let data = type == .json ? try DataTransfer.json(file) : Data(DataTransfer.csv(file).utf8)
            exportDocument = ExportDocument(data: data)
            exportType = type
            showExporter = true
        } catch {
            message = String(localized: "Couldn't export right now. Nothing was changed.")
        }
    }

    private func importFrom(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let file = try DataTransfer.decode(Data(contentsOf: url))
            let outcome = try DataTransfer.importFile(file, into: context)
            message = String(localized: "Added \(outcome.tasksAdded) tasks. \(outcome.tasksSkipped) were already here.")
        } catch {
            message = String(localized: "That file couldn't be read. Nothing was changed.")
        }
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

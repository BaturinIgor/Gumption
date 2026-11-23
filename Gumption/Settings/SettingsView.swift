import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.sessionMinutesKey) private var sessionMinutes = AppSettings.defaultSessionMinutes
    @AppStorage(AppSettings.breakMinutesKey) private var breakMinutes = AppSettings.defaultBreakMinutes
    @Query(filter: #Predicate<TaskItem> { $0.deletedAt != nil }) private var deleted: [TaskItem]

    var body: some View {
        List {
            Section {
                Picker("Default session", selection: $sessionMinutes) {
                    ForEach([2, 5, 10, 15, 25], id: \.self) { Text("\($0) min").tag($0) }
                }
                Picker("Break length", selection: $breakMinutes) {
                    ForEach([3, 5, 10, 15], id: \.self) { Text("\($0) min").tag($0) }
                }
            } header: {
                SectionLabel(text: "Focus")
            }

            Section {
                NavigationLink {
                    DataView()
                } label: {
                    Label("iCloud sync and backups", systemImage: "icloud")
                }
                NavigationLink {
                    RecentlyDeletedView()
                } label: {
                    HStack {
                        Label("Recently deleted", systemImage: "archivebox")
                        Spacer()
                        if !deleted.isEmpty { Text("\(deleted.count)").foregroundStyle(Palette.muted) }
                    }
                }
            } header: {
                SectionLabel(text: "Your data")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle("Settings")
    }
}

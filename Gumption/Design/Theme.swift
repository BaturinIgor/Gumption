import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Palette from the mockups. No red anywhere: status colors are amber (praise) and green (saved).
enum Palette {
    static let background = Color(hex: 0xF4F5FA)
    static let surface = Color.white
    static let ink = Color(hex: 0x171A26)
    static let muted = Color(hex: 0x5B6070)
    static let accent = Color(hex: 0x4F46E5)
    static let accentSoft = Color(hex: 0xE8E7FD)
    static let accentInk = Color(hex: 0x2E2A9E)
    static let praise = Color(hex: 0xF5A524)
    static let praiseSoft = Color(hex: 0xFDF0D8)
    static let saved = Color(hex: 0x1F9D6B)

    // Dark focus theme
    static let focusBackground = Color(hex: 0x14162B)
    static let focusSurface = Color(hex: 0x23264A)
    static let focusRing = Color(hex: 0x8B86FF)
    static let focusMuted = Color(hex: 0xB4B8D0)
    static let breakRing = Color(hex: 0x7FD1B0)
    static let focusText = Color(hex: 0xF4F5FA)
}

enum AppSettings {
    static let sessionMinutesKey = "settings.sessionMinutes"
    static let breakMinutesKey = "settings.breakMinutes"
    static let defaultSessionMinutes = 10
    static let defaultBreakMinutes = 5
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Palette.accent
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded, weight: .heavy))
            .frame(maxWidth: .infinity, minHeight: 60)
            .foregroundStyle(foreground)
            .background(tint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SectionLabel: View {
    let text: LocalizedStringKey
    var color: Color = Palette.muted

    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(.footnote.weight(.semibold))
            .tracking(0.5)
            .foregroundStyle(color)
    }
}

/// Ring timer shared by focus and break screens. Reads only timestamps (D2).
struct RingTimer: View {
    let timer: FocusTimer
    var ring: Color = Palette.focusRing
    var caption: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = timer.remaining(at: context.date)
            ZStack {
                Circle().stroke(Palette.focusSurface, lineWidth: 16)
                Circle()
                    .trim(from: 0, to: timer.fractionRemaining(at: context.date))
                    .stroke(ring, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text(FocusTimer.format(remaining))
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Palette.focusText)
                    if let caption {
                        Text(caption).font(.subheadline).foregroundStyle(Palette.focusMuted)
                    }
                }
            }
            .frame(width: 240, height: 240)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(FocusTimer.format(remaining)) left")
        }
    }
}

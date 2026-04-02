import SwiftUI

/// Raya Chat SDK — Example App with all 4 integration modes.
@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            MainScreen()
        }
    }
}

struct MainScreen: View {
    @State private var selectedMode: DemoMode?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0x0F0F14).ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    Text("Raya Chat SDK")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("iOS Sample App")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0x71717A))
                    Text("v0.1.0")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x3F3F46))
                        .padding(.top, 4)

                    Spacer().frame(height: 48)

                    VStack(spacing: 16) {
                        DemoButton(
                            title: "Mode 1 — SwiftUI View",
                            subtitle: "RayaChatView(token: \"...\")",
                            accent: Color(hex: 0x6C5CE7),
                            action: { selectedMode = .swiftUI }
                        )
                        DemoButton(
                            title: "Mode 2 — UIKit ViewController",
                            subtitle: "RayaChatViewController(token: \"...\")",
                            accent: Color(hex: 0x00CEC9),
                            action: { selectedMode = .uiKit }
                        )
                        DemoButton(
                            title: "Mode 3 — Sheet",
                            subtitle: ".sheet { RayaChatView(token: \"...\") }",
                            accent: Color(hex: 0xF59E0B),
                            action: { selectedMode = .sheet }
                        )
                        DemoButton(
                            title: "Mode 4 — Headless",
                            subtitle: "RayaChatClient(config: ...)",
                            accent: Color(hex: 0xEF4444),
                            action: { selectedMode = .headless }
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationDestination(item: $selectedMode) { mode in
                switch mode {
                case .swiftUI: SwiftUIDemo()
                case .uiKit: UIKitDemoWrapper()
                case .sheet: SheetDemo()
                case .headless: HeadlessDemo()
                }
            }
        }
    }
}

enum DemoMode: String, Identifiable, Hashable {
    case swiftUI, uiKit, sheet, headless
    var id: String { rawValue }
}

struct DemoButton: View {
    let title: String
    let subtitle: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
                Text(subtitle)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: 0x71717A))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(hex: 0x1A1A24))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// Color hex extension (duplicated here since Example doesn't import RayaChatUI's internal extension)
extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

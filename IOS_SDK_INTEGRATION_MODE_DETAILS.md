# 4 Integration Modes — iOS SDK Deep Explanation

---

## Mode 1: Packaged UI — SwiftUI View

```swift
// 3 lines — full chat widget
RayaChatView(token: "your-bot-token")
```

**Technology:** SwiftUI (Apple's modern declarative UI framework)

**What the developer gets:** Complete chat widget — intro screen, form, chat, commands, image upload, typing indicators — identical to what `<RayaChat>` provides in the RN SDK and `RayaChatWidget` provides in the Android SDK. Zero custom UI code.

**Why SwiftUI:**
- Apple's recommended UI framework since 2019 — all new iOS apps use it
- Declarative paradigm matches React and Compose mental model (state → UI)
- Our theme system (light/dark, gradient colors, RTL) maps naturally to SwiftUI's `Environment` and `@EnvironmentObject`
- SwiftUI Previews let developers see the widget in Xcode without running the app
- 80%+ of new iOS projects use SwiftUI as of 2026

**Who uses this:** Any modern iOS app built with SwiftUI. Most common integration path — just drop in the View.

**Under the hood:**
```
RayaChatView (SwiftUI View)
  └── RayaChatTheme (EnvironmentObject — colors, typography, RTL)
       └── RayaChatViewModel (ObservableObject — manages ChatSession + BotConfig)
            ├── IntroScreen (SwiftUI View)
            ├── FormScreen (SwiftUI View)
            └── ChatScreen (SwiftUI View)
                 ├── MessageList (ScrollViewReader + LazyVStack)
                 ├── MessageComposer (TextField + action buttons)
                 └── CommandUI (Rating, Feedback, Countdown)
```

**Full example:**
```swift
import SwiftUI
import RayaChatUI

struct SupportScreen: View {
    var body: some View {
        RayaChatView(
            token: "your-bot-token",
            locale: "en",
            onSessionStart: { id in print("Session: \(id)") },
            onError: { err in print("Error: \(err)") },
            onClose: { print("Closed") }
        )
    }
}
```

---

## Mode 2: Packaged UI — UIKit ViewController

```swift
// For apps using UIKit / Storyboards / Objective-C
let chatVC = RayaChatViewController(token: "your-bot-token")
navigationController?.pushViewController(chatVC, animated: true)
```

**Technology:** UIHostingController bridge (wraps SwiftUI inside UIKit)

**What the developer gets:** Same complete chat widget, but wrapped in a UIViewController that can be pushed, presented, or embedded in any UIKit navigation flow.

**Why UIHostingController bridge:**
- Millions of production apps still use UIKit + Storyboards (not SwiftUI)
- Enterprise apps, banking apps, government apps — they can't rewrite their UI to SwiftUI just to add a chat widget
- UIHostingController is Apple's official bridge between UIKit and SwiftUI
- The ViewController internally hosts SwiftUI — developers don't know or care that SwiftUI is inside
- Works with Objective-C apps (the ViewController is an NSObject subclass)

**Who uses this:** Apps built with UIKit, Storyboard-based apps, Objective-C apps, apps using UINavigationController.

**Under the hood:**
```
RayaChatViewController (UIHostingController<RayaChatView>)
  └── UIHostingController (bridge — renders SwiftUI inside UIKit)
       └── RayaChatView (same SwiftUI View as Mode 1)
```

The ViewController is a thin wrapper (~20 lines). All real work happens in SwiftUI. This makes the SDK accessible to 100% of iOS apps, not just SwiftUI apps.

**UIKit usage examples:**

```swift
// Push onto navigation stack
let chatVC = RayaChatViewController(token: "your-bot-token", locale: "en")
chatVC.onClose = { [weak self] in self?.navigationController?.popViewController(animated: true) }
navigationController?.pushViewController(chatVC, animated: true)

// Present as modal
let chatVC = RayaChatViewController(token: "your-bot-token")
present(chatVC, animated: true)

// Embed in container view
addChild(chatVC)
view.addSubview(chatVC.view)
chatVC.view.frame = containerView.bounds
chatVC.didMove(toParent: self)
```

**Storyboard usage:**
```swift
// In your ViewController
@IBAction func openChat(_ sender: Any) {
    let chatVC = RayaChatViewController(token: "your-bot-token")
    navigationController?.pushViewController(chatVC, animated: true)
}
```

---

## Mode 3: Packaged UI — Sheet/Modal

```swift
// One-liner — presents as a draggable sheet
.sheet(isPresented: $showChat) {
    RayaChatView(token: "your-bot-token")
}
```

**Technology:** SwiftUI `.sheet` modifier (native iOS presentation)

**What the developer gets:** The chat widget presented as a native iOS sheet/modal. On iOS 16+ it supports detents (half-height / full-height). User can swipe down to dismiss.

**Why Sheet:**
- Most natural iOS pattern for "secondary content" like chat support
- Matches the RN SDK's `<RayaChatModal>` and Android's `RayaChatBottomSheet`
- Native iOS behavior — drag to dismiss, detent support, accessibility
- No extra component needed — just SwiftUI's `.sheet` modifier

**Who uses this:** Apps that want chat as an overlay (not a full screen). E-commerce apps, delivery apps, fintech apps — "tap Help → sheet slides up → chat → swipe down → back to app."

**Full example:**
```swift
struct MyApp: View {
    @State private var showChat = false

    var body: some View {
        VStack {
            Button("Open Support Chat") {
                showChat = true
            }
        }
        .sheet(isPresented: $showChat) {
            RayaChatView(
                token: "your-bot-token",
                onClose: { showChat = false }
            )
        }
    }
}
```

**With iOS 16+ detents (half-sheet):**
```swift
.sheet(isPresented: $showChat) {
    RayaChatView(token: "your-bot-token")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

**UIKit modal presentation:**
```swift
let chatVC = RayaChatViewController(token: "your-bot-token")
chatVC.modalPresentationStyle = .pageSheet
if let sheet = chatVC.sheetPresentationController {
    sheet.detents = [.medium(), .large()]
    sheet.prefersGrabberVisible = true
}
present(chatVC, animated: true)
```

---

## Mode 4: Headless (Custom UI)

```swift
let client = RayaChatClient(config: RayaChatConfig(token: "your-bot-token"))

// Connect
Task {
    let botConfig = try await client.fetchBotConfig()
    try await client.connect(userInfo: UserInfo(fullName: "John", email: "john@test.com"), botConfig: botConfig)
}

// Observe state via Combine
client.$messages
    .receive(on: DispatchQueue.main)
    .sink { messages in /* render your own UI */ }
    .store(in: &cancellables)

// Actions
client.sendMessage("Hello")
client.sendImages(images, caption: "Check these out")
client.endSession()
```

**Technology:** Swift Concurrency (async/await) + Combine (`@Published` properties)

**What the developer gets:** All chat logic (WebSocket, heartbeat, reconnection, message parsing, persistence, commands) with zero UI. They build every pixel themselves. Same as `useRayaChat()` in the RN SDK and `RayaChatClient` in the Android SDK.

**Why Combine + async/await (not delegates, not closures, not RxSwift):**

| Option | Why NOT | Why Combine WINS |
|--------|---------|-----------------|
| Delegate pattern | Verbose, one-to-one only, no composition | Combine supports multiple subscribers |
| Closures/callbacks | Callback hell, no lifecycle management | Combine auto-cancels with `AnyCancellable` |
| RxSwift | Heavy third-party dependency (2MB+) | Combine is Apple-native, zero dependency |
| AsyncSequence | Good for streams but no current value | `@Published` always has current value like StateFlow |

`@Published` is the Swift equivalent of Kotlin `StateFlow` — it holds the current value and publishes changes to all subscribers.

**Full client API:**
```swift
class RayaChatClient: ObservableObject {
    // State (@Published — always has current value, auto-updates SwiftUI)
    @Published var messages: [TypeMessage] = []
    @Published var currentMessage: String = ""
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isConnected: Bool = false
    @Published var isOnline: Bool = true
    @Published var loading: Bool = false
    @Published var status: String? = nil
    @Published var info: String? = nil
    @Published var commandData: CommandData? = nil
    @Published var presets: [String] = []
    @Published var showHumanAgentBtn: Bool = false
    @Published var sessionCloseInfo: SessionCloseInfo? = nil
    @Published var currentSessionId: String = ""

    // Actions
    func connect(userInfo: UserInfo, botConfig: BotConfigProps?) async throws
    func sendMessage(_ text: String)
    func sendImages(_ images: [ImagePayload], caption: String = "")
    func sendAudio(_ base64: String)
    func sendPreset(_ text: String)
    func sendCommandResponse(command: String, response: Any)
    func clearSessionCloseInfo()
    func endSession() async
    func destroy()
    func fetchBotConfig() async throws -> BotConfigProps
}
```

**Why `connect()` takes `botConfig`:** The initial bot message (`chatbox_initial_msg`) is injected locally — the server doesn't send it via WebSocket. You must pass `botConfig` (fetched via `fetchBotConfig()`) to `connect()` for the welcome message to appear.

**Why `destroy()` exists:** Different from `endSession()`. `endSession()` is a user action that clears storage and resets to intro. `destroy()` is a lifecycle cleanup that releases WebSocket, Combine subscriptions, and observers when the host ViewController is deallocated — without clearing persisted data.

**Who uses this:** Apps with custom design systems, apps embedding chat inside existing screens, apps that need the chat data for analytics/logging, apps building completely different UIs.

**SwiftUI usage (headless + custom UI):**
```swift
struct CustomChatView: View {
    @StateObject private var client = RayaChatClient(
        config: RayaChatConfig(token: "your-bot-token")
    )

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(client.messages, id: \.id) { msg in
                        MyCustomBubble(message: msg)
                    }
                }
            }

            if client.loading {
                TypingDotsView()
            }

            MyCustomComposer(onSend: { text in
                client.sendMessage(text)
            })
        }
        .task {
            let config = try? await client.fetchBotConfig()
            try? await client.connect(
                userInfo: UserInfo(fullName: "", email: "", phone: ""),
                botConfig: config
            )
        }
    }
}
```

**UIKit usage (headless):**
```swift
class CustomChatVC: UIViewController {
    private let client = RayaChatClient(config: RayaChatConfig(token: "your-bot-token"))
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        client.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    deinit {
        client.destroy()
    }
}
```

---

## Why All 4 Modes Share One Core

```
┌─────────────────────────────────────────────────┐
│                RayaChatCore                       │
│                                                   │
│  WebSocket · Heartbeat · Reconnection · Queue     │
│  Message Parser · Commands · Error Sanitizer      │
│  Bot Config Fetch · Session Storage               │
│  App Lifecycle · Network Detection                │
│                                                   │
│  Storage:                                         │
│  → Core Data (messages)                           │
│  → Keychain (session + user)                      │
│                                                   │
│  → Swift Concurrency (async/await)                │
│  → Combine (@Published)                           │
│  → URLSessionWebSocketTask                        │
│  → Zero third-party dependencies                  │
└──────────────┬──────────────┬─────────────────────┘
               │              │
    ┌──────────▼──────┐  ┌───▼──────────────────┐
    │  RayaChatUI     │  │  Developer's own UI   │
    │                 │  │                       │
    │  Mode 1: View   │  │  Mode 4: Headless     │
    │  Mode 2: VC     │  │  (SwiftUI or UIKit)   │
    │  Mode 3: Sheet  │  │                       │
    │                 │  │  client.$messages      │
    │  SwiftUI        │  │  client.sendMessage()  │
    └─────────────────┘  └───────────────────────┘
```

One WebSocket implementation. One message parser. One reconnection strategy. One persistence layer. Four ways to present it. Same architecture as the RN SDK (`useChatSession` → `<RayaChat>` / `useRayaChat`) and Android SDK (`RayaChatClient` → `RayaChatWidget` / headless).

---

## Adapter Interfaces

The SDK uses pluggable adapters for native device features. Buttons are **hidden** (not disabled) when no adapter is provided.

### ImagePickerAdapter
```swift
protocol ImagePickerAdapter {
    func pickImages(maxCount: Int) async -> [ImageAsset]
}
```

### AudioRecorderAdapter
```swift
protocol AudioRecorderAdapter {
    func startRecording() async throws
    func stopRecording() async throws -> AudioResult  // { uri: URL, base64: String? }
    func pauseRecording() async throws
    func resumeRecording() async throws
    func getAmplitude() async -> Float                 // 0...1 for waveform
    func cleanup() async
}
```

### AudioPlayerAdapter
```swift
protocol AudioPlayerAdapter {
    func loadAudio(uri: URL) async throws -> AudioInfo  // { durationMs: Int }
    func play() async throws
    func pause() async throws
    func seekTo(positionMs: Int) async throws
    func getPosition() async -> Int
    func cleanup() async
}
```

**Button visibility based on adapters provided:**

| Adapters provided | Buttons shown |
|-------------------|---------------|
| None | Emoji + Send only |
| `imagePickerAdapter` only | Emoji + Paperclip + Send |
| `audioRecorderAdapter` only | Emoji + Mic + Send |
| Both adapters | Emoji + Paperclip + Mic + Send |

---

## Cross-Platform SDK Comparison

| Aspect | RN SDK | Android SDK | iOS SDK |
|--------|--------|-------------|---------|
| Language | TypeScript | Kotlin | Swift |
| UI Framework | React Native | Jetpack Compose | SwiftUI |
| Legacy bridge | N/A | Fragment + ComposeView | UIHostingController |
| WebSocket | Vanilla WebSocket | OkHttp | URLSessionWebSocketTask |
| State mgmt | React useState | Kotlin StateFlow | Combine @Published |
| Persistence (msgs) | AsyncStorage (JSON) | Room Database | Core Data |
| Persistence (auth) | AsyncStorage | EncryptedSharedPrefs | Keychain |
| JSON | JSON.parse | Kotlinx Serialization | Codable |
| Image loading | RN Image | Coil | AsyncImage |
| Markdown | Custom regex | Markwon | AttributedString |
| Third-party deps | 1 (react-native-svg) | 5 | **0** |
| Distribution | npm | Maven Central | SPM + CocoaPods |
| Integration modes | 3 | 4 | 4 |
| Min platform | RN 0.72+ | API 24+ | iOS 15+ |

# Raya Chat iOS SDK — Implementation Plan

Build a native iOS SDK (`raya-chat-ios`) in Swift + SwiftUI that achieves 100% feature parity with the React Native SDK (`@teammates-ai/raya-chat-react-native` v0.1.0) and Android SDK (`ai.teammates:raya-chat-core/ui` v0.1.0).

Reference: [NATIVE_SDK_SPEC.md](./NATIVE_SDK_SPEC.md) defines all protocol details, message formats, and UI behavior.

---

## Artifacts

Two Swift Package targets:

| Target | Purpose | Dependencies | Who installs |
|--------|---------|-------------|-------------|
| `RayaChatCore` | Headless engine — WebSocket, API, models, storage | **Zero** third-party | Mode 4 (Headless) developers |
| `RayaChatUI` | Packaged UI — SwiftUI screens + UIKit wrappers | Depends on `RayaChatCore` | Mode 1, 2, 3 developers |

**Zero third-party dependencies.** iOS has everything built-in: URLSession WebSocket, Keychain, Core Data, AsyncImage, AttributedString markdown, Combine, NWPathMonitor.

## Integration Modes

| Mode | Entry Point | Technology | Target Apps |
|------|-------------|-----------|-------------|
| 1. SwiftUI View | `RayaChatView(token: "...")` | SwiftUI | Modern Swift apps |
| 2. UIKit VC | `RayaChatViewController(token: "...")` | UIHostingController bridge | UIKit/Storyboard/ObjC apps |
| 3. Sheet/Modal | `.sheet { RayaChatView(token: "...") }` | SwiftUI sheet | Any app wanting chat as overlay |
| 4. Headless | `RayaChatClient(config: ...)` + Combine | Swift Concurrency | Custom UI / any architecture |

---

## Storage Architecture

| Data | Storage | iOS API | Encrypted |
|------|---------|---------|-----------|
| Session ID | Keychain | Security framework | Yes (hardware-backed) |
| User info | Keychain | Security framework | Yes (hardware-backed) |
| Messages (up to 500) | Core Data | NSPersistentContainer | App sandbox (encrypted at rest on device) |

### Why Core Data for Messages

Same rationale as Android's Room — O(1) inserts, SQL-based trimming, reactive queries via `NSFetchedResultsController` or `@FetchRequest`. The RN SDK's AsyncStorage stores messages as one giant JSON string (O(n) on every operation).

### Why Keychain (not UserDefaults)

`UserDefaults` stores data in plain text plist files. Keychain is hardware-encrypted by the Secure Enclave. Session IDs and user emails are sensitive data.

---

## Phase 1: Project Scaffolding + Models + Constants

**Days 1-2 · Goal: Buildable Swift Package with all data models and utilities.**

### Root Files

```
raya-chat-ios/
├── Package.swift                            # SPM manifest (2 targets: Core + UI)
├── RayaChat.podspec                         # CocoaPods spec (optional)
├── .gitignore
├── .swiftlint.yml                           # Linting config
├── README.md
├── NATIVE_SDK_SPEC.md
├── IOS_SDK_IMPLEMENTATION_PLAN.md           # This file
└── LICENSE
```

### Package.swift Structure

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RayaChat",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "RayaChatCore", targets: ["RayaChatCore"]),
        .library(name: "RayaChatUI", targets: ["RayaChatUI"]),
    ],
    targets: [
        .target(name: "RayaChatCore"),
        .target(name: "RayaChatUI", dependencies: ["RayaChatCore"]),
        .testTarget(name: "RayaChatCoreTests", dependencies: ["RayaChatCore"]),
        .testTarget(name: "RayaChatUITests", dependencies: ["RayaChatUI"]),
    ]
)
```

### Core Module Files

```
Sources/RayaChatCore/
├── RayaChatConfig.swift              # PUBLIC — config struct
├── Constants.swift                   # SDK_VERSION, DEFAULT_ENDPOINT, timeouts, limits
│
├── Models/
│   ├── TypeMessage.swift             # Message model (Core Data NSManagedObject subclass)
│   ├── ChatMessage.swift             # Raw inbound WS message (Codable)
│   ├── Attachment.swift              # Image/file attachment (Codable)
│   ├── AudioData.swift               # Audio message data (Codable)
│   ├── BotConfigProps.swift          # Bot configuration (Codable)
│   ├── CommandData.swift             # Server command
│   ├── SessionCloseInfo.swift        # Auto-close info
│   ├── UserInfo.swift                # User form data (Codable)
│   ├── DeviceMetadata.swift          # Device info for WS URL (Codable)
│   ├── ImageAsset.swift              # Image for upload
│   ├── OutboundModels.swift          # OutboundMessage, ImagePayload (Codable)
│   └── Enums.swift                   # MessageType, ConnectionStatus, ViewMode
│
├── Adapters/
│   ├── ImagePickerAdapter.swift      # Protocol
│   ├── AudioRecorderAdapter.swift    # Protocol
│   └── AudioPlayerAdapter.swift      # Protocol
│
└── Util/
    ├── ColorUtils.swift              # isDarkColor, getContrastColor
    ├── ErrorSanitizer.swift          # XSS strip, sensitive patterns
    ├── Validation.swift              # validateEmail, validatePhone
    ├── TimeFormat.swift              # formatLocalTime
    └── TextDirection.swift           # isRTLLocale, isRTLText
```

### Key Design Decisions — Phase 1

**All models are `Codable`:** Swift's native JSON encoding/decoding. Zero dependencies.

**`BotConfigProps` — all optional fields:** Server can return `null` for any field. Every `String` property is `String?` with defaults:
```swift
struct BotConfigProps: Codable {
    let theme: String?
    let chatboxInitialMsg: String?
    // ... all optional with CodingKeys for snake_case mapping
}
```

**TypeMessage as Core Data entity:** Uses `@NSManaged` properties. Complex fields (attachments, audio) stored as JSON strings in Core Data, decoded on access via computed properties.

### Tests

```
Tests/RayaChatCoreTests/
├── Models/
│   └── CodableTests.swift            # All models encode/decode round-trip
└── Util/
    ├── ColorUtilsTests.swift
    ├── ErrorSanitizerTests.swift
    ├── ValidationTests.swift
    ├── TimeFormatTests.swift
    └── TextDirectionTests.swift
```

### Verification

- `swift build` passes
- `swift test` passes (all util + model tests)
- All models Codable round-trip

---

## Phase 2: Core Protocol Layer

**Days 3-6 · Goal: Complete headless SDK — `RayaChatClient` with Combine @Published state + actions. Mode 4 (Headless) works end-to-end.**

### Files

```
Sources/RayaChatCore/
├── RayaChatClient.swift              # PUBLIC API — ObservableObject
│
├── WebSocket/
│   ├── WebSocketManager.swift        # URLSessionWebSocketTask lifecycle
│   └── MessageQueue.swift            # Queue messages during CONNECTING
│
├── API/
│   └── APIClient.swift               # Bot config fetch + WS URL construction
│
├── Protocol/
│   ├── MessageHandler.swift          # Route all 10 inbound message types
│   └── MessageHandlerDelegate.swift  # Delegate protocol
│
├── Storage/
│   ├── KeychainStorage.swift         # Session ID + user info (Keychain)
│   ├── CoreDataStack.swift           # NSPersistentContainer setup
│   ├── MessageStore.swift            # CRUD + trim operations
│   └── RayaChat.xcdatamodeld        # Core Data model definition
│
├── Lifecycle/
│   └── AppLifecycleObserver.swift    # UIApplication notifications
│
└── Network/
    └── NetworkMonitor.swift          # NWPathMonitor → @Published Bool
```

### RayaChatClient — Public API

```swift
class RayaChatClient: ObservableObject {
    // ── State (@Published — reactive, always has current value) ──
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

    // ── Actions ──
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

### iOS-Specific Concerns

1. **URLSessionWebSocketTask** — Apple's native WebSocket. No third-party needed. Callbacks via `receive()` async loop, not delegate pattern.

2. **Keychain** — `SecItemAdd`/`SecItemCopyMatching` for session ID and user info. Hardware-encrypted by Secure Enclave. Unlike Android's EncryptedSharedPreferences, Keychain never fails on any device — no fallback needed.

3. **Core Data on background context:** All writes use `container.newBackgroundContext()`. Reads use `viewContext` (main thread). Same pattern as Android's Room with `Dispatchers.IO`.

4. **Heartbeat uses Task.sleep:** `try await Task.sleep(for: .seconds(25))` instead of Android's `delay()` or RN's `setInterval`.

5. **NWPathMonitor:** Apple's Network framework for connectivity detection. Publishes via `@Published var isOnline: Bool`.

6. **App lifecycle:** `NotificationCenter.default` observing `UIApplication.didBecomeActiveNotification` and `UIApplication.willResignActiveNotification` instead of Android's ProcessLifecycleOwner.

### Tests

```
Tests/RayaChatCoreTests/
├── WebSocket/
│   └── MessageQueueTests.swift
├── API/
│   └── APIClientTests.swift          # URL encoding, bot config parse
├── Protocol/
│   └── MessageHandlerTests.swift     # All 10 message types
├── Storage/
│   ├── KeychainStorageTests.swift
│   └── MessageStoreTests.swift       # In-memory Core Data
└── Integration/
    └── ChatSessionTests.swift        # connect → send → receive → verify
```

### Verification

- `swift build` passes
- `swift test` passes
- Headless demo: connect → send → receive response → end session

---

## Phase 3: Theme + SwiftUI Components

**Days 7-9 · Goal: All reusable SwiftUI building blocks — no screen orchestration yet.**

### Files

```
Sources/RayaChatUI/
├── Theme/
│   ├── ColorTokens.swift             # Light/dark color tokens (exact hex from RN SDK)
│   ├── RayaTheme.swift               # Theme struct + EnvironmentKey
│   ├── Typography.swift              # Font definitions
│   └── RTLUtils.swift                # LayoutDirection utilities
│
├── Components/
│   ├── Chat/
│   │   ├── MessageBubble.swift       # User (gradient, right) + bot (gray, left + avatar) + system
│   │   ├── MessageList.swift         # ScrollViewReader + LazyVStack, auto-scroll
│   │   ├── MessageComposer.swift     # TextField + emoji/image/mic/send
│   │   ├── TypingIndicator.swift     # 3 animated dots (withAnimation)
│   │   ├── PresetButtons.swift       # Wrapping HStack with FlowLayout
│   │   ├── ScrollToBottom.swift      # Floating button
│   │   └── MarkdownText.swift        # AttributedString (iOS 15+)
│   │
│   ├── Commands/
│   │   ├── RatingUI.swift            # 5 face icons (Path drawn) in bot bubble
│   │   ├── FeedbackInput.swift       # TextEditor + Skip/Submit in bot bubble
│   │   ├── EndSessionUI.swift        # Pill buttons in bot bubble
│   │   ├── CountdownClose.swift      # Circle + timer animation
│   │   └── EndChatModal.swift        # Full-screen confirmation
│   │
│   ├── Media/
│   │   ├── ImageViewer.swift         # Full-screen overlay with AsyncImage
│   │   ├── ImagePickerPreview.swift  # Dynamic-width HStack with X buttons
│   │   ├── AudioRecorderUI.swift     # Waveform + controls
│   │   └── AudioPlayerUI.swift       # Progress bar + play/pause
│   │
│   └── Common/
│       ├── Header.swift              # Gradient background, bot icon, buttons
│       ├── Icons.swift               # SF Symbols + custom Shape paths
│       ├── Strings.swift             # EN/AR localized dictionary
│       └── Toast.swift               # Overlay notification
```

### iOS-Specific UI Decisions

**MarkdownText — AttributedString (native):**
```swift
// iOS 15+ has built-in markdown support
Text(try! AttributedString(markdown: content))
```
No Markwon, no third-party library. Apple handles bold, italic, code, links natively.

**TypingIndicator — SwiftUI withAnimation:**
```swift
Circle()
    .offset(y: isAnimating ? -6 : 0)
    .animation(.easeInOut(duration: 0.3).repeatForever().delay(Double(index) * 0.15))
```

**Icons — SF Symbols:**
Most icons use SF Symbols (Apple's built-in icon library). Custom icons use SwiftUI `Shape` + `Path`:
```swift
Image(systemName: "paperplane.fill")  // Send icon
Image(systemName: "paperclip")        // Attach icon
Image(systemName: "mic")              // Record icon
Image(systemName: "xmark")            // Close icon
```

**PresetButtons — FlowLayout:**
SwiftUI doesn't have FlowRow natively (pre-iOS 16). Use a custom `FlowLayout` or `Layout` protocol (iOS 16+) with fallback.

**Auto-scroll — ScrollViewReader:**
```swift
ScrollViewReader { proxy in
    LazyVStack {
        ForEach(messages) { msg in
            MessageBubble(message: msg).id(msg.id)
        }
    }
    .onChange(of: messages.count) { _ in
        withAnimation { proxy.scrollTo(messages.last?.id) }
    }
}
```

### Verification

- `swift build` passes
- All components have `#Preview` macros for Xcode preview
- Icons render correctly

---

## Phase 4: Screen Orchestration + Integration Modes

**Days 10-12 · Goal: Wire everything into 4 integration modes. Full feature parity.**

### Files

```
Sources/RayaChatUI/
├── RayaChatViewModel.swift           # ObservableObject — INTRO→FORM→CHAT state machine
├── RayaChatView.swift                # Mode 1: SwiftUI View entry point
├── RayaChatViewController.swift      # Mode 2: UIHostingController bridge
│
├── Screens/
│   ├── IntroScreen.swift             # Full port (gradient header, card, footer)
│   ├── FormScreen.swift              # Full port (floating labels, validation)
│   └── ChatScreen.swift              # Full port (header + list + composer)
```

### RayaChatViewModel

```swift
class RayaChatViewModel: ObservableObject {
    let client: RayaChatClient

    @Published var viewMode: ViewMode = .intro
    @Published var showEndChatModal: Bool = false
    @Published var botConfig: BotConfigProps = BotConfigProps()
    @Published var isConfigLoading: Bool = true

    func startChat() { ... }
    func submitForm(userInfo: UserInfo) { ... }
    func closeChat() { ... }
    func confirmEndSession() async { ... }
}
```

### Mode 2: UIKit Bridge

```swift
public class RayaChatViewController: UIHostingController<RayaChatView> {
    public convenience init(token: String, locale: String = "en") {
        let view = RayaChatView(token: token, locale: locale)
        self.init(rootView: view)
    }

    public var onClose: (() -> Void)?
    public var onSessionStart: ((String) -> Void)?
}
```

### Keyboard Handling

SwiftUI handles keyboard avoidance automatically on iOS 15+ — no manual `imePadding()` needed. The `TextField` in the composer naturally pushes content up when the keyboard appears.

### Tests

```
Tests/RayaChatUITests/
├── RayaChatViewModelTests.swift      # State transitions
└── Screens/
    ├── IntroScreenTests.swift        # UI tests
    └── FormScreenTests.swift         # Validation
```

### Verification

- All 4 modes launch without crash
- Full flow: Intro → Form → Chat → Send → Receive → Commands → End Session
- Keyboard avoidance works
- Sheet dismiss works

---

## Phase 5: Example App + Polish + Distribution

**Days 13-14 · Goal: Production-ready with demo app and SPM/CocoaPods publishing.**

### Example App

```
Example/
├── ExampleApp.swift                  # App entry point with TabView
├── SwiftUIDemo.swift                 # Mode 1: RayaChatView
├── UIKitDemo.swift                   # Mode 2: RayaChatViewController in UIKit
├── SheetDemo.swift                   # Mode 3: .sheet presentation
├── HeadlessDemo.swift                # Mode 4: Custom UI with RayaChatClient
└── Adapters/
    └── PhotoPickerAdapter.swift      # PHPickerViewController wrapper
```

### Distribution

**Swift Package Manager (primary):**
```swift
// Package.swift is already configured
// Developers add via Xcode: File → Add Package Dependencies
// URL: https://github.com/teammates-ai/raya-chat-ios
```

**CocoaPods (secondary):**
```ruby
Pod::Spec.new do |s|
  s.name         = "RayaChat"
  s.version      = "0.1.0"
  s.summary      = "Raya AI Chat SDK for iOS"
  s.homepage     = "https://github.com/teammates-ai/raya-chat-ios"
  s.license      = { :type => "MIT" }
  s.author       = { "Teammates AI" => "dev@teammates.ai" }
  s.source       = { :git => "https://github.com/teammates-ai/raya-chat-ios.git", :tag => s.version }
  s.ios.deployment_target = "15.0"
  s.swift_version = "5.9"

  s.subspec "Core" do |core|
    core.source_files = "Sources/RayaChatCore/**/*.swift"
    core.resources = "Sources/RayaChatCore/**/*.xcdatamodeld"
  end

  s.subspec "UI" do |ui|
    ui.source_files = "Sources/RayaChatUI/**/*.swift"
    ui.dependency "RayaChat/Core"
  end

  s.default_subspecs = "UI"
end
```

### CI/CD

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  build-and-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: swift build
      - name: Test
        run: swift test
```

### Verification

- `swift build` passes
- `swift test` passes
- Example app runs all 4 modes on Simulator
- SPM resolution works from a fresh Xcode project
- CocoaPods `pod lib lint` passes

---

## Complete File Inventory

| Module | Swift Files | Test Files | Resources | Total |
|--------|-----------|------------|-----------|-------|
| RayaChatCore | ~25 | ~10 | 1 (.xcdatamodeld) | ~36 |
| RayaChatUI | ~28 | ~5 | 0 | ~33 |
| Example | ~6 | 0 | 0 | ~6 |
| Root (config) | 0 | 0 | ~5 | ~5 |
| **Total** | **~59** | **~15** | **~6** | **~80** |

## Timeline

```
Day 1-2:   Phase 1 — Package.swift, models, constants, utilities
Day 3-6:   Phase 2 — Core protocol (WebSocket, API, storage, RayaChatClient)
Day 7-9:   Phase 3 — Theme + SwiftUI components
Day 10-12: Phase 4 — Screen orchestration + 4 integration modes
Day 13-14: Phase 5 — Example app, polish, SPM/CocoaPods publishing

Total: 14 days sequential
```

## Verification Checkpoints

After EACH phase:

1. `swift build` passes
2. `swift test` passes
3. No compiler warnings
4. All public APIs have documentation comments
5. Example app runs on Simulator (Phase 4+)
6. Full flow works end-to-end (Phase 4+)

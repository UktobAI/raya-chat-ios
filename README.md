# Raya Chat iOS SDK

Native iOS SDK for embedding the Raya AI chat widget in iOS apps. Built with Swift + SwiftUI. **Zero third-party dependencies.**

Works with **SwiftUI**, **UIKit + Storyboard**, **Sheet/Modal**, and **headless (custom UI)**.

## Installation

### Swift Package Manager (recommended)

In Xcode: **File → Add Package Dependencies** → paste:

```
https://github.com/teammates-ai/raya-chat-ios
```

Select **RayaChatUI** (includes Core) for packaged UI, or **RayaChatCore** for headless only.

### CocoaPods

```ruby
pod 'RayaChat', '~> 0.1.0'       # Packaged UI (includes Core)
pod 'RayaChat/Core', '~> 0.1.0'  # Headless only
```

---

## Quick Start

### Mode 1: SwiftUI View

```swift
import RayaChatUI

struct SupportView: View {
    var body: some View {
        RayaChatView(
            token: "your-bot-token",
            locale: "en",
            onSessionStart: { id in print("Session: \(id)") },
            onError: { err in print("Error: \(err)") },
            onClose: { /* dismiss */ }
        )
    }
}
```

### Mode 2: UIKit ViewController

```swift
import RayaChatUI

let chatVC = RayaChatViewController(token: "your-bot-token", locale: "en")
chatVC.onSessionStart = { id in print("Session: \(id)") }
chatVC.onClose = { self.dismiss(animated: true) }

// Push, present, or embed — it's a standard UIViewController
navigationController?.pushViewController(chatVC, animated: true)
```

### Mode 3: Sheet

```swift
.sheet(isPresented: $showChat) {
    RayaChatView(
        token: "your-bot-token",
        onClose: { showChat = false }
    )
    .presentationDetents([.large])
}
```

### Mode 4: Headless (Custom UI)

```swift
import RayaChatCore

let client = RayaChatClient(config: RayaChatConfig(
    token: "your-bot-token",
    locale: "en",
    onSessionStart: { id in print("Session: \(id)") },
    onError: { err in print("Error: \(err)") }
))

// Fetch config + connect
Task {
    let botConfig = await client.fetchBotConfig()
    await client.connect(userInfo: UserInfo("John", "john@test.com", ""), botConfig: botConfig)
}

// Observe state via Combine @Published
client.$messages       // [TypeMessage]
client.$loading        // Bool
client.$presets        // [String]
client.$commandData    // CommandData?

// Actions
client.sendMessage("Hello")
client.sendPreset("Ask about pricing")
client.sendImages(imagePayloads, caption: "Check these out")
client.sendCommandResponse(command: "rate_conversation", response: 5)
client.endSession()
client.destroy()
```

---

## Headless Mode — Full Guide

### All State (@Published)

| State | Type | Description |
|-------|------|-------------|
| `messages` | `[TypeMessage]` | Full message history |
| `currentMessage` | `String` | Streaming text (grows as chunks arrive) |
| `connectionStatus` | `ConnectionStatus` | `.connecting`, `.connected`, `.disconnected`, `.reconnecting` |
| `isConnected` | `Bool` | WebSocket is open |
| `isOnline` | `Bool` | Device has network connectivity |
| `loading` | `Bool` | Bot is processing |
| `status` | `String?` | "Searching...", "Thinking..." |
| `info` | `String?` | "Waiting for human agent..." |
| `commandData` | `CommandData?` | Active server command |
| `presets` | `[String]` | Suggestion buttons |
| `showHumanAgentBtn` | `Bool` | Escalation available |
| `sessionCloseInfo` | `SessionCloseInfo?` | Session closed by server |
| `currentSessionId` | `String` | Current session ID |

### All Actions

| Action | Signature | Description |
|--------|-----------|-------------|
| `connect` | `func connect(userInfo:, botConfig:) async` | Start WebSocket |
| `sendMessage` | `func sendMessage(_ text:)` | Send text |
| `sendImages` | `func sendImages(_ images:, caption:)` | Send images with caption |
| `sendAudio` | `func sendAudio(_ base64:)` | Send voice note |
| `sendPreset` | `func sendPreset(_ text:)` | Send preset + clear buttons |
| `sendCommandResponse` | `func sendCommandResponse(command:, response:)` | Respond to commands |
| `clearSessionCloseInfo` | `func clearSessionCloseInfo()` | Reset auto_close warning |
| `endSession` | `func endSession() async` | End session, clear storage |
| `destroy` | `func destroy()` | Release all resources |
| `fetchBotConfig` | `func fetchBotConfig() async` | Fetch bot configuration |

### endSession vs destroy

| Method | Clears storage? | Closes WebSocket? | Resets UI? | When to call |
|--------|----------------|-------------------|-----------|-------------|
| `endSession()` | Yes | Yes | Yes → Intro | User taps "End Session" |
| `destroy()` | No | Yes | N/A | View disappears / ViewController dealloc |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 RayaChatCore                      │
│                                                  │
│  URLSession WebSocket · Heartbeat · Reconnection │
│  Message Parser · Commands · Error Sanitizer     │
│  Bot Config Fetch · Keychain · Core Data         │
│  App Lifecycle · NWPathMonitor                   │
│                                                  │
│  → Combine @Published                            │
│  → URLSessionWebSocketTask (built-in)            │
│  → Core Data (messages)                          │
│  → Keychain (session + user — Secure Enclave)    │
│  → Zero third-party dependencies                 │
└──────────────┬──────────────┬────────────────────┘
               │              │
    ┌──────────▼──────┐  ┌───▼──────────────────┐
    │  RayaChatUI     │  │  Developer's own UI   │
    │                 │  │                       │
    │  Mode 1: View   │  │  Mode 4: Headless     │
    │  Mode 2: UIKit  │  │  (SwiftUI or UIKit)   │
    │  Mode 3: Sheet  │  │                       │
    │                 │  │  client.$messages      │
    │  SwiftUI        │  │  client.sendMessage()  │
    └─────────────────┘  └───────────────────────┘
```

## Requirements

| Requirement | Version |
|------------|---------|
| iOS | 16.0+ |
| macOS | 13.0+ (for SPM build) |
| Swift | 5.9+ |
| Xcode | 15.0+ |
| Third-party dependencies | **0** |

## Example App

The `Example/` directory demonstrates all 4 integration modes:

| Demo | Mode | What it shows |
|------|------|--------------|
| SwiftUI | Mode 1 | Full chat widget — 3 lines of code |
| UIKit | Mode 2 | Chat in UINavigationController |
| Sheet | Mode 3 | Chat slides up as bottom sheet |
| Headless | Mode 4 | Nocturne Velvet custom UI with all features |

## License

MIT

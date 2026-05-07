# Raya Chat iOS SDK

Native iOS SDK for embedding the Raya AI chat widget in iOS apps. Built with Swift + SwiftUI. **Zero third-party dependencies.**

Works with **SwiftUI**, **UIKit + Storyboard**, **Sheet/Modal**, and **Headless (custom UI)**.

---

## Table of Contents

- [Installation](#installation)
- [Which Mode Should I Use?](#which-mode-should-i-use)
- [Quick Start](#quick-start)
  - [Mode 1: SwiftUI View](#mode-1-swiftui-view)
  - [Mode 2: UIKit ViewController](#mode-2-uikit-viewcontroller)
  - [Mode 3: Sheet / Modal](#mode-3-sheet--modal)
  - [Mode 4: Headless (Custom UI)](#mode-4-headless-custom-ui)
- [Configuration](#configuration)
- [Callbacks](#callbacks)
- [What Packaged UI Handles for You](#what-packaged-ui-handles-for-you)
- [Adapters](#adapters)
- [Features](#features)
- [Theming](#theming)
- [RTL / Arabic Support](#rtl--arabic-support)
- [Headless Mode — Full Guide](#headless-mode--full-guide)
- [Exporting Session Data (onSessionEnd)](#exporting-session-data-onsessionend)
- [Real-Time Message Sync (onMessageUpdate)](#real-time-message-sync-onmessageupdate)
- [TypeMessage Schema](#typemessage-schema)
- [Session Persistence](#session-persistence)
- [Background / Foreground Behavior](#background--foreground-behavior)
- [Keeping Chat Alive Across Tabs](#keeping-chat-alive-across-tabs)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Example App](#example-app)
- [Troubleshooting](#troubleshooting)

---

## Installation

### Swift Package Manager (recommended)

In Xcode: **File > Add Package Dependencies** > paste:

```
https://github.com/UktobAI/raya-chat-ios
```

Select **RayaChatUI** (includes Core) for packaged UI, or **RayaChatCore** for headless only.

### CocoaPods

```ruby
pod 'RayaChatUI', '~> 0.1.2'     # Packaged UI (pulls in RayaChatCore automatically)
pod 'RayaChatCore', '~> 0.1.2'   # Headless only
```

### Permissions (Info.plist)

The SDK is **permission-free by default**. You only need to add an Info.plist key if you want voice notes:

| Key | When required |
|---|---|
| `NSMicrophoneUsageDescription` | Only if your bot config has `enable_voice_note = true` AND you want users to record voice notes. The SDK detects the absence of this key at runtime and silently keeps the mic button hidden — no crash. Apps that don't enable voice notes never need this key. |

Recommended value (Apple App Review accepts specific use cases): `"Used to record voice notes in chat support."` Customize for your app's actual use case.

If you want the same image/audio behavior with no Info.plist setup, leave `enable_voice_note = false` on the bot config. The SDK uses `PHPickerViewController` for images, which **does not require any photo-library permission** because it runs out-of-process.

---

## Which Mode Should I Use?

| Mode | Best for | You build | You get for free | Dependency |
|------|----------|-----------|------------------|------------|
| **1. SwiftUI View** | Modern SwiftUI apps | Nothing — drop-in | Full UI: intro, form, chat, commands, end session | `RayaChatUI` |
| **2. UIKit VC** | UIKit/Storyboard/ObjC apps | Nothing — drop-in | Same as Mode 1, inside a UIViewController | `RayaChatUI` |
| **3. Sheet** | Any app wanting chat as overlay | Nothing — one-liner | Same as Mode 1, as a bottom sheet | `RayaChatUI` |
| **4. Headless** | Apps that need fully custom chat UI | Entire UI from scratch | WebSocket, reconnection, storage, state management | `RayaChatCore` |

**Rule of thumb:** Start with Mode 1 (SwiftUI) or Mode 2 (UIKit). Only use Mode 4 if you need a completely custom design that doesn't match the built-in screens.

---

## Quick Start

### Mode 1: SwiftUI View

Drop-in SwiftUI View. Full chat widget with intro, form, and chat screens.

```swift
import RayaChatUI

struct SupportView: View {
    var body: some View {
        RayaChatView(
            token: "your-bot-token",
            locale: "en",
            onSessionStart: { sessionId in print("Session: \(sessionId)") },
            onSessionEnd: { sessionId, messages in
                // Full message history with remote attachment URLs
                print("Session \(sessionId) ended with \(messages.count) messages")
            },
            onError: { err in print("Error: \(err)") },
            onClose: { /* dismiss */ }
        )
    }
}
```

That's it. The widget handles everything: fetching bot config, showing the intro screen, user form, chat, commands, end session, and reconnection.

### Mode 2: UIKit ViewController

For apps using UIKit, Storyboards, or Objective-C. The ViewController wraps SwiftUI internally — your app does **not** need SwiftUI knowledge.

```swift
import RayaChatUI
import RayaChatCore

let chatVC = RayaChatViewController(
    token: "your-bot-token",
    locale: "en",
    onSessionStart: { sessionId in print("Session: \(sessionId)") },
    onSessionEnd: { sessionId, messages in
        print("Session \(sessionId) ended with \(messages.count) messages")
    },
    onError: { err in print("Error: \(err)") },
    onClose: { self.dismiss(animated: true) }
)

// Push, present, or embed — it's a standard UIViewController
navigationController?.pushViewController(chatVC, animated: true)
```

### Mode 3: Sheet / Modal

Chat slides up from the bottom as a sheet. Works with SwiftUI apps.

```swift
.sheet(isPresented: $showChat) {
    RayaChatView(
        token: "your-bot-token",
        onSessionEnd: { sessionId, messages in
            print("Session \(sessionId) ended with \(messages.count) messages")
        },
        onClose: { showChat = false }
    )
    .presentationDetents([.large])
}
```

### Mode 4: Headless (Custom UI)

Full control — all chat logic with zero pre-built UI. Build your own screens with Combine `@Published`.

```swift
import RayaChatCore

let client = RayaChatClient(config: RayaChatConfig(
    token: "your-bot-token",
    locale: "en",
    onSessionStart: { id in print("Session: \(id)") },
    onSessionEnd: { sessionId, messages in
        print("Session \(sessionId) ended with \(messages.count) messages")
    },
    onError: { err in print("Error: \(err)") }
))

// Fetch config + connect
Task {
    let botConfig = await client.fetchBotConfig()
    await client.connect(
        userInfo: UserInfo(fullName: "John", email: "john@test.com", phone: ""),
        botConfig: botConfig
    )
}

// Observe state via Combine @Published
client.$messages       // [TypeMessage]
client.$currentMessage // String (streaming text)
client.$loading        // Bool
client.$presets        // [String]
client.$commandData    // CommandData?

// Send messages
client.sendMessage("Hello")
client.sendPreset("Ask about pricing")
client.sendImages(imagePayloads, caption: "Check these out")
client.sendCommandResponse(command: "rate_conversation", response: 5)
await client.endSession()
client.destroy()
```

> **Full headless guide:** See [Headless Mode — Full Guide](#headless-mode--full-guide) below for all state fields, actions, command handling, and streaming.

---

## Configuration

All 4 modes accept the same configuration parameters. In packaged UI modes (1-3), pass them as function parameters. In headless mode (4), pass them via `RayaChatConfig`.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `token` | `String` | **Yes** | — | Bot token from [Teammates.ai](https://teammates.ai) dashboard |
| `locale` | `String` | No | `"en"` | `"en"` (English) or `"ar"` (Arabic with RTL layout) |
| `imagePickerAdapter` | `ImagePickerAdapter?` | No | Built-in PHPicker | Adapter for image selection. Pass `nil` to hide image button. |
| `audioRecorderAdapter` | `AudioRecorderAdapter?` | No | `nil` | Adapter for voice recording. Mic button hidden if not provided. |
| `onSessionStart` | `(String) -> Void` | No | `nil` | Called when WebSocket connects successfully |
| `onSessionEnd` | `(String, [TypeMessage]) -> Void` | No | `nil` | Called when session ends — passes session ID and full message history |
| `onMessageUpdate` | `(String, TypeMessage) -> Void` | No | `nil` | Called for each message sent/received — passes (sessionId, message) for real-time sync |
| `onError` | `(String) -> Void` | No | `nil` | Called on connection or send errors |
| `onClose` | `() -> Void` | No | `nil` | Called when user taps the close (X) button |

### Bot Configuration (from API)

These are configured on the [Teammates.ai](https://teammates.ai) dashboard and fetched automatically by the SDK. You do **not** set these in code.

| Property | Controls |
|----------|----------|
| `theme` | `"light"` or `"dark"` mode |
| `chatbox_gradient_color` | Primary/brand color (header, buttons, user bubbles) |
| `chatbox_chat_icon` | Bot avatar image URL |
| `chatbox_system_heading` | Intro screen heading text |
| `chatbox_system_paragraph` | Intro screen subtitle |
| `chatbox_initial_msg` | First bot message when chat starts |
| `chatbox_placeholder` | Message input placeholder text |
| `enable_user_form` | Show/skip user info form before chat |
| `enable_user_email` | Show email field in the form |
| `enable_user_phone` | Show phone field in the form |
| `enable_voice_note` | Enable microphone button (still requires adapter) |
| `enable_image_upload` | Enable image upload button |
| `preset_options` | Static suggestion buttons shown on first message |

---

## Callbacks

All callbacks are optional. They fire in all modes (packaged UI and headless).

### `onSessionStart(_ sessionId: String)`

Fires when the WebSocket connection is established. The `sessionId` is assigned by the server and identifies this conversation.

```swift
onSessionStart: { sessionId in
    Analytics.track("chat_started", ["session_id": sessionId])
}
```

### `onSessionEnd(_ sessionId: String, _ messages: [TypeMessage])`

Fires when `client.endSession()` is called — receives the session ID and **complete message history** captured before state is cleared. The packaged UI calls `endSession()` for you in these flows:

- User confirms "End Session" in the modal
- Server sends `feedback_received` → countdown finishes → packaged UI calls `endSession()`

In **headless mode** you call `client.endSession()` yourself. The callback **does not fire automatically** for `auto_close` (inactivity timeout) — the SDK only sets `sessionCloseInfo` and tears down the WebSocket. Observe `client.sessionCloseInfo` and call `endSession()` if you want the callback to fire on auto-close.

```swift
onSessionEnd: { sessionId, messages in
    // Export transcript, send to your API, log analytics, etc.
    print("Session \(sessionId): \(messages.count) messages")
}
```

See [Exporting Session Data](#exporting-session-data-onsessionend) for a full example.

### `onMessageUpdate(_ sessionId: String, _ message: TypeMessage)`

Fires for every message transaction — both sent and received. Use this to sync messages to your backend in real-time, so nothing is lost even if the user never ends the session.

```swift
onMessageUpdate: { sessionId, message in
    api.syncMessage(sessionId: sessionId, message: [
        "id": message.id,
        "sender": message.sender,
        "type": message.type,
        "content": message.content ?? "",
        "created_at": message.createdAt ?? "",
        "attachments_json": message.attachmentsJson ?? "",
        "audio_json": message.audioJson ?? "",
    ])
}
```

**Image/audio messages are deferred** — the callback does NOT fire when the user sends images or audio (because local data URIs are useless for your DB). It fires only after the server responds with remote S3 URLs. See [Real-Time Message Sync](#real-time-message-sync-onmessageupdate) for the complete timeline.

### `onError(_ error: String)`

Fires on connection failures, send failures, or server errors. Error messages are sanitized (HTML stripped, sensitive data redacted, max 200 chars).

```swift
onError: { error in
    showAlert(error)
}
```

### `onClose()`

Fires when the user taps the close (X) button in the header. Use this to dismiss the chat view.

```swift
onClose: { dismiss() }  // or navigationController?.popViewController(animated: true)
```

---

## What Packaged UI Handles for You

When you use Mode 1, 2, or 3, the SDK handles all of the following automatically. You do **not** need to build or manage any of this:

| Feature | Details |
|---------|---------|
| **Intro screen** | Bot avatar, heading, subtitle, "Start a chat" button, privacy note, powered-by footer |
| **User form** | Full name (required), email (optional), phone (optional), validation, error messages |
| **Chat screen** | Message list, typing indicator, streaming responses, markdown rendering, timestamps |
| **Message composer** | Text input, emoji (system keyboard), image button, mic button, send button |
| **Bot config fetch** | Fetches theme, colors, form settings, initial message from API on launch |
| **Theme** | Light/dark mode, gradient colors, contrast text — all from bot config |
| **Commands** | Rating (5 faces), feedback (textarea), end session (yes/no), countdown timer, auto-close |
| **End chat modal** | Confirmation dialog with cancel/end buttons |
| **Image handling** | Built-in PHPicker, preview grid with remove buttons, full-screen viewer on tap |
| **Audio handling** | Recording waveform, playback bar (requires adapters) |
| **Preset buttons** | Dynamic suggestion pills from server + static presets from config |
| **Escalation** | "Connect with human representative" button when server triggers it |
| **Keyboard** | Dismiss on tap outside, dismiss on send, dismiss on preset selection |
| **Auto-scroll** | Scrolls to latest message; floating "scroll to bottom" button when scrolled up |
| **RTL** | Full Arabic layout, mirrored bubbles, translated strings (when `locale = "ar"`) |
| **Reconnection** | Exponential backoff, message queue, session resume — all invisible to the user |
| **Persistence** | Messages and session ID survive app restart |

---

## Adapters

The SDK uses **pluggable adapters** for native device features (camera, microphone). All adapters ship with built-in defaults — provide custom ones only if you want different behavior.

| Bot config | Info.plist | Buttons shown in composer |
|---|---|---|
| `enable_image_upload = true`, `enable_voice_note = false` | (none required) | Emoji + Image + Send |
| `enable_image_upload = true`, `enable_voice_note = true` | `NSMicrophoneUsageDescription` set | Emoji + Image + Mic + Send |
| `enable_image_upload = true`, `enable_voice_note = true` | `NSMicrophoneUsageDescription` **missing** | Emoji + Image + Send (mic auto-hidden, no crash) |
| `imagePickerAdapter: nil` passed explicitly | (any) | Emoji + Send only |

### ImagePickerAdapter

A built-in `DefaultImagePickerAdapter` using `PHPickerViewController` is provided automatically. Images are resized to max 1024px and compressed to JPEG at 70% quality.

To provide a custom implementation:

```swift
public protocol ImagePickerAdapter: AnyObject {
    func pickImages(maxCount: Int) async throws -> [ImageAsset]
}
```

`ImageAsset` fields:

| Field | Type | Description |
|-------|------|-------------|
| `uri` | `String` | Data URI for local display |
| `name` | `String` | Filename, e.g., `"photo.jpg"` |
| `type` | `String` | MIME type, e.g., `"image/jpeg"` |
| `base64` | `String` | Full data URL: `"data:image/jpeg;base64,/9j/4AAQ..."` |

### AudioRecorderAdapter

A built-in `DefaultAudioRecorderAdapter` using `AVAudioRecorder` is provided automatically. Records 16 kHz mono 16-bit PCM WAV (Whisper-native sample rate, accepted by OpenAI Responses API). Auto-stops at 3 minutes. Validates against the host app's `NSMicrophoneUsageDescription` Info.plist key — returns `nil` if missing, so the mic button stays hidden and the app never crashes.

To provide a custom implementation:

```swift
public protocol AudioRecorderAdapter: AnyObject {
    func startRecording() async throws
    func stopRecording() async throws -> AudioResult  // { uri: String, base64: String? }
    func pauseRecording() async throws
    func resumeRecording() async throws
    func getAmplitude() async -> Float                 // 0..1 for waveform visualization
    func cleanup() async                               // release resources
}
```

The SDK sends raw audio bytes as a **WebSocket binary frame** (not base64-encoded text), matching the web widget's wire format. Server-side handlers route binary frames straight to OpenAI for transcription.

### AudioPlayerAdapter

A built-in `DefaultAudioPlayerAdapter` using `AVAudioPlayer` handles both local data URIs (`data:audio/wav;base64,...`) and remote `https://` URLs. It also implements `getAmplitudes(sampleCount:)` to extract real waveform data from the loaded file via `AVAudioFile`, so chat bubbles show actual amplitude bars (not stylized placeholders).

```swift
public protocol AudioPlayerAdapter: AnyObject {
    func loadAudio(uri: String) async throws -> AudioInfo  // { durationMs: Int64 }
    func play() async throws
    func pause() async throws
    func seekTo(positionMs: Int64) async throws
    func getPosition() async -> Int64
    func cleanup() async
    func getAmplitudes(sampleCount: Int) async -> [Float]?  // optional — default returns nil
}
```

---

## Features

### Chat
- Real-time text messaging via WebSocket
- Streaming bot responses (chunks rendered as they arrive)
- Markdown rendering in bot messages (bold, italic, code, links — native `AttributedString`)
- Message persistence across app restarts (Core Data, up to 500 messages)
- Auto-scroll to latest message

### Media
- Image upload (up to 5 per message) with preview grid and remove buttons
- Full-screen image viewer on tap
- Voice note recording with waveform visualization (requires adapter)
- Voice note playback with progress bar

### Interactive
- Preset/suggestion buttons (static from config + dynamic from server)
- Server command system: rating, feedback, end session, countdown, auto-close
- End chat confirmation modal
- Escalation to human agent button
- Emoji via system keyboard

### Connection
- WebSocket heartbeat (ping every 25s, timeout after 60s)
- Automatic reconnection with exponential backoff (max 100 attempts, 30s cap)
- Message queue during reconnection (messages sent while connecting are queued and flushed on open)
- Session ID persistence — reconnection resumes the same conversation
- App background/foreground awareness (stops heartbeat when backgrounded, reconnects on foreground)
- Online/offline detection via `NWPathMonitor`

---

## Theming

The SDK automatically fetches theme settings from your bot configuration. No manual setup needed.

**How it works:**

1. `theme: "light" | "dark"` — controls background, cards, borders, and text colors
2. `chatbox_gradient_color` — controls header, buttons, and user message bubbles
3. Text on the gradient **automatically adapts**: white text on dark gradients, dark text on light gradients

These two settings are independent. A dark theme can have a light gradient color and vice versa.

**Dark mode colors:**

| Element | Color |
|---------|-------|
| Background | `#14161A` |
| Cards/Bubbles | `#2C2D31` |
| Borders | `#3F3F46` |
| Text | `#FAFAFA` |

**Light mode colors:**

| Element | Color |
|---------|-------|
| Background | `#FFFFFF` |
| Bot bubbles | `#F5F5F5` |
| Borders | `#E4E4E7` |
| Text | `#14161A` |

---

## RTL / Arabic Support

Set `locale: "ar"` — the entire UI adapts automatically:

- All text right-aligned
- Message bubbles mirrored (user left, bot right)
- Navigation arrows flipped
- Arabic translations for all built-in strings (form labels, buttons, errors, placeholders)
- Per-message language detection for mixed-language chats
- **No global mutation** — the SDK does NOT change your app's `layoutDirection` or any global iOS setting. RTL is scoped entirely within the SDK's views.

---

## Headless Mode — Full Guide

Headless mode gives you the complete chat engine (`RayaChatClient`) with all state exposed as Combine `@Published` properties. You build the entire UI yourself — the SDK handles WebSocket, reconnection, persistence, commands, and state management.

### All State (@Published)

Observe these in your UI to react to changes:

| State | Type | Description |
|-------|------|-------------|
| `messages` | `[TypeMessage]` | Full message history (persisted across app restarts). Image/audio attachments are updated with remote URLs once the server processes them. |
| `currentMessage` | `String` | Streaming text — grows as chunks arrive, cleared on RESPONSE |
| `connectionStatus` | `ConnectionStatus` | `.connecting`, `.connected`, `.disconnected`, `.reconnecting` |
| `isConnected` | `Bool` | WebSocket is open and healthy |
| `isOnline` | `Bool` | Device has network connectivity |
| `loading` | `Bool` | Bot is processing (STEP received, cleared on RESPONSE) |
| `status` | `String?` | Status text from server: "Searching...", "Thinking..." |
| `info` | `String?` | Info text: "Waiting for human agent..." |
| `commandData` | `CommandData?` | Active server command — see [Handling Commands](#handling-commands) |
| `presets` | `[String]` | Suggestion button titles from server |
| `showHumanAgentBtn` | `Bool` | Escalation to human agent is available |
| `sessionCloseInfo` | `SessionCloseInfo?` | Non-nil when server closed the session (auto_close) |
| `currentSessionId` | `String` | Server-assigned session ID (empty before first response) |

### All Actions

| Action | Signature | When to call |
|--------|-----------|--------------|
| `connect` | `func connect(userInfo:, botConfig:) async` | After user submits form (or with empty `UserInfo` to skip form) |
| `fetchBotConfig` | `func fetchBotConfig() async -> BotConfigProps` | Before `connect()` — needed for initial bot message |
| `sendMessage` | `func sendMessage(_ text:)` | User taps send button |
| `sendImages` | `func sendImages(_ images:, caption:)` | User sends images |
| `sendAudio` | `func sendAudio(_ base64:)` | User sends voice note |
| `sendPreset` | `func sendPreset(_ text:)` | User taps a suggestion button |
| `sendCommandResponse` | `func sendCommandResponse(command:, response:)` | User responds to a command (rating, feedback, etc.) |
| `clearSessionCloseInfo` | `func clearSessionCloseInfo()` | When starting a new chat after auto_close |
| `endSession` | `func endSession() async` | User wants to end the session (clears all storage) |
| `destroy` | `func destroy()` | View disappears / ViewController deinit |

### Lifecycle: endSession vs destroy

| Method | Clears storage? | Closes WebSocket? | Fires `onSessionEnd`? | When to call |
|--------|----------------|-------------------|----------------------|-------------|
| `endSession()` | **Yes** — deletes messages, session ID, user info | Yes | **Yes** — with session ID + messages | User taps "End Session" |
| `destroy()` | **No** — messages and session persist for resume | Yes | No | View disappears / deinit |

> `endSession()` snapshots the session ID and messages **before** clearing, then passes both to `onSessionEnd`. This is safe even when triggered by a server command.

### Handling Streaming Messages

The bot sends responses in chunks. Here's the typical sequence:

```
Server: STEP     { text: "Searching..." }     -> loading = true, status = "Searching..."
Server: CHUNK    { text: "Here are " }         -> currentMessage = "Here are "
Server: CHUNK    { text: "the results" }       -> currentMessage = "Here are the results"
Server: RESPONSE { data: { content: ... } }    -> message added to messages, currentMessage = "", loading = false
```

In your UI, render `currentMessage` as a temporary bot bubble at the bottom of the list:

```swift
struct ChatScreen: View {
    @ObservedObject var client: RayaChatClient

    var body: some View {
        ScrollView {
            LazyVStack {
                // Render finalized messages
                ForEach(client.messages) { msg in
                    MessageBubble(message: msg)
                }

                // Show streaming bot response (temporary — disappears when RESPONSE arrives)
                if !client.currentMessage.isEmpty {
                    BotBubble(text: client.currentMessage)
                }

                // Show typing indicator while waiting for first chunk
                if client.loading && client.currentMessage.isEmpty {
                    TypingIndicator()
                }
            }
        }
    }
}
```

### Handling Commands

The server sends commands for interactive UI (rating, feedback, end session). When `commandData` is non-nil, you should:

1. Show the appropriate UI (disable the message composer)
2. Collect the user's response
3. Call `sendCommandResponse(command:, response:)`

```swift
if let cmd = client.commandData {
    switch cmd.content {
    case "rate_conversation":
        // Show 5 rating icons (1-5). cmd.message = "How would you rate this conversation?"
        // cmd.options = [1, 2, 3, 4, 5]
        RatingUI(message: cmd.message, onRate: { rating in
            client.sendCommandResponse(command: "rate_conversation", response: rating)
        })

    case "submit_feedback":
        // Show textarea + Skip/Submit buttons. cmd.message = "Any feedback?"
        FeedbackUI(message: cmd.message, optional: cmd.optional, onSubmit: { text in
            client.sendCommandResponse(command: "submit_feedback", response: text)
        })

    case "end_session":
        // Show Yes/No buttons. cmd.message = "Do you want to end this session?"
        EndSessionUI(message: cmd.message, onConfirm: {
            client.sendCommandResponse(command: "end_session", response: "yes")
        })

    case "feedback_received":
        // Show countdown (3 seconds), then call endSession()
        CountdownUI(message: cmd.message, onComplete: {
            Task { await client.endSession() }
        })

    default: break
    }
}
```

**Command flow (typical):**

```
end_session -> user picks Yes/No
    -> if Yes: rate_conversation -> user rates 1-5
        -> submit_feedback -> user types feedback or skips
            -> feedback_received -> 3s countdown -> endSession()
```

---

## Exporting Session Data (onSessionEnd)

The `onSessionEnd` callback receives the session ID and full message history, captured before state is cleared. It fires whenever `client.endSession()` is called — by the user via the packaged UI's End Session modal, by the packaged UI after a `feedback_received` countdown, or by your own headless code. It does **not** auto-fire on `auto_close`; see the callback reference for that case.

### Packaged UI example

```swift
struct SupportScreen: View {
    let customerId: String
    let rideId: String

    var body: some View {
        RayaChatView(
            token: "your-bot-token",
            onSessionEnd: { sessionId, messages in
                Task {
                    await api.post("/support/sessions", body: [
                        "customer_id": customerId,
                        "ride_id": rideId,
                        "session_id": sessionId,
                        "message_count": messages.count,
                        "transcript": messages.map { msg in
                            [
                                "sender": msg.sender == 1 ? "user" : "bot",
                                "content": msg.content ?? "",
                                "timestamp": msg.createdAt ?? "",
                                "attachments_json": msg.attachmentsJson ?? "",
                                "audio_json": msg.audioJson ?? "",
                            ]
                        },
                    ])
                }
            },
            onClose: { /* dismiss */ }
        )
    }
}
```

### What `onSessionEnd` receives

| Parameter | Type | Description |
|-----------|------|-------------|
| `sessionId` | `String` | The server-assigned session ID (empty string if session never connected) |
| `messages` | `[TypeMessage]` | Complete message history at the moment the session ended |

See [TypeMessage Schema](#typemessage-schema) for the full message object structure.

### When to use `onSessionEnd` vs `onMessageUpdate`

| Scenario | Use |
|----------|-----|
| Export full transcript after session ends | `onSessionEnd` |
| Mark session as "closed" in your DB | `onSessionEnd` |
| Sync every message in real-time so no data is lost on app close | `onMessageUpdate` |
| Both — real-time sync + close marker | Both callbacks together |

`onSessionEnd` fires **only** on explicit session end (user action or server command). If the user closes the app without ending the session, `onSessionEnd` **never fires** and unsent messages are not exported. Use `onMessageUpdate` to guarantee every message reaches your backend regardless of how the app exits.

---

## Real-Time Message Sync (onMessageUpdate)

The `onMessageUpdate` callback fires after every message send/receive with the individual message. Unlike `onSessionEnd`, it fires **during** the session — so by the time the user closes the app, every message has already been synced.

### When it fires

| Event | Fires? | Message received |
|-------|--------|-----------------|
| User sends text | Yes (immediately) | User's message (sender=1, type=1) |
| Bot responds | Yes (immediately) | Bot's message (sender=2, type=1) |
| User sends images | Yes (after server returns S3 URLs) | User's image message with remote URLs (sender=1, type=3) |
| User sends audio | Yes (after server returns S3 URL) | User's audio message with remote URL (sender=1, type=2) |
| System / agent activity (e.g., "Agent joined") | Yes (immediately) | Activity message (sender=2, type=4) |
| Bot thinking (STEP/CHUNK) | No | -- |
| Presets/commands | No | -- |
| Session end | No | Use `onSessionEnd` instead |

### Why image/audio messages are deferred

When the user sends images, the SDK initially stores local `data:image/jpeg;base64,...` URIs. These are useless for your backend DB. The callback waits until the server processes the upload and responds with permanent remote URLs (e.g., `https://s3.amazonaws.com/...`), then fires with the updated message.

### Example — sync every message to your API

```swift
RayaChatView(
    token: "your-bot-token",
    onMessageUpdate: { sessionId, message in
        Task {
            await api.post("/v1/messages", body: [
                "session_id": sessionId,
                "customer_id": customerId,
                "message_id": message.id,
                "sender": message.sender == 1 ? "user" : "agent",  // 1 = human user, 2 = AI/human agent (incl. system activity)
                "type": message.type == 1 ? "text" : (message.type == 2 ? "audio" : (message.type == 3 ? "image" : "system")),
                "content": message.content ?? "",
                "attachments": message.attachmentsJson ?? "",
                "audio": message.audioJson ?? "",
                "created_at": message.createdAt ?? "",
            ])
        }
    },
    onSessionEnd: { sessionId, messages in
        // Mark session as closed in your backend
        Task { await api.post("/v1/sessions/close", body: ["session_id": sessionId]) }
    }
)
```

### Image message timeline

```
1. User picks 2 images and taps send
2. Images appear in chat immediately (local URIs for display)
3. SDK sends images to server via WebSocket
4. Server processes and returns RESPONSE with S3 URLs
5. SDK updates user's message with remote URLs
6. onMessageUpdate fires with: sender=1, type=3, attachmentsJson=[{id:"local-att-1712678420-0", url:"https://s3...", type:"image", name:"IMG_0001.JPG"}, ...]
7. onMessageUpdate fires with bot's reply: sender=2, type=1, content="I see your images..."
```

Steps 1-5 happen internally. The developer's callback only fires at step 6 and 7 — always with clean, storable data.

### Complete session timeline

```
1.  Bot: "Hi there 👋"                → onMessageUpdate(sid, bot msg)
2.  User: "Hello"                      → onMessageUpdate(sid, user msg)
3.  Bot: "How can I help?"             → onMessageUpdate(sid, bot msg)
4.  User sends 2 images + "Check this" → (no callback yet)
5.  Server processes images...
6.  User image gets remote URLs        → onMessageUpdate(sid, user img msg with S3 URLs)
7.  Bot: "I see your images"           → onMessageUpdate(sid, bot msg)
8.  User: "Thanks"                     → onMessageUpdate(sid, user msg)
9.  Bot: "You're welcome"              → onMessageUpdate(sid, bot msg)
10. User taps End Session              → onSessionEnd(sid, all 7 messages)

If user closes app after step 9 instead of step 10 — all 7 messages
were already synced individually via onMessageUpdate. Nothing is lost.
```

See [TypeMessage Schema](#typemessage-schema) for the full message object structure.

---

## TypeMessage Schema

`TypeMessage` is the message object returned by `onSessionEnd`, `onMessageUpdate`, and `client.messages` (headless mode). Every message in the SDK — user, bot, or system — uses this structure.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique message ID. User messages: `"local-1712678410-a1b2c3d4"`. Bot/agent responses: `"resp-uuid"`. Agent-activity messages: a generated UUID. |
| `sender` | `Int` | Who sent it: `1` = human user (the person using the app), `2` = AI agent / human agent / system agent_activity. The SDK never emits `sender=0`. |
| `type` | `Int` | Message type: `1` = text, `2` = audio, `3` = image, `4` = agent_activity (system messages like "Agent joined"). Use `type==4` to distinguish system activity from regular bot text. |
| `content` | `String?` | Message text. May contain markdown for bot messages. Image caption for image messages. `nil` for audio-only messages. |
| `createdAt` | `String?` | Unix timestamp in **seconds** (e.g., `"1712678410"`). Stored as String. |
| `attachmentsJson` | `String?` | JSON string containing a list of image attachments. `nil` for non-image messages. See [Attachment Schema](#attachment-schema) below. |
| `audioJson` | `String?` | JSON string containing audio data. `nil` for non-audio messages. See [AudioData Schema](#audiodata-schema) below. |

### Examples by message type

**Text message (user):**
```json
{
    "id": "local-1712678410-a1b2c3d4",
    "sender": 1,
    "type": 1,
    "content": "Hello, I need help with my order",
    "createdAt": "1712678410",
    "attachmentsJson": null,
    "audioJson": null
}
```

**Text message (bot):**
```json
{
    "id": "resp-550e8400-e29b-41d4-a716-446655440000",
    "sender": 2,
    "type": 1,
    "content": "Hi there! I'd be happy to help. Could you share your order number?",
    "createdAt": "1712678415",
    "attachmentsJson": null,
    "audioJson": null
}
```

**Image message (user — with remote S3 URLs):**
```json
{
    "id": "local-img-1712678420-e5f6g7h8",
    "sender": 1,
    "type": 3,
    "content": "Here's a photo of the issue",
    "createdAt": "1712678420",
    "attachmentsJson": "[{\"id\":\"local-att-1712678420-0\",\"url\":\"https://s3.amazonaws.com/bucket/image1.jpg\",\"type\":\"image\",\"name\":\"IMG_0001.JPG\"},{\"id\":\"local-att-1712678420-1\",\"url\":\"https://s3.amazonaws.com/bucket/image2.jpg\",\"type\":\"image\",\"name\":\"IMG_0002.JPG\"}]",
    "audioJson": null
}
```

**Audio message (user — with remote S3 URL):**
```json
{
    "id": "local-audio-1712678430",
    "sender": 1,
    "type": 2,
    "content": "",
    "createdAt": "1712678430",
    "attachmentsJson": null,
    "audioJson": "{\"type\":\"remote\",\"audioUrls\":\"https://s3.amazonaws.com/bucket/voice-note.m4a\"}"
}
```

**Agent-activity message (system "Agent joined"):**
```json
{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "sender": 2,
    "type": 4,
    "content": "Agent joined the conversation",
    "createdAt": "1712678440",
    "attachmentsJson": null,
    "audioJson": null
}
```
> Note: `sender=2` here, same as a regular bot reply. Use `type==4` to detect system/activity messages.

### Attachment Schema

`attachmentsJson` is a JSON-serialized array. Parse it to get individual image URLs:

```swift
// Swift
let attachments = message.attachments  // computed property — decodes JSON automatically
for att in attachments {
    print("Image: \(att.url)")
}

// Or manually:
if let json = message.attachmentsJson,
   let data = json.data(using: .utf8),
   let atts = try? JSONDecoder().decode([Attachment].self, from: data) {
    for att in atts { print("Image: \(att.url)") }
}
```

Each `Attachment` object:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Client-side attachment ID assigned at send time (e.g., `"local-att-1712678420-0"`). Preserved through the local→remote URL swap so backends can dedup. |
| `url` | `String` | Remote image URL — e.g., `"https://s3.amazonaws.com/bucket/image1.jpg"` |
| `type` | `String` | Always `"image"` |
| `name` | `String` | Original filename from the picker (e.g., `"IMG_0001.JPG"`). Preserved through the local→remote URL swap. |

Example parsed:
```json
[
    {"id": "local-att-1712678420-0", "url": "https://s3.amazonaws.com/bucket/image1.jpg", "type": "image", "name": "IMG_0001.JPG"},
    {"id": "local-att-1712678420-1", "url": "https://s3.amazonaws.com/bucket/image2.jpg", "type": "image", "name": "IMG_0002.JPG"}
]
```

### AudioData Schema

`audioJson` is a JSON-serialized object. Parse it to get the audio URL:

```swift
// Swift
if let audio = message.audio {  // computed property — decodes JSON automatically
    print("Audio: \(audio.audioUrls)")
}

// Or manually:
if let json = message.audioJson,
   let data = json.data(using: .utf8),
   let audio = try? JSONDecoder().decode(AudioData.self, from: data) {
    print("Audio: \(audio.audioUrls)")
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | `String` | `"remote"` (server URL) or `"local"` (before upload — never in callbacks) |
| `audioUrls` | `String` | Remote audio URL — e.g., `"https://s3.amazonaws.com/bucket/voice.m4a"` |

> **Note:** `audioUrls` is a single URL string (not an array) despite the plural name. This naming is inherited from the server protocol.

Example parsed:
```json
{"type": "remote", "audioUrls": "https://s3.amazonaws.com/bucket/voice-note.m4a"}
```

### Important notes

- **All URLs are remote server URLs, never local paths.** `attachmentsJson` and `audioJson` in `onSessionEnd` and `onMessageUpdate` callbacks always contain permanent S3/CDN URLs that can be stored in your database or accessed from any device.
- **`content` may contain markdown** for bot messages (bold, italic, code, links). Parse or render accordingly if storing in your system.
- **`createdAt` is seconds, not milliseconds.** Multiply by 1000 if you need a JavaScript `Date` or Swift `Date(timeIntervalSince1970:)` already takes seconds.
- **`sender` values:** `1` = human user (the person using the app), `2` = everyone else — AI agent, human agent, and system "agent_activity" messages all share `sender=2`. The SDK never emits `sender=0`. To distinguish a system/activity message from a regular bot reply, check `type==4` (agent_activity) vs `type==1` (text).

---

## Session Persistence

The SDK persists data so conversations survive app restarts:

| Data | Storage | Encrypted |
|------|---------|-----------|
| Session ID | Keychain | Yes (Secure Enclave) |
| User info | Keychain | Yes (Secure Enclave) |
| Messages (up to 500) | Core Data (SQLite) | App sandbox |

**How it works:**

1. User chats, messages are saved to Core Data on every send/receive
2. User kills the app or the OS kills the process
3. User reopens the app and taps "Start a chat"
4. SDK reads stored session ID and messages from storage
5. WebSocket connects with the stored session ID — server resumes the conversation
6. Previous messages appear immediately in the chat

**When data is cleared:**

- `endSession()` — clears everything (session ID, messages, user info)
- `destroy()` — does **not** clear storage (data survives for session resume)

---

## Background / Foreground Behavior

| Duration in background | What happens on return |
|-----------------------|------------------------|
| < 60 seconds | WebSocket likely survived. Returns seamlessly. |
| 1-5 minutes | WebSocket may have died. SDK auto-reconnects with same session. |
| 5+ minutes | WebSocket dead. Stale streaming state cleared. SDK auto-reconnects with saved session ID. |
| App killed by OS | Everything in memory lost. Keychain + Core Data survive. User taps "Start Chat" -> messages restored. |

The SDK uses `NotificationCenter` to detect foreground/background transitions (`UIApplication.didBecomeActiveNotification` / `willResignActiveNotification`). When backgrounded, it stops the heartbeat to save battery. When foregrounded, it reconnects if needed and clears any stale streaming state.

---

## Keeping Chat Alive Across Tabs

If your app has tab navigation, keep the chat view mounted — hide it visually instead of removing it:

```swift
// Correct — stays mounted, preserves chat state
TabView(selection: $activeTab) {
    HomeView().tag("home")
    RayaChatView(token: "...").tag("support")
}

// Wrong — recreates on every tab switch
if activeTab == "support" {
    RayaChatView(token: "...")
}
```

When `RayaChatView` leaves the view hierarchy, `destroy()` is called automatically (via `deinit`), which closes the WebSocket. Mounting it again starts a fresh session from the intro screen (though stored messages are restored).

---

## Architecture

```
+--------------------------------------------------+
|              RayaChatCore                         |
|                                                  |
|  WebSocket . Heartbeat . Reconnection . Queue    |
|  Message Parser . Commands . Error Sanitizer     |
|  Bot Config Fetch . Session Storage              |
|  App Lifecycle . Network Detection               |
|                                                  |
|  Storage:                                        |
|  -> Core Data (messages, max 500)                |
|  -> Keychain (session + user, Secure Enclave)    |
|                                                  |
|  Swift Concurrency + Combine @Published          |
|  URLSessionWebSocketTask (built-in)              |
|  Zero third-party dependencies                   |
+------------------+---------------+---------------+
                   |               |
       +-----------v------+  +----v------------------+
       |  RayaChatUI      |  |  Developer's own UI   |
       |                  |  |                       |
       |  Mode 1: View    |  |  Mode 4: Headless     |
       |  Mode 2: UIKit   |  |  (SwiftUI or UIKit)   |
       |  Mode 3: Sheet   |  |                       |
       |                  |  |  client.$messages      |
       |  SwiftUI         |  |  client.sendMessage()  |
       +------------------+  +-----------------------+
```

### Project Structure

```
raya-chat-ios/
├── Sources/RayaChatCore/              # Headless engine (no UI)
│   ├── RayaChatClient.swift           # Main entry point
│   ├── RayaChatConfig.swift           # Configuration
│   ├── Constants.swift                # SDK constants
│   ├── Models/                        # 14 data models + enums
│   ├── Adapters/                      # 3 adapter protocols
│   ├── WebSocket/                     # WebSocket + message queue
│   ├── API/                           # Bot config fetch + URL builder
│   ├── Protocol/                      # Message handler (10 types)
│   ├── Storage/                       # Core Data + Keychain
│   ├── Lifecycle/                     # Background/foreground observer
│   ├── Network/                       # NWPathMonitor connectivity
│   └── Util/                          # Color, validation, time, RTL, error sanitizer
│
├── Sources/RayaChatUI/                # Packaged UI (SwiftUI)
│   ├── RayaChatView.swift             # Mode 1: SwiftUI View
│   ├── RayaChatViewController.swift   # Mode 2: UIKit bridge
│   ├── RayaChatViewModel.swift        # State machine (INTRO -> FORM -> CHAT)
│   ├── Screens/                       # IntroScreen, FormScreen, ChatScreen
│   ├── Components/Chat/              # MessageBubble, Composer, Presets, Typing
│   ├── Components/Commands/          # Rating, Feedback, EndSession, Countdown
│   ├── Components/Media/             # ImageViewer, ImagePreview, Audio, DefaultImagePicker
│   ├── Components/Common/            # Header, Icons, Strings, Toast
│   └── Theme/                        # Colors, typography, RTL utils
│
└── ExampleApp/                        # Demo app (4 integration modes, Xcode project)
```

---

## Requirements

| Requirement | Version |
|------------|---------|
| iOS | 15.0+ |
| macOS | 13.0+ (for SPM build) |
| Swift | 5.9+ |
| Xcode | 15.0+ |
| Third-party dependencies | **0** |

## Example App

Open `ExampleApp/ExampleApp.xcodeproj` in Xcode, pick a simulator, and press ⌘R. The demo covers all 4 integration modes:

| Demo | Mode | What it shows |
|------|------|--------------|
| SwiftUIDemo | Mode 1 | Full chat widget — 3 lines of code |
| UIKitDemo | Mode 2 | Chat in UINavigationController |
| SheetDemo | Mode 3 | Chat slides up as bottom sheet |
| HeadlessDemo | Mode 4 | Nocturne Velvet custom UI with all features |

Set your bot token in `ExampleApp/ExampleApp/SampleToken.swift` (a sample is included).

---

## Troubleshooting

### Paperclip (image) button not showing

The built-in `DefaultImagePickerAdapter` is provided automatically. If you explicitly pass `imagePickerAdapter: nil`, the button is hidden. Also check that `enable_image_upload` is enabled in your bot config on the dashboard.

### Keyboard doesn't dismiss

Tap any blank area in the chat screen, or send a message — both dismiss the keyboard automatically. If using headless mode, you must handle keyboard dismissal in your own UI.

### onSessionEnd not firing

Make sure the session ends via `endSession()`. In Mode 2 (UIKit), pass `onSessionEnd` in the `init` constructor — not as a stored property after init.

### Image attachments have base64 data URIs instead of remote URLs

Wait for the bot to respond before ending the session. The server sends back remote S3 URLs in its response, which replace the local data URIs. If you end the session before the server responds, attachments will still have local data URIs.

### WebSocket disconnects after sending a message

Check your network connection. The SDK automatically reconnects with exponential backoff. If the issue persists, ensure your bot token is valid and the server is accessible.

### Chat resets to intro on tab switch

Keep the `RayaChatView` mounted in the view hierarchy. See [Keeping Chat Alive Across Tabs](#keeping-chat-alive-across-tabs).

### Mode 2 (UIKit) callbacks not working

All callbacks (`onSessionStart`, `onSessionEnd`, `onError`, `onClose`) must be passed in the `RayaChatViewController` constructor. They cannot be set as properties after init.

### CocoaPods build error: "Sandbox: rsync(...) deny" (Xcode 15+)

If `pod install` succeeds but the first build fails with errors like:

```
error: Sandbox: rsync(...) deny(1) file-write-create .../Frameworks/RayaChatCore.framework/_CodeSignature
```

This is an Xcode 15+ default that blocks CocoaPods' framework-embed step — not an SDK issue. Fix it once in your Xcode target:

1. Select the project in the file navigator → pick your **app target** (not the project)
2. Go to **Build Settings** → click **All** (the Basic tab hides this setting)
3. Search for `User Script Sandboxing`
4. Set the value to **No**
5. ⌘R

The setting only affects your app, not the SDK. Tracked upstream at [CocoaPods/CocoaPods#12012](https://github.com/CocoaPods/CocoaPods/issues/12012).

## License

MIT

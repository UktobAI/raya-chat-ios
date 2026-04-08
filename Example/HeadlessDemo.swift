import SwiftUI
import RayaChatCore

// MARK: - Nocturne Velvet Palette

private let midnight = Color(hex: 0x0C0C10)
private let onyx = Color(hex: 0x141418)
private let slate = Color(hex: 0x1C1C22)
private let graphite = Color(hex: 0x26262E)
private let amber = Color(hex: 0xD4A056)
private let cream = Color(hex: 0xF5EDE0)
private let creamMuted = Color(hex: 0xF5EDE0).opacity(0.7)
private let stone = Color(hex: 0x6B6B78)
private let rose = Color(hex: 0xD4566A)
private let emerald = Color(hex: 0x4ADE80)

/// Mode 4 demo — Nocturne Velvet headless chat using ALL RayaChatClient features.
/// Matches Android HeadlessDemoActivity + CustomChatScreen feature for feature.
struct HeadlessDemo: View {
    @StateObject private var client = RayaChatClient(config: RayaChatConfig(
        token: sampleToken,
        onSessionStart: { id in print("[Mode4] Session: \(id)") },
        onError: { err in print("[Mode4] Error: \(err)") }
    ))

    var imagePickerAdapter: (any ImagePickerAdapter)?

    @State private var chatStarted = false
    @State private var text = ""
    @State private var selectedImages: [ImageAsset] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if !chatStarted {
                welcomeScreen
            } else {
                chatScreen
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Welcome

    private var welcomeScreen: some View {
        ZStack {
            LinearGradient(colors: [onyx, midnight], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Amber ring avatar
                ZStack {
                    Circle().stroke(amber, lineWidth: 1.5).frame(width: 72, height: 72)
                    Text("N").font(.system(size: 28, weight: .thin)).foregroundColor(amber).tracking(2)
                }

                Text("Nocturne Concierge")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(cream)
                    .tracking(3)
                Text("Headless Mode — All Features")
                    .font(.system(size: 11))
                    .foregroundColor(stone)
                    .tracking(2)

                // Session close warning
                if let closeInfo = client.sessionCloseInfo {
                    Text(closeInfo.message)
                        .font(.system(size: 12))
                        .foregroundColor(rose)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(rose.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 40)

                    Button("Dismiss") { client.clearSessionCloseInfo() }
                        .font(.system(size: 11)).foregroundColor(stone)
                }

                Spacer().frame(height: 20)

                // Start button
                Button(action: startChat) {
                    Text("Begin Conversation")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(midnight)
                        .tracking(1.5)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(amber)
                        .clipShape(Capsule())
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Text("← Back").font(.system(size: 12)).foregroundColor(stone)
                }
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Chat

    private var chatScreen: some View {
        VStack(spacing: 0) {
            chatHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayMessages) { msg in
                            if msg.type == 4 {
                                systemMsg(msg)
                            } else {
                                chatBubble(msg)
                            }
                        }
                        footerContent.id("__footer__")
                    }
                }
                .onChange(of: client.messages.count) { _ in
                    withAnimation { proxy.scrollTo("__footer__", anchor: .bottom) }
                }
                .onChange(of: client.currentMessage) { _ in
                    proxy.scrollTo("__footer__", anchor: .bottom)
                }
            }

            composer
        }
        .background(midnight.ignoresSafeArea())
    }

    private var displayMessages: [TypeMessage] {
        var msgs = client.messages
        if !client.currentMessage.isEmpty {
            msgs.append(TypeMessage(id: "__streaming__", sender: 2, type: 1, content: client.currentMessage))
        }
        return msgs
    }

    // MARK: - Header

    private var chatHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle().fill(graphite).frame(width: 36, height: 36)
                            Text("N").font(.system(size: 15, weight: .thin)).foregroundColor(amber).tracking(1)
                        }
                        Circle()
                            .fill(client.isConnected ? emerald : (client.isOnline ? amber : rose))
                            .frame(width: 10, height: 10)
                            .overlay(Circle().fill(onyx).frame(width: 12, height: 12), alignment: .center)
                            .overlay(Circle().fill(client.isConnected ? emerald : (client.isOnline ? amber : rose)).frame(width: 8, height: 8))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nocturne").font(.system(size: 15, weight: .light)).foregroundColor(cream).tracking(1)
                        Text(client.isConnected ? "Active" : (client.isOnline ? "Reconnecting..." : "Offline"))
                            .font(.system(size: 10)).foregroundColor(client.isConnected ? stone : rose).tracking(0.5)
                    }
                }

                Spacer()

                // Session ID
                if !client.currentSessionId.isEmpty {
                    Text(client.currentSessionId.prefix(8) + "...")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(stone.opacity(0.5))
                }

                Button(action: endChat) {
                    Text("End").font(.system(size: 12, weight: .medium)).foregroundColor(rose).tracking(1)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(onyx)

            Rectangle().fill(amber.opacity(0.15)).frame(height: 0.5)
        }
    }

    // MARK: - Bubbles

    private func chatBubble(_ msg: TypeMessage) -> some View {
        let isUser = msg.sender == 1
        let content = msg.content ?? ""
        let attachments = msg.attachments

        return AnyView(
            HStack(alignment: .bottom, spacing: 8) {
                if !isUser {
                    ZStack {
                        Circle().fill(graphite).frame(width: 24, height: 24)
                        Text("N").font(.system(size: 9, weight: .thin)).foregroundColor(amber)
                    }
                }

                VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                    // Image attachments
                    if !attachments.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(attachments, id: \.id) { att in
                                AsyncImage(url: URL(string: att.url)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(graphite)
                                        .overlay(Text("📷").font(.system(size: 16)))
                                }
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    if !content.isEmpty {
                        Text(content)
                            .font(.system(size: 14))
                            .foregroundColor(isUser ? midnight : cream)
                            .lineSpacing(4)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isUser ? amber : slate)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    if let ts = msg.createdAt.flatMap({ Int64($0) }), ts > 0 {
                        Text(formatLocalTimeOrEmpty(epochSeconds: ts))
                            .font(.system(size: 9)).foregroundColor(stone.opacity(0.6))
                            .padding(.horizontal, 4)
                    }
                }
                .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)

                if isUser { Spacer(minLength: 0) }
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        )
    }

    private func systemMsg(_ msg: TypeMessage) -> some View {
        Text(msg.content ?? "")
            .font(.system(size: 10)).foregroundColor(stone).tracking(0.5)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(graphite).clipShape(RoundedRectangle(cornerRadius: 4))
            .frame(maxWidth: .infinity).padding(.vertical, 10)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerContent: some View {
        // Typing indicator — animated dots
        if client.loading && client.currentMessage.isEmpty && client.info == nil {
            typingDots
        }

        // Status (Searching..., Thinking...)
        if let status = client.status, client.currentMessage.isEmpty {
            Text(status).font(.system(size: 10)).foregroundColor(amber.opacity(0.7)).tracking(1)
                .padding(.leading, 32).padding(.bottom, 8)
        }

        // Info (Waiting for human agent...)
        if let info = client.info {
            HStack(spacing: 6) {
                Text("⏳").font(.system(size: 10))
                Text(info).font(.system(size: 12)).foregroundColor(creamMuted)
            }
            .padding(.leading, 32).padding(.bottom, 12)
        }

        // Escalation button
        if client.showHumanAgentBtn {
            HStack {
                Spacer()
                Button(action: { client.sendMessage("/human_agent") }) {
                    Text("Connect with a person")
                        .font(.system(size: 11)).foregroundColor(amber).tracking(0.5)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(amber.opacity(0.4), lineWidth: 0.5))
                }
            }
            .padding(.bottom, 12)
        }

        // Commands
        if let cmd = client.commandData {
            commandUI(cmd)
        }

        // Presets
        if !client.presets.isEmpty && client.commandData == nil {
            HStack(spacing: 8) {
                Spacer()
                ForEach(client.presets, id: \.self) { preset in
                    Button(action: { client.sendPreset(preset) }) {
                        Text(preset).font(.system(size: 12)).foregroundColor(creamMuted).tracking(0.3)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .overlay(Capsule().stroke(stone.opacity(0.3), lineWidth: 0.5))
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
    }

    // MARK: - Typing Dots (animated, matches Android stagger)

    private var typingDots: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.8)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    let stagger = Double(i) * 0.15
                    let local = phase - stagger
                    let t = (local > 0 && local < 0.4) ? (local < 0.2 ? local / 0.2 : 1.0 - (local - 0.2) / 0.2) : 0.0
                    Circle().fill(amber.opacity(0.6)).frame(width: 5, height: 5)
                        .offset(y: CGFloat(-5.0 * t))
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(slate).clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 32).padding(.bottom, 12)
    }

    // MARK: - Commands

    @ViewBuilder
    private func commandUI(_ cmd: CommandData) -> some View {
        switch cmd.content {
        case "rate_conversation":
            ratingCommand(cmd)
        case "submit_feedback":
            feedbackCommand(cmd)
        case "end_session":
            endSessionCommand(cmd)
        case "feedback_received":
            countdownCommand(cmd)
        default:
            EmptyView()
        }
    }

    private func ratingCommand(_ cmd: CommandData) -> some View {
        let colors: [Color] = [rose, Color(hex: 0xF97316), amber, Color(hex: 0x84CC16), emerald]
        return VStack(alignment: .leading, spacing: 10) {
            if !cmd.message.isEmpty {
                Text(cmd.message).font(.system(size: 13)).foregroundColor(creamMuted)
            }
            HStack(spacing: 8) {
                ForEach(0..<cmd.options.count, id: \.self) { i in
                    let val = (cmd.options[i].value as? Int) ?? (i + 1)
                    let c = colors.indices.contains(i) ? colors[i] : amber
                    Button(action: { client.sendCommandResponse(command: "rate_conversation", response: val) }) {
                        Text("\(val)").font(.system(size: 14, weight: .light)).foregroundColor(c)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(c.opacity(0.5), lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(14).background(slate).clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    @State private var feedbackText = ""

    private func feedbackCommand(_ cmd: CommandData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !cmd.message.isEmpty {
                Text(cmd.message).font(.system(size: 13)).foregroundColor(creamMuted)
            }
            TextField("Share your thoughts...", text: $feedbackText)
                .font(.system(size: 13)).foregroundColor(cream)
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(stone.opacity(0.3), lineWidth: 0.5))

            Text("\(feedbackText.count)/200")
                .font(.system(size: 10)).foregroundColor(stone)

            HStack {
                Spacer()
                if cmd.optional {
                    Button("Skip") {
                        client.sendCommandResponse(command: "submit_feedback", response: "")
                        feedbackText = ""
                    }
                    .font(.system(size: 12)).foregroundColor(stone)
                }
                Button("Submit") {
                    client.sendCommandResponse(command: "submit_feedback", response: feedbackText)
                    feedbackText = ""
                }
                .font(.system(size: 12, weight: .medium)).foregroundColor(midnight)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(amber).clipShape(Capsule())
            }
        }
        .padding(14).background(slate).clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private func endSessionCommand(_ cmd: CommandData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !cmd.message.isEmpty {
                Text(cmd.message).font(.system(size: 13)).foregroundColor(creamMuted)
            }
            HStack(spacing: 10) {
                ForEach(0..<cmd.options.count, id: \.self) { i in
                    let opt = cmd.options[i].description
                    Button(action: { client.sendCommandResponse(command: "end_session", response: opt) }) {
                        Text(opt).font(.system(size: 12)).foregroundColor(cream)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .overlay(Capsule().stroke(stone.opacity(0.4), lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(14).background(slate).clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    @State private var countdownRemaining = 3

    private func countdownCommand(_ cmd: CommandData) -> some View {
        HStack(spacing: 10) {
            // Circular countdown
            ZStack {
                Circle().stroke(stone.opacity(0.3), lineWidth: 2).frame(width: 28, height: 28)
                Circle()
                    .trim(from: 0, to: CGFloat(countdownRemaining) / 3.0)
                    .stroke(amber, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                Text("\(countdownRemaining)").font(.system(size: 11, weight: .semibold)).foregroundColor(cream)
            }
            Text("Ending session...").font(.system(size: 11)).foregroundColor(stone)
        }
        .padding(.leading, 32).padding(.bottom, 12)
        .task {
            for _ in 0..<3 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if countdownRemaining > 0 { countdownRemaining -= 1 }
            }
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 0) {
            // Image preview
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, img in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: img.uri)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8).fill(graphite)
                                }
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button(action: { selectedImages.remove(at: index) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(cream)
                                        .frame(width: 18, height: 18)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                }
            }

            Rectangle().fill(amber.opacity(0.1)).frame(height: 0.5)
            HStack(spacing: 10) {
                // Image picker button (only if adapter provided)
                if imagePickerAdapter != nil {
                    Button(action: pickImages) {
                        Text("📎").font(.system(size: 18))
                            .frame(width: 36, height: 36)
                    }
                }

                TextField("Write something...", text: $text)
                    .font(.system(size: 15)).foregroundColor(cream)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(slate).clipShape(RoundedRectangle(cornerRadius: 22))

                Button(action: sendMessage) {
                    let canSend = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(canSend ? midnight : stone)
                        .frame(width: 40, height: 40)
                        .background(canSend ? amber : graphite)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(onyx)
        }
    }

    // MARK: - Actions

    private func startChat() {
        Task {
            let config = await client.fetchBotConfig()
            await client.connect(userInfo: UserInfo(), botConfig: config)
            chatStarted = true
        }
    }

    private func sendMessage() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if !selectedImages.isEmpty {
            let payloads = selectedImages.map {
                ImagePayload(name: $0.name, type: $0.type, base64: $0.base64, uri: $0.uri)
            }
            client.sendImages(payloads, caption: trimmed)
            selectedImages = []
            text = ""
        } else if !trimmed.isEmpty {
            client.sendMessage(trimmed)
            text = ""
        }
    }

    private func pickImages() {
        guard let adapter = imagePickerAdapter else { return }
        Task {
            let remaining = 5 - selectedImages.count
            guard remaining > 0 else { return }
            if let picked = try? await adapter.pickImages(maxCount: remaining), !picked.isEmpty {
                await MainActor.run {
                    selectedImages = (selectedImages + picked).prefix(5).map { $0 }
                }
            }
        }
    }

    private func endChat() {
        Task {
            await client.endSession()
            chatStarted = false
        }
    }
}

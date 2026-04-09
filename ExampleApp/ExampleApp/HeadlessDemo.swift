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
struct HeadlessDemo: View {
    @StateObject private var client = RayaChatClient(config: RayaChatConfig(
        token: sampleToken,
        onSessionStart: { id in print("[Mode4] Session: \(id)") },
        onSessionEnd: { sessionId, messages in print("[Mode4] Session ended — id: \(sessionId), \(messages.count) messages") },
        onError: { err in print("[Mode4] Error: \(err)") }
    ))

    @State private var chatStarted = false
    @State private var text = ""
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
            // Header
            chatHeader

            // Messages
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

                        // Footer
                        footerContent
                            .id("__footer__")
                    }
                }
                .onChange(of: client.messages.count) { _ in
                    withAnimation { proxy.scrollTo("__footer__", anchor: .bottom) }
                }
                .onChange(of: client.currentMessage) { _ in
                    proxy.scrollTo("__footer__", anchor: .bottom)
                }
            }

            // Composer
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
                            .overlay(Circle().fill(onyx).frame(width: 12, height: 12).offset(x: 0, y: 0), alignment: .center)
                            .overlay(Circle().fill(client.isConnected ? emerald : (client.isOnline ? amber : rose)).frame(width: 8, height: 8))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nocturne").font(.system(size: 15, weight: .light)).foregroundColor(cream).tracking(1)
                        Text(client.isConnected ? "Active" : (client.isOnline ? "Reconnecting..." : "Offline"))
                            .font(.system(size: 10)).foregroundColor(client.isConnected ? stone : rose).tracking(0.5)
                    }
                }

                Spacer()

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
        guard !content.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            HStack(alignment: .bottom, spacing: 8) {
                if !isUser {
                    ZStack {
                        Circle().fill(graphite).frame(width: 24, height: 24)
                        Text("N").font(.system(size: 9, weight: .thin)).foregroundColor(amber)
                    }
                }

                VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundColor(isUser ? midnight : cream)
                        .lineSpacing(4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isUser ? amber : slate)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

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
        // Typing
        if client.loading && client.currentMessage.isEmpty && client.info == nil {
            typingDots
        }

        // Status
        if let status = client.status, client.currentMessage.isEmpty {
            Text(status).font(.system(size: 10)).foregroundColor(amber.opacity(0.7)).tracking(1)
                .padding(.leading, 32).padding(.bottom, 8)
        }

        // Info
        if let info = client.info {
            Text(info).font(.system(size: 12)).foregroundColor(creamMuted)
                .padding(.leading, 32).padding(.bottom, 12)
        }

        // Escalation
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

    // MARK: - Typing Dots

    private var typingDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle().fill(amber.opacity(0.6)).frame(width: 5, height: 5)
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
            Text("Closing session...").font(.system(size: 11)).foregroundColor(stone)
                .padding(.leading, 32).padding(.bottom, 12)
        default:
            EmptyView()
        }
    }

    private func ratingCommand(_ cmd: CommandData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !cmd.message.isEmpty {
                Text(cmd.message).font(.system(size: 13)).foregroundColor(creamMuted)
            }
            HStack(spacing: 8) {
                ForEach(0..<cmd.options.count, id: \.self) { i in
                    let val = (cmd.options[i].value as? Int) ?? (i + 1)
                    Button(action: { client.sendCommandResponse(command: "rate_conversation", response: val) }) {
                        Text("\(val)").font(.system(size: 14, weight: .light)).foregroundColor(stone)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(stone.opacity(0.3), lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(14).background(slate).clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private func feedbackCommand(_ cmd: CommandData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !cmd.message.isEmpty {
                Text(cmd.message).font(.system(size: 13)).foregroundColor(creamMuted)
            }
            TextField("Share your thoughts...", text: .constant(""))
                .font(.system(size: 13)).foregroundColor(cream)
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(stone.opacity(0.3), lineWidth: 0.5))

            HStack {
                Spacer()
                if cmd.optional {
                    Button("Skip") { client.sendCommandResponse(command: "submit_feedback", response: "") }
                        .font(.system(size: 12)).foregroundColor(stone)
                }
                Button("Submit") { client.sendCommandResponse(command: "submit_feedback", response: "") }
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

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(amber.opacity(0.1)).frame(height: 0.5)
            HStack(spacing: 10) {
                TextField("Write something...", text: $text)
                    .font(.system(size: 15)).foregroundColor(cream)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(slate).clipShape(RoundedRectangle(cornerRadius: 22))

                Button(action: sendMessage) {
                    let canSend = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        guard !trimmed.isEmpty else { return }
        client.sendMessage(trimmed)
        text = ""
    }

    private func endChat() {
        Task {
            await client.endSession()
            chatStarted = false
        }
    }
}

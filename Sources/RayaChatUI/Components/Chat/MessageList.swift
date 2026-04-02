import SwiftUI
import RayaChatCore

/// Scrollable message list with auto-scroll, streaming message, and footer content.
///
/// Auto-scroll: instant for streaming, animated for discrete events.
/// Stops when user scrolls up, resumes on scroll-to-bottom button tap.
struct MessageList<Footer: View>: View {
    let messages: [TypeMessage]
    let currentMessage: String
    let botIcon: String?
    var onImagePress: ((String) -> Void)?
    let footerContent: () -> Footer
    var footerChangeSignal: Int = 0

    @State private var userScrolledUp = false

    var body: some View {
        let isStreaming = !currentMessage.isEmpty

        // Build streaming message (separate from persistent list — no list copy)
        let streamingMsg: TypeMessage? = isStreaming ? TypeMessage(
            id: "__streaming__",
            sender: 2,
            type: 1,
            content: currentMessage,
            createdAt: nil
        ) : nil

        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Persistent messages
                        ForEach(messages) { msg in
                            MessageBubble(message: msg, botIcon: botIcon, onImagePress: onImagePress)
                                .id(msg.id)
                        }

                        // Streaming message — separate item, only rebuilds when currentMessage changes
                        if let streaming = streamingMsg {
                            MessageBubble(message: streaming, botIcon: botIcon)
                                .id("__streaming__")
                        }

                        // Footer (typing, presets, commands)
                        footerContent()
                            .id("__footer__")
                    }
                }

                // Scroll-to-bottom button
                ScrollToBottomButton(visible: userScrolledUp) {
                    userScrolledUp = false
                    withAnimation {
                        proxy.scrollTo("__footer__", anchor: .bottom)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            // Auto-scroll on new messages — animated
            .onChange(of: messages.count) { _ in
                guard !userScrolledUp else { return }
                withAnimation { proxy.scrollTo("__footer__", anchor: .bottom) }
            }
            // Streaming + footer changes — instant scroll
            .onChange(of: currentMessage) { _ in
                guard !userScrolledUp else { return }
                proxy.scrollTo("__footer__", anchor: .bottom)
            }
            .onChange(of: footerChangeSignal) { _ in
                guard !userScrolledUp else { return }
                proxy.scrollTo("__footer__", anchor: .bottom)
            }
        }
    }
}

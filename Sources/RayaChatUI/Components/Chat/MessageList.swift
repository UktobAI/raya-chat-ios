import SwiftUI
import RayaChatCore

/// Scrollable message list with auto-scroll, streaming message, and footer content.
/// Matches Android SDK MessageList.kt auto-scroll behavior:
/// - User scrolls up → auto-scroll stops, scroll-to-bottom button appears
/// - User scrolls back to bottom → auto-scroll resumes, button hides
/// - New message → animated scroll
/// - Streaming chunk / footer change → instant scroll
struct MessageList<Footer: View>: View {
    let messages: [TypeMessage]
    let currentMessage: String
    let botIcon: String?
    var onImagePress: ((String) -> Void)?
    @ViewBuilder let footerContent: () -> Footer
    var footerChangeSignal: Int = 0

    @State private var userScrolledUp = false
    @State private var isNearBottom = true

    var body: some View {
        let isStreaming = !currentMessage.isEmpty

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

                        // Streaming message
                        if let streaming = streamingMsg {
                            MessageBubble(message: streaming, botIcon: botIcon)
                                .id("__streaming__")
                        }

                        // Footer (typing, presets, commands)
                        footerContent()
                            .id("__footer__")

                        // Scroll anchor at the very bottom — invisible
                        Color.clear
                            .frame(height: 1)
                            .id("__bottom__")

                        // Scroll position detector — tracks how far from bottom the user is
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetKey.self,
                                    value: geo.frame(in: .named("scrollArea")).maxY
                                )
                        }
                        .frame(height: 0)
                    }
                }
                .coordinateSpace(name: "scrollArea")
                .onPreferenceChange(ScrollOffsetKey.self) { maxY in
                    // maxY is the bottom edge of content relative to the scroll area.
                    // When near the bottom of the scroll view, maxY is close to the visible height.
                    // When scrolled up, maxY is much larger than the visible height.
                    // We consider "near bottom" if maxY < screen height + 150pt buffer.
                    let screenHeight = 900.0 // approximate — exact value not needed
                    let nearBottom = maxY < screenHeight + 150

                    if nearBottom && userScrolledUp {
                        // User scrolled back to bottom → re-enable auto-scroll
                        userScrolledUp = false
                    } else if !nearBottom && !userScrolledUp && isNearBottom {
                        // User scrolled away from bottom → disable auto-scroll
                        userScrolledUp = true
                    }
                    isNearBottom = nearBottom
                }

                // Scroll-to-bottom button — visible when user scrolls up
                ScrollToBottomButton(visible: userScrolledUp) {
                    userScrolledUp = false
                    withAnimation {
                        proxy.scrollTo("__bottom__", anchor: .bottom)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            // New message added → animated scroll to bottom
            .onChange(of: messages.count) { _ in
                guard !userScrolledUp else { return }
                withAnimation {
                    proxy.scrollTo("__bottom__", anchor: .bottom)
                }
            }
            // Streaming chunk → instant scroll (no animation to avoid stutter)
            .onChange(of: currentMessage) { _ in
                guard !userScrolledUp else { return }
                proxy.scrollTo("__bottom__", anchor: .bottom)
            }
            // Footer changes (presets, typing, commands) → instant scroll
            .onChange(of: footerChangeSignal) { _ in
                guard !userScrolledUp else { return }
                proxy.scrollTo("__bottom__", anchor: .bottom)
            }
        }
    }
}

// MARK: - Scroll Position Tracking

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

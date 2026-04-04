import SwiftUI
import RayaChatCore

/// Scrollable message list matching Android SDK auto-scroll behavior.
///
/// Scroll detection uses a `isProgrammaticScroll` flag to distinguish
/// user scrolls from auto-scrolls — same approach as Android's `isScrollInProgress`.
struct MessageList<Footer: View>: View {
    let messages: [TypeMessage]
    let currentMessage: String
    let botIcon: String?
    var onImagePress: ((String) -> Void)?
    @ViewBuilder let footerContent: () -> Footer
    var footerChangeSignal: Int = 0

    @State private var userScrolledUp = false
    @State private var isProgrammaticScroll = false
    @State private var scrollViewHeight: CGFloat = 0
    @State private var lastBottomY: CGFloat = 0

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
                        ForEach(messages) { msg in
                            MessageBubble(message: msg, botIcon: botIcon, onImagePress: onImagePress)
                                .id(msg.id)
                        }

                        if let streaming = streamingMsg {
                            MessageBubble(message: streaming, botIcon: botIcon)
                                .id("__streaming__")
                        }

                        footerContent()
                            .id("__footer__")

                        // Invisible anchor at absolute bottom
                        Color.clear
                            .frame(height: 1)
                            .id("__bottom__")
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: BottomPositionKey.self,
                                        value: geo.frame(in: .named("chatScroll")).minY
                                    )
                                }
                            )
                    }
                }
                .coordinateSpace(name: "chatScroll")
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollViewHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
                .onPreferenceChange(ScrollViewHeightKey.self) { h in
                    scrollViewHeight = h
                }
                .onPreferenceChange(BottomPositionKey.self) { bottomY in
                    // IGNORE position changes during programmatic auto-scroll
                    // This is the key fix — matches Android's isScrollInProgress guard
                    guard !isProgrammaticScroll else { return }
                    guard scrollViewHeight > 0 else { return }

                    let threshold: CGFloat = 80
                    let nearBottom = bottomY <= scrollViewHeight + threshold && bottomY > 0

                    // Detect scroll DIRECTION (like Android's firstVisibleIndex comparison)
                    let scrolledUpward = bottomY > lastBottomY + 5 // 5pt deadzone
                    lastBottomY = bottomY

                    if scrolledUpward && !nearBottom && !userScrolledUp {
                        // User scrolled UP away from bottom → show button
                        userScrolledUp = true
                    } else if nearBottom && userScrolledUp {
                        // User scrolled back to bottom → hide button
                        userScrolledUp = false
                    }
                }

                // Scroll-to-bottom button
                if userScrolledUp {
                    ScrollToBottomButton(visible: true) {
                        userScrolledUp = false
                        isProgrammaticScroll = true
                        withAnimation {
                            proxy.scrollTo("__bottom__", anchor: .bottom)
                        }
                        // Reset flag after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            isProgrammaticScroll = false
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: userScrolledUp)
            // New message → animated scroll
            .onChange(of: messages.count) { _ in
                guard !userScrolledUp else { return }
                isProgrammaticScroll = true
                withAnimation { proxy.scrollTo("__bottom__", anchor: .bottom) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isProgrammaticScroll = false
                }
            }
            // Streaming → instant scroll
            .onChange(of: currentMessage) { _ in
                guard !userScrolledUp else { return }
                isProgrammaticScroll = true
                proxy.scrollTo("__bottom__", anchor: .bottom)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isProgrammaticScroll = false
                }
            }
            // Footer changes → instant scroll
            .onChange(of: footerChangeSignal) { _ in
                guard !userScrolledUp else { return }
                isProgrammaticScroll = true
                proxy.scrollTo("__bottom__", anchor: .bottom)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isProgrammaticScroll = false
                }
            }
        }
    }
}

// MARK: - Preference Keys

private struct BottomPositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ScrollViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


import SwiftUI
import WebKit

// The nine Figma frames share one gift draft throughout the journey.
private enum GiftDelivery {
    case draft, scheduled, sent
}

private enum GiftKind: String, CaseIterable, Identifiable {
    case heart, bear, present, rose, rocket, diamond
    var id: String { rawValue }
    var asset: String? {
        switch self {
        case .heart: "F16_17493_imgImage"
        case .bear: "F16_17493_imgImage5"
        case .present: "F16_17493_imgImage6"
        case .rose, .rocket, .diamond: nil
        }
    }
    var price: Int {
        switch self {
        case .heart: 15
        case .rose: 25
        case .bear, .present, .rocket: 50
        case .diamond: 100
        }
    }
    /// Animated Telemoji sticker shown in the gift catalog grid (💝 / 💐 / 🎂).
    var animation: String {
        switch self {
        case .heart: "gift_heart"
        case .bear: "gift_bouquet"
        case .present: "gift_cake"
        case .rose: "gift_rose"
        case .rocket: "gift_rocket"
        case .diamond: "gift_diamond"
        }
    }
    /// The matching system emoji, shown while the animation loads.
    var emoji: String {
        switch self {
        case .heart: "💝"
        case .bear: "💐"
        case .present: "🎂"
        case .rose: "🌹"
        case .rocket: "🚀"
        case .diamond: "💎"
        }
    }
    var spokenName: String {
        switch self {
        case .heart: "Heart"
        case .bear: "Bouquet"
        case .present: "Cake"
        case .rose: "Rose"
        case .rocket: "Rocket"
        case .diamond: "Diamond"
        }
    }
}

private enum TelegramStyle {
    static var surface: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
    static let green = Color(hex: 0x4FA35A)
    static let capsule = Color(hex: 0xEAF8EE).opacity(0.85)
    static let sheet = Color(hex: 0xEFEFF4)
    static let datePill = Color(hex: 0x3D9A3C).opacity(0.9)
    static let servicePill = Color(hex: 0x5BA557).opacity(0.9)
    static let meta = Color(hex: 0x9A9A9E)
    static let outgoing = LinearGradient(colors: [Color(hex: 0xEFFADB), Color(hex: 0xE1F7C4)], startPoint: .leading, endPoint: .trailing)
    static let blue = LinearGradient(colors: [Color(hex: 0x1FA6F7), Color(hex: 0x0A84FF)], startPoint: .leading, endPoint: .trailing)
    static let messageInput = LinearGradient(colors: [Color(hex: 0xE4F6E8).opacity(0.95), Color(hex: 0xF2F8D8).opacity(0.95)], startPoint: .leading, endPoint: .trailing)
    static var preview: some View {
        LinearGradient(colors: [Color(hex: 0xD6DE8F), Color(hex: 0xA9CF8E), Color(hex: 0x86BF97)], startPoint: .leading, endPoint: .trailing)
            .overlay(LinearGradient(colors: [Color(hex: 0x9CCB7E).opacity(0.35), Color(hex: 0x5FA27C).opacity(0.25)], startPoint: .top, endPoint: .bottom))
    }
}

/// Light glass circle used by the chat header and composer buttons in the Figma frames.
private struct ChromeCircle: ViewModifier {
    var size: CGFloat = 39
    var fill: Color = TelegramStyle.capsule
    var prominentShadow = true
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(fill, in: Circle())
            .shadow(color: .black.opacity(prominentShadow ? 0.16 : 0.06), radius: prominentShadow ? 8 : 4, y: 2)
    }
}

/// Icon buttons keep their original colors while pressed (no system dimming or tint).
private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.contentShape(Rectangle())
    }
}

/// Primary blue capsule button with the subtle inner top highlight from the design.
private struct PrimaryCapsule: ViewModifier {
    let height: CGFloat
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: height)
            .background(TelegramStyle.blue, in: Capsule())
            .overlay(Capsule().inset(by: 0.5).stroke(.white.opacity(0.35), lineWidth: 1).blur(radius: 1).mask(Capsule()))
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
}

private struct DesignImage: View {
    let name: String
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        Image(name).resizable().scaledToFit().frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

struct ContentView: View {
    @State private var showGifts = false
    @State private var delivery = GiftDelivery.draft
    @State private var balloonBurstID: UUID?
    @State private var pendingScheduledBalloons = false
    @State private var gift = GiftKind.heart
    @State private var giftMessage = ""
    @State private var hideName = false
    @State private var scheduledDate: Date?
    @State private var showScheduled = false
    @State private var showDetails = false
    @State private var pinned = true
    @State private var composer = ""
    @State private var messages: [ChatMessage] = []
    private let initialFrame: Int

    init(initialFrame: Int = 1) {
        self.initialFrame = initialFrame
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if pinned {
                        PinnedMessage { pinned = false }
                            .padding(.horizontal, 15).padding(.bottom, 8)
                    }
                    ScrollView {
                        VStack(spacing: 7) {
                            Spacer(minLength: 0)
                            ChatHistory()
                            if delivery == .sent {
                                DatePill(title: "Today").padding(.top, 20)
                                // The heart plays Telegram's animated 💝 sticker (Telemoji U+1F49D) instead of the still.
                                GiftCard(gift: gift, message: giftMessage, personalized: true, inChat: true,
                                         animated: gift == .heart) {
                                    showDetails = true
                                }
                                .overlay(alignment: .top) {
                                    if let burstID = balloonBurstID {
                                        GiftBalloonBurst {
                                            if balloonBurstID == burstID { balloonBurstID = nil }
                                        }
                                        .frame(width: 300, height: geometry.size.height)
                                        // Launch from the gift artwork, without changing the card's layout.
                                        .offset(y: 100 - geometry.size.height)
                                        .id(burstID)
                                    }
                                }
                                .padding(.top, 1).padding(.bottom, 24)
                            }
                            ForEach(messages) { message in
                                MessageBubble(text: message.text, outgoing: true)
                            }
                        }
                        .padding(.horizontal, 9)
                        .frame(minHeight: max(0, geometry.size.height - (pinned ? 103 : 50)), alignment: .bottom)
                    }
                    .defaultScrollAnchor(.bottom)
                    ChatComposer(text: $composer, scheduled: delivery == .scheduled, openGifts: {
                        showGifts = true
                    }, openScheduled: {
                        showScheduled = true
                    }, send: {
                        let text = composer.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        messages.append(ChatMessage(text: text))
                        composer = ""
                    })
                    .padding(.horizontal, 23).padding(.top, 10).padding(.bottom, 8)
                }
            }
            .background { ChatWallpaper().ignoresSafeArea() }
            .toolbar {
                // The design draws its own light circles, so the system glass is hidden.
                ToolbarItem(placement: .cancellationAction) {
                    Button { messages = []; delivery = .draft } label: {
                        DesignImage(name: "F7_27_imgIconChevronLeft", width: 24, height: 24)
                            .modifier(ChromeCircle())
                    }
                    .buttonStyle(IconButtonStyle())
                    .accessibilityLabel("Restart chat")
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        ChatTitleName()
                        Text("online").font(.footnote).foregroundStyle(Color(hex: 0x2E9E5B))
                    }
                    .padding(.horizontal, 15.5).padding(.vertical, 3)
                    .background(TelegramStyle.capsule, in: Capsule())
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .primaryAction) {
                    DesignImage(name: "F11_660_imgPhoto", width: 35, height: 35)
                        .clipShape(Circle())
                        .modifier(ChromeCircle())
                        .accessibilityLabel("Anastasia")
                }
                .sharedBackgroundVisibility(.hidden)
            }
            #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(isPresented: $showScheduled) {
                ScheduledSendScreen(gift: gift, message: $giftMessage, hideName: $hideName, date: $scheduledDate,
                                    sendNow: {
                                        delivery = .sent
                                        pendingScheduledBalloons = true
                                        showScheduled = false
                                    },
                                    delete: { delivery = .draft; scheduledDate = nil; showScheduled = false })
                    .onDisappear {
                        // Start on the revealed chat, not behind the scheduled screen during dismissal.
                        guard !showScheduled, pendingScheduledBalloons, delivery == .sent else { return }
                        pendingScheduledBalloons = false
                        balloonBurstID = UUID()
                    }
            }
            .sheet(isPresented: $showDetails) {
                GiftDetail(gift: gift, message: giftMessage, hideName: hideName)
                    .presentationDetents([.height(360)])
            }
        }
        // iOS insets partial-height system sheets from the screen edges, so the Figma
        // edge-to-edge gift sheet is presented with a native-feeling custom bottom sheet.
        .edgeToEdgeSheet(isPresented: $showGifts, height: 721) {
            GiftCatalog(gift: $gift, message: $giftMessage, hideName: $hideName, date: $scheduledDate, initialFrame: initialFrame,
                        close: { showGifts = false }) { scheduled in
                delivery = scheduled ? .scheduled : .sent
                balloonBurstID = scheduled ? nil : UUID()
                showGifts = false
            }
        }
        .tint(Color(hex: 0x3C684C))
        .preferredColorScheme(.light)
        .transaction { if initialFrame > 1 { $0.disablesAnimations = true } }
        .task {
            // Seed numbered design previews; normal app launches start in frame 01.
            if initialFrame >= 6 {
                scheduledDate = Calendar.current.date(from: DateComponents(year: 2027, month: 3, day: 17))
            }
            if initialFrame >= 7 { giftMessage = "Happy Birthday" }
            if initialFrame == 8 { delivery = .scheduled }
            if initialFrame == 9 { delivery = .sent }
            if (2...7).contains(initialFrame) { showGifts = true }
        }
    }
}

/// Chat title with Telegram's animated 🌺 (U+1F33A) emoji after the name.
private struct ChatTitleName: View {
    // Sized like an inline emoji in the 17pt headline and scales with Dynamic Type.
    @ScaledMetric(relativeTo: .headline) private var emojiSize: CGFloat = 20
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Text("Anastasia Afonicheva")
            emoji.frame(width: emojiSize, height: emojiSize)
        }
        .font(.headline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Anastasia Afonicheva")
    }

    private var emoji: some View {
        AnimatedSticker(name: "hibiscus", isPlaying: !reduceMotion)
            .allowsHitTesting(false)
    }
}

/// Animated star particles behind the recipient avatar (premium_stars.html), in the
/// Figma "Sparkles" slot. The static image shows until the canvas has drawn its first frame.
private struct PremiumStars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ready = false

    var body: some View {
        ZStack {
            Image("F16_17493_imgImage2").resizable().scaledToFill()
                .opacity(ready ? 0 : 1)
            BundledPage(name: "premium_stars", query: reduceMotion ? "static" : nil) {
                withAnimation(.easeOut(duration: 0.25)) { ready = true }
            }
            .opacity(ready ? 1 : 0)
        }
        .frame(width: 383, height: 142)
        .clipped()
        // Particles fade out at the sheet's top edge (5pt into the slot) and before the
        // "Gift Premium" title (134pt) instead of being cut off or drawn over the letters.
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 5 / 142),
                .init(color: .black, location: 18 / 142),
                .init(color: .black, location: 120 / 142),
                .init(color: .clear, location: 133 / 142)
            ], startPoint: .top, endPoint: .bottom)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A transient send effect. Its identity is created by sending, never by reopening the chat.
private struct GiftBalloonBurst: View {
    let completion: () -> Void
    @State private var ready = false

    var body: some View {
        BundledPage(name: "gift_balloons", onReady: { ready = true })
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: ready) {
            guard ready else { return }
            do {
                try await Task.sleep(for: .seconds(4))
                completion()
            } catch { return }
        }
        .onDisappear(perform: completion)
    }
}

/// Shows a bundled, self-contained HTML page in a transparent web view, unmodified.
/// `onReady` fires once the page has rendered its first frames.
private struct BundledPage {
    let name: String
    var query: String? = nil
    var onReady: (() -> Void)? = nil

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var onReady: (() -> Void)?
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            onReady?()
            onReady = nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private func makeWebView(_ coordinator: Coordinator) -> WKWebView {
        coordinator.onReady = onReady
        let configuration = WKWebViewConfiguration()
        // Signals readiness after two animation frames, without editing the page itself.
        let readyScript = "requestAnimationFrame(function(){requestAnimationFrame(function(){window.webkit.messageHandlers.ready.postMessage(1);});});"
        configuration.userContentController.addUserScript(
            WKUserScript(source: readyScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        configuration.userContentController.add(coordinator, name: "ready")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        #if os(macOS)
        webView.setValue(false, forKey: "drawsBackground")
        #else
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isUserInteractionEnabled = false
        #endif
        if let fileURL = Bundle.main.url(forResource: name, withExtension: "html") {
            var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)
            components?.query = query
            webView.loadFileURL(components?.url ?? fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
        return webView
    }

    private static func tearDown(_ webView: WKWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "ready")
    }
}

#if os(macOS)
extension BundledPage: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateNSView(_ webView: WKWebView, context: Context) {}
    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) { tearDown(webView) }
}
#else
extension BundledPage: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateUIView(_ webView: WKWebView, context: Context) {}
    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) { tearDown(webView) }
}
#endif

#if os(macOS)
/// Plays a bundled Telegram sticker (Lottie JSON decompressed from .tgs) with lottie-web,
/// the same engine behind the `<tgs-player>` web snippet. Everything is bundled, so it works offline.
private struct AnimatedSticker {
    static func hasFrames(_ name: String) -> Bool { false }
    let name: String
    var isPlaying = true
    /// Called once the first animation frame has been drawn, so callers can swap out a placeholder.
    var onReady: (() -> Void)? = nil

    /// The player script is read from the bundle once and shared by every sticker.
    private static let player: String? = Bundle.main.url(forResource: "lottie_light.min", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) }

    /// Self-contained page: the lottie-web player and the animation data are inlined.
    private static func html(for name: String, autoplay: Bool) -> String? {
        guard let player,
              let dataURL = Bundle.main.url(forResource: name, withExtension: "json"),
              let animation = try? String(contentsOf: dataURL, encoding: .utf8) else { return nil }
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}#s{width:100vw;height:100vh}</style>
        </head><body><div id="s"></div><script>\(player)</script><script>
        var a = lottie.loadAnimation({container: document.getElementById('s'), renderer: 'svg',
            loop: true, autoplay: \(autoplay), animationData: \(animation)});
        if (!\(autoplay)) { a.goToAndStop(0, true); }
        a.addEventListener('DOMLoaded', function () {
            requestAnimationFrame(function () { window.webkit.messageHandlers.ready.postMessage(1); });
        });
        </script></body></html>
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var onReady: (() -> Void)?
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            onReady?()
            onReady = nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private func makeWebView(_ coordinator: Coordinator) -> WKWebView {
        coordinator.onReady = onReady
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(coordinator, name: "ready")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        #if os(macOS)
        webView.setValue(false, forKey: "drawsBackground")
        #else
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isUserInteractionEnabled = false
        #endif
        if let html = Self.html(for: name, autoplay: isPlaying) {
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    /// Breaks the handler's retain cycle (WKUserContentController holds its handlers strongly).
    private static func tearDown(_ webView: WKWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "ready")
    }
}

#if os(macOS)
extension AnimatedSticker: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateNSView(_ webView: WKWebView, context: Context) {}
    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) { tearDown(webView) }
}
#else
extension AnimatedSticker: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateUIView(_ webView: WKWebView, context: Context) {}
    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) { tearDown(webView) }
}
#endif
#else
/// Pre-rendered frames of a bundled Telegram sticker: `<name>.stickerframes` packs the Lottie
/// animation as WebP frames ("STK1", count, fps, size, per-frame byte lengths, frame data).
/// Native playback replaces per-sticker WKWebViews, which dropped or half-drew stickers for a
/// few frames while the gift grid scrolled.
nonisolated final class StickerFrames: Sendable {
    let data: Data
    let ranges: [Range<Int>]
    let fps: Double

    init?(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "stickerframes"),
              let data = try? Data(contentsOf: url, options: .mappedIfSafe), data.count > 16,
              data.prefix(4) == Data("STK1".utf8) else { return nil }
        func word(_ offset: Int) -> Int {
            data.withUnsafeBytes { Int(UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self))) }
        }
        let count = word(4)
        var cursor = 16 + 4 * count
        guard count > 0, data.count >= cursor else { return nil }
        var ranges: [Range<Int>] = []
        for index in 0..<count {
            let length = word(16 + 4 * index)
            ranges.append(cursor..<(cursor + length))
            cursor += length
        }
        guard cursor <= data.count else { return nil }
        self.data = data
        self.ranges = ranges
        self.fps = Double(max(word(8), 1))
    }

    var count: Int { ranges.count }

    /// Fully decoded frame, so assigning it to a layer never shows an undrawn image.
    func image(at index: Int) -> CGImage? {
        let slice = data.subdata(in: ranges[index]) as CFData
        guard let source = CGImageSourceCreateWithData(slice, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
    }
}

/// Plays a bundled Telegram sticker natively from its pre-rendered frames.
private struct AnimatedSticker: UIViewRepresentable {
    let name: String
    var isPlaying = true
    /// Called once the first frame is on screen, so callers can swap out a placeholder.
    var onReady: (() -> Void)? = nil

    private static var cache: [String: StickerFrames] = [:]

    static func frames(_ name: String) -> StickerFrames? {
        if let cached = cache[name] { return cached }
        let loaded = StickerFrames(name: name)
        cache[name] = loaded
        return loaded
    }

    /// True when the sticker can draw its first frame immediately (no placeholder needed).
    static func hasFrames(_ name: String) -> Bool { frames(name) != nil }

    func makeUIView(context: Context) -> StickerPlayerView {
        let view = StickerPlayerView(frames: Self.frames(name), playing: isPlaying)
        if let onReady { DispatchQueue.main.async(execute: onReady) }
        return view
    }

    func updateUIView(_ view: StickerPlayerView, context: Context) { view.setPlaying(isPlaying) }
}

private final class StickerPlayerView: UIView {
    nonisolated private struct Decoded: @unchecked Sendable { let index: Int; let image: CGImage }

    private let frames: StickerFrames?
    private var playing: Bool
    private var link: CADisplayLink?
    private var start: CFTimeInterval?
    private var shown = 0
    private var buffer: [Int: CGImage] = [:]
    private var decoding = false
    private static let queue = DispatchQueue(label: "sticker.decode", qos: .userInteractive, attributes: .concurrent)

    init(frames: StickerFrames?, playing: Bool) {
        self.frames = frames
        self.playing = playing
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        layer.contentsGravity = .resizeAspect
        layer.contents = frames?.image(at: 0)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setPlaying(_ value: Bool) {
        guard value != playing else { return }
        playing = value
        updateLink()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateLink()
    }

    private func updateLink() {
        let run = playing && window != nil && (frames?.count ?? 0) > 1
        if run, link == nil {
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            link.add(to: .main, forMode: .common)
            self.link = link
        } else if !run {
            link?.invalidate()
            link = nil
            start = nil
        }
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard let frames else { return }
        let start = self.start ?? (link.timestamp - Double(shown) / frames.fps)
        self.start = start
        let index = Int((link.targetTimestamp - start) * frames.fps) % frames.count
        if index != shown, let image = buffer[index] {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.contents = image
            CATransaction.commit()
            shown = index
        }
        // Keep only the frames still ahead of the playhead.
        buffer = buffer.filter { ($0.key - index + frames.count) % frames.count <= 4 }
        prefetch(from: index, frames: frames)
    }

    private func prefetch(from index: Int, frames: StickerFrames) {
        guard !decoding else { return }
        let wanted = (1...3).map { (index + $0) % frames.count }.filter { buffer[$0] == nil }
        guard !wanted.isEmpty else { return }
        decoding = true
        Self.queue.async { [weak self] in
            let decoded = wanted.compactMap { i in frames.image(at: i).map { Decoded(index: i, image: $0) } }
            DispatchQueue.main.async {
                guard let self else { return }
                for item in decoded { self.buffer[item.index] = item.image }
                self.decoding = false
            }
        }
    }
}
#endif

private struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
}

private struct ChatWallpaper: View {
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(stops: [.init(color: Color(hex: 0x3D9E8F), location: 0), .init(color: Color(hex: 0x7DC66C), location: 0.55), .init(color: Color(hex: 0xA5D15B), location: 1)], startPoint: .leading, endPoint: .trailing)
                .overlay(LinearGradient(stops: [.init(color: Color(hex: 0x2F8F86).opacity(0.35), location: 0), .init(color: .clear, location: 0.45), .init(color: Color(hex: 0xC9C548).opacity(0.45), location: 1)], startPoint: .top, endPoint: .bottom))
                .overlay {
                    Image("F12_14128_img4").resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        .opacity(0.30).blendMode(.overlay)
                }
                // Figma softens the wallpaper behind the header and composer with blurred bands.
                .overlay(alignment: .top) { EdgeBlur(fadesDown: true) }
                .overlay(alignment: .bottom) { EdgeBlur(fadesDown: false) }
        }
    }
}

private struct EdgeBlur: View {
    let fadesDown: Bool
    var body: some View {
        Rectangle().fill(.ultraThinMaterial).opacity(0.7)
            .frame(height: 130)
            .mask(LinearGradient(colors: [.black, .clear], startPoint: fadesDown ? .top : .bottom, endPoint: fadesDown ? .bottom : .top))
            .allowsHitTesting(false)
    }
}

private struct PinnedMessage: View {
    let dismiss: () -> Void
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x1C1C1E)).frame(width: 2, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("Pinned Message").font(.subheadline.weight(.medium))
                HStack(spacing: 3) {
                    Text("Cool, good luck").font(.subheadline)
                    DesignImage(name: "F11_594_imgSticker", width: 18, height: 18)
                }
            }
            Spacer()
            Button(action: dismiss) {
                DesignImage(name: "F11_594_imgIconClose", width: 17, height: 17)
            }.buttonStyle(IconButtonStyle()).accessibilityLabel("Dismiss pinned message")
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(TelegramStyle.capsule, in: Capsule())
        .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
    }
}

private struct DatePill: View {
    let title: String
    var body: some View {
        Text(title).font(.footnote.weight(.medium)).foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 2.5)
            .background(TelegramStyle.datePill, in: RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity)
    }
}

private struct MessageBubble: View {
    let text: String
    let outgoing: Bool
    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            Text(text).font(.body)
            HStack(spacing: 2) {
                Text("15:59").font(.caption2)
                    .foregroundStyle(outgoing ? TelegramStyle.green : TelegramStyle.meta)
                if outgoing {
                    DesignImage(name: "F7_50_imgIconRead", width: 15, height: 10)
                }
            }
        }
        .padding(.leading, 12).padding(.trailing, 9).padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 17)
                .fill(outgoing ? AnyShapeStyle(TelegramStyle.outgoing) : AnyShapeStyle(TelegramStyle.surface))
        }
        .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
    }
}

private struct ChatHistory: View {
    @State private var reacted = true
    var body: some View {
        VStack(spacing: 7) {
            DatePill(title: "March 16").padding(.bottom, 2)
            MessageBubble(text: "Hi!", outgoing: true)
            MessageBubble(text: "Hi! You're here too?", outgoing: false)
            MessageBubble(text: "Yep, exploring Telegram", outgoing: true)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 3) {
                    Text("Cool, good luck").font(.body)
                    DesignImage(name: "F7_66_imgSticker", width: 21, height: 21)
                }.padding(.leading, 4)
                HStack(alignment: .bottom, spacing: 14) {
                    Button { reacted.toggle() } label: {
                        HStack(spacing: 6) {
                            DesignImage(name: "F7_66_img", width: 17, height: 17)
                            if reacted { DesignImage(name: "F7_66_imgAvatar", width: 20, height: 20) }
                        }
                        .padding(.leading, 10).padding(.trailing, 3).padding(.vertical, 3)
                        .background(Color(hex: 0xF6F6F6), in: Capsule())
                    }
                    .buttonStyle(IconButtonStyle())
                    .accessibilityLabel("Heart reaction")
                    HStack(spacing: 2) {
                        DesignImage(name: "F7_66_imgIconPinned", width: 11, height: 11)
                        Text("16:51").font(.caption2).foregroundStyle(TelegramStyle.meta)
                    }
                }
            }
            .padding(.leading, 8).padding(.trailing, 9).padding(.vertical, 6)
            .background(TelegramStyle.surface, in: RoundedRectangle(cornerRadius: 17))
            .frame(maxWidth: .infinity, alignment: .leading)
            ReplyBubble()
        }
    }
}

private struct ReplyBubble: View {
    var heart = "F7_78_img"
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Anastasia Afonicheva").font(.system(size: 14, weight: .medium)).foregroundStyle(Color(hex: 0x2E9A55))
                HStack(spacing: 3) {
                    Text("Cool, good luck").font(.system(size: 14))
                    DesignImage(name: "F7_78_imgSticker", width: 16.8, height: 16.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 12).padding(.vertical, 4)
            .background(TelegramStyle.green.opacity(0.12))
            .overlay(alignment: .leading) { Rectangle().fill(Color(hex: 0x3DA05A)).frame(width: 3) }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            HStack(alignment: .bottom, spacing: 12) {
                HStack(spacing: 4) {
                    Text("Thanks").font(.body)
                    DesignImage(name: heart, width: 21, height: 21)
                }
                HStack(spacing: 2) {
                    Text("edited 17:09").font(.caption2).foregroundStyle(TelegramStyle.green)
                    DesignImage(name: "F7_78_imgIconRead", width: 15, height: 10)
                }
            }
            .padding(.leading, 1)
        }
        .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 6).fixedSize()
        .background(TelegramStyle.outgoing, in: RoundedRectangle(cornerRadius: 17))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct ChatComposer: View {
    @Binding var text: String
    let scheduled: Bool
    let openGifts: () -> Void
    let openScheduled: () -> Void
    let send: () -> Void
    var body: some View {
        HStack(spacing: 6) {
            Button(action: openGifts) {
                DesignImage(name: "F12_15182_imgAttachIcon1", width: 23.02, height: 23.02)
                    .frame(width: 22, height: 22, alignment: .topLeading)
                    .mask(DesignImage(name: "F12_15182_imgAttachIcon", width: 22, height: 22))
                    .colorMultiply(.black)
                    .modifier(ChromeCircle(size: 36, prominentShadow: false))
            }
            .buttonStyle(IconButtonStyle()).accessibilityLabel("Attachments")
            HStack(spacing: 10) {
                TextField("Message", text: $text, prompt: Text("Message").foregroundStyle(Color(hex: 0x9AA59A)))
                    .font(.body).foregroundStyle(.primary).onSubmit(send)
                if scheduled {
                    Button(action: openScheduled) { DesignImage(name: "F24_28402_imgIconCalendarScheduled", width: 22, height: 22) }
                        .buttonStyle(IconButtonStyle()).accessibilityLabel("Scheduled gift")
                }
                Button(action: openGifts) {
                    DesignImage(name: "F12_15197_imgGift", width: 22, height: 22)
                }.buttonStyle(IconButtonStyle()).accessibilityLabel("Send a gift")
                Button { text += "❤️" } label: {
                    DesignImage(name: "F12_15197_imgStickers", width: 20, height: 20)
                }.buttonStyle(IconButtonStyle()).accessibilityLabel("Insert heart")
            }
            .padding(.horizontal, 12).frame(height: 40)
            .background(TelegramStyle.capsule, in: Capsule())
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            Button(action: text.isEmpty ? openGifts : send) {
                Group {
                    if text.isEmpty {
                        DesignImage(name: "F12_15204_imgRecordAudioIcon1", width: 16.06, height: 21.41)
                            .colorMultiply(.black)
                    } else {
                        Image(systemName: "arrow.up").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x858E99))
                    }
                }
                .modifier(ChromeCircle(size: 36, prominentShadow: false))
            }
            .buttonStyle(IconButtonStyle())
            .accessibilityLabel(text.isEmpty ? "Voice and attachment options" : "Send message")
        }
    }
}

private struct GiftCatalog: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var gift: GiftKind
    @Binding var message: String
    @Binding var hideName: Bool
    @Binding var date: Date?
    var initialFrame: Int = 1
    /// Closes the catalog when it isn't presented by the system (falls back to `dismiss`).
    var close: (() -> Void)? = nil
    let complete: (Bool) -> Void
    @State private var showPreview = false
    /// Send result held while the preview sheet slides away, so the catalog closes only after it.
    @State private var pendingCompletion: Bool?
    @State private var collectibles = false
    private static let gridLayout: [GiftKind] = [.heart, .bear, .present, .rose, .rocket, .diamond]
    @State private var info: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CatalogHeader { info = "Premium unlocks additional Telegram features for Anastasia." }
                HStack(spacing: 10) {
                    PremiumTile(animation: "premium_gift_3_months", placeholder: "F16_17493_imgImage1", title: "3 Months", price: "$11.99", discount: nil)
                    PremiumTile(animation: "premium_gift_6_months", placeholder: "F16_17493_imgImage3", title: "6 Months", price: "$15.99", discount: "-10%")
                    PremiumTile(animation: "premium_gift_12_months", placeholder: "F16_17493_imgImage4", title: "1 Year", price: "$28.99", discount: "-25%")
                }
                .padding(.horizontal, 14)
                .onTapGesture { info = "Premium purchases are not connected in this design prototype." }
                Text("Send a Gift").font(.title2.bold()).padding(.top, 18.5)
                Text("Give **Anastasia** gifts that can be kept\non their profile or converted to Stars.")
                    .font(.subheadline).lineSpacing(0.3).multilineTextAlignment(.center).padding(.top, 7)
                Button("Learn more about Stars ›") {
                    info = "Stars can be used to send gifts. Anastasia can display gifts on her profile or convert this gift to 13 Stars."
                }.font(.subheadline).foregroundStyle(Color(hex: 0x1F8CE6))
                HStack(spacing: 12) {
                    Button { collectibles = false } label: {
                        Text("All").padding(.horizontal, 11).padding(.vertical, 4)
                            .background(collectibles ? Color.clear : Color(hex: 0xE2E2E7), in: Capsule())
                    }
                    Button { collectibles = true } label: {
                        Text("Collectibles").padding(.horizontal, 8).padding(.vertical, 4)
                            .background(collectibles ? Color(hex: 0xE2E2E7) : Color.clear, in: Capsule())
                    }
                }.font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: 0x8E8E93))
                    .padding(.top, 31).padding(.bottom, 18)
                if collectibles {
                    Text("No collectible gifts available").font(.footnote).foregroundStyle(.secondary).padding(25)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(Self.gridLayout) { item in
                            GiftTile(gift: item) { gift = item; showPreview = true }
                        }
                    }.padding(.horizontal, 14)
                }
            }.padding(.bottom, 90)
        }
        .scrollIndicators(.hidden)
        .task { if (3...7).contains(initialFrame) { showPreview = true } }
        .background(TelegramStyle.sheet)
        .overlay(alignment: .topLeading) {
            CloseButton(fill: .white.opacity(0.85)) { close?() ?? dismiss() }.padding(14)
        }
        .overlay(alignment: .bottom) {
            // Soft white fade behind the attach menu (Figma "Rectangle 1").
            LinearGradient(colors: [.white.opacity(0), .white.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .frame(height: 110).allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            AttachmentBar { info = "\($0) is outside the gift flow shown in this concept." }
                .padding(.horizontal, 18).padding(.bottom, 22)
        }
        .sheet(isPresented: $showPreview, onDismiss: {
            // Runs once the preview's dismissal animation has finished; only then close the catalog.
            guard let scheduled = pendingCompletion else { return }
            pendingCompletion = nil
            complete(scheduled)
        }) {
            // Same treatment as the Send Later sheet: no fixed corner radius, so iOS gives the
            // inset sheet corners concentric with the display, and the background fills the shape.
            GiftPreview(gift: gift, message: $message, hideName: $hideName, date: $date, initialFrame: initialFrame,
                        complete: { scheduled in
                            pendingCompletion = scheduled
                            showPreview = false
                        })
                .presentationDetents([.height(562)])
                .presentationBackground(TelegramStyle.sheet)
                .presentationDragIndicator(.visible)
        }
        .alert("Telegram", isPresented: Binding(get: { info != nil }, set: { if !$0 { info = nil } })) {
            Button("OK") { info = nil }
        } message: { Text(info ?? "") }
    }
}

private struct CatalogHeader: View {
    let learnMore: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            DesignImage(name: "F16_17493_imgRecipientAvatar", width: 88, height: 88).clipShape(Circle())
                .padding(.top, 39)
            Text("Gift Premium").font(.title2.bold()).padding(.top, 2)
            Text("Give **Anastasia** access to exclusive").font(.subheadline).padding(.top, 8)
            HStack(spacing: 3) {
                Text("Telegram features.")
                Button("Learn more about Premium ›", action: learnMore).foregroundStyle(Color(hex: 0x1F8CE6))
            }.font(.subheadline)
            Spacer(minLength: 0)
        }
        .frame(height: 222).frame(maxWidth: .infinity)
        .background(alignment: .top) { PremiumStars().offset(y: -5) }
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("Balance").font(.system(size: 11.5))
                HStack(spacing: 3) {
                    DesignImage(name: "F16_17493_imgTelegramPremiumStar1", width: 14, height: 15)
                    Text("15").font(.system(size: 14, weight: .semibold))
                }
            }.padding(.top, 15).padding(.trailing, 19)
        }
    }
}

private struct PremiumTile: View {
    /// Telegram's animated Premium gift sticker (keycaps 2️⃣/3️⃣/4️⃣ = 3/6/12 months).
    let animation: String
    /// Figma's static gift image, shown until the animation's first frame is ready.
    let placeholder: String
    @State private var animationReady = false
    let title: String
    let price: String
    let discount: String?
    /// Pre-rendered stickers draw their first frame immediately, so the placeholder never shows.
    private var ready: Bool { animationReady || AnimatedSticker.hasFrames(animation) }
    var body: some View {
        VStack(spacing: 0) {
            // The resting gift box fills the lower half of the sticker canvas, so a 92pt canvas
            // shows it at ≥ 52×46 (the Figma size) and leaves the top for the opening burst.
            ZStack(alignment: .bottom) {
                // The Figma image has transparent margins; at 61×54 its box matches the
                // animation's resting box, so nothing jumps when the crossfade happens.
                DesignImage(name: placeholder, width: 61, height: 54)
                    .opacity(ready ? 0 : 1)
                AnimatedSticker(name: animation) {
                    withAnimation(.easeOut(duration: 0.2)) { animationReady = true }
                }
                .frame(width: 92, height: 92)
                .opacity(ready ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .frame(width: 92, height: 92)
            Text(title).font(.subheadline.weight(.semibold)).padding(.top, 7)
            Text("Premium").font(.footnote).foregroundStyle(Color(hex: 0x1C1C1E))
            Text(price).font(.caption.weight(.semibold)).foregroundStyle(Color(hex: 0x2B8CE3))
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Color(hex: 0xE3F0FC), in: Capsule()).padding(.top, 10)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity).frame(height: 175)
        .background(TelegramStyle.surface)
        .overlay(alignment: .topTrailing) {
            if let discount {
                Text(discount).font(.caption2.weight(.semibold)).foregroundStyle(.white)
                    .frame(width: 96, height: 20)
                    .background(LinearGradient(colors: [Color(hex: 0xD16BD3), Color(hex: 0x8B7CF6)], startPoint: .leading, endPoint: .trailing))
                    .rotationEffect(.degrees(45)).offset(x: 28, y: 7)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct GiftTile: View {
    let gift: GiftKind
    let action: () -> Void
    @State private var animationReady = false
    private var ready: Bool { animationReady || AnimatedSticker.hasFrames(gift.animation) }
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Same 82×78 Figma slot as the static image; the sticker is drawn slightly
                // larger around it because its square canvas has built-in padding.
                Text(gift.emoji).font(.system(size: 56))
                    .frame(width: 82, height: 78)
                    .opacity(ready ? 0 : 1)
                    .overlay {
                        AnimatedSticker(name: gift.animation) {
                            withAnimation(.easeOut(duration: 0.2)) { animationReady = true }
                        }
                        .frame(width: 86, height: 86)
                        .opacity(ready ? 1 : 0)
                        .allowsHitTesting(false)
                    }
                    .accessibilityHidden(true)
                HStack(spacing: 3) {
                    DesignImage(name: "F16_17493_imgTelegramPremiumStar1", width: 15, height: 15)
                    Text("\(gift.price)").font(.footnote.weight(.semibold)).foregroundStyle(Color(hex: 0xC9861A))
                }.padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Color(hex: 0xFCEFD2), in: Capsule())
            }
            .padding(.top, 14)
            .frame(maxWidth: .infinity).frame(height: 137, alignment: .top)
            .background(TelegramStyle.surface, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain).accessibilityLabel("\(gift.spokenName) gift, \(gift.price) Stars")
    }
}

private struct AttachmentBar: View {
    let select: (String) -> Void
    private let items = [
        ("Gallery", "F27_29356_imgIconGallery"),
        ("Gift", "F27_29356_imgIcon"),
        ("Wallet", "F27_29356_imgIcon1"),
        ("File", "F27_29356_imgIcon2"),
        ("Location", "F27_29356_imgIcon3"),
        ("Checklist", "F27_29356_imgIcon4")
    ]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                Button { if item.0 != "Gift" { select(item.0) } } label: {
                    VStack(spacing: 2) {
                        DesignImage(name: item.1, width: 28, height: 28)
                        Text(item.0).font(.system(size: 10, weight: .medium))
                    }
                    .frame(width: item.0 == "Location" ? 64 : 56, height: 48)
                    .background(item.0 == "Gift" ? Color(hex: 0xE9E9EE) : Color.clear, in: RoundedRectangle(cornerRadius: 23))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(IconButtonStyle())
                .foregroundStyle(item.0 == "Gift" ? Color(hex: 0x2BA04E) : Color(hex: 0x1C1C1E))
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

private struct CloseButton: View {
    /// The catalog and calendar use a white circle; the gift preview uses a pale green one.
    var fill: Color = Color(hex: 0xF1FFDD).opacity(0.85)
    /// The calendar's button floats like the chat header buttons, with their stronger shadow.
    var prominentShadow = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            DesignImage(name: "F19_19942_imgIconClose", width: 24, height: 24)
                .modifier(ChromeCircle(fill: fill, prominentShadow: prominentShadow))
        }
        .buttonStyle(IconButtonStyle()).accessibilityLabel("Close")
    }
}

/// Full-width bottom sheet that reaches the bottom screen edge, matching the Figma gift sheet.
/// Mirrors a native sheet: dimmed backdrop, spring entrance, grabber drag with rubber-banding
/// and velocity-based dismissal, tap-outside and accessibility escape to close.
private struct EdgeToEdgeSheet<Sheet: View>: ViewModifier {
    @Binding var isPresented: Bool
    let height: CGFloat
    @ViewBuilder let sheet: () -> Sheet
    @State private var dragOffset: CGFloat = 0
    /// Like a system sheet, touches are ignored while it slides in, so the tap that
    /// opened it can't also land on a control that appears under the finger.
    @State private var acceptsTouches = false

    private var progress: CGFloat { 1 - min(max(dragOffset, 0) / height, 1) }

    private func dismiss() {
        withAnimation(.spring(duration: 0.35, bounce: 0)) { isPresented = false }
    }

    private var grabberDrag: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let t = value.translation.height
                // Follows the finger downward; resists (rubber-bands) when pulled up.
                dragOffset = t >= 0 ? t : -pow(-t, 0.7)
            }
            .onEnded { value in
                let projected = value.predictedEndTranslation.height
                if value.translation.height > height * 0.3 || projected > height * 0.6 {
                    dismiss()
                }
                withAnimation(.spring(duration: 0.4, bounce: 0.15)) { dragOffset = 0 }
            }
    }

    func body(content: Content) -> some View {
        content.overlay {
            ZStack(alignment: .bottom) {
                if isPresented {
                    Color(red: 11 / 255, green: 58 / 255, blue: 38 / 255)
                        .opacity(0.14 * progress)
                        .ignoresSafeArea()
                        .onTapGesture(perform: dismiss)
                        .accessibilityHidden(true)
                        .transition(.opacity)

                    sheet()
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 44, topTrailingRadius: 44, style: .continuous))
                        .overlay(alignment: .top) {
                            // Grabber plus a generous invisible drag area, kept clear of the close button.
                            Grabber(color: Color(hex: 0xC7C7CC))
                                .frame(width: 200, height: 36, alignment: .top)
                                .contentShape(Rectangle())
                                .gesture(grabberDrag)
                                // Exposed like the system "Sheet Grabber": activating it dismisses.
                                .accessibilityElement()
                                .accessibilityLabel("Sheet Grabber")
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction { dismiss() }
                        }
                        .shadow(color: .black.opacity(0.12), radius: 10, y: -2)
                        // While sliding in, an invisible layer swallows touches (instead of letting
                        // them fall through to the dim, which would dismiss the sheet).
                        .overlay {
                            if !acceptsTouches {
                                Color.clear.contentShape(Rectangle()).accessibilityHidden(true)
                            }
                        }
                        .offset(y: dragOffset)
                        // Keep every control inside reachable while marking the sheet as modal.
                        .accessibilityElement(children: .contain)
                        .accessibilityAddTraits(.isModal)
                        .accessibilityAction(.escape, dismiss)
                        .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .animation(.spring(duration: 0.45, bounce: 0), value: isPresented)
        }
        .onChange(of: isPresented) { _, shown in
            dragOffset = 0
            acceptsTouches = false
            guard shown else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                if isPresented { acceptsTouches = true }
            }
        }
    }
}

private extension View {
    func edgeToEdgeSheet<Sheet: View>(isPresented: Binding<Bool>, height: CGFloat,
                                      @ViewBuilder content: @escaping () -> Sheet) -> some View {
        modifier(EdgeToEdgeSheet(isPresented: isPresented, height: height, sheet: content))
    }
}

/// Static stand-in for the system grabber in the composed design previews.
private struct Grabber: View {
    let color: Color
    var body: some View {
        Capsule().fill(color).frame(width: 36, height: 5).padding(.top, 5)
    }
}

private struct GiftPreview: View {
    @Environment(\.dismiss) private var dismiss
    let gift: GiftKind
    @Binding var message: String
    @Binding var hideName: Bool
    @Binding var date: Date?
    var initialFrame: Int = 1
    let complete: (Bool) -> Void
    @State private var showOptions = false
    @State private var showCalendar = false
    @State private var showDetails = false
    @State private var pressingSend = false
    @FocusState private var editing: Bool

    /// A regular tap sends right away (or on the scheduled date if one was picked).
    private func send() {
        editing = false
        complete(date != nil)
    }

    /// Long press reveals the send options with a context-menu-like spring.
    private func openOptions() {
        editing = false
        withAnimation(.spring(duration: 0.42, bounce: 0.24)) { showOptions = true }
    }

    private var sendTitle: String {
        guard let date else { return "Send a Gift for" }
        // 24-hour time, matching the Send Later wheels.
        let time = Calendar.current.dateComponents([.hour, .minute], from: date)
        let clock = String(format: "%02d:%02d", time.hour ?? 0, time.minute ?? 0)
        return "Send on \(date.formatted(.dateTime.month(.abbreviated).day())) at \(clock) for"
    }

    private var sendButton: some View {
        HStack(spacing: 4) {
            Text(sendTitle)
            Image("F16_17493_imgTelegramPremiumStar1")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("\(gift.price)")
        }
        .font(.headline)
        .modifier(PrimaryCapsule(height: 44))
        // Native-style press feedback: the button shrinks slightly while held.
        .scaleEffect(pressingSend ? 0.96 : 1)
        .brightness(pressingSend ? -0.04 : 0)
        .animation(.spring(duration: 0.3, bounce: 0.3), value: pressingSend)
        .contentShape(Capsule())
        // Separate gestures so a tap only sends and only a long press opens the menu.
        .gesture(
            LongPressGesture(minimumDuration: 0.4)
                .exclusively(before: TapGesture())
                .onEnded { value in
                    pressingSend = false
                    switch value {
                    case .first(true): openOptions()
                    case .second: send()
                    default: break
                    }
                }
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: showOptions) { _, isShown in isShown }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { send() }
        .accessibilityAction(named: Text("Send Options")) { openOptions() }
    }

    private func closeOptions() {
        withAnimation(.spring(duration: 0.26, bounce: 0)) { showOptions = false }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Service pill hugs its text and is centered over the gift card.
                Text("A gift for \(Text("\(gift.price) Stars").fontWeight(.semibold))")
                    .font(.caption2).foregroundStyle(.white)
                    .fixedSize()
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(TelegramStyle.servicePill, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 24)
                GiftCard(gift: gift, message: message, personalized: !message.isEmpty, animated: true) { showDetails = true }
                    .padding(.top, 7)
                Spacer(minLength: 9)
                HStack {
                    TextField("Your message (optional)", text: $message,
                              prompt: Text("Your message (optional)").foregroundStyle(Color(hex: 0x9AA89E)))
                        .font(.body).focused($editing).submitLabel(.done)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                    Button { message += "❤️" } label: {
                        DesignImage(name: "F19_19942_imgIconSmile", width: 24, height: 24)
                    }.buttonStyle(IconButtonStyle()).accessibilityLabel("Add heart to gift message")
                }
                .padding(.leading, 16).padding(.trailing, 17).frame(height: 34)
                .background(TelegramStyle.messageInput, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1))
                // A tap anywhere on the capsule (not just the text line) focuses the field and
                // brings up the keyboard; the field and smile button still handle their own taps.
                .contentShape(Capsule())
                .onTapGesture { editing = true }
                .padding(.horizontal, 21).padding(.bottom, 14)
            }
            .frame(height: 362).frame(maxWidth: .infinity)
            .background(TelegramStyle.preview)
            GiftPrivacy(hideName: $hideName).padding(.horizontal, 21).padding(.top, 22)
            Spacer(minLength: 12)
            sendButton
            .padding(.horizontal, 28).padding(.bottom, 30)
        }
        .task {
            showOptions = initialFrame == 4
            showCalendar = initialFrame == 5
        }
        .background(TelegramStyle.sheet.ignoresSafeArea())
        .overlay(alignment: .topLeading) { CloseButton(prominentShadow: true) { dismiss() }.padding(14) }
        .overlay {
            if showOptions {
                // Tapping anywhere outside dismisses the menu, like a system context menu.
                Color.clear.contentShape(Rectangle()).ignoresSafeArea()
                    .onTapGesture(perform: closeOptions)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showOptions {
                SendOptions(schedule: { closeOptions(); showCalendar = true }, silent: { closeOptions(); complete(false) })
                    .padding(.trailing, 30).padding(.bottom, 90)
                    .transition(MenuPopTransition())
            }
        }
        .sheet(isPresented: $showCalendar) {
            // No fixed corner radius: iOS gives the inset sheet corners concentric with the
            // display, and the background fills the whole sheet shape so nothing shows through.
            SchedulePicker(date: $date)
                .presentationDetents([.height(370)])
                .presentationBackground(TelegramStyle.surface)
        }
        .sheet(isPresented: $showDetails) {
            GiftDetail(gift: gift, message: message, hideName: hideName)
                .presentationDetents([.height(360)])
        }
    }
}

private struct GiftPrivacy: View {
    @Binding var hideName: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Hide My Name", isOn: $hideName)
                .font(.body).tint(TelegramStyle.green)
                .padding(.leading, 14).padding(.trailing, 12).frame(height: 42)
                .background(TelegramStyle.surface, in: Capsule())
            Text("You can hide your name and message from everyone who visits Anastasia's profile. Only Anastasia will see your hidden name and message.")
                .font(.caption).lineSpacing(0.1).foregroundStyle(Color(hex: 0x8A8A8E))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GiftCard: View {
    let gift: GiftKind
    let message: String
    let personalized: Bool
    /// The sent card in the chat (frame 09) uses a diagonal variant of the preview gradient.
    var inChat = false
    /// Shows the gift's animated sticker instead of the static image (gift preview, frames 03–07).
    var animated = false
    let view: () -> Void
    @State private var animationReady = false

    // The gift artwork has an opaque background baked in, so these stops must match Figma
    // exactly for the image to blend into the card.
    private var cardBackground: some View {
        let base = Gradient(stops: [
            .init(color: Color(hex: 0x8EB247), location: inChat ? 0.046 : 0),
            .init(color: Color(hex: 0x7EAC49), location: inChat ? 0.256 : 0.26),
            .init(color: Color(hex: 0x53A24E), location: inChat ? 0.718 : 0.76),
            .init(color: Color(hex: 0x50A04F), location: inChat ? 0.96 : 1)
        ])
        let shade = Gradient(stops: [
            .init(color: Color(hex: 0x56A257).opacity(0), location: inChat ? 0.637 : 0.1),
            .init(color: Color(hex: 0x56A257).opacity(0.75), location: inChat ? 0.896 : 0.41),
            .init(color: Color(hex: 0x5A9E6C).opacity(inChat ? 0.78 : 0.9), location: 1)
        ])
        return LinearGradient(gradient: base, startPoint: inChat ? .bottomTrailing : .leading, endPoint: inChat ? .topLeading : .trailing)
            .overlay(LinearGradient(gradient: shade, startPoint: inChat ? .bottomTrailing : .top, endPoint: inChat ? .topLeading : .bottom))
    }

    /// Same 97×76 Figma slot either way; the square sticker is drawn a little larger around it
    /// (its canvas has built-in padding) and shows the matching emoji while it loads.
    @ViewBuilder private var giftArt: some View {
        if animated || gift.asset == nil {
            Text(gift.emoji).font(.system(size: 62))
                .frame(width: 97, height: 75.95)
                .opacity(animationReady || AnimatedSticker.hasFrames(gift.animation) ? 0 : 1)
                .overlay {
                    AnimatedSticker(name: gift.animation) {
                        withAnimation(.easeOut(duration: 0.2)) { animationReady = true }
                    }
                    .frame(width: 92, height: 92)
                    .opacity(animationReady || AnimatedSticker.hasFrames(gift.animation) ? 1 : 0)
                    .allowsHitTesting(false)
                }
                .id(gift)
                .accessibilityHidden(true)
        } else if let asset = gift.asset {
            DesignImage(name: gift == .heart ? "F19_19942_imgGift" : asset, width: 97, height: 75.95)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            giftArt
                .padding(.top, 24.5)
            HStack(spacing: 4) {
                Text(personalized ? "Gift from" : "Gift for Anastasia")
                if personalized {
                    DesignImage(name: "F24_26371_imgAvatar", width: 16, height: 16)
                    Text("Sasha")
                }
            }.font(.subheadline.weight(.semibold)).padding(.top, 29)
            Group {
                if personalized {
                    Text(message)
                } else {
                    Text("Anastasia can display this gift\non their profile or convert it\nto **13 Stars**.")
                }
            }
                .font(.caption).lineSpacing(0.9).multilineTextAlignment(.center)
                .padding(.top, 1).padding(.horizontal, 10)
            Button("View", action: view).font(.subheadline.weight(.semibold))
                .frame(width: 111, height: 29)
                .background(Color(hex: 0x1E5A30).opacity(0.28), in: Capsule()).padding(.top, personalized ? 8 : 9)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white).frame(width: 194, height: personalized ? (inChat ? 231 : 232) : 255)
        .background { cardBackground }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct SendOptions: View {
    let schedule: () -> Void
    let silent: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: schedule) {
                HStack(spacing: 22) {
                    DesignImage(name: "F20_21973_imgIconCalendar", width: 24, height: 24)
                    Text("Send Later")
                }
            }
            Button(action: silent) {
                HStack(spacing: 22) {
                    DesignImage(name: "F20_21973_imgIconBellSlash", width: 24, height: 24)
                    Text("Send Without Sound")
                }
            }
        }
        .buttonStyle(MenuRowStyle())
        .fixedSize()
        .font(.system(size: 17)).foregroundStyle(.black)
        .padding(.vertical, 6)
        .background(.white.opacity(0.89), in: RoundedRectangle(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
    }
}

/// Full-width row with the gray press highlight used by system menus.
private struct MenuRowStyle: ButtonStyle {
    /// Side inset of the press highlight; 0 keeps it edge to edge.
    var highlightInset: CGFloat = 0
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20).frame(height: 46)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                // Corner radius is concentric with the menu's 28pt corners at this inset.
                RoundedRectangle(cornerRadius: highlightInset > 0 ? 28 - highlightInset : 0, style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed ? 0.08 : 0))
                    .padding(.horizontal, highlightInset)
            }
            .contentShape(Rectangle())
    }
}

/// Grows the menu out of the Send button with a soft blur, mirroring iOS context menus.
private struct MenuPopTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 0.35, anchor: UnitPoint(x: 0.7, y: 1.15))
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 8)
    }
}

private struct SchedulePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date?
    /// Starts an hour from now (to the minute) unless a date was already chosen.
    @State private var selection: Date = {
        #if DEBUG
        // A reproducible starting wheel position for simulator promo captures.
        if let value = ProcessInfo.processInfo.environment["SHOWTIME_SCHEDULE_START"],
           let date = ISO8601DateFormatter().date(from: value) { return date }
        #endif
        return Calendar.current.dateInterval(of: .minute, for: Date().addingTimeInterval(3600))?.start ?? Date()
    }()
    var body: some View {
        VStack(spacing: 0) {
            Text("Send Later").font(.headline).padding(.top, 24)
            ScheduleDatePicker(selection: $selection)
                .padding(.horizontal, 25).frame(height: 190).padding(.top, 29)
            Spacer(minLength: 20)
            Button {
                date = selection
                dismiss()
            } label: {
                Text("Save").font(.headline)
                    .modifier(PrimaryCapsule(height: 45))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 27.5).padding(.bottom, 29)
        }
        .frame(maxWidth: .infinity).background(TelegramStyle.surface)
        .overlay(alignment: .topLeading) {
            CloseButton(fill: .white.opacity(0.85), prominentShadow: true) { dismiss() }.padding(14)
        }
        .onAppear { if let date { selection = date } }
    }
}

/// "09 — send later": Telegram's scheduled-messages chat for the scheduled gift.
/// Tapping the card (not its View button) opens the actions menu ("10 — tap on gift").
private struct ScheduledSendScreen: View {
    @Environment(\.dismiss) private var dismiss
    let gift: GiftKind
    @Binding var message: String
    @Binding var hideName: Bool
    @Binding var date: Date?
    var initialMenu = false
    let sendNow: () -> Void
    let delete: () -> Void
    @State private var showMenu = false
    @State private var cardFrame: CGRect = .zero
    @State private var menuHeight: CGFloat = 196
    @State private var showEditor = false
    @State private var showCalendar = false
    @State private var showDetails = false
    @State private var confirmDelete = false
    @State private var composer = ""

    private var dayTitle: String {
        (date ?? Date()).formatted(.dateTime.month(.wide).day())
    }

    private func openMenu() {
        withAnimation(.spring(duration: 0.42, bounce: 0.24)) { showMenu = true }
    }

    private func closeMenu(then action: (() -> Void)? = nil) {
        withAnimation(.spring(duration: 0.26, bounce: 0)) { showMenu = false }
        action?()
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 7) {
                        Spacer(minLength: 0)
                        DatePill(title: dayTitle)
                        GiftCard(gift: gift, message: message, personalized: true, inChat: true, animated: gift == .heart) { showDetails = true }
                            .contentShape(RoundedRectangle(cornerRadius: 24))
                            .onTapGesture(perform: openMenu)
                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("scheduledScreen")) } action: { cardFrame = $0 }
                            .accessibilityAction(named: Text("Actions"), openMenu)
                            // Anchored to the card, so iOS points the confirmation at the gift itself.
                            .confirmationDialog("Delete the scheduled gift?", isPresented: $confirmDelete, titleVisibility: .visible) {
                                Button("Delete", role: .destructive, action: delete)
                                Button("Cancel", role: .cancel) {}
                            }
                            .padding(.top, 1).padding(.bottom, 2)
                    }
                    .padding(.horizontal, 9)
                    .frame(minHeight: max(0, geometry.size.height - 60), alignment: .bottom)
                }
                .defaultScrollAnchor(.bottom)
                ChatComposer(text: $composer, scheduled: false, openGifts: {}, openScheduled: {}, send: { composer = "" })
                    .padding(.horizontal, 23).padding(.top, 10).padding(.bottom, 8)
            }
            .coordinateSpace(.named("scheduledScreen"))
            .overlay(alignment: .topLeading) {
                if showMenu {
                    // Tapping anywhere outside closes the menu, like a system context menu.
                    Color.clear.contentShape(Rectangle())
                        .onTapGesture { closeMenu() }
                        .accessibilityHidden(true)
                    // Figma: menu's right edge 52pt past the card's, its top 80pt above the card.
                    ScheduledGiftMenu(
                        sendNow: { closeMenu(then: sendNow) },
                        edit: { closeMenu { showEditor = true } },
                        changeTime: { closeMenu { showCalendar = true } },
                        delete: { closeMenu { confirmDelete = true } })
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { menuHeight = $0 }
                        .position(x: cardFrame.maxX + 52 - ScheduledGiftMenu.width / 2,
                                  y: cardFrame.minY - 80 + menuHeight / 2)
                        .transition(MenuPopTransition())
                }
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showMenu) { _, isShown in isShown }
        .background { ChatWallpaper().ignoresSafeArea() }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    DesignImage(name: "F7_27_imgIconChevronLeft", width: 24, height: 24)
                        .modifier(ChromeCircle())
                }
                .buttonStyle(IconButtonStyle())
                .accessibilityLabel("Back")
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .principal) {
                Text("Scheduled Send").font(.headline)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 214, minHeight: 38)
                    .background(TelegramStyle.capsule, in: Capsule())
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .primaryAction) {
                DesignImage(name: "F11_660_imgPhoto", width: 35, height: 35)
                    .clipShape(Circle())
                    .modifier(ChromeCircle())
                    .accessibilityLabel("Anastasia")
            }
            .sharedBackgroundVisibility(.hidden)
        }
        #if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { if initialMenu { showMenu = true } }
        .sheet(isPresented: $showEditor) {
            GiftPreview(gift: gift, message: $message, hideName: $hideName, date: $date) { scheduled in
                showEditor = false
                if !scheduled { sendNow() }
            }
            .presentationDetents([.height(562)])
            .presentationBackground(TelegramStyle.sheet)
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCalendar) {
            SchedulePicker(date: $date)
                .presentationDetents([.height(370)])
                .presentationBackground(TelegramStyle.surface)
        }
        .sheet(isPresented: $showDetails) {
            GiftDetail(gift: gift, message: message, hideName: hideName)
                .presentationDetents([.height(360)])
        }
    }
}

/// Context menu for a scheduled gift ("10 — tap on gift").
private struct ScheduledGiftMenu: View {
    static let width: CGFloat = 192
    let sendNow: () -> Void
    let edit: () -> Void
    let changeTime: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row("F76_10037_imgIconSend", "Send Now", sendNow)
            row("F75_9883_imgIconEdit", "Edit", edit)
            row("F20_21973_imgIconCalendar", "Change time", changeTime)
            row("F75_9891_imgIconDelete", "Delete", delete)
        }
        .buttonStyle(MenuRowStyle())
        .font(.system(size: 17)).foregroundStyle(.black)
        .frame(width: Self.width)
        .padding(.vertical, 6)
        .background(Color(hex: 0xEAF8EE).opacity(0.89), in: RoundedRectangle(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
    }

    private func row(_ icon: String, _ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 22) {
                DesignImage(name: icon, width: 24, height: 24)
                Text(title)
            }
        }
    }
}

private struct GiftDetail: View {
    let gift: GiftKind
    let message: String
    let hideName: Bool
    var body: some View {
        VStack(spacing: 18) {
            if let asset = gift.asset {
                DesignImage(name: asset, width: 110, height: 105)
            } else {
                AnimatedSticker(name: gift.animation)
                    .frame(width: 110, height: 105)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            Text("Gift for Anastasia").font(.title2.bold())
            Text(message.isEmpty ? "A gift worth \(gift.price) Stars" : message)
            Text(hideName ? "Your name is hidden on Anastasia's profile." : "From Sasha")
                .font(.footnote).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TelegramStyle.preview)
    }
}

// Static canvas compositions keep all nine states reviewable without waiting for modal animations.
private struct JourneyPreview: View {
    /// Inset sheets: 40pt top corners, bottom corners concentric with the display's.
    private static let insetSheetShape = ConcentricRectangle(uniformTopCorners: .fixed(40), uniformBottomCorners: .concentric)
    let frame: Int
    private var previewDate: Date? {
        frame >= 6 ? Calendar.current.date(from: DateComponents(year: 2027, month: frame == 6 ? 11 : 3, day: frame == 6 ? 15 : 17)) : nil
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            ContentView(initialFrame: frame >= 8 ? frame : 1)
            if (2...7).contains(frame) {
                Color(red: 11 / 255, green: 58 / 255, blue: 38 / 255).opacity(0.14).ignoresSafeArea()
                GiftCatalog(gift: .constant(.heart), message: .constant(""), hideName: .constant(false), date: .constant(nil)) { _ in }
                    .overlay(alignment: .top) { Grabber(color: Color(hex: 0xC7C7CC)) }
                    .frame(height: 721).clipShape(RoundedRectangle(cornerRadius: 44))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: -2)
                if frame >= 3 {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    GiftPreview(gift: .heart, message: .constant(frame >= 7 ? "Happy Birthday" : ""), hideName: .constant(false), date: .constant(previewDate), initialFrame: frame == 4 ? 4 : 1) { _ in }
                        .overlay(alignment: .top) { Grabber(color: .black.opacity(0.18)) }
                        .frame(height: 580).clipShape(Self.insetSheetShape)
                        .padding(.horizontal, 5).padding(.bottom, 2)
                }
                if frame == 5 {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    SchedulePicker(date: .constant(nil)).frame(height: 389)
                        .clipShape(Self.insetSheetShape)
                        .padding(.horizontal, 5).padding(.bottom, 2)
                }
            }
        }.ignoresSafeArea(edges: .bottom).preferredColorScheme(.light)
    }
}

#Preview("01 — Chat") {
    JourneyPreview(frame: 1).id(1)
}

#Preview("02 — Gift") {
    JourneyPreview(frame: 2).id(2)
}

#Preview("03 — Select gift") {
    JourneyPreview(frame: 3).id(3)
}

#Preview("04 — Send options") {
    JourneyPreview(frame: 4).id(4)
}

#Preview("05 — Calendar") {
    JourneyPreview(frame: 5).id(5)
}

#Preview("06 — Date selected") {
    JourneyPreview(frame: 6).id(6)
}

#Preview("07 — Message") {
    JourneyPreview(frame: 7).id(7)
}

#Preview("08 — Gift prepared") {
    JourneyPreview(frame: 8).id(8)
}

#Preview("09 — Gift sent") {
    JourneyPreview(frame: 9).id(9)
}

private struct ScheduledSendPreview: View {
    let showMenu: Bool
    var body: some View {
        NavigationStack {
            ScheduledSendScreen(gift: .heart, message: .constant("Happy Birthday"), hideName: .constant(false),
                                date: .constant(Calendar.current.date(from: DateComponents(year: 2027, month: 3, day: 17))),
                                initialMenu: showMenu, sendNow: {}, delete: {})
        }
        .tint(Color(hex: 0x3C684C))
        .preferredColorScheme(.light)
    }
}

#Preview("10 — Scheduled send") {
    ScheduledSendPreview(showMenu: false)
}

#Preview("11 — Scheduled gift menu") {
    ScheduledSendPreview(showMenu: true)
}


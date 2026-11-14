
import SwiftUI

// The nine Figma frames share one gift draft throughout the journey.
private enum GiftDelivery {
    case draft, scheduled, sent
}

private enum GiftKind: String, CaseIterable, Identifiable {
    case heart, bear, present
    var id: String { rawValue }
    var asset: String {
        switch self {
        case .heart: "F16_17493_imgImage"
        case .bear: "F16_17493_imgImage5"
        case .present: "F16_17493_imgImage6"
        }
    }
    var price: Int { self == .present ? 25 : 15 }
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
    static let outgoing = LinearGradient(colors: [Color(hex: 0xEFFADB), Color(hex: 0xE1F7C4)], startPoint: .leading, endPoint: .trailing)
    static let blue = LinearGradient(colors: [Color(hex: 0x1FA6F7), Color(hex: 0x0A84FF)], startPoint: .leading, endPoint: .trailing)
    static let preview = LinearGradient(colors: [Color(hex: 0xC2D68B), Color(hex: 0x9AC889), Color(hex: 0x82BA96)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                                GiftCard(gift: gift, message: giftMessage, personalized: true) {
                                    showDetails = true
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
                ToolbarItem(placement: .cancellationAction) {
                    Button { messages = []; delivery = .draft } label: {
                        DesignImage(name: "F7_27_imgIconChevronLeft", width: 24, height: 24)
                    }
                    .accessibilityLabel("Restart chat")
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("Anastasia Afonicheva 😻").font(.system(size: 15.5, weight: .semibold))
                        Text("online").font(.caption).foregroundStyle(Color(hex: 0x2E9E5B))
                    }
                    .padding(.horizontal, 15).padding(.vertical, 3)
                    .background(TelegramStyle.capsule, in: Capsule())
                }
                ToolbarItem(placement: .primaryAction) {
                    DesignImage(name: "F11_660_imgPhoto", width: 35, height: 35)
                        .clipShape(Circle()).accessibilityLabel("Anastasia")
                }
            }
            #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showGifts) {
                GiftCatalog(gift: $gift, message: $giftMessage, hideName: $hideName, date: $scheduledDate, initialFrame: initialFrame) { scheduled in
                    delivery = scheduled ? .scheduled : .sent
                    showGifts = false
                }
                .presentationDetents([.height(687)])
                .presentationCornerRadius(44)
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showScheduled) {
                ScheduledGift(gift: gift, message: giftMessage, date: scheduledDate) {
                    delivery = .sent
                    showScheduled = false
                }
                .presentationDetents([.height(380)])
                .presentationCornerRadius(40)
            }
            .sheet(isPresented: $showDetails) {
                GiftDetail(gift: gift, message: giftMessage, hideName: hideName)
                    .presentationDetents([.height(360)])
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
        }
    }
}

private struct PinnedMessage: View {
    let dismiss: () -> Void
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x1C1C1E)).frame(width: 2, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("Pinned Message").font(.system(size: 13, weight: .medium))
                HStack(spacing: 3) {
                    Text("Cool, good luck").font(.system(size: 13))
                    DesignImage(name: "F11_594_imgSticker", width: 15.3, height: 15.3)
                }
            }
            Spacer()
            Button(action: dismiss) {
                DesignImage(name: "F11_594_imgIconClose", width: 17, height: 17)
            }.accessibilityLabel("Dismiss pinned message")
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(TelegramStyle.capsule, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}

private struct DatePill: View {
    let title: String
    var body: some View {
        Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Color(hex: 0x5BA557).opacity(0.9), in: Capsule())
            .frame(maxWidth: .infinity)
    }
}

private struct MessageBubble: View {
    let text: String
    let outgoing: Bool
    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            Text(text).font(.system(size: 13.5))
            HStack(spacing: 2) {
                Text("15:59").font(.system(size: 9.5))
                    .foregroundStyle(outgoing ? TelegramStyle.green : Color(hex: 0x9A9A9E))
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
                    Text("Cool, good luck").font(.system(size: 13.5))
                    DesignImage(name: "F7_66_imgSticker", width: 17.1, height: 17.1)
                }.padding(.leading, 4)
                HStack(alignment: .bottom, spacing: 14) {
                    Button { reacted.toggle() } label: {
                        HStack(spacing: 6) {
                            DesignImage(name: "F7_66_img", width: 17, height: 17)
                            if reacted { DesignImage(name: "F7_66_imgAvatar", width: 20, height: 20) }
                        }
                        .padding(.leading, 10).padding(.trailing, 3).padding(.vertical, 3)
                        .background(Color(hex: 0xF6F6F6), in: Capsule())
                    }.accessibilityLabel("Heart reaction")
                    HStack(spacing: 2) {
                        DesignImage(name: "F7_66_imgIconPinned", width: 11, height: 11)
                        Text("16:51").font(.system(size: 9.5)).foregroundStyle(.gray)
                    }
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(TelegramStyle.surface, in: RoundedRectangle(cornerRadius: 17))
            .frame(maxWidth: .infinity, alignment: .leading)
            ReplyBubble()
        }
    }
}

private struct ReplyBubble: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Anastasia Afonicheva").font(.system(size: 10.5, weight: .medium)).foregroundStyle(TelegramStyle.green)
                HStack(spacing: 3) {
                    Text("Cool, good luck").font(.system(size: 10.5))
                    DesignImage(name: "F7_78_imgSticker", width: 12.6, height: 12.6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 12).padding(.vertical, 4)
            .background(TelegramStyle.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 1).fill(TelegramStyle.green).frame(width: 3) }
            HStack(spacing: 4) {
                Text("Thanks").font(.system(size: 13.5))
                DesignImage(name: "F7_78_img", width: 17, height: 17)
                Spacer(minLength: 4)
                Text("edited 17:09").font(.system(size: 9.5)).foregroundStyle(TelegramStyle.green)
                DesignImage(name: "F7_78_imgIconRead", width: 15, height: 10)
            }
        }
        .padding(8).frame(width: 177)
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
            Button(action: openGifts) { DesignImage(name: "F12_15182_imgAttachIcon1", width: 23, height: 23)
                    .mask(DesignImage(name: "F12_15182_imgAttachIcon", width: 22, height: 22)) }
                .buttonStyle(.bordered).buttonBorderShape(.circle).accessibilityLabel("Attachments")
            HStack(spacing: 10) {
                TextField("Message", text: $text).font(.system(size: 15)).onSubmit(send)
                if scheduled {
                    Button(action: openScheduled) { DesignImage(name: "F24_28402_imgIconCalendarScheduled", width: 22, height: 22) }
                        .accessibilityLabel("Scheduled gift")
                }
                Button(action: openGifts) {
                    DesignImage(name: "F12_15197_imgGift", width: 22, height: 22)
                }.accessibilityLabel("Send a gift")
                Button { text += "❤️" } label: {
                    DesignImage(name: "F12_15197_imgStickers", width: 20, height: 20)
                }.accessibilityLabel("Insert heart")
            }
            .padding(.horizontal, 12).frame(height: 40)
            .background(TelegramStyle.capsule, in: Capsule())
            Button(action: text.isEmpty ? openGifts : send) {
                if text.isEmpty {
                    DesignImage(name: "F12_15204_imgRecordAudioIcon1", width: 16, height: 22)
                } else {
                    Image(systemName: "arrow.up")
                }
            }.buttonStyle(.bordered).buttonBorderShape(.circle)
                .accessibilityLabel(text.isEmpty ? "Voice and attachment options" : "Send message")
        }
        .foregroundStyle(Color(hex: 0x8AA28B))
    }
}

private struct GiftCatalog: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var gift: GiftKind
    @Binding var message: String
    @Binding var hideName: Bool
    @Binding var date: Date?
    var initialFrame: Int = 1
    let complete: (Bool) -> Void
    @State private var showPreview = false
    @State private var collectibles = false
    @State private var info: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CatalogHeader { info = "Premium unlocks additional Telegram features for Anastasia." }
                HStack(spacing: 10) {
                    PremiumTile(asset: "F16_17493_imgImage1", title: "3 Months", price: "$11.99", discount: nil)
                    PremiumTile(asset: "F16_17493_imgImage3", title: "6 Months", price: "$15.99", discount: "-10%")
                    PremiumTile(asset: "F16_17493_imgImage4", title: "1 Year", price: "$28.99", discount: "-25%")
                }
                .padding(.horizontal, 14)
                .onTapGesture { info = "Premium purchases are not connected in this design prototype." }
                Text("Send a Gift").font(.system(size: 22.25, weight: .bold)).padding(.top, 15)
                Text("Give **Anastasia** gifts that can be kept\non their profile or converted to Stars.")
                    .font(.system(size: 12.75)).multilineTextAlignment(.center).padding(.top, 5)
                Button("Learn more about Stars ›") {
                    info = "Stars can be used to send gifts. Anastasia can display gifts on her profile or convert this gift to 13 Stars."
                }.font(.system(size: 12.75)).foregroundStyle(Color(hex: 0x1F8CE6))
                HStack(spacing: 12) {
                    Button { collectibles = false } label: {
                        Text("All").padding(.horizontal, 11).padding(.vertical, 4)
                            .background(collectibles ? Color.clear : Color(hex: 0xE2E2E7), in: Capsule())
                    }
                    Button { collectibles = true } label: {
                        Text("Collectibles").padding(.horizontal, 8).padding(.vertical, 4)
                            .background(collectibles ? Color(hex: 0xE2E2E7) : Color.clear, in: Capsule())
                    }
                }.font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: 0x8E8E93))
                    .padding(.top, 31).padding(.bottom, 18)
                if collectibles {
                    Text("No collectible gifts available").font(.footnote).foregroundStyle(.secondary).padding(25)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(GiftKind.allCases) { item in
                            GiftTile(gift: item) { gift = item; showPreview = true }
                        }
                        ForEach(GiftKind.allCases) { item in
                            GiftTile(gift: item == .heart ? .bear : item) {
                                gift = item == .heart ? .bear : item
                                showPreview = true
                            }
                        }
                    }.padding(.horizontal, 14)
                }
            }.padding(.bottom, 90)
        }
        .scrollIndicators(.hidden)
        .task { if (3...7).contains(initialFrame) { showPreview = true } }
        .background(TelegramStyle.sheet)
        .overlay(alignment: .topLeading) {
            CloseButton { dismiss() }.padding(14)
        }
        .overlay(alignment: .bottom) {
            AttachmentBar { info = "\($0) is outside the gift flow shown in this concept." }
                .padding(.horizontal, 18).padding(.bottom, 6)
        }
        .sheet(isPresented: $showPreview) {
            GiftPreview(gift: gift, message: $message, hideName: $hideName, date: $date, initialFrame: initialFrame, complete: complete)
                .presentationDetents([.height(520)])
                .presentationCornerRadius(40).presentationDragIndicator(.visible)
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
            Text("Gift Premium").font(.system(size: 22, weight: .bold)).padding(.top, 2)
            Text("Give **Anastasia** access to exclusive").font(.system(size: 12.75)).padding(.top, 8)
            HStack(spacing: 3) {
                Text("Telegram features.")
                Button("Learn more about Premium ›", action: learnMore).foregroundStyle(Color(hex: 0x1F8CE6))
            }.font(.system(size: 12.75))
            Spacer(minLength: 0)
        }
        .frame(height: 222).frame(maxWidth: .infinity)
        .background(alignment: .top) {
            Image("F16_17493_imgImage2").resizable().scaledToFill().frame(height: 142).clipped().offset(y: -5)
        }
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("Balance").font(.system(size: 11.5))
                HStack(spacing: 3) {
                    DesignImage(name: "F16_17493_imgTelegramPremiumStar1", width: 14, height: 15)
                    Text("15").font(.system(size: 13, weight: .semibold))
                }
            }.padding(.top, 15).padding(.trailing, 19)
        }
    }
}

private struct PremiumTile: View {
    let asset: String
    let title: String
    let price: String
    let discount: String?
    var body: some View {
        VStack(spacing: 0) {
            DesignImage(name: asset, width: 52, height: 46).padding(.top, 26)
            Text(title).font(.system(size: 12.5, weight: .semibold)).padding(.top, 10)
            Text("Premium").font(.system(size: 11))
            Text(price).font(.system(size: 9.5, weight: .semibold)).foregroundStyle(Color(hex: 0x2B8CE3))
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Color(hex: 0xE3F0FC), in: Capsule()).padding(.top, 10)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity).frame(height: 158)
        .background(TelegramStyle.surface)
        .overlay(alignment: .topTrailing) {
            if let discount {
                Text(discount).font(.system(size: 10.5, weight: .medium)).foregroundStyle(.white)
                    .frame(width: 96, height: 20)
                    .background(LinearGradient(colors: [Color(hex: 0xD16BD3), Color(hex: 0x8B7CF6)], startPoint: .leading, endPoint: .trailing))
                    .rotationEffect(.degrees(45)).offset(x: 25, y: 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct GiftTile: View {
    let gift: GiftKind
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                DesignImage(name: gift.asset, width: 82, height: 78)
                HStack(spacing: 3) {
                    DesignImage(name: "F16_17493_imgIconStar", width: 15, height: 15)
                    Text("\(gift.price)").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: 0xC9861A))
                }.padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Color(hex: 0xFCEFD2), in: Capsule())
            }
            .frame(maxWidth: .infinity).frame(height: 137)
            .background(TelegramStyle.surface, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain).accessibilityLabel("\(gift.rawValue) gift, \(gift.price) Stars")
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
                        Text(item.0).font(.system(size: 8.75, weight: .medium))
                    }
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(item.0 == "Gift" ? Color(hex: 0xE9E9EE) : Color.clear, in: Capsule())
                }
                .foregroundStyle(item.0 == "Gift" ? Color(hex: 0x2BA04E) : Color(hex: 0x1C1C1E))
            }
        }
        .padding(4).background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

private struct CloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            DesignImage(name: "F19_19942_imgIconClose", width: 24, height: 24)
        }
        .buttonStyle(.bordered).buttonBorderShape(.circle)
        .tint(Color(hex: 0xF1FFDD)).accessibilityLabel("Close")
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
    @FocusState private var editing: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("You sent a gift for **\(gift.price) Stars**")
                    .font(.system(size: 11)).foregroundStyle(.white)
                    .padding(.horizontal, 7).frame(width: 204, height: 17, alignment: .leading)
                    .background(Color(hex: 0x5BA557).opacity(0.9), in: Capsule()).padding(.top, 24)
                GiftCard(gift: gift, message: message, personalized: !message.isEmpty) { showDetails = true }
                    .padding(.top, 7)
                Spacer(minLength: 9)
                HStack {
                    TextField("Your message (optional)", text: $message)
                        .font(.system(size: 14.25)).focused($editing).submitLabel(.done)
                    Button { message += "❤️" } label: {
                        DesignImage(name: "F19_19942_imgIconSmile", width: 24, height: 24)
                    }.accessibilityLabel("Add heart to gift message")
                }
                .padding(.horizontal, 16).frame(height: 34)
                .background(TelegramStyle.outgoing, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1))
                .padding(.horizontal, 21).padding(.bottom, 14)
            }
            .frame(height: 350).frame(maxWidth: .infinity)
            .background(TelegramStyle.preview)
            GiftPrivacy(hideName: $hideName).padding(.horizontal, 21).padding(.top, 22)
            Spacer(minLength: 12)
            Button {
                editing = false
                if date == nil { showOptions.toggle() } else { complete(true) }
            } label: {
                HStack(spacing: 4) {
                    Text(date.map { "Send on " + $0.formatted(.dateTime.month(.abbreviated).day()) + " at 00:00 for" } ?? "Send a Gift for")
                    DesignImage(name: "F19_19942_imgIconStar", width: 16, height: 16)
                    Text("\(gift.price)")
                }
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(TelegramStyle.blue, in: Capsule())
            }
            .onLongPressGesture { editing = false; showOptions = true }
            .padding(.horizontal, 28).padding(.bottom, 14)
        }
        .task {
            showOptions = initialFrame == 4
            showCalendar = initialFrame == 5
        }
        .background(TelegramStyle.sheet.ignoresSafeArea())
        .overlay(alignment: .topLeading) { CloseButton { dismiss() }.padding(14) }
        .overlay(alignment: .bottomTrailing) {
            if showOptions {
                SendOptions(schedule: { showOptions = false; showCalendar = true }, silent: { complete(false) })
                    .padding(.trailing, 30).padding(.bottom, 74)
            }
        }
        .sheet(isPresented: $showCalendar) {
            SchedulePicker(date: $date)
                .presentationDetents([.height(355)]).presentationCornerRadius(40)
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
                .font(.system(size: 11.75)).tint(TelegramStyle.green)
                .padding(.horizontal, 14).frame(height: 42)
                .background(TelegramStyle.surface, in: Capsule())
            Text("You can hide your name and message from everyone who\nvisits Anastasia's profile. Only Anastasia will see your\nhidden name and message.")
                .font(.system(size: 8.75)).foregroundStyle(Color(hex: 0x8A8A8E))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GiftCard: View {
    let gift: GiftKind
    let message: String
    let personalized: Bool
    let view: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            DesignImage(name: gift == .heart ? "F19_19942_imgGift" : gift.asset, width: 97, height: 75.95)
                .padding(.top, 24.5)
            HStack(spacing: 4) {
                Text(personalized ? "Gift from" : "Gift for Anastasia")
                if personalized {
                    DesignImage(name: "F24_26371_imgAvatar", width: 16, height: 16)
                    Text("Sasha")
                }
            }.font(.system(size: 12.5, weight: .semibold)).padding(.top, 29)
            Text(personalized ? message : "Anastasia can display this gift\non their profile or convert it\nto 13 Stars.")
                .font(.system(size: 11)).lineSpacing(1).multilineTextAlignment(.center)
                .padding(.top, 1).padding(.horizontal, 10)
            Button("View", action: view).font(.system(size: 12.5, weight: .semibold))
                .frame(width: 111, height: 29)
                .background(Color(hex: 0x1E5A30).opacity(0.28), in: Capsule()).padding(.top, 9)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white).frame(width: 194, height: personalized ? 222 : 245)
        .background {
            LinearGradient(colors: [Color(hex: 0x8EB247), Color(hex: 0x50A04F)], startPoint: .leading, endPoint: .trailing)
                .overlay(LinearGradient(colors: [.clear, Color(hex: 0x56A257).opacity(0.75), Color(hex: 0x5A9E6C).opacity(0.9)], startPoint: .top, endPoint: .bottom))
        }
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
                }.frame(height: 46)
            }
            Button(action: silent) {
                HStack(spacing: 22) {
                    DesignImage(name: "F20_21973_imgIconBellSlash", width: 24, height: 24)
                    Text("Send Without Sound")
                }.frame(height: 46)
            }
        }
        .font(.system(size: 17)).foregroundStyle(.primary)
        .padding(.horizontal, 20).padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
    }
}

private struct SchedulePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date?
    @State private var selection = Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 1)) ?? Date()
    var body: some View {
        VStack(spacing: 0) {
            Text("Send Later").font(.system(size: 14.5, weight: .semibold)).padding(.top, 24)
            GiftDatePicker(selection: $selection)
                .padding(.horizontal, 25).frame(height: 190).padding(.top, 29)
            Spacer()
            Button {
                date = Calendar.current.startOfDay(for: selection)
                dismiss()
            } label: {
                Text("Save").font(.system(size: 14.25, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 45)
                    .background(TelegramStyle.blue, in: Capsule())
            }.padding(.horizontal, 28).padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity).background(TelegramStyle.surface)
        .overlay(alignment: .topLeading) { CloseButton { dismiss() }.padding(14) }
        .onAppear { if let date { selection = date } }
    }
}

private struct ScheduledGift: View {
    let gift: GiftKind
    let message: String
    let date: Date?
    let sendNow: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Text("Scheduled Gift").font(.headline).padding(.top, 22)
            if let date { Text(date, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary) }
            GiftCard(gift: gift, message: message, personalized: true, view: sendNow)
            Button("Send Now", action: sendNow)
                .buttonStyle(.borderedProminent).tint(Color(hex: 0x0A84FF))
        }.frame(maxWidth: .infinity)
    }
}

private struct GiftDetail: View {
    let gift: GiftKind
    let message: String
    let hideName: Bool
    var body: some View {
        VStack(spacing: 18) {
            DesignImage(name: gift.asset, width: 110, height: 105)
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
    let frame: Int
    private var previewDate: Date? {
        frame >= 6 ? Calendar.current.date(from: DateComponents(year: 2027, month: frame == 6 ? 11 : 3, day: frame == 6 ? 15 : 17)) : nil
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            ContentView(initialFrame: frame >= 8 ? frame : 1)
            if (2...7).contains(frame) {
                Color.black.opacity(0.15).ignoresSafeArea()
                GiftCatalog(gift: .constant(.heart), message: .constant(""), hideName: .constant(false), date: .constant(nil)) { _ in }
                    .frame(height: 721).clipShape(RoundedRectangle(cornerRadius: 44))
                if frame >= 3 {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    GiftPreview(gift: .heart, message: .constant(frame >= 7 ? "Happy Birthday" : ""), hideName: .constant(false), date: .constant(previewDate), initialFrame: frame == 4 ? 4 : 1) { _ in }
                        .frame(height: 554).clipShape(RoundedRectangle(cornerRadius: 40)).padding(.horizontal, 5)
                }
                if frame == 5 {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    SchedulePicker(date: .constant(nil)).frame(height: 389)
                        .clipShape(RoundedRectangle(cornerRadius: 40)).padding(.horizontal, 5)
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


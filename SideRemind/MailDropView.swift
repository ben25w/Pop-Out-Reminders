import AppKit
import SwiftUI

/// Transparent AppKit view that accepts Apple Mail drags.
/// SwiftUI's onDrop can't load com.apple.mail.email via NSItemProvider
/// (times out). Reading the drag pasteboard directly works reliably.
struct MailDropOverlay: NSViewRepresentable {
    let onMailDrop: (URL) -> Void
    @Binding var isTargeted: Bool

    func makeNSView(context: Context) -> MailDropNSView {
        let v = MailDropNSView()
        v.onMailDrop       = onMailDrop
        v.onTargetChanged  = { targeted in DispatchQueue.main.async { isTargeted = targeted } }
        return v
    }

    func updateNSView(_ nsView: MailDropNSView, context: Context) {
        nsView.onMailDrop = onMailDrop
    }
}

class MailDropNSView: NSView {
    var onMailDrop: ((URL) -> Void)?
    var onTargetChanged: ((Bool) -> Void)?

    private let mailType = NSPasteboard.PasteboardType("com.apple.mail.email")

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([mailType, .URL])
    }
    required init?(coder: NSCoder) { fatalError() }

    // Pass all normal mouse events through to SwiftUI content below.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard accepts(sender) else { return [] }
        onTargetChanged?(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        accepts(sender) ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onTargetChanged?(false)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        onTargetChanged?(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { accepts(sender) }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard

        // 1. message:// URL stored as a string under the mail type
        if let str = pb.string(forType: mailType),
           let url = URL(string: str), url.scheme == "message" {
            onMailDrop?(url); return true
        }

        // 2. Raw data that decodes to a message:// URL string
        if let data = pb.data(forType: mailType),
           let str  = String(data: data, encoding: .utf8),
           let url  = URL(string: str.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.scheme == "message" {
            onMailDrop?(url); return true
        }

        // 3. Standard URL objects on the pasteboard (some Mail versions put these)
        if let urls = pb.readObjects(forClasses: [NSURL.self]) as? [URL],
           let url  = urls.first(where: { $0.scheme == "message" }) {
            onMailDrop?(url); return true
        }

        // 4. Fallback: any URL (still useful as a reminder link)
        if let urls = pb.readObjects(forClasses: [NSURL.self]) as? [URL],
           let url  = urls.first {
            onMailDrop?(url); return true
        }

        return false
    }

    // MARK: -

    private func accepts(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.availableType(from: [mailType, .URL]) != nil
    }
}

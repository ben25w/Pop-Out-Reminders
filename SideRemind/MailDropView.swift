import AppKit
import SwiftUI

/// Transparent AppKit view that accepts Apple Mail drags.
/// SwiftUI's onDrop can't load com.apple.mail.email via NSItemProvider
/// (times out). Reading the drag pasteboard directly works reliably.
struct MailDropPayload {
    let url: URL
    let subject: String?
}

struct MailDropOverlay: NSViewRepresentable {
    let onMailDrop: (MailDropPayload) -> Void
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
    var onMailDrop: ((MailDropPayload) -> Void)?
    var onTargetChanged: ((Bool) -> Void)?

    private let mailType = NSPasteboard.PasteboardType("com.apple.mail.email")
    private let logPrefix = "[MailDrop]"

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([mailType, .URL])
        NSLog("%@ registered drag types: %@", logPrefix, registeredDraggedTypes.map(\.rawValue).joined(separator: ", "))
    }
    required init?(coder: NSCoder) { fatalError() }

    // Keep normal clicks going to SwiftUI, but allow external drag movement
    // to target this AppKit view.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let event = NSApp.currentEvent else { return nil }
        switch event.type {
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            return self
        default:
            return nil
        }
    }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        logDrag("draggingEntered", sender)
        guard accepts(sender) else { return [] }
        onTargetChanged?(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        accepts(sender) ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        NSLog("%@ draggingExited", logPrefix)
        onTargetChanged?(false)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        NSLog("%@ draggingEnded", logPrefix)
        onTargetChanged?(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        logDrag("prepareForDragOperation", sender)
        return accepts(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard
        dumpPasteboard(pb)
        onTargetChanged?(false)

        if let url = firstURL(from: pb, preferredType: mailType, messageOnly: true) {
            onMailDrop?(MailDropPayload(url: url, subject: firstSubject(from: pb)))
            return true
        }

        if let url = firstURL(from: pb, preferredType: .URL, messageOnly: true) {
            onMailDrop?(MailDropPayload(url: url, subject: firstSubject(from: pb)))
            return true
        }

        if let url = firstURL(from: pb, preferredType: .URL, messageOnly: false) {
            onMailDrop?(MailDropPayload(url: url, subject: firstSubject(from: pb)))
            return true
        }

        NSLog("%@ no usable URL found on drop", logPrefix)
        return false
    }

    // MARK: -

    private func accepts(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.availableType(from: [mailType, .URL]) != nil
    }

    private func logDrag(_ name: String, _ sender: NSDraggingInfo) {
        let pb = sender.draggingPasteboard
        let types = pb.types?.map(\.rawValue).joined(separator: ", ") ?? "<none>"
        NSLog("%@ %@ frame=%@ types=%@", logPrefix, name, NSStringFromRect(frame), types)
    }

    private func dumpPasteboard(_ pb: NSPasteboard) {
        let types = pb.types ?? []
        NSLog("%@ performDragOperation types=%@", logPrefix, types.map(\.rawValue).joined(separator: ", "))

        for type in types {
            if let str = pb.string(forType: type) {
                NSLog("%@ type %@ as string: %@", logPrefix, type.rawValue, str)
            } else if let data = pb.data(forType: type) {
                let hex = data.prefix(200).map { String(format: "%02x", $0) }.joined()
                NSLog("%@ type %@ as data bytes=%d prefix=%@", logPrefix, type.rawValue, data.count, hex)
            } else {
                NSLog("%@ type %@ could not be read as string or data", logPrefix, type.rawValue)
            }
        }
    }

    private func firstURL(
        from pb: NSPasteboard,
        preferredType: NSPasteboard.PasteboardType,
        messageOnly: Bool
    ) -> URL? {
        if let str = pb.string(forType: preferredType),
           let url = url(in: str, messageOnly: messageOnly) {
            return url
        }

        if let data = pb.data(forType: preferredType) {
            for str in decodedStrings(from: data) {
                if let url = url(in: str, messageOnly: messageOnly) {
                    return url
                }
            }
        }

        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL] {
            return urls.compactMap { $0 as URL }.first { !messageOnly || $0.scheme == "message" }
        }

        return nil
    }

    private func firstSubject(from pb: NSPasteboard) -> String? {
        var candidates: [String] = []

        for item in pb.pasteboardItems ?? [] {
            for type in item.types {
                if let string = item.string(forType: type) {
                    candidates.append(string)
                }
            }
        }

        for type in pb.types ?? [] {
            if let string = pb.string(forType: type) {
                candidates.append(string)
            }

            if let data = pb.data(forType: type) {
                candidates.append(contentsOf: decodedStrings(from: data))
                if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
                   let subject = subject(in: plist) {
                    return subject
                }
            }
        }

        for candidate in candidates {
            if let subject = subject(in: candidate) {
                return subject
            }
        }

        return nil
    }

    private func decodedStrings(from data: Data) -> [String] {
        var values: [String] = []
        let encodings: [String.Encoding] = [.utf8, .utf16, .utf16LittleEndian, .utf16BigEndian, .ascii]

        for encoding in encodings {
            if let string = String(data: data, encoding: encoding), !string.isEmpty {
                values.append(string)
            }
        }

        if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
            values.append(String(describing: plist))
        }

        return values
    }

    private func subject(in object: Any) -> String? {
        if let dict = object as? [String: Any] {
            for key in ["subject", "Subject", "NSSubject", "MessageSubject"] {
                if let value = dict[key] as? String,
                   let subject = cleanedSubject(value) {
                    return subject
                }
            }

            for value in dict.values {
                if let subject = subject(in: value) {
                    return subject
                }
            }
        }

        if let array = object as? [Any] {
            for value in array {
                if let subject = subject(in: value) {
                    return subject
                }
            }
        }

        if let string = object as? String {
            return subject(in: string)
        }

        return nil
    }

    private func subject(in raw: String) -> String? {
        let patterns = [
            #"(?im)^subject:\s*(.+)$"#,
            #"(?i)"subject"\s*[:=]\s*"([^"]+)""#,
            #"(?i)\bsubject\s*[:=]\s*([^\n\r,}]+)"#
        ]

        for pattern in patterns {
            if let match = raw.range(of: pattern, options: .regularExpression) {
                let matched = String(raw[match])
                let value = matched
                    .replacingOccurrences(of: #"(?im)^subject:\s*"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"(?i)^"subject"\s*[:=]\s*""#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"(?i)^subject\s*[:=]\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\";,} \n\r\t"))

                if let subject = cleanedSubject(value) {
                    return subject
                }
            }
        }

        return nil
    }

    private func cleanedSubject(_ raw: String) -> String? {
        let subject = raw
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return subject.isEmpty ? nil : subject
    }

    private func url(in raw: String, messageOnly: Bool) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = URL(string: trimmed), !messageOnly || direct.scheme == "message" {
            return direct
        }

        let pattern = messageOnly ? #"message://[^\s<>"']+"# : #"https?://[^\s<>"']+"#
        if let range = trimmed.range(of: pattern, options: .regularExpression),
           let url = URL(string: String(trimmed[range])) {
            return url
        }

        return nil
    }
}

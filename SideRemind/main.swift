import AppKit

// Pure AppKit entry point — avoids SwiftUI scene lifecycle conflicts
// with LSUIElement = true. All UI is via NSHostingView in AppDelegate.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

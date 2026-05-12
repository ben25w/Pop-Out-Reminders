import AppKit
import SwiftUI

class SidebarPanel: NSPanel {
    private let remindersManager = RemindersManager()
    private let settings = AppSettings.shared
    private var panelVisible = false

    convenience init() {
        self.init(contentRect: .zero,
                  styleMask: [.borderless, .nonactivatingPanel],
                  backing: .buffered,
                  defer: false)
        configure()
    }

    private func configure() {
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovable = false
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // Frosted glass background
        let blur = NSVisualEffectView()
        blur.material = .sidebar
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 14

        let hosting = NSHostingView(rootView:
            ContentView()
                .environmentObject(remindersManager)
        )
        hosting.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: blur.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: blur.bottomAnchor)
        ])
        contentView = blur

        // Wire up width changes from SwiftUI drag handle
        settings.onPanelWidthChange = { [weak self] newWidth in
            guard let self, self.panelVisible else { return }
            self.updateVisibleFrame(width: newWidth, animated: false)
        }

        // Start off-screen
        if let screen = NSScreen.main {
            setFrame(offscreenRect(screen: screen), display: false)
        }
        orderFrontRegardless()
    }

    // MARK: - Frame helpers

    private func panelRect(screen: NSScreen, width: CGFloat? = nil) -> NSRect {
        let w = width ?? settings.panelWidth
        let sf = screen.frame
        let h = sf.height * 0.70
        let y = sf.minY + (sf.height - h) / 2
        return NSRect(x: sf.maxX - w, y: y, width: w, height: h)
    }

    private func offscreenRect(screen: NSScreen, width: CGFloat? = nil) -> NSRect {
        let w = width ?? settings.panelWidth
        let sf = screen.frame
        let h = sf.height * 0.70
        let y = sf.minY + (sf.height - h) / 2
        return NSRect(x: sf.maxX, y: y, width: w, height: h)
    }

    private func updateVisibleFrame(width: CGFloat, animated: Bool) {
        guard let screen = NSScreen.main else { return }
        let target = panelRect(screen: screen, width: width)
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().setFrame(target, display: true)
            }
        } else {
            setFrame(target, display: true)
        }
    }

    // MARK: - Show / Hide

    func show() {
        guard let screen = NSScreen.main else { return }
        panelVisible = true
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(panelRect(screen: screen), display: true)
        }
    }

    func hide() {
        guard let screen = NSScreen.main else { return }
        panelVisible = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().setFrame(offscreenRect(screen: screen), display: true)
        }
    }
}

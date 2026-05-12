import AppKit
import SwiftUI
import Combine

class SidebarPanel: NSPanel {
    private let remindersManager = RemindersManager()
    private let settings = AppSettings.shared
    private var panelVisible = false
    private var cancellables = Set<AnyCancellable>()

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

        // Observe width and height changes — live-update the frame if visible
        Publishers.Merge(
            settings.$panelWidth.map { _ in () },
            settings.$panelHeightFraction.map { _ in () }
        )
        .dropFirst()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            // Defer setFrame to the next run-loop iteration so it never fires
            // synchronously inside a SwiftUI layout pass (which causes recursion).
            DispatchQueue.main.async {
                guard let self, self.panelVisible else { return }
                self.setFrame(self.visibleRect(), display: true)
            }
        }
        .store(in: &cancellables)

        // Start off-screen
        if let screen = NSScreen.main {
            setFrame(offscreenRect(screen: screen), display: false)
        }
        orderFrontRegardless()
    }

    // MARK: - Frame helpers

    private func visibleRect(screen: NSScreen? = nil) -> NSRect {
        let s = screen ?? NSScreen.main ?? NSScreen.screens[0]
        let sf = s.frame
        let w = settings.panelWidth
        let h = sf.height * CGFloat(settings.panelHeightFraction)
        let y = sf.minY + (sf.height - h) / 2
        return NSRect(x: sf.maxX - w, y: y, width: w, height: h)
    }

    private func offscreenRect(screen: NSScreen? = nil) -> NSRect {
        let s = screen ?? NSScreen.main ?? NSScreen.screens[0]
        let sf = s.frame
        let w = settings.panelWidth
        let h = sf.height * CGFloat(settings.panelHeightFraction)
        let y = sf.minY + (sf.height - h) / 2
        return NSRect(x: sf.maxX, y: y, width: w, height: h)
    }

    // MARK: - Show / Hide

    func show() {
        panelVisible = true
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(visibleRect(), display: true)
        }
    }

    func hide() {
        panelVisible = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().setFrame(offscreenRect(), display: true)
        }
    }
}

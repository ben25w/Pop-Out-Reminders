import AppKit
import SwiftUI
import Combine

class SidebarPanel: NSPanel {

    // Allow the panel to become the key window so text fields inside it work.
    override var canBecomeKey: Bool { true }

    // Intercept every click: make the panel key before SwiftUI processes the
    // event, so @FocusState and text field input work in a nonactivatingPanel.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown, !isKeyWindow {
            NSApp.activate(ignoringOtherApps: true)
            makeKey()
        }
        super.sendEvent(event)
    }

    let remindersManager = RemindersManager()
    private let settings = AppSettings.shared
    private var panelVisible = false
    private var cancellables = Set<AnyCancellable>()

    convenience init() {
        // Start with the real off-screen frame so NSHostingView is never
        // created at zero size — a zero-frame first layout pass confuses
        // SwiftUI and causes layout recursion / EXC_BAD_ACCESS.
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let s = AppSettings.shared
        let sf = screen.frame
        let w = s.panelWidth
        let h = sf.height * CGFloat(s.panelHeightFraction)
        let y = sf.minY + (sf.height - h) / 2
        let offscreen = NSRect(x: sf.maxX, y: y, width: w, height: h)

        self.init(contentRect: offscreen,
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

        let blur = NSVisualEffectView()
        blur.material = .sidebar
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 14

        // Pass AppSettings as an environment object alongside RemindersManager
        // so every child view uses @EnvironmentObject (one subscription, not many).
        let hosting = NSHostingView(rootView:
            ContentView()
                .environmentObject(remindersManager)
                .environmentObject(AppSettings.shared)
                .environmentObject(PanelNavigation.shared)
        )
        hosting.translatesAutoresizingMaskIntoConstraints = false
        hosting.sizingOptions = []   // prevent re-entrant setContentSize during layout
        blur.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: blur.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: blur.bottomAnchor)
        ])
        contentView = blur

        // Live-resize when sliders change — deferred to next run-loop
        // so setFrame never fires synchronously inside a SwiftUI layout pass.
        Publishers.Merge(
            settings.$panelWidth.map { _ in () },
            settings.$panelHeightFraction.map { _ in () }
        )
        .dropFirst()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            DispatchQueue.main.async {
                guard let self, self.panelVisible else { return }
                self.setFrame(self.visibleRect(), display: true)
            }
        }
        .store(in: &cancellables)

        orderFrontRegardless()
    }

    // MARK: - Frame helpers

    private func visibleRect() -> NSRect {
        let s = NSScreen.main ?? NSScreen.screens[0]
        let sf = s.frame
        let w = settings.panelWidth
        let h = sf.height * CGFloat(settings.panelHeightFraction)
        let y = sf.minY + (sf.height - h) / 2
        return NSRect(x: sf.maxX - w, y: y, width: w, height: h)
    }

    private func offscreenRect() -> NSRect {
        let s = NSScreen.main ?? NSScreen.screens[0]
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

import SwiftUI
import EventKit
import UniformTypeIdentifiers

enum SidebarSelection: Hashable {
    case today
    case scheduled
    case all
    case flagged
    case list(String) // calendarIdentifier
}

struct ContentView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var nav: PanelNavigation
    @State private var selection: SidebarSelection = .today

    // Sidebar drag state
    @State private var sidebarDragging = false
    @State private var sidebarDragStartWidth: CGFloat = 0

    // Panel edge drag state
    @State private var panelDragging = false
    @State private var panelDragStartWidth: CGFloat = 0

    // Email drag-drop
    @State private var isMailDropTargeted = false

    var body: some View {
        ZStack(alignment: .leading) {
            if nav.isShowingForm {
                InlineReminderFormView()
                    .environmentObject(manager)
                    .environmentObject(settings)
                    .environmentObject(nav)
                    .transition(.move(edge: .trailing))
            } else {
                mainLayout
                    .transition(.move(edge: .leading))
            }
            if !nav.isShowingForm {
                panelResizeHandle
            }
        }
        .background(.clear)
        .animation(.easeInOut(duration: 0.2), value: nav.isShowingForm)
        .task {
            await manager.requestAccess()
        }
    }

    // MARK: - Main layout

    private var mainLayout: some View {
        HStack(spacing: 0) {
            SidebarListView(selection: $selection)
                .environmentObject(manager)
                .frame(width: settings.sidebarWidth)

            sidebarDivider

            detailView
                .environmentObject(manager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .center) {
                    if isMailDropTargeted {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor, lineWidth: 2)
                            .background(Color.accentColor.opacity(0.08).cornerRadius(12))
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "envelope.badge.fill")
                                        .font(.system(size: 32))
                                    Text("Drop to link this email")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.accentColor)
                            }
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                }
                .onDrop(of: [UTType.url], isTargeted: $isMailDropTargeted) { providers in
                    handleEmailDrop(providers)
                }
        }
    }

    // MARK: - Sidebar divider (internal resize handle)

    private var sidebarDivider: some View {
        Color(NSColor.separatorColor)
            .frame(width: 1)
            .background(Color.clear.contentShape(Rectangle().inset(by: -4)))
            .onHover { hovering in
                if hovering { NSCursor.resizeLeftRight.push() }
                else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        if !sidebarDragging {
                            sidebarDragging = true
                            sidebarDragStartWidth = settings.sidebarWidth
                        }
                        settings.sidebarWidth = max(120, min(240,
                            sidebarDragStartWidth + value.translation.width))
                    }
                    .onEnded { _ in sidebarDragging = false }
            )
    }

    // MARK: - Panel left-edge resize handle

    private var panelResizeHandle: some View {
        Color.clear
            .frame(width: 6)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering { NSCursor.resizeLeftRight.push() }
                else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .global)
                    .onChanged { value in
                        if !panelDragging {
                            panelDragging = true
                            panelDragStartWidth = settings.panelWidth
                        }
                        // Drag left = panel gets wider
                        let delta = value.startLocation.x - value.location.x
                        settings.panelWidth = panelDragStartWidth + delta
                    }
                    .onEnded { _ in panelDragging = false }
            )
    }

    // MARK: - Email drag-drop

    private func handleEmailDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first,
              provider.canLoadObject(ofClass: URL.self) else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url = url, url.scheme == "message" else { return }
            DispatchQueue.main.async {
                let cal: EKCalendar? = {
                    switch selection {
                    case .list(let id): return manager.lists.first { $0.calendarIdentifier == id }
                    default: return nil
                    }
                }()
                nav.openNew(calendar: cal, mailURL: url)
            }
        }
        return true
    }

    // MARK: - Detail view switcher

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .today:      TodayView()
        case .scheduled:  ScheduledView()
        case .all:        AllRemindersView()
        case .flagged:    FlaggedView()
        case .list(let id): ListDetailView(calendarIdentifier: id)
        }
    }
}

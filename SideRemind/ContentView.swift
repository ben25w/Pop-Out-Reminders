import SwiftUI

enum SidebarSelection: Hashable {
    case today
    case scheduled
    case all
    case flagged
    case list(String) // calendarIdentifier
}

struct ContentView: View {
    @EnvironmentObject var manager: RemindersManager
    @StateObject private var settings = AppSettings.shared
    @State private var selection: SidebarSelection = .today

    // Sidebar drag state
    @State private var sidebarDragging = false
    @State private var sidebarDragStartWidth: CGFloat = 0

    // Panel edge drag state
    @State private var panelDragging = false
    @State private var panelDragStartWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            mainLayout
            panelResizeHandle
        }
        .background(.clear)
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

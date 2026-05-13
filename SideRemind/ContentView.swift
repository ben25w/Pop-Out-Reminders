import SwiftUI
import EventKit

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
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.96))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                            }
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
                    // AppKit overlay handles the actual drop — SwiftUI's onDrop
                    // can't load com.apple.mail.email from NSItemProvider.
                    MailDropOverlay(
                        onMailDrop: { payload in
                            let cal: EKCalendar? = {
                                switch selection {
                                case .list(let id): return manager.lists.first { $0.calendarIdentifier == id }
                                default: return nil
                                }
                            }()
                            let dueDate: Date? = {
                                switch selection {
                                case .today: return Date()
                                default: return nil
                                }
                            }()
                            nav.openNew(
                                calendar: cal,
                                dueDate: dueDate,
                                title: payload.subject,
                                mailURL: payload.url
                            )
                        },
                        isTargeted: $isMailDropTargeted
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

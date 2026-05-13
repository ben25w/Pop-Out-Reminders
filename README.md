# Pop Out Reminders

A free, open-source macOS sidebar for Apple Reminders. Move your mouse to the right edge of the screen and your reminders pop out in a frosted glass panel — no Dock icon, no app switching.

Built as a free alternative to [Side Reminder](https://sidereminder.com).

---

## ⬇️ Download

**[Click here to download the latest version (v1.5.2)](https://github.com/ben25w/Pop-Out-Reminders/releases/latest/download/PopOutReminders-v1.5.2.dmg)**

> **First time opening?** If macOS blocks the app: right-click the app → **Open** → **Open**. This is normal for apps not distributed through the App Store.

---

## Features

- **Mouse-edge trigger** — move your cursor to the right edge of the screen to reveal the panel; move away to hide it
- **Inline add & edit form** — tap any reminder or the + button to open the full form right inside the panel — no floating window
- **Quick add bar** — type a reminder title at the bottom of any view and press Return to add it instantly
- **Today view** — shows all reminders due today (including overdue); new reminders auto-fill with today's date and time
- **Smart lists** — Today, Scheduled, and All
- **All your lists** — colour-coded with your Reminders list colours
- **Priority** — set Low, Medium, or High priority on any reminder; shown as ! marks on the row
- **Drag to reschedule** — in Scheduled view, drag a reminder from one day to another to change its due date
- **Mail deep links** — reminders linked to an email show an envelope icon; click to jump straight to that message in Mail
- **Right-click shortcuts** — quickly reschedule to Tomorrow, This Weekend, or Next Week from the context menu
- **Default list setting** — choose which list new reminders default to (Settings)
- **Show completed items** — toggle to show completed reminders at the bottom of each list (Settings)
- **Resizable panel** — drag the left edge of the panel to make it wider or narrower
- **Hide and reorder lists** — tap the gear icon in the sidebar to hide lists you don't need or drag to reorder them
- **Lives in the menu bar** — no Dock icon; quit from the menu bar icon

---

## Requirements

- macOS 14 Sonoma or later
- Xcode 15 or later (to build from source)

---

## Usage tips

| Action | How |
|---|---|
| Show panel | Move mouse to right screen edge |
| Hide panel | Move mouse away from the panel |
| Add reminder | Click **+** in the header, or type in the bar at the bottom |
| Edit reminder | Tap any reminder row |
| Complete reminder | Click the circle on the left |
| Delete reminder | Right-click the reminder → Delete |
| Reschedule quickly | Right-click → Tomorrow / This Weekend / Next Week |
| Drag to reschedule | Drag a reminder to a different day in Scheduled view |
| Open linked email | Click the envelope icon on a reminder |
| Resize panel width | Drag the left edge of the panel |
| Hide / reorder lists | Click the gear icon at the bottom of the sidebar |
| Settings | Click the menu bar icon → Settings |
| Quit | Click the menu bar icon → Quit |

---

## Building from source

1. Install [xcodegen](https://github.com/yonaskolb/XcodeGen):
   ```
   brew install xcodegen
   ```
2. Clone the repo:
   ```
   git clone https://github.com/ben25w/Pop-Out-Reminders.git
   cd Pop-Out-Reminders
   ```
3. Generate the Xcode project:
   ```
   cd SideRemind
   xcodegen generate
   ```
4. Open `PopOutReminders.xcodeproj` in Xcode and press **⌘R**

---

## First run

On first launch macOS will ask for Reminders permission — grant it and your lists will appear immediately.

If macOS blocks the app because it's not from the App Store: right-click the app → **Open** → **Open**.

---

## Known limitations

- **Sections within a list** are not accessible through Apple's public EventKit API — this is an Apple limitation that affects all third-party apps
- App is not notarised, so macOS Gatekeeper will block it on first open (use right-click → Open to bypass)

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the current next-step plan.

---

## License

MIT — free to use, modify, and distribute.

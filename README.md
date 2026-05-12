# Pop Out Reminders

A free, open-source macOS sidebar for Apple Reminders. Move your mouse to the right edge of the screen and your reminders pop out in a frosted glass panel — no Dock icon, no app switching.

Built as a free alternative to [Side Reminder](https://sidereminder.com).

---

## Features

- **Mouse-edge trigger** — move your cursor to the right edge of the screen to reveal the panel; move away to hide it
- **Today view** — shows today's date and all reminders due today; new reminders auto-fill with today's date
- **All your lists** — colour-coded with your Reminders list colours
- **Smart lists** — Today, Scheduled, Flagged, and All
- **Double-click to add** — double-click anywhere in the empty area of a list to create a new reminder for that list
- **Resizable panel** — drag the left edge of the panel to make it wider or narrower
- **Resizable sidebar** — drag the divider between your lists and the reminders to resize
- **Hide and reorder lists** — tap the gear icon in the sidebar to hide lists you don't need or drag to reorder them; preferences are saved
- **Add reminders** — title, notes, due date, and list picker; defaults to the list you're currently viewing
- **Complete and delete reminders** — tap the circle to complete; right-click to delete
- **Lives in the menu bar** — no Dock icon; quit from the menu bar icon

---

## Requirements

- macOS 14 Sonoma or later
- Xcode 15 or later (to build from source)

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

## Usage tips

| Action | How |
|---|---|
| Show panel | Move mouse to right screen edge |
| Hide panel | Move mouse away from the panel |
| Add reminder | Click **+** in the header, or **double-click** in empty space |
| Complete reminder | Click the circle on the left |
| Delete reminder | Right-click the reminder → Delete |
| Resize panel width | Drag the left edge of the panel |
| Resize sidebar | Drag the divider between lists and reminders |
| Hide / reorder lists | Click the gear icon at the bottom of the sidebar |
| Quit | Click the menu bar icon → Quit |

---

## Known limitations

- **Sections within a list** are not accessible through Apple's public EventKit API — this is an Apple limitation that affects all third-party apps
- App is not notarised, so macOS Gatekeeper will block it on first open (use right-click → Open to bypass)

---

## License

MIT — free to use, modify, and distribute.

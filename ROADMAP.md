# Pop Out Reminders Roadmap

This is the working plan for the next public branch of Pop Out Reminders.

## Current Release

- v1.5.0 improves Mail drag-to-create-reminder so dragging an Apple Mail message onto the panel opens the inline reminder form with the email attached.
- Keep the existing Mail deep-link behavior: saved reminders with `message://` URLs should show an envelope icon and open the original message in Mail.
- Mail drops try to prefill the reminder title from the email subject, and drops onto Today preselect today's date.

## Next Implementation Steps

1. Verify the AppKit `MailDropNSView` receives `draggingEntered`, `prepareForDragOperation`, and `performDragOperation` callbacks.
2. Inspect all pasteboard types provided by Apple Mail and parse a usable `message://` URL when one is present.
3. Keep normal reminder clicks and editing working while the transparent drop target is active.
4. Add a fallback email-link workflow if Mail drag data is not reliable on recent macOS versions.
5. Delete unused legacy add-reminder code once the inline form is fully confirmed.
6. Cut future releases with an updated DMG and README download link after changes are verified.

## Future Improvements

- Search across reminder titles and notes.
- Recurring reminder controls.
- Always-visible Flagged smart list.
- Optional panel height setting.
- Multi-screen edge detection.
- Notarised release build if an Apple Developer account is available.

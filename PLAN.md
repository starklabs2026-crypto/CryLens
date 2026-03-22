# Gate the app by sign-in and keep each user’s history separate

**Features**
- [x] Show the sign-in screen before the main app for signed-out users.
- [x] Open the main app automatically after a successful sign-in.
- [x] Keep cry analysis history separate for each signed-in person.
- [x] Add a sign-out action from the history screen with a confirmation prompt.

**Design**
- Keep the current dark, native iPhone look and existing app styling.
- Use a standard destructive confirmation for signing out so the action feels clear and safe.
- Preserve the current tab layout and overall flow.

**Pages / Screens**
- [x] **Launch flow**: Decide between the sign-in screen and the main app based on whether the user is signed in.
- [x] **History screen**: Add a top-right sign-out button and a confirmation alert before signing out.
- [x] **Saved history**: Store each person’s analysis history in their own private app data file so accounts do not mix.

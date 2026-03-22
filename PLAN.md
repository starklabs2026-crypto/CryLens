# Add account session management

**Features**
- [x] Keep track of whether the user is signed in or signed out.
- [x] Remember an existing signed-in session when the app opens.
- [x] Support creating an account with email and password.
- [x] Support signing in with email and password.
- [x] Support signing out and clearing the current account state.
- [x] Support sending a password reset email.
- [x] Show clear validation messages for invalid email or short passwords.
- [x] Show loading state while account actions are in progress.

**Design**
- [x] No visual redesign is included in this change.
- [x] This is a behind-the-scenes account layer that existing screens can use.
- [x] Error messages will stay simple and user-friendly.

**Pages / Screens**
- [x] No new screens in this step.
- [x] Existing screens will be able to read account state once this is added.

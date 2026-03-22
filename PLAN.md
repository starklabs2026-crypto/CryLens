# Add a polished authentication flow before the main app

**Features**
- [x] Show a dedicated sign-in screen before anyone can access the main app.
- [x] Let people enter their email and password to sign in.
- [x] Show a loading state on the main action while sign-in is in progress.
- [x] Show a clear alert when sign-in fails, with a simple OK action to dismiss it.
- [x] Add a Sign Up flow so new users can create an account without leaving the app.
- [x] Add a Forgot Password flow so users can request a reset email.
- [x] Open the main listening and history experience automatically after a successful sign-in.

**Design**
- [x] Use a dark, refined background that matches the app’s current premium look.
- [x] Keep the top area minimal with the waveform symbol, app name, and a quiet supporting line.
- [x] Style the email and password fields with soft translucent surfaces for a modern iOS feel.
- [x] Make the primary sign-in action full-width, bold, and high-contrast.
- [x] Keep secondary actions understated and elegant so the main action stays visually dominant.
- [x] Use generous spacing, subtle depth, and clean typography for an upscale feel.

**Pages / Screens**
- [x] **Sign In**: Branded welcome screen with email, password, forgot password, and sign-in action.
- [x] **Sign Up**: Simple account creation screen with the same visual style as sign-in.
- [x] **Forgot Password**: Lightweight reset screen focused on entering an email and sending reset instructions.
- [x] **Main App**: Existing listening and history experience shown only after authentication.

**Behavior**
- [x] Present Sign Up and Forgot Password as modal screens from the sign-in screen.
- [x] Keep the experience smooth so users can dismiss those screens and return to sign-in easily.
- [x] Preserve the signed-in state so returning users go straight into the app when already logged in.
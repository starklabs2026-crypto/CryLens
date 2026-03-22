# Add Profile Tab, Clean Up Auth Routing, and Polish Views

**Changes Overview**

This update adds a Profile tab, removes duplicate auth logic, and polishes the sign-in/sign-up screens.

**Features**
- New **Profile** tab showing your account email, usage stats (total analyses, this week's count, most common cry reason), and a Sign Out button
- Sign Out moved from the History toolbar to the Profile tab for a cleaner layout
- Simplified app routing — no more duplicate auth checks

**Design**
- Profile screen uses a native grouped list style with an avatar circle, account info, stats section, and a red Sign Out button
- Sign-in subtitle changed to *"Your baby's voice, understood."*
- Sign-up subtitle changed to *"Save your cry history and track your baby's patterns over time."*
- A small privacy note added at the bottom of the sign-in form: *"Your data is stored securely and never shared."*

**Screens**
- **Listen tab** — unchanged
- **History tab** — Sign Out button removed from toolbar (clear history button remains)
- **Profile tab** (new) — account info, stats, and Sign Out
- **Sign In / Sign Up** — updated subtitle text and privacy note

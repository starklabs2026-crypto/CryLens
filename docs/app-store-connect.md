# CryLens App Store Connect Setup

This file captures the current production-facing values for CryLens.

## App Information

- App name: `CryLens`
- Bundle ID: `com.starklabs.crylens`
- Primary language: `English (U.S.)`
- Category: `Medical`
- Secondary category: `Lifestyle`
- Age rating guidance:
  - No explicit content
  - No gambling
  - No unrestricted web access
  - No user-generated public content

## App Description

### Subtitle

Understand every baby cry

### Promotional Text

CryLens helps parents record, analyse, and track baby cries with AI-powered insights, cry history, and subscription-based Pro features.

### Full Description

CryLens helps parents understand crying patterns faster.

Record your baby's cry, import an audio clip, and get an AI-assisted cry category with confidence scoring and history tracking. CryLens is designed to make it easier to spot patterns over time and keep important moments organised in one place.

Features:
- Record and analyse baby cries
- Import audio clips for analysis
- Track cry history by baby profile
- View cry trends and summary stats
- Sign in with email, Google, or Apple
- Restore purchases and manage CryLens Pro access

CryLens is not a medical device and does not replace professional medical advice.

### Keywords

baby cry,newborn,parenting,baby tracker,infant,cry analyser,feeding,sleep,baby monitor

## Support And Legal URLs

- Marketing URL: `https://starklabs2026-crypto.github.io/CryLens/support.html`
- Support URL: `https://starklabs2026-crypto.github.io/CryLens/support.html`
- Privacy Policy URL: `https://starklabs2026-crypto.github.io/CryLens/privacy.html`
- Terms of Use URL: `https://starklabs2026-crypto.github.io/CryLens/terms.html`

These GitHub Pages URLs were verified live on `2026-04-26`.

## Screenshot Assets

Generated App Store screenshots live in `artifacts/appstore-screenshots/`.

### iPhone 6.5"

- `iphone-record.png`
- `iphone-history.png`
- `iphone-profile.png`
- `iphone-settings-account.png`
- `iphone-paywall.png`

### iPad 13"

- `ipad-record.png`
- `ipad-history.png`
- `ipad-profile.png`
- `ipad-settings-account.png`
- `ipad-paywall.png`

Notes:
- `iphone-settings-account.png` and `ipad-settings-account.png` both show the account deletion entry as a small, visible destructive action.
- `iphone-paywall.png` is the cleanest paywall screenshot for App Review reference.
- `ipad-paywall.png` is acceptable for internal submission records, but the iPhone paywall image is the stronger merchandising asset.

## Subscription Products

### Subscription Group

- Reference name: `CryLens Pro`

### Products

1. Weekly
- Product ID: `crysense_pro_monthly`
- Reference name: `CryLens Pro Weekly`
- Display name: `CryLens Pro Weekly`
- Description: `Full access to CryLens Pro features, billed weekly.`
- Duration: `1 week`
- Price: `$9.99`
- Introductory offer: none
- Note: the product ID says `monthly`, but App Store Connect now shows this subscription as `1 week`. Keep it if this is the product you created; users do not see the product ID.

2. Yearly
- Product ID: `crysense_pro_yearly`
- Reference name: `CryLens Pro Yearly`
- Display name: `CryLens Pro Yearly`
- Description: `Full access to CryLens Pro features, billed yearly.`
- Duration: `1 year`
- Price: `$49.99`
- Introductory offer: `7 days free`, yearly plan only

### Current In-App Pricing Used In App Copy

- Weekly: `$9.99 / week`
- Yearly: `$49.99 / year`
- Yearly discount math:
  - Weekly annualized cost: `$9.99 * 52 = $519.48`
  - Savings with yearly: `$519.48 - $49.99 = $469.49`
  - Discount: `$469.49 / $519.48 = 90.38%`
  - App-facing copy: `Save 90%`

If you choose different App Store prices, update the paywall copy in the iOS app.

## RevenueCat Mapping

- RevenueCat iOS public SDK key: read from `RevenueCatAPIKey` in `Info.plist`
- Entitlement ID: `pro`
- Default offering packages expected by the paywall:
  - `$rc_weekly`
  - `$rc_annual`

Map them like this in RevenueCat:

- Entitlement `pro`
- Offering `default` or current offering
- Package `$rc_weekly` -> `crysense_pro_monthly`
- Package `$rc_annual` -> `crysense_pro_yearly`

## App Store Connect Submission Values

### Pricing And Availability

- App price: `Free`
- Availability: all intended launch countries/regions unless there is a legal reason to restrict.
- In-app purchases/subscriptions: submit both subscriptions with the app version.
- If App Store Connect keeps the existing product ID `crysense_pro_monthly`, that is OK as long as the duration is `1 week`, the reference/display name says weekly, and RevenueCat maps it to `$rc_weekly`.

### App Privacy

Use the privacy policy as the final source of truth. Based on the current app and backend:

- Data collected: `Contact Info` (email/name), `User Content` (audio recordings, notes), `Identifiers` (account IDs/sign-in IDs), `Purchases` (subscription entitlement/status), and `Other Data` or `Health & Fitness` only if Apple requires baby profile/cry history to be classified there.
- Data linked to user: yes, for account, baby profile, cry history, audio, and subscription status.
- Data used for tracking: no, unless third-party ad or cross-app tracking SDKs are added later.
- Third-party advertising: no.
- Data shared with third-party services for processing: yes, backend/auth/storage/subscription/AI providers process data to operate the app.

### App Review Notes

Use this note if App Review asks how to test subscriptions:

`CryLens includes CryLens Pro auto-renewable subscriptions. Use the paywall from the app after signing in. The weekly product is $9.99/week with no free trial. The yearly product is $49.99/year with a 7-day free trial. CryLens is not a medical device and does not replace professional medical advice.`

If reviewer credentials are required, create a temporary test account and add it in App Review Information before submission.

## Sandbox Testing Checklist

1. In App Store Connect, create the two auto-renewable subscriptions above.
2. Make sure both are in the same subscription group.
3. In RevenueCat, attach both products to the `pro` entitlement.
4. On the test iPhone, sign out of the real App Store account if needed and use a Sandbox tester account when prompted by StoreKit.
5. Build and run the app on a physical iPhone.
6. Open the paywall and confirm products load.
7. Purchase weekly and verify the `pro` entitlement becomes active.
8. Use Restore Purchases and verify access remains active.
9. Cancel or expire the sandbox subscription and verify entitlement removal after sandbox renewal timing.
10. Purchase yearly with a fresh sandbox tester and verify the 7-day trial is shown before confirmation.

## Release Notes Draft

Understand your baby's cries with AI-assisted analysis, audio import, cry history, and subscription-based Pro features.

## Readiness Snapshot (2026-04-26)

### Ready

- iOS simulator build passes.
- iOS simulator tests pass.
- GitHub Pages support, privacy, and terms pages are live.
- App Store screenshot set exists for iPhone and iPad.
- Account deletion is visible in settings and baby deletion exists in the edit-baby flow.
- Paywall copy matches current pricing targets:
  - Weekly: `$9.99 / week`
  - Yearly: `$49.99 / year`
  - Trial: `7 days free` on yearly only
  - Discount copy: `Save 90%`

### Not Ready / Blockers

- Production backend is not stable enough to submit yet.
- Live smoke test on `2026-04-26` returned `502` for:
  - `/health`
  - `/auth/register`
  - `/babies`
  - `/analysis/history`
- Until production API is stable again, end-to-end verification is still incomplete for:
  - email auth
  - Google sign-in
  - Apple sign-in
  - live baby CRUD
  - history loading from backend
  - subscription entitlement checks after purchase

### Final Steps Before Submission

1. Fix the Railway/Supabase production backend instability until all core endpoints return success.
2. Run physical-device verification for email, Google, and Apple sign-in.
3. Complete Sandbox purchase testing for weekly and yearly products.
4. Create the archive build in Xcode and validate it in Organizer.
5. Fill App Review Information with reviewer notes and, if needed, a temporary review account.

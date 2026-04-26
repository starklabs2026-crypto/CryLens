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

## Subscription Products

### Subscription Group

- Reference name: `CryLens Pro`

### Products

1. Monthly
- Product ID: `crylens_pro_monthly`
- Reference name: `CryLens Pro Monthly`
- Display name: `CryLens Pro Monthly`
- Description: `Full access to CryLens Pro features, billed monthly.`
- Duration: `1 month`

2. Yearly
- Product ID: `crylens_pro_yearly`
- Reference name: `CryLens Pro Yearly`
- Display name: `CryLens Pro Yearly`
- Description: `Full access to CryLens Pro features, billed yearly.`
- Duration: `1 year`

### Current In-App Pricing Used In App Copy

- Monthly: `$4.99 / month`
- Yearly: `$19.99 / year`

If you choose different App Store prices, update the paywall copy in the iOS app.

## RevenueCat Mapping

- RevenueCat iOS public SDK key: read from `RevenueCatAPIKey` in `Info.plist`
- Entitlement ID: `pro`
- Default offering packages expected by the paywall:
  - `$rc_monthly`
  - `$rc_annual`

Map them like this in RevenueCat:

- Entitlement `pro`
- Offering `default` or current offering
- Package `$rc_monthly` -> `crylens_pro_monthly`
- Package `$rc_annual` -> `crylens_pro_yearly`

## Sandbox Testing Checklist

1. In App Store Connect, create the two auto-renewable subscriptions above.
2. Make sure both are in the same subscription group.
3. In RevenueCat, attach both products to the `pro` entitlement.
4. On the test iPhone, sign out of the real App Store account if needed and use a Sandbox tester account when prompted by StoreKit.
5. Build and run the app on a physical iPhone.
6. Open the paywall and confirm products load.
7. Purchase monthly and verify the `pro` entitlement becomes active.
8. Use Restore Purchases and verify access remains active.
9. Cancel or expire the sandbox subscription and verify entitlement removal after sandbox renewal timing.

## Release Notes Draft

Understand your baby's cries with AI-assisted analysis, audio import, cry history, and subscription-based Pro features.

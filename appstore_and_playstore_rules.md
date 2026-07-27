# APP STORE & GOOGLE PLAY DEVELOPMENT RULES
Version: 2026

---

# PURPOSE

This document defines mandatory requirements that MUST be respected while developing this Flutter application.

Whenever a feature is generated, modified, or refactored, the implementation MUST comply with:

- Apple App Store Review Guidelines
- Apple Human Interface Guidelines
- Apple Privacy Requirements
- Apple Developer Program License Agreement
- Google Play Developer Program Policies
- Google Play Developer Distribution Agreement
- Google Play User Data Policy
- Google Play Families Policy
- Google Play Payments Policy
- Android Compatibility Definition
- Android Security Best Practices
- Flutter Best Practices

Whenever this document conflicts with generated code, THIS DOCUMENT ALWAYS WINS.

---

# GENERAL RULES

Never generate code that can lead to App Store rejection.

Never generate code that can lead to Google Play rejection.

Always prefer official Flutter APIs.

Never use deprecated APIs.

Always target the latest stable Flutter SDK.

Always support Android and iOS.

Always write production-ready code.

Never generate placeholder security logic.

Never hardcode secrets.

Never expose API keys.

Never store tokens in plaintext.

Always use HTTPS.

Reject any insecure HTTP connection unless explicitly required for localhost development.

---

# FLUTTER REQUIREMENTS

Use

- Material 3
- Cupertino widgets where appropriate
- Responsive layouts
- Dark Mode
- Light Mode
- Accessibility
- Internationalization
- Localization
- High DPI assets

Support

Android

iOS

Tablets

Foldables

Landscape when appropriate

---

# APP PERFORMANCE

The app must

Start quickly

Avoid frame drops

Maintain 60 FPS minimum

Dispose controllers

Dispose streams

Dispose animations

Avoid memory leaks

Avoid unnecessary rebuilds

Lazy load lists

Cache network images

Compress assets

Optimize images

Optimize network calls

Minimize battery consumption

Minimize CPU usage

Minimize RAM usage

Avoid blocking UI thread

Use isolates for heavy work

---

# ACCESSIBILITY

Everything must be accessible.

Provide semantic labels.

Provide screen reader support.

Support VoiceOver.

Support TalkBack.

Support Dynamic Type.

Support larger fonts.

Support keyboard navigation.

Support high contrast.

Support reduced motion.

Do not rely only on color.

Touch targets must be large enough.

---

# PRIVACY

Collect the minimum amount of user data.

Only collect data required for the feature.

Never collect hidden information.

Never fingerprint devices.

Never access contacts without user consent.

Never access location without user consent.

Never access photos without permission.

Never access microphone without permission.

Never access camera without permission.

Never access Bluetooth without permission.

Never access calendar without permission.

Never access health data without permission.

Never request unnecessary permissions.

Always explain permission usage before requesting it.

Provide a Privacy Policy.

Provide Terms of Service.

Support account deletion.

Support data export when user accounts exist.

Support user consent management.

---

# PERMISSIONS

Every permission must have

A real use case

A user-facing explanation

Graceful denial handling

Retry handling

Settings redirect

No fake permission dialogs

---

# SECURITY

Never expose secrets.

Never expose passwords.

Never expose API keys.

Never expose private endpoints.

Always validate server responses.

Always sanitize user input.

Escape HTML.

Escape Markdown.

Prevent SQL Injection.

Prevent XSS.

Prevent CSRF where applicable.

Prevent replay attacks.

Prevent token leakage.

Store secrets securely.

Use secure storage.

Validate JWT expiration.

Refresh expired tokens.

Use certificate pinning where applicable.

---

# AUTHENTICATION

Support

Login

Logout

Password reset

Email verification

Session expiration

Refresh tokens

Secure storage

Apple Sign In when required

Google Sign In when appropriate

Do not require unnecessary account creation.

Guest mode should exist when possible.

---

# APP STORE LOGIN RULES

If third-party login exists

Apple Sign In must also exist
unless Apple's exceptions apply.

Never violate Apple's login policy.

---

# PAYMENTS

Digital content

Use Apple In-App Purchases.

Use Google Play Billing.

Do not bypass billing.

Do not advertise cheaper external purchases.

Do not redirect users around store billing.

Physical goods

External payments allowed.

Subscriptions

Must use platform billing.

Restore purchases.

Handle billing failures gracefully.

---

# ADS

Ads must

Be clearly identifiable.

Not interfere with navigation.

Not mimic system dialogs.

Not force accidental clicks.

Respect children's policies.

Respect consent requirements.

Respect GDPR.

Respect CCPA.

Respect ATT.

---

# USER GENERATED CONTENT

Must provide

Report

Block

Mute

Moderation

Terms

Privacy Policy

Content removal

Abuse detection

---

# AI FEATURES

Clearly disclose AI-generated content where appropriate.

Do not impersonate humans.

Do not generate illegal content.

Do not generate copyrighted material.

Do not violate privacy.

Do not mislead users.

Provide reporting mechanisms.

---

# NOTIFICATIONS

Notifications must

Provide value

Be user controlled

Support opt-out

Not spam

Not advertise excessively

Respect quiet hours when applicable

---

# LOCATION

Only request when required.

Support

Approximate

Precise

Background only if justified.

Explain why location is needed.

---

# CAMERA

Explain usage.

Handle denial.

Do not continuously record.

---

# MICROPHONE

Explain usage.

Stop recording immediately when finished.

---

# PHOTO LIBRARY

Only access selected photos when possible.

Support modern Android Photo Picker.

Support iOS Limited Library.

---

# FILES

Only access files selected by users.

Never scan storage.

---

# DATA STORAGE

Encrypt sensitive information.

Use

flutter_secure_storage

Encrypted databases

Keychain

Android Keystore

Never store passwords.

---

# NETWORK

Use HTTPS.

Retry transient failures.

Handle offline mode.

Support caching.

Support timeouts.

Support exponential backoff.

---

# CRASH HANDLING

Never crash intentionally.

Catch exceptions.

Log errors.

Report crashes.

Provide graceful fallback.

---

# UI

Professional.

Consistent.

Responsive.

No placeholder text.

No lorem ipsum.

No clipped text.

No overflowing layouts.

No pixel overflow.

Support RTL.

Support localization.

---

# APP ICON

Unique.

No copyrighted material.

No misleading branding.

High resolution.

---

# SPLASH SCREEN

Fast.

No unnecessary delay.

---

# STORE LISTING

Must include

Privacy Policy

Description

Keywords

Screenshots

Feature graphic

Promotional text

Support URL

Marketing URL if available

Age rating

Content declaration

Data Safety

Privacy Nutrition Labels

---

# CONTENT

No pornography.

No hate speech.

No illegal activity.

No malware.

No spyware.

No misleading claims.

No fake functionality.

No deceptive subscriptions.

No hidden features.

No cryptocurrency mining.

No unauthorized downloads.

No piracy.

---

# CHILDREN

Comply with

COPPA

Families Policy

Age-appropriate design

No personalized ads when prohibited.

---

# MEDICAL

Do not provide medical diagnosis.

Clearly disclose limitations.

Provide disclaimers.

---

# FINANCIAL

Do not misrepresent financial information.

Secure sensitive data.

Follow applicable regulations.

---

# LEGAL

Respect

Copyright

Trademark

Patent

Licensing

Open-source licenses

Privacy laws

GDPR

CCPA

Apple policies

Google policies

---

# TESTING

Every feature must have

Unit tests

Widget tests

Integration tests

Error handling

Offline testing

Permission testing

Dark mode testing

Accessibility testing

---

# RELEASE CHECKLIST

Before release verify

✓ No debug logs
✓ No TODOs
✓ No test API keys
✓ Release signing
✓ Version updated
✓ Build number updated
✓ Privacy policy exists
✓ Terms exist
✓ Icons correct
✓ Screenshots correct
✓ Permissions justified
✓ Data Safety complete
✓ Privacy Labels complete
✓ Crash free
✓ Performance tested
✓ Accessibility tested
✓ Localization tested
✓ Billing tested
✓ Sign In tested
✓ Notifications tested

---

# WHEN GENERATING CODE

Claude must always ask

"Would this implementation violate any Apple or Google Play policy?"

If yes

Generate a compliant implementation instead.

---

# OFFICIAL REFERENCES

Always prefer the official documentation over blogs.

Apple
https://developer.apple.com/app-store/review/guidelines/

Apple HIG
https://developer.apple.com/design/human-interface-guidelines/

Google Play Policies
https://play.google.com/about/developer-content-policy/

Google Play Console Help
https://support.google.com/googleplay/android-developer

Android Developers
https://developer.android.com

Flutter
https://docs.flutter.dev

---

End of document.
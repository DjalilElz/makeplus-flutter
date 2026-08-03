# Shipping MakePlus to Google Play

Actionable release checklist. For the *policy* rules that govern how code is
written, see `appstore_and_playstore_rules.md` — this file is the "how do I
actually ship it" companion, not a replacement.

Status legend: ✅ done in-repo · ⬜ you must do it · ⚠️ decision needed

---

## 1. Already compliant (verified in-repo)

| Requirement | Value | |
|---|---|---|
| `targetSdk` / `compileSdk` | 36 | ✅ meets Play's API-36 requirement |
| `minSdk` | 24 (Android 7.0) | ✅ |
| App Bundle (`.aab`) output | supported | ✅ Play requires AAB, not APK |
| 64-bit ABIs | via Flutter | ✅ |
| HTTPS-only | `network_security_config.xml`, `cleartextTrafficPermitted="false"` | ✅ |
| User-installed CAs distrusted | no `<certificates src="user" />` | ✅ blocks MITM proxies |
| Tokens at rest | `EncryptedSharedPreferences` (AES256-GCM) | ✅ see `lib/data/services/secure_storage.dart` |
| Passwords at rest | **never stored** — only sent as a POST body | ✅ |
| Secrets in source | none found | ✅ |
| Release logging | `AppLogger` + Dio `LogInterceptor` both gated on `kDebugMode` | ✅ no token leaks in release |
| Permissions | `INTERNET`, `CAMERA` (`required=false`) only | ✅ storage perms deliberately removed |
| Code shrinking | R8 + resource shrinking + ProGuard rules | ✅ |
| In-app account deletion | Settings → *Supprimer mon compte* | ✅ (but see §4) |
| `flutter analyze` | clean | ✅ |

---

## 2. ⬜ Generate the upload keystore

Without this, `flutter build appbundle --release` **silently signs with debug
keys** and Play will reject the upload. `android/app/build.gradle` prints a
warning when it falls back.

From the `android/` directory:

```bash
keytool -genkey -v -keystore upload-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then copy `android/key.properties.example` → `android/key.properties` and fill
in the real values:

```properties
storeFile=../upload-keystore.jks
storePassword=<your password>
keyAlias=upload
keyPassword=<your password>
```

> **Back up the `.jks` file and its passwords somewhere you will not lose them.**
> If you lose the upload key you cannot publish an update to an existing Play
> listing without going through Google's key-reset process. `*.jks` and
> `key.properties` are already gitignored — never commit them.

Enrolling in **Play App Signing** (recommended, and default for new apps) means
Google holds the *app signing* key and yours is only the *upload* key, which
makes a lost key recoverable. Do this when you create the Play listing.

---

## 3. ⬜ Build the release bundle

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Bump `version:` in `pubspec.yaml` before every upload — the part after `+` is
the `versionCode` and **must strictly increase** for each upload, or Play
rejects it:

```yaml
version: 1.0.0+1   # 1.0.0 = versionName (shown to users), 1 = versionCode
```

---

## 4. ⬜ Play Console requirements you must supply

These are Console/hosting items — they cannot be satisfied from inside the app.

**a. Privacy policy URL — ✅ hosted, paste this into the Console:**

```
https://makeplus-events.onrender.com/legal/privacy/
```

**b. Account deletion URL — ✅ hosted, paste this into the Console:**

```
https://makeplus-events.onrender.com/legal/account-deletion/
```

Both are served by the Django backend (`dashboard/views_legal.py`, templates in
`dashboard/templates/legal/`), require no authentication, and are reachable
without installing the app — which is exactly what Google requires, since
in-app deletion alone does not satisfy the policy.

Their wording is kept in sync with the in-app screens
(`privacy_policy_screen.dart`). **Update both together** — Play compares them
and a contradiction is a rejection cause.

**c. Data Safety form.** Based on what the code actually collects:

| Data type | Collected | Purpose | Notes |
|---|---|---|---|
| Email address | Yes | Account management | signup + login |
| Name (first/last) | Yes | Account management | signup |
| Password | Yes | Authentication | transmitted only, never stored on device |
| Camera | **Used, not collected** | QR badge scanning | frames decoded on-device, never uploaded or stored |
| Photos / media | **No** | — | `image_picker` was removed; the app has no photo-library access |
| App activity (scans) | Yes | Event/booth attendance | exhibitor scan records |

Declare: encrypted in transit ✅ · users can request deletion ✅.
Verify the table against your backend before submitting — the form is a legal
declaration and mis-declaring is a common takedown cause.

**d. Content rating questionnaire**, store listing (icon, screenshots,
descriptions), and target-audience declaration — all standard Console steps.

---

## 5. ⚠️ Open items worth deciding before you submit

**a. ~~`image_picker` unused~~ — ✅ resolved.** Removed from `pubspec.yaml`
along with `NSPhotoLibraryUsageDescription` in `ios/Runner/Info.plist` and the
"Photos" section of the in-app privacy policy, which described access the app
no longer has. `get_it` is also unused but declares no permissions and is
marked as planned DI, so it was left in place.

**b. ~~Toolchain near end-of-support~~ — ✅ resolved.** Upgraded to
Gradle `8.14.3`, AGP `8.11.1`, Kotlin `2.2.20` — the minimums Flutter named.

**c. Bundle size is ~73 MB.** That is the AAB (all ABIs/densities); the actual
per-device download is much smaller. Still worth checking the Play Console's
reported download size — investigate assets if it looks large.

**d. `share_plus` is pinned at 12.0.2, not 13.x.** 13.x requires `win32 ^6`,
which conflicts with `flutter_secure_storage` 9.x (`win32 ^5`). Moving to 13.x
requires upgrading `flutter_secure_storage` to 10.x at the same time.

**e. Manual device testing.** Nothing here substitutes for installing the
release build on a physical device and walking every role (participant,
exhibitor, badge controller, room manager) end to end.

---

## 6. Note on the secure-storage migration

`lib/data/services/secure_storage.dart` switched Android from the plugin's
legacy KeyStore-wrapped backend to `EncryptedSharedPreferences`. Tokens written
by the old backend **cannot be decrypted by the new one**, so:

- Every user already signed in will be **logged out once** on the update. This
  is expected and was accepted deliberately.
- `resetOnError: true` is set so an unreadable legacy entry is cleared and read
  returns `null` (→ "not logged in") instead of throwing a `PlatformException`,
  which would otherwise be a hard failure at launch for those users.
- ProGuard keep rules for Google Tink were added to
  `android/app/proguard-rules.pro`. `EncryptedSharedPreferences` pulls in Tink,
  which resolves classes reflectively; without those rules R8 strips them and
  the app **builds fine but crashes at runtime on first secure-storage access**
  (i.e. at login, release builds only).

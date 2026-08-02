// lib/data/services/secure_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The one and only [FlutterSecureStorage] configuration used by the app.
///
/// ApiClient and DjangoAuthService both read and write the *same* keys
/// (`access_token`, `refresh_token`, `temp_token`). If they were each
/// constructed with different AndroidOptions, one would write through a
/// different backend than the other reads from and every token lookup would
/// silently return null — so the options are defined here once and never
/// inlined at a call site. Add new secure-storage users by importing this,
/// not by constructing `FlutterSecureStorage()` directly.
///
/// * `encryptedSharedPreferences: true` selects Jetpack Security's
///   EncryptedSharedPreferences (AES256-GCM) instead of the plugin's legacy
///   backend (an AES key wrapped by an AndroidKeyStore RSA key). Both encrypt;
///   this is the modern, recommended one. It requires API 23+, and our
///   minSdk is 24.
///
/// * `resetOnError: true` matters specifically because we are *switching*
///   backends: tokens written by the old implementation cannot be decrypted
///   by the new one. Without this, that surfaces as a thrown
///   PlatformException on read — i.e. a crash/hard failure at launch for
///   every already-signed-in user. With it, the unreadable entry is cleared
///   and `read` returns null, which the app already handles as "not logged
///   in". The only data here is JWTs, which are recovered by signing in
///   again, so a wipe is cheap; a crash is not.
const FlutterSecureStorage appSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  ),
);

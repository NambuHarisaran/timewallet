import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'state/app_providers.dart';

// ── Firebase App Check (defense-in-depth, currently NOT wired) ───────────────
// App Check attests each request comes from a genuine, untampered build of THIS
// app before Firebase honors it — the client-side complement to the Firestore
// rules (blunts API-key abuse / scripted writes). It was scaffolded but backed
// out: on this Windows toolchain the `firebase_app_check` plugin's native
// Gradle build fails to load ("Plugin directory does not exist") despite the
// package extracting fine, blocking every build. Re-enable once that's sorted
// (try a clean machine / CI, or a newer plugin + AGP combo):
//
//   1. `flutter pub add firebase_app_check`
//   2. add `import 'package:firebase_app_check/firebase_app_check.dart';`
//      and `import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;`
//   3. right after Firebase.initializeApp below:
//        if (!kIsWeb) {
//          try {
//            await FirebaseAppCheck.instance.activate(
//              providerAndroid: kDebugMode
//                  ? const AndroidDebugProvider()
//                  : const AndroidPlayIntegrityProvider(),
//              providerApple: kDebugMode
//                  ? const AppleDebugProvider()
//                  : const AppleAppAttestWithDeviceCheckFallbackProvider(),
//            );
//          } catch (_) {/* non-fatal: never brick startup */}
//        }
//   4. register apps + debug tokens in the Firebase console, verify tokens in
//      the Metrics tab, THEN enable per-service enforcement (Firestore, Auth).
//   Web additionally needs a reCAPTCHA v3 site key:
//      FirebaseAppCheck.instance.activate(
//        webProvider: ReCaptchaV3Provider('<recaptcha-v3-site-key>'));
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline-first: cache all reads/writes locally and auto-sync to the
  // server when connectivity returns. Mutations made offline are queued
  // and replayed by the SDK once online — no manual backup needed.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const TimeWalletApp(),
  ));
}

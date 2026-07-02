# Security Policy — TimeWallet

## Reporting a vulnerability

Email **contact@no1ads.in** with a description, reproduction steps, and impact.
Do not open a public GitHub issue for security reports. You should receive a
response within 72 hours.

## Threat model (summary)

TimeWallet is a Flutter client (Android / web) backed by Firebase Auth +
Cloud Firestore. There is no custom server: **Firestore security rules are the
entire server-side authorization layer**, so their correctness is the primary
security boundary. All Firebase client config (`firebase_options.dart`,
`google-services.json`) is public by design — those values are identifiers,
not secrets; protection comes from rules, Auth, and platform restrictions.

Sensitive assets: per-user financial records (expenses, goals, holdings,
budgets, income), auth credentials, and the Android release-signing material.

## Audit — 2026-07-02

Full-repository audit (client code, Firestore rules, Android config, web
shell, CI, git history). Findings and status:

| # | Severity | Finding | CWE | Status |
|---|----------|---------|-----|--------|
| F1 | High | Play signing-key export material (`output.zip` PEPK blob, `pepk.jar`, `internal_cert.der`, `encryption_public_key.pem`) committed in **public** git history at `6a673f6` | CWE-538 | ⚠ Operator action — history scrub (below) |
| F2 | Medium | No Firebase App Check: any client with the (public) API key can call Firestore/Auth endpoints directly — quota abuse / spam-account risk | CWE-799 | ⚠ Operator action (below) |
| F3 | Medium | CI actions pinned by mutable tag (`@v4` / `@v2`), dependency resolution not locked in CI | CWE-829 | ✅ Patched (S10) |
| F4 | Medium | No Content-Security-Policy on the web build | CWE-1021 | ✅ Patched (S13) |
| F5 | Low | Firestore rules accepted unbounded numeric magnitudes and unbounded `activity.type` int (owner-gated, data-integrity risk only) | CWE-20 | ✅ Patched (S11) — redeploy rules |
| F6 | Low | `AuthService.describeError` default case surfaced raw `FirebaseAuthException.message` to the UI (backend detail leak) | CWE-209 | ✅ Patched (S12) |
| F7 | Low | Stray duplicate `google-services.json` tracked at repo root (build uses `android/app/`) | — | ✅ Removed |
| F8 | Info | Firebase Web API keys in repo — expected, but must be paired with key restrictions + authorized domains | — | ⚠ Operator action (below) |
| F9 | Info | Password policy enforced client-side only (8+ on signup); Firebase server default is 6 | CWE-521 | ⚠ Operator action (below) |
| F10 | Info | Build artifact (`build/reports/...html`) in old history; `/build/` now ignored | — | Accepted (scrubbed with F1) |

Verified as already sound during this audit: Firestore rules are fail-closed,
owner-scoped, email-verification-gated, and shape/size-validated per
collection; CSV export neutralizes spreadsheet formula injection (CWE-1236);
`allowBackup=false` keeps the local Firestore cache out of device backups;
`taskAffinity=""` blocks task-hijacking; release builds refuse debug-signing
fallback; R8 minification enabled; receipt OCR is fully on-device (no image
upload); CI token is read-only; no cleartext traffic, no hardcoded secrets,
no debug logging of user data.

## Required operator actions (cannot be fixed in code)

1. **Scrub key material from git history (F1).** The PEPK `output.zip` is
   encrypted to Google's key so it is not directly decryptable, but signing-key
   export material must not live in a public repo. Rewrite history and
   force-push — **destructive; coordinate with any collaborators first**:

   ```
   git filter-repo --invert-paths \
     --path output.zip --path pepk.jar \
     --path internal_cert.der --path encryption_public_key.pem \
     --path "android/build/reports/problems/problems-report.html"
   git push origin --force --all
   ```

   Then verify in Play Console → Setup → App signing that **Play App Signing**
   manages the app signing key (it should, given PEPK was used). If the
   *upload* key is ever suspected compromised, request an upload-key reset
   from Play Console.

2. **Enable Firebase App Check (F2).** Firebase Console → App Check: register
   the Android app with Play Integrity and the web app with reCAPTCHA
   Enterprise/v3, add `firebase_app_check` to the app, then enforce for
   Firestore and Auth once metrics show real traffic passing.

3. **Restrict the API keys (F8).** Google Cloud Console → Credentials: give
   the Android key an application restriction (package
   `in.no1ads.timewallet` + release SHA-256) and the web key an HTTP-referrer
   restriction (production domains only). Firebase Console → Auth → Settings:
   prune **authorized domains** to production + localhost.

4. **Server-side password policy (F9).** Firebase Console → Authentication →
   Settings → Password policy: require length ≥ 8 (matches the client rule),
   enable "Require enforcement".

5. **Deploy the tightened rules (F5):** `firebase deploy --only firestore:rules`.

## Hardening ledger

Code comments reference these markers:

- **S1** — Play signing-key export material gitignored (`output.zip`, `pepk.jar`, `*.pem`, `*.der`)
- **S2** — account deletion wipes data first and pre-checks recent login (no orphaned-data path)
- **S3** — per-user `state/*` docs enumerated and shape-checked in rules (fail closed)
- **S4** — rules require verified email for password accounts (not just UI gating)
- **S7** — release build fails without real signing config (no debug-signed release); R8 enabled
- **S8** — `allowBackup=false` (local financial cache excluded from backups)
- **S9** — CI `GITHUB_TOKEN` restricted to `contents: read`
- **S10** — CI actions pinned to commit SHAs; `pub get --enforce-lockfile` in CI
- **S11** — rules: numeric upper bounds (≤ 1e11) and bounded `activity.type`
- **S12** — auth errors surface only the error code, never raw backend messages
- **S13** — CSP on the web shell (allowlists Firebase/Google endpoints only)

## Supported versions

Only the latest released version receives security fixes.

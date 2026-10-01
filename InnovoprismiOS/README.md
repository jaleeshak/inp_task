# Innovoprism for iPhone & iPad

A native iOS app for the Innovoprism task-management web app. It's a SwiftUI
shell around a WKWebView that opens your Innovoprism server, so **every
feature of the web app works on day one**, and every web-app update
(8.4.0, 8.5.0, ...) shows up in the iPhone app automatically. You only rebuild
the iOS app when you change the app itself (name, icon, native features).

What the native shell adds on top of the website:

- Its own home-screen icon, full screen, stays logged in
- Alert sounds play without the "tap once to unlock audio" step
- JS dialogs (alert / confirm / prompt) shown as native iOS dialogs
- File downloads open the iOS share sheet (Save to Files, AirDrop, WhatsApp...)
- Photo/camera uploads, camera + microphone for calls
- Links to other websites open in Safari; tel:/mailto: links open the right app
- Pull down to refresh; swipe from the edge to go back
- Friendly "Can't reach server — is Tailscale connected?" screen instead of a blank page
- **Two-finger long-press anywhere** → menu: Reload · Home · Open in Safari · Change server

**No Mac needed at any point.** The Xcode project is *generated* from
`project.yml` by XcodeGen on GitHub's free cloud Mac, which also compiles the
app. You install it from Windows.

---

## Files

```
project.yml                        XcodeGen spec (replaces a hand-made .xcodeproj)
.github/workflows/build-ios.yml    Cloud build -> Innovoprism.ipa
Innovoprism/
  Info.plist                       App name, permissions, DefaultServerURL
  Assets.xcassets/                 App icon (placeholder), accent + launch colours
  App/InnovoprismApp.swift         App entry point
  App/AppSettings.swift            Saved server address
  App/RootView.swift               Setup screen vs. web app
  App/SetupView.swift              First-launch "Server address" screen
  Web/WebContainerView.swift       SwiftUI <-> UIKit bridge
  Web/WebViewController.swift      The web view + downloads, dialogs, permissions
  Web/ConnectionErrorView.swift    "Can't reach Innovoprism" screen
```

---

## Step 1 — Optional customising (before the first build)

| What | Where |
|---|---|
| Pre-fill the server so teammates skip setup | `Innovoprism/Info.plist` → `DefaultServerURL` (e.g. `https://innovoprism.your-tailnet.ts.net`) |
| Real logo | Replace `Innovoprism/Assets.xcassets/AppIcon.appiconset/AppIcon.png` with a **1024×1024 PNG, no transparency** |
| App name under the icon | `Info.plist` → `CFBundleDisplayName` |
| Version | `project.yml` → `MARKETING_VERSION` (build number auto-increments per cloud build) |
| Bundle ID | `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER` |

Info.plist is plain XML — Notepad/VS Code is fine.

## Step 2 — Put the project on GitHub

1. Create a free account at github.com → **New repository** → name `innovoprism-ios`.
   *Public* repos get unlimited free Mac build minutes. *Private* is fine too:
   the free plan's minutes cover roughly a couple of dozen builds a month
   (Mac minutes count 10×; each build takes ~3–5 min).
2. Upload the contents of this folder (so `project.yml` sits at the top level of
   the repo — not inside a sub-folder). Either:
   - **Browser:** "uploading an existing file" → drag everything in, including
     the `.github` folder → Commit. Check afterwards that
     `.github/workflows/build-ios.yml` is visible in the repo.
   - **Git (PowerShell / Git Bash):**
     ```
     cd InnovoprismiOS
     git init -b main
     git add .
     git commit -m "Innovoprism iOS app"
     git remote add origin https://github.com/<you>/innovoprism-ios.git
     git push -u origin main
     ```

## Step 3 — Build the .ipa in the cloud

1. Repo → **Actions** tab. If asked, click "I understand my workflows, enable them".
2. The push starts a build automatically (or pick **Build iOS app** → **Run workflow**).
3. Wait for the green tick (~4 min). Open the run → **Artifacts** → download
   **Innovoprism-ipa** → unzip → you have `Innovoprism.ipa`.

If it goes red, open the failed step, copy the last ~30 lines of the log, and
send them to me — it'll be a quick fix.

## Step 4 — Install on the iPhone from Windows (Sideloadly)

1. Install **iTunes** and **iCloud** from apple.com (the *non*-Microsoft-Store
   versions — Sideloadly needs their drivers), then **Sideloadly** from sideloadly.io.
2. Connect the iPhone by USB, unlock it, tap **Trust This Computer**.
3. Open Sideloadly → drag in `Innovoprism.ipa` → enter your Apple ID → **Start**.
   Sideloadly signs the app with your free Apple ID (tip: use a spare Apple ID
   if you prefer). Enter the 2-factor code when asked.
4. On the iPhone:
   - **Settings → Privacy & Security → Developer Mode → On** (restarts the phone; iOS 16+).
   - **Settings → General → VPN & Device Management** → tap your Apple ID → **Trust**.
5. Open Innovoprism from the home screen.

(AltStore works too if you already set it up earlier — install the same `.ipa` through it.)

**Free Apple ID limits:** the app must be re-signed every **7 days** (re-run
Sideloadly, or enable its auto-refresh; your data and login are kept), and at
most 3 sideloaded apps per device. The paid route below removes both.

## Step 5 — First launch

1. Make sure the **Tailscale** app is connected on the iPhone (same as when
   using the site in Safari).
2. Enter the server address — exactly what you type in the browser, e.g.
   `https://innovoprism.your-tailnet.ts.net` or `100.x.y.z:8080`
   (no `http://` needed; `*.ts.net` names get `https://` automatically).
3. Log in as usual. Allow camera/microphone/photos when iOS asks.

To switch servers later: **two-finger long-press → Change server…**

## Good to know

- **Calls need HTTPS.** iOS only gives camera/microphone to pages served over
  `https://` (same rule as Safari). If calls work in Safari today, they'll work
  here. If your server is plain `http://`, enable Tailscale HTTPS
  (`tailscale cert` / `tailscale serve`) and use the `…ts.net` address.
- **Alerts while the app is closed** need Apple Push Notifications, which
  require the paid Apple Developer Program and a server change — a good
  follow-up project. While the app is open, sounds and in-app alerts work.
- The app allows plain `http://` (`NSAllowsArbitraryLoads`) because private
  tailnet servers often use it. Tighten this before any App Store submission.

## Rolling it out to the whole team (later)

Free sideloading suits you and a few testers. For everyone, join the **Apple
Developer Program ($99/year)** and distribute via **TestFlight**: no 7-day
expiry, no USB cable, up to 10,000 testers, just an invite link. That needs
signing certificates added to GitHub as secrets and an extra upload step in
the workflow — ask when you're ready and I'll add it.

## Updating the app

- Web-app changes: nothing to do, the app loads the latest version from your server.
- iOS-app changes: edit files → push to GitHub → download the new `.ipa` →
  install with Sideloadly over the old one (data is kept).

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Can't reach Innovoprism" | Tailscale connected on the phone? Same address works in Safari? |
| "Untrusted Developer" on launch | Step 4.4 → Trust your Apple ID |
| App won't open, no message | Developer Mode is off (Step 4.4) |
| Stopped opening after a week | Free signing expired → run Sideloadly again |
| Sideloadly "device not found" | Install iTunes (non-Store), re-plug, unlock & Trust |
| Camera/mic not working in calls | Server must be https:// (see "Calls need HTTPS"); check Settings → Innovoprism permissions |
| Page looks stuck | Two-finger long-press → Reload, or pull down to refresh |

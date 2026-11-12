# CLAUDE.md: Squeezy Game (Godot 4.7, Android, fully offline)

Owner: Rahul (GitHub org `rekixo-lab`). He talks in Hindi/Hinglish, so reply to him in simple Hindi. Code comments in this project are in Hinglish (Roman script). Keep that style.

## What this is
- A one-tap 3D casual game. The hero jumps between pillars in the sea, flips in the air, butt-slams objects and gets fatter. It has 200 levels.
- Engine: Godot 4.7, renderer `gl_compatibility`, portrait 720×1280. The project was opened in the Godot .NET editor (`.godot/mono` exists), **but there is no C# code**. All code is GDScript.
- Entry point: `scenes/main.tscn` → `scripts/main.gd` (screens) → `scripts/game.gd` (gameplay + HUD).
- Character: `models/squeezy_man.glb` + `scripts/squeezy_man.gd`, wrapped by `scripts/player.gd`.
- Visual look (light, sky, water, pillar shader): **only** in `scripts/look.gd` (class `Look`).
- Save data: `user://save.cfg` via `scripts/game_data.gd`.
- `scenes/squeezy_preview.tscn` is a dev-only character test scene. It is excluded from export.

## Hard rules (Play Store policy: do not break)
1. **Fully offline.** No INTERNET permission, no network code, no ads, no analytics, no crash-reporting SDKs, no login, no IAP. If any of these is ever added, `docs/privacy-policy.html` and the Data safety answers in `store/PLAY_STORE.md` must change first.
2. The Android export must request **zero permissions**.
3. Never commit signing keys or passwords. The release keystore lives outside the repo, and signing goes through the environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`.
4. Increase `version/code` in `export_presets.cfg` for every Play upload. Keep `version/name` in sync with `config/version` in `project.godot`.
5. No placeholder "coming soon" screens visible in release builds. Mail and Shop are hidden (`SHOW_MAIL` / `SHOW_SHOP` in `scripts/ui/home_screen.gd`).

## Fixed decisions (from Rahul)
- Website / privacy-policy host: **https://squeezy-game.rekixo.com** (privacy page at `/privacy-policy.html`)
- Support email: **squeezygame@rekixo.com**
- GitHub repo: **rekixo-lab/squeezy-godot** (branch `main` = live)
- Android package: `com.rekixo.squeezygame` (matches the domain; final once uploaded)

## Safety boundaries (Cloudflare + GitHub): ALWAYS follow these
- **GitHub:** work ONLY in `rekixo-lab/squeezy-godot`. Do not create, edit, delete or change settings or secrets in any other repository or org setting.
- **Cloudflare, create only:** you MAY create a NEW Pages project (or a NEW Worker) named `squeezy-game`, attach the NEW hostname `squeezy-game.rekixo.com` to it, and add the NEW email address `squeezygame@rekixo.com`.
- **Cloudflare, never touch:** do NOT edit, rename, redeploy or delete any existing Worker, Pages project, route, DNS record, email rule, SSL/WAF/cache setting or the root `rekixo.com` site.
- Before creating anything, LIST what already exists (`wrangler pages project list`, `wrangler deployments`, DNS records for the zone, email routing rules).
  - If `squeezy-game` or `squeezy-game.rekixo.com` already exists, STOP and ask Rahul.
  - If the Cloudflare email-routing destination for `squeezygame@rekixo.com` is not obvious, ask Rahul which inbox to forward to.
  - If Email Routing is not enabled on the zone, ask Rahul before enabling it, because enabling it changes MX records.
- Any delete, force-push or overwrite anywhere: **ask Rahul first.**
- Whenever Rahul's hands are needed, stop and tell him in simple Hindi exactly what to click or type, then wait. Examples: browser login or approval, typing a password, an approval in the Cloudflare/GitHub/Play dashboard, testing on a phone.

## Folders
- `docs/`: privacy-policy site, deployed to Rahul's company domain with Cloudflare Pages. Not exported.
- `store/`: Play Store listing text, answers and graphics. Not exported.
- `tools/`: dev scripts. Not exported.
- `Claude outputs/`: scratch images from Claude (has `.gdignore`, git-ignored).
- `build/`: export output (git-ignored).

---

# RELEASE TASK v1.0.0 (do this when Rahul asks you to "release / production ready / bundle")

Work step by step. After each step, tell Rahul in one or two Hindi lines what happened. **Stop and ask Rahul** wherever ⚠️ is marked. Do not guess those answers.

### Step 0: Tools check
- Find the Godot 4.7 editor binary (`which godot`, or ask Rahul for its path). Note whether it is the .NET build.
- Export templates for the *exact same* version (and .NET flavour if the editor is .NET) must be installed. If they are missing, download them from the official Godot site / godotengine GitHub releases and install them under `~/.local/share/godot/export_templates/<version>/`.
- JDK 17 and the Android SDK (platform-tools, build-tools, `platforms;android-36`, cmdline-tools) must be installed. Point Godot at them in editor settings (`export/android/java_sdk_path`, `export/android/android_sdk_path`).
- Install the Android Gradle build template into the project (`android/` folder, which is git-ignored). Use the editor menu *Project → Install Android Build Template*, or the matching headless option.

### Step 1: Make it compile and run cleanly
- `godot --headless --path . --import`, then run the game for a while and read every error and warning in the output. Fix all of them.
- Recently changed files have **never been run in Godot**: `scripts/look.gd` (new), `game.gd`, `object_factory.gd`, `fruit_factory.gd`, `squeezy_preview.gd`, `squeezy_man.gd`, `ui/home_screen.gd`, `ui/coin_bar.gd`, `models/squeezy_man.glb` (crotch cloth geometry added). Check these first.
- Take screenshots of: the home screen, the level map, and gameplay on levels 1, 3 and 10 (including a flip and a smash). Show them to Rahul. In `look.gd`, the scene must not look washed-out or too white, and pillar edges and object shapes must read clearly. Tune only the constants at the top of `look.gd` if needed.

### Step 2: Font
- Download **Lilita One** (SIL Open Font License) from the official google/fonts GitHub repo (`ofl/lilitaone/`). Save it as `fonts/game_font.ttf`, and save the licence next to it as `fonts/OFL.txt`. Without this, Android falls back to Roboto and the UI looks wrong.

### Step 3: Icons and store graphics
Write `tools/capture_store_assets.gd` (run it with the Godot editor binary, not headless, because it needs a GPU) to produce:
- `icons/icon_192.png`: launcher icon, 192×192.
- `icons/adaptive_fg_432.png`: the hero's happy face and shoulders on a TRANSPARENT background. Keep everything inside the centre 66% safe zone.
- `icons/adaptive_bg_432.png`: plain bright gradient (cyan `#00c1fd` → pink `#fc71dd`, matching the home screen).
- `store/assets/icon_512.png`: 512×512, foreground on the background, no transparency, no text.
- `store/assets/feature_1024x500.png`: the hero mid-flip over the pillars and sea, with space on the left for a big title. Use the final app name ⚠️ (Rahul may rename the game; see `store/PLAY_STORE.md` §1).
- `store/assets/screenshot_1..6.png`: 1080×1920 real gameplay frames (home, map, jump, flip, smash, win).

Use `Look.environment()` / `Look.sun()` so the assets match the game. Set `config/icon="res://icons/icon_192.png"` in `project.godot`. Show every image to Rahul and wait for his OK ⚠️.

### Step 4: Clean the repo
- `.bak` files and `Claude outputs/` must stay out of git (already in `.gitignore`).
- Delete `scripts/player_old.gd.bak` and `models/squeezy_man.glb.bak` only after Rahul confirms the new character looks right.

### Step 5: Upload key, then store it in GitHub Secrets ⚠️
- Ask Rahul whether he already has an upload keystore. If he does not, let **him** type the password himself in the terminal. Never put it in a command line you write. Then run:
  `keytool -genkeypair -v -keystore ~/keys/squeezy-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
- Put the key into the repo's **GitHub Actions secrets** (encrypted; it never shows in code or logs):
  ```
  base64 -w0 ~/keys/squeezy-upload.jks | gh secret set ANDROID_UPLOAD_KEYSTORE_BASE64 -R rekixo-lab/squeezy-godot
  gh secret set ANDROID_UPLOAD_KEY_ALIAS -R rekixo-lab/squeezy-godot --body upload
  gh secret set ANDROID_UPLOAD_KEYSTORE_PASSWORD -R rekixo-lab/squeezy-godot   # Rahul types it at the prompt
  ```
- Secrets cannot be downloaded back from GitHub. So Rahul must **also** keep the `.jks` and its password in an offline backup, such as a password manager or a pen drive. Then delete the local plain copy only if he wants to.

### Step 6: Build the AAB
```
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=~/keys/squeezy-upload.jks
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=...   # ask Rahul / read from his env, never hard-code
mkdir -p build
godot --headless --path . --export-release "Android Release (Play Store AAB)" build/squeezy_game.aab
```
Then verify with bundletool (download the jar if it is missing):
- `bundletool validate --bundle build/squeezy_game.aab`
- The manifest shows **targetSdkVersion 36**, minSdk 24, and **no `<uses-permission>`** lines (`bundletool dump manifest`).
- The native libraries are aligned for **16 KB page size**. Build the APKs and check with `zipalign -c -P 16 -v 4`. If the check fails, fix it before shipping.
- The `.aab` is signed by the upload key (`jarsigner -verify`).

### Step 6b: Automatic build on GitHub Actions
Create `.github/workflows/android-release.yml`. It runs on a `v*` tag push or manually (`workflow_dispatch`), on `ubuntu-latest`, and must:
- Download the **standard (non-.NET)** Godot editor of the same version as the local one (Linux x86_64) and its export templates from the official godotengine release, and install the templates into `~/.local/share/godot/export_templates/<version>/`.
- Set up Temurin JDK 17 and use the runner's Android SDK, installing `platforms;android-36` plus the matching build-tools with `sdkmanager`. Point the Godot editor settings at the JDK and SDK (create the editor settings file the same way it works locally).
- Install the Android build template, then decode the `ANDROID_UPLOAD_KEYSTORE_BASE64` secret to a temp file and export it with the `GODOT_ANDROID_KEYSTORE_RELEASE_*` env vars.
- Run the same bundletool checks as in Step 6, then upload `squeezy_game.aab` as a **private workflow artifact** (retention 30 days). Never attach it to a public release.
- Optional, only if Rahul asks later: publish to the Play **internal testing** track with a Play service-account JSON stored as a secret.

Test it with `gh workflow run`, watch it with `gh run watch`, and fix it until it is green.

### Step 7: Test on a real phone
- `bundletool build-apks --bundle build/squeezy_game.aab --output build/test.apks --connected-device` (signed with the same key), then `install-apks`.
- Test all of these: first launch with no internet, levels 1–3, fail and retry, win and next, back button on every screen, home/recents then resume, settings toggles persisting after a restart, the quit button, portrait lock, and a notched or tall screen.
- Report any crash or problem to Rahul and fix it.

### Step 8: Git, merge to `main` ("live")
The local folder `/home/rekixo/Workspace/SqueezyGame` has **no git yet**. The GitHub repo `rekixo-lab/squeezy-godot` already has `main` with only `README.md` and `.gitignore`.
```
git init -b release/v1.0.0
git remote add origin https://github.com/rekixo-lab/squeezy-godot.git
git add -A && git commit -m "Squeezy Game v1.0.0: production-ready offline release"
git fetch origin
git merge origin/main --allow-unrelated-histories   # keep OUR README.md; merge .gitignore lines
git push -u origin release/v1.0.0
gh pr create --base main --title "Release v1.0.0" --body "<summary of changes + test results>"
```
- Before committing, run `git status` and make sure no `.jks` file, `build/` folder, `.godot/` folder or `android/` folder is included.
- After Rahul says OK ⚠️, merge the PR into `main`, then tag: `git tag v1.0.0 && git push origin v1.0.0`.
- **Do not attach the .aab file to a public GitHub release.** It stays local and goes to the Play Console only.

### Step 9: Website and privacy policy at squeezy-game.rekixo.com (Cloudflare)
- The email `squeezygame@rekixo.com` is already in `docs/privacy-policy.html`. Delete `docs/.nojekyll`.
- Set the privacy URL in `store/PLAY_STORE.md` §4 to `https://squeezy-game.rekixo.com/privacy-policy.html`.
- Follow the **Safety boundaries** above: list what exists first, then create only new things.
- Create a NEW Cloudflare Pages project `squeezy-game` that serves the `docs/` folder. Use one of these:
  - (a) Connect it to the GitHub repo `rekixo-lab/squeezy-godot`: branch `main`, no build command, output dir `docs`. If Rahul has to approve the Cloudflare GitHub app for this ONE repo only, tell him exactly what to click.
  - (b) `npx wrangler login` (Rahul approves in his browser), then `npx wrangler pages project create squeezy-game --production-branch main` and `npx wrangler pages deploy docs --project-name squeezy-game`. With this option, add a GitHub Actions job using the secrets `CLOUDFLARE_API_TOKEN` (a token Rahul creates, scoped to *Pages: Edit* only) and `CLOUDFLARE_ACCOUNT_ID`, so the site redeploys on every push to `main`.
- Add the custom domain `squeezy-game.rekixo.com` to that Pages project. Cloudflare then creates the new CNAME record. Change no other DNS record.
- Email: in Cloudflare Email Routing, add a NEW custom address `squeezygame@rekixo.com` that forwards to the inbox Rahul names. Ask him if you are unsure.
- Check that `https://squeezy-game.rekixo.com/` and `/privacy-policy.html` open over HTTPS, and that a test mail to `squeezygame@rekixo.com` arrives (Rahul confirms).
- This game stays **fully offline**. Do not connect it to the company API or database. Any online feature (leaderboard, cloud save) needs a new privacy policy and a new Data safety form first.

### Step 10: Hand-off
Give Rahul a short Hindi checklist of what **he** must do in the Play Console, following `store/PLAY_STORE.md`:
- create the app
- the listing
- graphics
- content rating
- target audience
- data safety
- privacy URL (company domain)
- closed test with 12 testers for 14 days (personal accounts)
- production

Include the path to the `.aab` and its `versionCode`.

# itch.io Deploy Guide

> Step-by-step: from clean checkout → uploaded itch.io build.
> Target: Dark Olympus 0.0.1 first-playable demo (Windows + Web HTML5).

---

## Prereqs

- Godot 4.6 stable installed
- Export templates installed (`Editor → Manage Export Templates`)
- itch.io account with an unlisted draft page created (see `itch-io-page-copy.md`)
- [butler](https://itch.io/docs/butler/) CLI installed and logged in: `butler login`

---

## 1. Set up `export_presets.cfg`

The template lives at `src/export_presets.cfg.template`. It's not committed to git (Godot writes machine-specific paths into it), but the template is the source of truth.

```bash
cd src
cp export_presets.cfg.template export_presets.cfg
```

Open the project in Godot once so it re-imports resources. Godot may re-sort keys in `export_presets.cfg` — that's fine, don't fight it.

---

## 2. Verify the Web preset settings (itch.io-critical)

In Godot: `Project → Export → Web`. Confirm:

| Setting | Value | Why |
|---------|-------|-----|
| `variant/thread_support` | **true** | itch.io sets the COOP/COEP headers needed. Without threads the engine is much slower |
| `html/canvas_resize_policy` | **2 (Adaptive)** | Makes the canvas fill the itch.io iframe at 430x932 |
| `html/focus_canvas_on_start` | **true** | Mobile browsers need this for first-tap input |
| `progressive_web_app/enabled` | **false** | itch.io iframe is the host — don't install as a PWA |
| `export_path` | `../build/web/index.html` | Creates `build/web/` at repo root |

---

## 3. Build

### Windows

```bash
# From Godot editor:
Project → Export → Windows Desktop → Export Project
# Choose path: build/windows/dark_olympus.exe

# Or CLI (from repo root, src/ as project):
godot --headless --path src --export-release "Windows Desktop" ../build/windows/dark_olympus.exe
```

### Web

```bash
# From Godot editor:
Project → Export → Web → Export Project
# Choose path: build/web/index.html

# Or CLI:
godot --headless --path src --export-release "Web" ../build/web/index.html
```

The Web export produces: `index.html`, `*.pck`, `*.wasm`, `*.js`, `*.png`, `*.audio.worklet.js`, `*.worker.js`. All of them must ship together.

---

## 4. Smoke-test locally

### Windows
Double-click `build/windows/dark_olympus.exe`. Reach the splash → hub without crashing. Quit.

### Web
```bash
cd build/web
python3 -m http.server 8000
```
Open `http://localhost:8000` in a Chromium-based browser. The threaded WebAssembly build requires COOP/COEP — the simple python server doesn't send those headers, so for a proper local test use:

```bash
# Python with headers (one-liner):
python3 -c "
import http.server, socketserver
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()
with socketserver.TCPServer(('', 8000), H) as s: s.serve_forever()
"
```

Confirm: black loading bar → splash screen → hub. No console errors about SharedArrayBuffer.

---

## 5. Package for itch.io

### Windows
```bash
cd build
zip -r windows-dark-olympus-0.0.1.zip windows/
```

### Web
```bash
cd build
zip -r web-dark-olympus-0.0.1.zip web/
```

> The Web zip must contain `index.html` at the root of the zip (not inside `web/`). Adjust:
> ```bash
> cd build/web && zip -r ../web-dark-olympus-0.0.1.zip .
> ```

---

## 6. Upload via butler

```bash
# First time — creates the channel:
butler push build/web-dark-olympus-0.0.1.zip YOUR_USERNAME/dark-olympus:web-0.0.1 --userversion 0.0.1
butler push build/windows-dark-olympus-0.0.1.zip YOUR_USERNAME/dark-olympus:win-0.0.1 --userversion 0.0.1

# Verify:
butler status YOUR_USERNAME/dark-olympus
```

### Important itch.io page settings (manual in the browser)

- **Kind of project**: HTML ✅ and Windows ✅ (check both)
- **Embed options** → "This file will be played in the browser" → check on the `web-0.0.1` channel
- **Viewport dimensions**: Width `430`, Height `932` (matches our portrait design)
- **Mobile friendly**: Check ✅ (this build is designed for portrait touch)
- **Automatically start on page load**: Check ✅
- **Enable scrollbars**: Uncheck ✗
- **Fullscreen button**: Check ✅

---

## 7. Release checklist

Before flipping the draft to public:

- [ ] Windows build runs on a clean Windows 11 (no dev dependencies)
- [ ] Web build runs on Chrome + Firefox + mobile Safari
- [ ] No console errors in F12 DevTools on first load
- [ ] Full Ch1 playthrough reaches `ch01_complete` without softlock
- [ ] End-of-demo CTA shows and links to Patreon/wishlist correctly
- [ ] Cover image 630×500, 3–5 screenshots at 630×500 or 1920×1080
- [ ] Description copy proofread (see `itch-io-page-copy.md`)
- [ ] Pricing: "No payment" or "Pay what you want" (demo — keep free)
- [ ] Tags: rpg, dating-sim, visual-novel, cards, mythology, mobile-friendly
- [ ] Devlog post announcing the release drafted (`production/releases/0.0.1-devlog.md`)

---

## 8. Rollback plan

If 0.0.1 is critically broken after launch:

```bash
# Take down the Web channel temporarily:
butler push /path/to/previous/good-build.zip YOUR/dark-olympus:web-0.0.1 --userversion 0.0.1
```

Or mark the build as disabled in the itch.io dashboard under Uploads. Never delete — itch.io keeps download history.

---

## Known limitations of 0.0.1

- Single save slot (multi-slot is a 0.0.2 feature — LAUNCH-005)
- English only (locale scaffolding exists but no Spanish strings for demo)
- No cloud save sync (out of scope for demo)
- No achievements / Steam-like integration (itch.io doesn't require it)

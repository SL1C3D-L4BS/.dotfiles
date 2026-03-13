// ─────────────────────────────────────────────────────────────────────────────
// Firefox user-overrides.js — SL1C3D-L4BS 2026
// Applied ON TOP of arkenfox user.js to re-enable things we need.
// Order: user.js loads first, then user-overrides.js overrides it.
// ─────────────────────────────────────────────────────────────────────────────
// To use: place both in ~/.mozilla/firefox/<profile>/
//   curl -fsSL https://raw.githubusercontent.com/arkenfox/user.js/master/user.js -o user.js
// Then apply overrides below.

// ── Re-enable WebRTC (needed for video calls: Discord, Google Meet) ──────────
user_pref("media.peerconnection.enabled", true);

// ── Allow custom CSS (userChrome.css) ───────────────────────────────────────
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// ── Enable smooth scrolling ──────────────────────────────────────────────────
user_pref("general.smoothScroll", true);
user_pref("general.smoothScroll.mouseWheel.durationMaxMS", 200);
user_pref("general.smoothScroll.mouseWheel.durationMinMS", 100);

// ── Hardware acceleration ─────────────────────────────────────────────────────
user_pref("gfx.webrender.all", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("layers.acceleration.force-enabled", true);

// ── Compact UI density ────────────────────────────────────────────────────────
user_pref("browser.uidensity", 1);   // 0=normal, 1=compact, 2=touch

// ── Reader view / dark mode preference ───────────────────────────────────────
user_pref("reader.color_scheme", "dark");

// ── Enable developer tools remote debugging (optional) ──────────────────────
// user_pref("devtools.debugger.remote-enabled", true);

// ── Search engine ─────────────────────────────────────────────────────────────
// user_pref("browser.search.defaultenginename", "DuckDuckGo");

// ── Restore previous session on startup ──────────────────────────────────────
user_pref("browser.startup.page", 3);

// ── Allow signed-in sync (arkenfox disables this) ────────────────────────────
user_pref("identity.fxaccounts.enabled", true);

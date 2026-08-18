// user.js -- Zen prefs enforced on every startup (Zen rewrites prefs.js on
// exit, so anything set only via about:config can be lost; user.js reapplies).

// Native Linux chrome transparency. Gates a CSS block in
// chrome/browser/content/browser/zen-styles/zen-theme.css that sets
// `background: transparent` on #main-window and blanks
// --zen-themed-toolbar-bg-transparent. It affects the browser CHROME only --
// web page content stays opaque, because content transparency is a separate
// pref (browser.tabs.allow_transparent_browser) left at its default false.
// This is the reason there is no Hyprland opacity window rule for class `zen`:
// compositor alpha is whole-surface and made videos translucent too.
user_pref("zen.widget.linux.transparency", true);

// Deliberately NOT enabled: zen.theme.acrylic-elements. It adds backdrop-filter
// blur to the sidebar/urlbar, but Zen's own source comments say it "makes zen
// REALLY slow" (it forces layering via `translate: 0` on the content browser).
// On an Iris Plus G1 that is not a trade worth making.
// user_pref("zen.theme.acrylic-elements", true);

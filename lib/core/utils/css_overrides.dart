/// CSS injected into cineby.at after page load.
///
/// Goal: hide the site's own top/bottom navigation bars so Flutter's native
/// navigation takes over. Do NOT restyle content — only hide redundant
/// navigation chrome.
///
/// ⚠️ Important: cineby.at uses Next.js with dynamic class names that may
/// change between deployments. Do NOT target specific generated class names
/// like `.Navbar__abc123`. Instead, target semantic HTML elements (`header`,
/// `footer`, `nav`) and stable data attributes (e.g. `data-testid`).
/// This list must be re-verified if the site updates.
const String cssOverrides = r"""
/* Hide the site's own navigation header */
header, nav.site-header, .navbar, [class*='header'] {
  display: none !important;
}

/* Hide any bottom nav the site might render */
footer, nav.bottom-nav, [class*='bottom-nav'] {
  display: none !important;
}

/* Remove top padding that was reserved for the now-hidden header */
body, #__next, main {
  padding-top: 0 !important;
  margin-top: 0 !important;
}

/* Smooth momentum scroll on iOS */
* {
  -webkit-overflow-scrolling: touch;
  scroll-behavior: smooth;
}

/* Hide sticky banner / cookie prompts that interfere with the shell */
[class*='cookie'], [class*='Cookie'], [class*='consent'] {
  display: none !important;
}

/* Suppress the site's own download modal if any — the native FAB
   is the preferred download entry point */
[class*='DownloadModal'], [class*='download-modal'] {
  display: none !important;
}
""";

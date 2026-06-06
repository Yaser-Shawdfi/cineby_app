/// JavaScript injected into cineby.at via InAppWebView.evaluateJavascript().
///
/// Two scripts:
///  • [videoInterceptScript] — watches the DOM for `<video>` and `<source>`
///    elements, patches `XMLHttpRequest.open` to catch m3u8 playlists, and
///    reports URLs to Flutter via the `VideoChannel` JS bridge.
///  • [downloadButtonScript] — attaches click handlers to the site's own
///    download buttons and forwards the URL + title to Flutter via
///    `DownloadChannel`.
///
/// Both channels must be registered with [InAppWebViewController.addJavaScriptChannel]
/// in `onWebViewCreated` before the page loads.
library;

/// Watch for `<video>` elements being added to the DOM and report their src.
/// Also patch XMLHttpRequest to catch m3u8 playlist requests that
/// the site might load programmatically.
const String videoInterceptScript = r"""
(function() {
  if (window.__cinebyVideoInterceptInstalled) return;
  window.__cinebyVideoInterceptInstalled = true;

  function reportVideo(url) {
    if (!url) return;
    if (
      url.includes('.m3u8') ||
      url.includes('.mp4')  ||
      url.startsWith('blob:')
    ) {
      try { window.VideoChannel.postMessage(url); } catch (e) { /* noop */ }
    }
  }

  // Watch for <video>/<source> elements being added to the DOM
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      mutation.addedNodes.forEach(function(node) {
        if (!(node instanceof Element)) return;
        if (node.nodeName === 'VIDEO') {
          wireVideo(node);
        }
        if (node.nodeName === 'SOURCE' && node.parentNode) {
          reportVideo(node.src);
        }
        if (node.querySelectorAll) {
          node.querySelectorAll('video').forEach(wireVideo);
          node.querySelectorAll('source').forEach(function(s) {
            reportVideo(s.src);
          });
        }
      });
    });
  });

  function wireVideo(v) {
    if (v.__cinebyWired) return;
    v.__cinebyWired = true;
    reportVideo(v.src);
    v.addEventListener('loadstart', function() {
      reportVideo(v.src);
    });
    v.addEventListener('play', function() {
      reportVideo(v.currentSrc || v.src);
    });
  }

  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['src']
  });

  // Wire any videos that already exist
  document.querySelectorAll('video').forEach(wireVideo);
  document.querySelectorAll('source').forEach(function(s) {
    reportVideo(s.src);
  });

  // Patch XMLHttpRequest to catch m3u8 playlist requests
  const origOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url) {
    try {
      if (typeof url === 'string') reportVideo(url);
    } catch (e) { /* noop */ }
    return origOpen.apply(this, arguments);
  };

  // Patch fetch as well — some players use fetch() for HLS
  if (window.fetch) {
    const origFetch = window.fetch;
    window.fetch = function(input, init) {
      try {
        const u = typeof input === 'string'
          ? input
          : (input && input.url) || '';
        reportVideo(u);
      } catch (e) { /* noop */ }
      return origFetch.apply(this, arguments);
    };
  }
})();
""";

/// Inject a click handler over the site's own download buttons. Tapping them
/// posts the URL and document title to Flutter via `DownloadChannel`.
const String downloadButtonScript = r"""
(function() {
  if (window.__cinebyDownloadHandlerInstalled) return;
  window.__cinebyDownloadHandlerInstalled = true;

  const selectors = [
    '[data-download]',
    '.download-btn',
    'button[aria-label*="download" i]',
    'a[aria-label*="download" i]',
    'button[title*="download" i]',
    'a[title*="download" i]'
  ];

  function wireButton(btn) {
    if (btn.__cinebyWired) return;
    btn.__cinebyWired = true;
    btn.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      const url =
        btn.getAttribute('href') ||
        btn.getAttribute('data-src') ||
        btn.getAttribute('data-url') ||
        '';
      const title = document.title || 'Cineby Download';
      try {
        window.DownloadChannel.postMessage(JSON.stringify({
          url: url,
          title: title
        }));
      } catch (err) { /* noop */ }
    }, true);
  }

  function wireAll() {
    selectors.forEach(function(sel) {
      document.querySelectorAll(sel).forEach(wireButton);
    });
  }

  wireAll();

  // Re-wire when DOM changes (SPA route changes can re-render buttons)
  const obs = new MutationObserver(function() { wireAll(); });
  obs.observe(document.documentElement, { childList: true, subtree: true });
})();
""";

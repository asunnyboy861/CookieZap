(() => {
  const REJECT_TEXTS = [
    'reject', 'decline', 'refuse', 'deny', 'opt out', 'opt-out',
    'only necessary', 'essential only', 'necessary only',
    'accept necessary', 'essential cookies', 'necessary cookies',
    'do not consent', "don't consent", 'non-consent',
    'manage choices', 'cookie choices', 'customize',
    'reject all', 'decline all', 'refuse all', 'deny all',
    'i refuse', 'i decline', 'no thanks', 'no, thanks',
    'continue without', 'proceed without', 'without accepting',
    'disagree', "don't agree", 'do not agree'
  ];

  const CMP_SELECTORS = [
    '#onetrust-banner-sdk', '#onetrust-consent-sdk',
    '.cookie-banner', '.cookie-consent', '.cookie-notice',
    '.cookie-popup', '.cookie-bar', '.cookie-warning',
    '#cookie-banner', '#cookie-consent', '#cookie-notice',
    '#cookie-popup', '#cookie-bar', '#cookie-warning',
    '[class*="cookie-banner"]', '[class*="cookie-consent"]',
    '[class*="cookie-notice"]', '[class*="cookie-popup"]',
    '[id*="cookie-banner"]', '[id*="cookie-consent"]',
    '[id*="cookie-notice"]', '[id*="cookie-popup"]',
    '#CybotCookiebotDialog', '#CybotCookiebotDialogBody',
    '.cc-window', '.cc-banner', '#cc-banner',
    '#consent-banner', '.consent-banner',
    '#gdpr-banner', '.gdpr-banner',
    '#js-gdpr-notice', '.js-gdpr-notice',
    '#truste-consent-track', '.truste-consent-track',
    '.qc-cmp2-container', '#qc-cmp2-container',
    '#__tealiumGDPRecModal', '.tealium-gdpr',
    '#didomi-popup', '.didomi-popup',
    '#popin-tc', '.popin-tc',
    '.cky-consent-container', '.cky-banner',
    '#usercentrics-root', '[data-testid="uc-default-banner"]',
    '#borlabs-cookie-banner', '.borlabs-cookie',
    '#cmplz-cookiebanner-container', '.cmplz-cookiebanner',
    '.cli-bar-container', '#cliSettingsPopup',
    '#moove_gdpr_cookie_info_bar', '.moove-gdpr-info-bar',
    '.gdpr-cookie-banner', '#gdpr-cookie-banner'
  ];

  let isEnabled = true;
  let blockingMode = 'smart';
  let whitelistDomains = [];

  function loadSettings() {
    try {
      if (typeof safari !== 'undefined' && safari.extension) {
        safari.extension.dispatchMessage('getSettings');
      }
      const settings = localStorage.getItem('cookiezap_settings');
      if (settings) {
        const parsed = JSON.parse(settings);
        isEnabled = parsed.isEnabled !== false;
        blockingMode = parsed.blockingMode || 'smart';
        whitelistDomains = parsed.whitelistDomains || [];
      }
    } catch (e) {}
  }

  function saveSettings() {
    try {
      localStorage.setItem('cookiezap_settings', JSON.stringify({
        isEnabled: isEnabled,
        blockingMode: blockingMode,
        whitelistDomains: whitelistDomains
      }));
    } catch (e) {}
  }

  function isWhitelisted() {
    const hostname = window.location.hostname.toLowerCase();
    return whitelistDomains.some(d => hostname === d || hostname.endsWith('.' + d));
  }

  function findRejectButton(container) {
    const buttons = container.querySelectorAll(
      'button, a, input[type="button"], input[type="submit"], [role="button"], [tabindex]'
    );

    for (const btn of buttons) {
      const text = (btn.textContent || btn.value || btn.getAttribute('aria-label') || '').toLowerCase().trim();
      const title = (btn.getAttribute('title') || '').toLowerCase().trim();
      const combined = text + ' ' + title;

      for (const rejectText of REJECT_TEXTS) {
        if (combined.includes(rejectText)) {
          return btn;
        }
      }
    }

    return null;
  }

  function findSettingsButton(container) {
    const settingsTexts = [
      'manage', 'settings', 'options', 'preferences', 'customize',
      'configure', 'more options', 'more choices', 'cookie settings',
      'cookie options', 'cookie preferences', 'manage cookies',
      'manage choices', 'manage preferences', 'manage settings'
    ];

    const buttons = container.querySelectorAll(
      'button, a, input[type="button"], [role="button"], [tabindex]'
    );

    for (const btn of buttons) {
      const text = (btn.textContent || btn.getAttribute('aria-label') || '').toLowerCase().trim();
      for (const settingsText of settingsTexts) {
        if (text.includes(settingsText)) {
          return btn;
        }
      }
    }

    return null;
  }

  function findCMPBanner() {
    for (const selector of CMP_SELECTORS) {
      const el = document.querySelector(selector);
      if (el && el.offsetParent !== null) {
        return el;
      }
    }

    const allDivs = document.querySelectorAll('div[style*="position: fixed"], div[style*="position:fixed"]');
    for (const div of allDivs) {
      if (div.offsetParent !== null && isLikelyCookieBanner(div)) {
        return div;
      }
    }

    return null;
  }

  function isLikelyCookieBanner(el) {
    const text = (el.textContent || '').toLowerCase();
    const cookieKeywords = ['cookie', 'cookies', 'gdpr', 'consent', 'privacy', 'tracking', 'data processing'];
    const matchCount = cookieKeywords.filter(k => text.includes(k)).length;
    if (matchCount < 2) return false;

    const rect = el.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    if (rect.top > viewportHeight * 0.7 || rect.bottom < viewportHeight * 0.1) return false;

    const buttons = el.querySelectorAll('button, a, input[type="button"], input[type="submit"]');
    if (buttons.length === 0) return false;

    return true;
  }

  function zapBanner(banner) {
    const cmp = detectCMP(banner);

    if (blockingMode === 'smart') {
      const rejectBtn = findRejectButton(banner);
      if (rejectBtn) {
        rejectBtn.click();
        reportZap('rejected', cmp);
        return;
      }

      const settingsBtn = findSettingsButton(banner);
      if (settingsBtn) {
        settingsBtn.click();
        setTimeout(() => {
          const rejectBtn = findRejectButton(document);
          if (rejectBtn) {
            rejectBtn.click();
            reportZap('rejected', cmp);
          }
        }, 500);
        return;
      }
    }

    banner.style.setProperty('display', 'none', 'important');
    reportZap('hidden', cmp);

    const overlay = document.querySelector('.cookiezap-overlay');
    if (overlay) overlay.style.setProperty('display', 'none', 'important');
  }

  function detectCMP(banner) {
    const id = banner.id || '';
    const classes = banner.className || '';

    if (id.includes('onetrust') || classes.includes('onetrust')) return 'OneTrust';
    if (id.includes('CybotCookiebot') || classes.includes('CybotCookiebot')) return 'Cookiebot';
    if (id.includes('cc-') || classes.includes('cc-')) return 'CookieConsent';
    if (id.includes('didomi') || classes.includes('didomi')) return 'Didomi';
    if (id.includes('usercentrics') || id.includes('uc-')) return 'Usercentrics';
    if (id.includes('borlabs') || classes.includes('borlabs')) return 'Borlabs';
    if (id.includes('cmplz') || classes.includes('cmplz')) return 'Complianz';
    if (id.includes('cky') || classes.includes('cky')) return 'CookieYes';
    if (id.includes('qc-cmp')) return 'Quantcast';
    if (id.includes('truste')) return 'TrustArc';
    if (id.includes('moove') || classes.includes('moove')) return 'Moove';
    if (id.includes('cli-') || classes.includes('cli-')) return 'CookieLawInfo';

    return 'Unknown';
  }

  function reportZap(action, cmp) {
    try {
      if (typeof safari !== 'undefined' && safari.extension) {
        safari.extension.dispatchMessage('zapEvent', {
          domain: window.location.hostname,
          action: action,
          cmp: cmp
        });
      }
    } catch (e) {}
  }

  function scan() {
    if (!isEnabled || isWhitelisted()) return;

    const banner = findCMPBanner();
    if (banner) {
      zapBanner(banner);
    }
  }

  loadSettings();

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => setTimeout(scan, 300));
  } else {
    setTimeout(scan, 300);
  }

  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === Node.ELEMENT_NODE) {
          if (node.matches && CMP_SELECTORS.some(s => {
            try { return node.matches(s); } catch(e) { return false; }
          })) {
            setTimeout(() => zapBanner(node), 100);
            return;
          }
          if (node.querySelector) {
            for (const selector of CMP_SELECTORS) {
              try {
                const match = node.querySelector(selector);
                if (match) {
                  setTimeout(() => zapBanner(match), 100);
                  return;
                }
              } catch(e) {}
            }
          }
        }
      }
    }
  });

  observer.observe(document.documentElement || document.body, {
    childList: true,
    subtree: true
  });

  if (typeof safari !== 'undefined' && safari.self) {
    safari.self.addEventListener('message', (event) => {
      if (event.name === 'settingsUpdated') {
        loadSettings();
        scan();
      }
    });
  }
})();

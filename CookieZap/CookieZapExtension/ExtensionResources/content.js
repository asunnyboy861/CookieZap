(() => {
  'use strict';

  if (window.__cookiezapLoaded) return;
  window.__cookiezapLoaded = true;

  const DEFAULT_SETTINGS = {
    isEnabled: true,
    blockingMode: 'smart',
    whitelistDomains: []
  };

  const HIDE_SELECTORS = [
    '#onetrust-banner-sdk',
    '#onetrust-pc-sdk',
    '#CybotCookiebotDialog',
    '#CybotCookiebotDialogBodyUnderlay',
    '#usercentrics-root',
    '#usercentrics-button',
    '#didomi-host',
    '#didomi-popup',
    '#qc-cmp2-container',
    '.qc-cmp2-container',
    '[id^="sp_message_container_"]',
    '#truste-consent-track',
    '#truste-consent-content',
    '.truste_overlay',
    '.truste_box_overlay',
    '#osano-cm-window',
    '#cookieyes-consent',
    '.cky-consent-container',
    '#hs-eu-cookie-confirmation',
    '#iubenda-cs-banner',
    '#gdpr-cookie-message',
    '#cookiebanner',
    '#cookie-banner',
    '.cookie-consent-banner',
    '.cc-window',
    '.cc-banner'
  ];

  const HIDE_STYLE_ID = 'cookiezap-hide-style';

  let settings = Object.assign({}, DEFAULT_SETTINGS);
  let engineStarted = false;
  let hideModeActive = false;
  let hideObserver = null;
  let hideReported = false;
  let reported = {};
  let host = '';

  const isTopFrame = (() => {
    try {
      return window.top === window;
    } catch (e) {
      return false;
    }
  })();

  const pageStatus = {
    available: true,
    isTopFrame,
    host: '',
    enabled: true,
    mode: 'smart',
    whitelisted: false,
    detectedCmp: null,
    action: null,
    cmp: null,
    zapped: 0
  };

  function safeSend(message) {
    try {
      if (typeof browser === 'undefined' || !browser.runtime || !browser.runtime.sendMessage) {
        return Promise.resolve(null);
      }
      const result = browser.runtime.sendMessage(message);
      if (result && typeof result.then === 'function') {
        return result.catch(() => null);
      }
      return Promise.resolve(result || null);
    } catch (e) {
      return Promise.resolve(null);
    }
  }

  function withTimeout(promise, ms) {
    return new Promise((resolve) => {
      let settled = false;
      const timer = setTimeout(() => {
        if (!settled) {
          settled = true;
          resolve(null);
        }
      }, ms);
      Promise.resolve(promise)
        .then((value) => {
          if (!settled) {
            settled = true;
            clearTimeout(timer);
            resolve(value);
          }
        })
        .catch(() => {
          if (!settled) {
            settled = true;
            clearTimeout(timer);
            resolve(null);
          }
        });
    });
  }

  function normalizeDomain(value) {
    if (!value || typeof value !== 'string') return '';
    return value
      .trim()
      .toLowerCase()
      .replace(/^https?:\/\//, '')
      .replace(/^www\./, '')
      .split('/')[0];
  }

  function normalizeSettings(input) {
    const next = Object.assign({}, DEFAULT_SETTINGS);
    if (!input || typeof input !== 'object') return next;
    if (typeof input.isEnabled === 'boolean') next.isEnabled = input.isEnabled;
    if (typeof input.enabled === 'boolean') next.isEnabled = input.enabled;
    if (typeof input.blockingMode === 'string') next.blockingMode = input.blockingMode;
    if (typeof input.mode === 'string') next.blockingMode = input.mode;
    if (Array.isArray(input.whitelistDomains)) {
      next.whitelistDomains = input.whitelistDomains.map(normalizeDomain).filter(Boolean);
    }
    return next;
  }

  async function loadSettings() {
    let remote = null;
    try {
      remote = await withTimeout(safeSend({ action: 'getSettings' }), 1500);
    } catch (e) {}

    if (remote && typeof remote === 'object' && (remote.isEnabled !== undefined || remote.blockingMode !== undefined)) {
      settings = normalizeSettings(remote);
      return settings;
    }

    try {
      if (typeof browser !== 'undefined' && browser.storage && browser.storage.local) {
        const cached = await withTimeout(
          browser.storage.local.get(['isEnabled', 'blockingMode', 'whitelistDomains']),
          800
        );
        if (cached && (cached.isEnabled !== undefined || cached.blockingMode !== undefined)) {
          settings = normalizeSettings(cached);
          return settings;
        }
      }
    } catch (e) {}

    settings = Object.assign({}, DEFAULT_SETTINGS);
    return settings;
  }

  function isWhitelisted() {
    if (!host) return false;
    return settings.whitelistDomains.some((domain) => host === domain || host.endsWith('.' + domain));
  }

  function updateStatus() {
    pageStatus.host = host;
    pageStatus.enabled = settings.isEnabled;
    pageStatus.mode = settings.blockingMode;
    pageStatus.whitelisted = isWhitelisted();
  }

  function sendZap(action, cmp) {
    const name = cmp || 'Unknown';
    const key = name + ':' + action;
    if (reported[key]) return;
    reported[key] = true;

    pageStatus.action = action;
    pageStatus.cmp = name;
    pageStatus.zapped += 1;

    const payload = {
      action: 'zapEvent',
      domain: host || 'unknown',
      actionType: action,
      cmp: name
    };

    if (isTopFrame) {
      safeSend(payload);
    } else {
      try {
        window.top.postMessage({ __cookiezapFrameZap: true, payload }, '*');
      } catch (e) {}
    }
  }

  function handleFrameZap(event) {
    if (!isTopFrame) return;
    if (!event || !event.data || !event.data.__cookiezapFrameZap) return;
    const payload = event.data.payload;
    if (!payload) return;
    sendZap(payload.actionType || 'rejected', payload.cmp || 'Unknown');
  }

  function bridgeEval(message) {
    if (!message || !message.id) return;
    safeSend({ action: 'evalInPage', code: message.code || '' })
      .then((response) => {
        const result = response && typeof response === 'object' ? response.result : null;
        if (window.CookieZapAutoconsent) {
          window.CookieZapAutoconsent.receiveMessage({
            type: 'evalResp',
            id: message.id,
            result: result === undefined ? null : result
          });
        }
      })
      .catch(() => {
        if (window.CookieZapAutoconsent) {
          window.CookieZapAutoconsent.receiveMessage({
            type: 'evalResp',
            id: message.id,
            result: null
          });
        }
      });
  }

  window.__cookiezapReport = (message) => {
    if (!message || !message.type) return Promise.resolve();

    if (message.type === 'eval') {
      bridgeEval(message);
      return Promise.resolve();
    }

    if (message.type === 'cmpDetected') {
      pageStatus.detectedCmp = message.cmp || null;
    } else if (message.type === 'popupFound') {
      pageStatus.detectedCmp = message.cmp || pageStatus.detectedCmp;
      pageStatus.cmp = message.cmp || pageStatus.cmp;
    } else if (message.type === 'optOutResult') {
      if (message.result) {
        sendZap('rejected', message.cmp);
      }
    } else if (message.type === 'autoconsentDone') {
      if (message.isCosmetic) {
        sendZap('hidden', message.cmp);
      }
    }

    return Promise.resolve();
  };

  function ensureHideStyle() {
    if (document.getElementById(HIDE_STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = HIDE_STYLE_ID;
    style.textContent = HIDE_SELECTORS.map((selector) => selector + '{display:none !important;}').join('\n');
    (document.head || document.documentElement).appendChild(style);
  }

  function removeHideStyle() {
    const style = document.getElementById(HIDE_STYLE_ID);
    if (style && style.parentNode) style.parentNode.removeChild(style);
  }

  function unlockScrollIfNeeded() {
    if (hideReported) return;
    try {
      document.documentElement.style.setProperty('overflow', 'auto', 'important');
      document.body.style.setProperty('overflow', 'auto', 'important');
    } catch (e) {}
  }

  function scanHiddenBanner() {
    if (!isTopFrame) return;
    for (const selector of HIDE_SELECTORS) {
      let node = null;
      try {
        node = document.querySelector(selector);
      } catch (e) {}
      if (node) {
        if (!hideReported) {
          hideReported = true;
          unlockScrollIfNeeded();
          sendZap('hidden', selector);
        }
        return;
      }
    }
  }

  function startHideMode() {
    if (hideModeActive) return;
    hideModeActive = true;
    ensureHideStyle();
    scanHiddenBanner();
    setTimeout(scanHiddenBanner, 500);
    setTimeout(scanHiddenBanner, 1500);

    try {
      hideObserver = new MutationObserver(() => scanHiddenBanner());
      hideObserver.observe(document.documentElement || document, { childList: true, subtree: true });
    } catch (e) {}
  }

  function startEngine() {
    if (engineStarted) return;
    if (!window.CookieZapAutoconsent) return;
    engineStarted = true;
    try {
      window.CookieZapAutoconsent.start({});
    } catch (e) {
      engineStarted = false;
    }
  }

  function applySettings() {
    host = normalizeDomain(location.hostname);
    pageStatus.host = host;
    updateStatus();

    if (!settings.isEnabled || isWhitelisted()) {
      removeHideStyle();
      if (hideObserver) {
        hideObserver.disconnect();
        hideObserver = null;
      }
      hideModeActive = false;
      return;
    }

    if (settings.blockingMode === 'hide' || settings.blockingMode === 'block') {
      startHideMode();
      return;
    }

    removeHideStyle();
    if (hideObserver) {
      hideObserver.disconnect();
      hideObserver = null;
    }
    hideModeActive = false;
    startEngine();
  }

  function getStatusSnapshot() {
    const snapshot = Object.assign({}, pageStatus);
    snapshot.whitelisted = isWhitelisted();
    snapshot.enabled = settings.isEnabled;
    snapshot.mode = settings.blockingMode;
    if (window.CookieZapAutoconsent && typeof window.CookieZapAutoconsent.getStatus === 'function') {
      const engineStatus = window.CookieZapAutoconsent.getStatus();
      if (engineStatus) {
        snapshot.detectedCmp = engineStatus.detected || snapshot.detectedCmp;
      }
    }
    return snapshot;
  }

  function manualZap() {
    if (!settings.isEnabled || isWhitelisted()) {
      return { ok: false, reason: 'paused' };
    }
    if (settings.blockingMode === 'smart') {
      startEngine();
      if (window.CookieZapAutoconsent) {
        window.CookieZapAutoconsent.forceOptOut();
      }
    } else {
      startHideMode();
      scanHiddenBanner();
    }
    return { ok: true };
  }

  try {
    if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.onMessage) {
      browser.runtime.onMessage.addListener((message) => {
        if (!message || typeof message !== 'object') return undefined;

        if (message.type === 'getPageStatus') {
          if (!isTopFrame) return undefined;
          return Promise.resolve(getStatusSnapshot());
        }

        if (message.type === 'manualZap') {
          if (!isTopFrame) return undefined;
          return Promise.resolve(manualZap());
        }

        if (message.type === 'settingsUpdated' && message.settings) {
          settings = normalizeSettings(message.settings);
          applySettings();
          return Promise.resolve({ ok: true });
        }

        return undefined;
      });
    }
  } catch (e) {}

  window.addEventListener('message', handleFrameZap, false);

  function init() {
    loadSettings().then(() => {
      applySettings();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init, { once: true });
  } else {
    init();
  }
})();

(() => {
  'use strict';

  const MODE_HINTS = {
    smart: 'Finds and clicks “Reject” for you.',
    hide: 'Hides known cookie banners without clicking.',
    block: 'Hides banners and blocks known consent scripts.'
  };

  const el = {
    siteName: document.getElementById('siteName'),
    enableToggle: document.getElementById('enableToggle'),
    statusCard: document.getElementById('statusCard'),
    statusDot: document.getElementById('statusDot'),
    statusTitle: document.getElementById('statusTitle'),
    statusDetail: document.getElementById('statusDetail'),
    zapButton: document.getElementById('zapButton'),
    todayCount: document.getElementById('todayCount'),
    totalCount: document.getElementById('totalCount'),
    modeButtons: Array.from(document.querySelectorAll('.mode')),
    modeHint: document.getElementById('modeHint'),
    whitelistToggle: document.getElementById('whitelistToggle'),
    ruleCount: document.getElementById('ruleCount')
  };

  const state = {
    tabId: null,
    host: '',
    settings: { isEnabled: true, blockingMode: 'smart', whitelistDomains: [] },
    page: null,
    supported: true
  };

  function send(message) {
    try {
      if (!browser || !browser.runtime) return Promise.resolve(null);
      const result = browser.runtime.sendMessage(message);
      return result && typeof result.then === 'function' ? result.catch(() => null) : Promise.resolve(result || null);
    } catch (e) {
      return Promise.resolve(null);
    }
  }

  function sendToTab(message) {
    try {
      if (!browser || !browser.tabs || state.tabId === null) return Promise.resolve(null);

      try {
        const withFrame = browser.tabs.sendMessage(state.tabId, message, { frameId: 0 });
        if (withFrame && typeof withFrame.then === 'function') {
          return withFrame.catch(() => {
            return browser.tabs.sendMessage(state.tabId, message).catch(() => null);
          });
        }
      } catch (e) {}

      const result = browser.tabs.sendMessage(state.tabId, message);
      return result && typeof result.then === 'function' ? result.catch(() => null) : Promise.resolve(result || null);
    } catch (e) {
      return Promise.resolve(null);
    }
  }

  function hostFromUrl(url) {
    if (!url) return '';
    try {
      const parsed = new URL(url);
      if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return '';
      return parsed.hostname.replace(/^www\./, '');
    } catch (e) {
      return '';
    }
  }

  function isWhitelisted() {
    if (!state.host) return false;
    return (state.settings.whitelistDomains || []).some((domain) => {
      return state.host === domain || state.host.endsWith('.' + domain);
    });
  }

  function setDot(color) {
    el.statusDot.className = 'dot' + (color ? ' ' + color : '');
  }

  function renderStatus() {
    const whitelisted = isWhitelisted();
    const enabled = state.settings.isEnabled;

    el.enableToggle.checked = enabled;
    el.whitelistToggle.checked = whitelisted;
    el.whitelistToggle.disabled = !enabled || !state.supported;

    el.modeButtons.forEach((button) => {
      button.classList.toggle('active', button.dataset.mode === state.settings.blockingMode);
    });
    el.modeHint.textContent = MODE_HINTS[state.settings.blockingMode] || MODE_HINTS.smart;

    if (!state.supported) {
      setDot('');
      el.statusTitle.textContent = 'No website open';
      el.statusDetail.textContent = 'Open a website in Safari to see CookieZap in action.';
      el.zapButton.disabled = true;
      return;
    }

    if (!enabled) {
      setDot('red');
      el.statusTitle.textContent = 'CookieZap is off';
      el.statusDetail.textContent = 'Turn it on to reject cookie popups on every site.';
      el.zapButton.disabled = true;
      return;
    }

    if (whitelisted) {
      setDot('orange');
      el.statusTitle.textContent = 'Paused on this site';
      el.statusDetail.textContent = 'Cookie banners are allowed here. Turn off “Pause on this site” to protect it.';
      el.zapButton.disabled = true;
      return;
    }

    el.zapButton.disabled = false;

    if (!state.page) {
      setDot('green');
      el.statusTitle.textContent = 'Ready to protect';
      el.statusDetail.textContent = 'Reload the page if you just enabled CookieZap.';
      return;
    }

    if (state.page.zapped > 0 || state.page.action) {
      const action = state.page.action === 'hidden' ? 'Hidden automatically' : 'Rejected automatically';
      const cmp = state.page.cmp && state.page.cmp !== 'Unknown' ? state.page.cmp : 'Cookie banner';
      setDot('green');
      el.statusTitle.textContent = state.page.zapped > 1
        ? state.page.zapped + ' popups zapped'
        : 'Popup zapped';
      el.statusDetail.textContent = cmp + ' · ' + action + ' on this page.';
      return;
    }

    if (state.page.detectedCmp) {
      setDot('orange');
      el.statusTitle.textContent = 'Banner detected';
      el.statusDetail.textContent = state.page.detectedCmp + ' is on this page. CookieZap is handling it.';
      return;
    }

    setDot('green');
    el.statusTitle.textContent = 'No cookie banner here';
    el.statusDetail.textContent = 'CookieZap is watching this page and will act the moment one appears.';
  }

  async function refreshStats() {
    const stats = await send({ action: 'getStats' });
    if (stats && typeof stats === 'object') {
      el.todayCount.textContent = stats.todayZapped || 0;
      el.totalCount.textContent = stats.totalZapped || 0;
    }
  }

  async function refreshPageStatus() {
    state.page = await sendToTab({ type: 'getPageStatus' });
    renderStatus();
  }

  async function refreshSettings() {
    const settings = await send({ action: 'getSettings' });
    if (settings && typeof settings === 'object') {
      state.settings = {
        isEnabled: settings.isEnabled !== false,
        blockingMode: settings.blockingMode || 'smart',
        whitelistDomains: Array.isArray(settings.whitelistDomains) ? settings.whitelistDomains : []
      };
    }
    renderStatus();
  }

  async function init() {
    try {
      const tabs = await browser.tabs.query({ active: true, currentWindow: true });
      const tab = tabs && tabs[0];
      if (tab) {
        state.tabId = tab.id;
        state.host = hostFromUrl(tab.url);
        state.supported = !!state.host;
      }
    } catch (e) {
      state.supported = false;
    }

    el.siteName.textContent = state.host || 'No website open';

    await Promise.all([refreshSettings(), refreshStats()]);
    await refreshPageStatus();
  }

  el.enableToggle.addEventListener('change', async () => {
    state.settings.isEnabled = el.enableToggle.checked;
    const updated = await send({ action: 'updateSettings', isEnabled: el.enableToggle.checked });
    if (updated && updated.isEnabled !== undefined) state.settings = updated;
    renderStatus();
    setTimeout(refreshPageStatus, 250);
  });

  el.modeButtons.forEach((button) => {
    button.addEventListener('click', async () => {
      state.settings.blockingMode = button.dataset.mode;
      renderStatus();
      const updated = await send({ action: 'updateSettings', blockingMode: button.dataset.mode });
      if (updated && updated.blockingMode) state.settings = updated;
      renderStatus();
      setTimeout(refreshPageStatus, 250);
    });
  });

  el.whitelistToggle.addEventListener('change', async () => {
    if (!state.host) return;
    const updated = await send({
      action: 'setWhitelisted',
      domain: state.host,
      whitelisted: el.whitelistToggle.checked
    });
    if (updated && updated.whitelistDomains) state.settings = updated;
    renderStatus();
    setTimeout(refreshPageStatus, 250);
  });

  el.zapButton.addEventListener('click', async () => {
    el.zapButton.disabled = true;
    el.statusTitle.textContent = 'Zapping…';
    el.statusDetail.textContent = 'Looking for a cookie banner on this page.';
    const result = await sendToTab({ type: 'manualZap' });
    setTimeout(async () => {
      await refreshPageStatus();
      await refreshStats();
      if (!result || !result.ok) {
        el.statusDetail.textContent = 'Reload the page, then try again.';
      }
    }, 1200);
  });

  document.addEventListener('DOMContentLoaded', init);
  if (document.readyState !== 'loading') init();
})();

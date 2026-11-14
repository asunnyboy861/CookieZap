const DEFAULT_SETTINGS = {
  isEnabled: true,
  blockingMode: 'smart',
  whitelistDomains: []
};

const CACHE_KEYS = ['isEnabled', 'blockingMode', 'whitelistDomains'];

function safeStorageGet(keys) {
  try {
    if (typeof browser !== 'undefined' && browser.storage && browser.storage.local) {
      return browser.storage.local.get(keys).catch(() => null);
    }
  } catch (e) {}
  return Promise.resolve(null);
}

function safeStorageSet(value) {
  try {
    if (typeof browser !== 'undefined' && browser.storage && browser.storage.local) {
      return browser.storage.local.set(value).catch(() => {});
    }
  } catch (e) {}
  return Promise.resolve();
}

function nativeRequest(message) {
  try {
    if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.sendNativeMessage) {
      const result = browser.runtime.sendNativeMessage('cookiezap', message);
      if (result && typeof result.then === 'function') {
        return result.catch(() => null);
      }
      return Promise.resolve(result || null);
    }
  } catch (e) {}
  return Promise.resolve(null);
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

async function readNativeSettings() {
  const response = await nativeRequest({ action: 'getSettings' });
  if (response && typeof response === 'object' && response.isEnabled !== undefined) {
    return normalizeSettings(response);
  }
  return null;
}

async function getSettings(forceRefresh) {
  const native = await readNativeSettings();
  if (native) {
    await safeStorageSet(native);
    return native;
  }

  if (!forceRefresh) {
    const cached = await safeStorageGet(CACHE_KEYS);
    if (cached && cached.isEnabled !== undefined) {
      return normalizeSettings(cached);
    }
  }

  return Object.assign({}, DEFAULT_SETTINGS);
}

async function persistSettings(settings) {
  await safeStorageSet(settings);
  await nativeRequest({
    action: 'updateSettings',
    isEnabled: settings.isEnabled,
    blockingMode: settings.blockingMode,
    whitelistDomains: settings.whitelistDomains
  });
  broadcastSettings(settings);
  return settings;
}

function broadcastSettings(settings) {
  try {
    if (typeof browser === 'undefined' || !browser.tabs || !browser.tabs.query) return;
    browser.tabs.query({}).then((tabs) => {
      for (const tab of tabs) {
        if (!tab || tab.id === undefined) continue;
        browser.tabs.sendMessage(tab.id, { type: 'settingsUpdated', settings }).catch(() => {});
      }
    }).catch(() => {});
  } catch (e) {}
}

async function updateSettings(patch) {
  const current = await getSettings(false);
  const next = normalizeSettings(Object.assign({}, current, patch));
  return persistSettings(next);
}

async function setWhitelisted(domain, whitelisted) {
  const clean = normalizeDomain(domain);
  if (!clean) return getSettings(false);

  const current = await getSettings(false);
  const domains = new Set(current.whitelistDomains);
  if (whitelisted) {
    domains.add(clean);
  } else {
    domains.delete(clean);
  }

  return updateSettings({ whitelistDomains: Array.from(domains) });
}

async function getStats() {
  const response = await nativeRequest({ action: 'getStats' });
  if (response && typeof response === 'object') return response;
  return { todayZapped: 0, totalZapped: 0, totalRejected: 0, totalAttempted: 0 };
}

async function evalInPage(message, sender) {
  const tabId = sender && sender.tab ? sender.tab.id : undefined;
  if (tabId === undefined) return { result: null };
  if (!message || typeof message.code !== 'string') return { result: null };

  const target = { tabId };
  if (sender.frameId !== undefined && sender.frameId !== null) {
    target.frameIds = [sender.frameId];
  }

  try {
    if (typeof browser === 'undefined' || !browser.scripting || !browser.scripting.executeScript) {
      return { result: null };
    }

    const injections = await browser.scripting.executeScript({
      target,
      world: 'MAIN',
      args: [message.code],
      func: (source) => {
        try {
          let value;
          try {
            value = (0, eval)(source);
          } catch (inner) {
            value = new Function('return (' + source + ')')();
          }
          if (value && typeof value.then === 'function') return null;
          if (value === undefined) return null;
          return JSON.parse(JSON.stringify(value));
        } catch (e) {
          return null;
        }
      }
    });

    const first = Array.isArray(injections) ? injections[0] : injections;
    return { result: first && first.result !== undefined ? first.result : null };
  } catch (e) {
    return { result: null };
  }
}

try {
  if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.onMessage) {
    browser.runtime.onMessage.addListener((message, sender) => {
      if (!message || typeof message !== 'object') return undefined;

      switch (message.action) {
        case 'getSettings':
          return getSettings(false);
        case 'updateSettings':
          return updateSettings(message);
        case 'setWhitelisted':
          return setWhitelisted(message.domain, !!message.whitelisted);
        case 'getStats':
          return getStats();
        case 'zapEvent':
          nativeRequest(message).catch(() => {});
          return Promise.resolve({ status: 'ok' });
        case 'evalInPage':
          return evalInPage(message, sender);
        default:
          return undefined;
      }
    });
  }
} catch (e) {}

try {
  if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.onInstalled) {
    browser.runtime.onInstalled.addListener(() => {
      getSettings(true).catch(() => {});
    });
  }
  if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.onStartup) {
    browser.runtime.onStartup.addListener(() => {
      getSettings(true).catch(() => {});
    });
  }
} catch (e) {}

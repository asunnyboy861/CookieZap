(() => {
  if (typeof browser !== 'undefined' && browser.runtime) {
    browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
      if (message.type === 'getSettings') {
        sendResponse({
          isEnabled: true,
          blockingMode: 'smart',
          whitelistDomains: []
        });
      }
    });

    browser.storage?.local?.get(['isEnabled', 'blockingMode', 'whitelistDomains'], (result) => {
      if (result.isEnabled === undefined) {
        browser.storage?.local?.set({
          isEnabled: true,
          blockingMode: 'smart',
          whitelistDomains: []
        });
      }
    });
  }
})();

document.addEventListener('DOMContentLoaded', () => {
  const enableToggle = document.getElementById('enableToggle');
  const todayCount = document.getElementById('todayCount');
  const totalCount = document.getElementById('totalCount');
  const modeButtons = document.querySelectorAll('.mode-btn');
  const openAppLink = document.getElementById('openApp');

  function loadSettings() {
    if (typeof browser !== 'undefined' && browser.storage) {
      browser.storage.local.get(['isEnabled', 'blockingMode'], (result) => {
        enableToggle.checked = result.isEnabled !== false;
        updateModeButtons(result.blockingMode || 'smart');
      });
    } else {
      enableToggle.checked = true;
      updateModeButtons('smart');
    }
  }

  function updateModeButtons(mode) {
    modeButtons.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.mode === mode);
    });
  }

  enableToggle.addEventListener('change', () => {
    if (typeof browser !== 'undefined' && browser.storage) {
      browser.storage.local.set({ isEnabled: enableToggle.checked });
    }
  });

  modeButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const mode = btn.dataset.mode;
      if (typeof browser !== 'undefined' && browser.storage) {
        browser.storage.local.set({ blockingMode: mode });
      }
      updateModeButtons(mode);
    });
  });

  openAppLink.addEventListener('click', (e) => {
    e.preventDefault();
    if (typeof browser !== 'undefined' && browser.tabs) {
      browser.tabs.create({ url: 'cookiezap://open' });
    }
  });

  loadSettings();
});

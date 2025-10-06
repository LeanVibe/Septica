// Romanian Septica - Service Worker Registration
// Handles SW lifecycle, updates, and status notifications

class ServiceWorkerManager {
  constructor() {
    this.registration = null;
    this.isSupported = 'serviceWorker' in navigator;
    this.updateAvailable = false;

    // Callbacks
    this.onStatusChange = null;
    this.onUpdateAvailable = null;
    this.onInstalled = null;

    if (this.isSupported) {
      this.initialize();
    } else {
      console.warn('⚠️ Service Worker not supported in this browser');
    }
  }

  async initialize() {
    try {
      // Wait for page load
      if (document.readyState === 'loading') {
        await new Promise(resolve => {
          window.addEventListener('DOMContentLoaded', resolve);
        });
      }

      // Register service worker
      await this.register();

      // Setup update detection
      this.setupUpdateDetection();

      // Listen for controller changes
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        console.log('🔄 Service Worker: Controller changed');
        this.notifyStatusChange('controllerchange');
      });

      // Check for updates periodically (every 5 minutes)
      setInterval(() => {
        this.checkForUpdates();
      }, 5 * 60 * 1000);

      console.log('✅ Service Worker Manager initialized');
    } catch (error) {
      console.error('❌ Service Worker Manager initialization failed:', error);
    }
  }

  async register() {
    if (!this.isSupported) {
      throw new Error('Service Worker not supported');
    }

    try {
      console.log('🔧 Registering Service Worker...');

      this.registration = await navigator.serviceWorker.register('/service-worker.js', {
        scope: '/'
      });

      console.log('✅ Service Worker registered successfully');
      console.log(`📍 Scope: ${this.registration.scope}`);

      // Log initial state
      if (this.registration.installing) {
        console.log('📦 Service Worker: Installing...');
        this.trackInstalling(this.registration.installing);
      } else if (this.registration.waiting) {
        console.log('⏳ Service Worker: Waiting to activate');
        this.notifyUpdateAvailable();
      } else if (this.registration.active) {
        console.log('✅ Service Worker: Active');
        this.notifyStatusChange('active');
      }

      return this.registration;
    } catch (error) {
      console.error('❌ Service Worker registration failed:', error);
      throw error;
    }
  }

  setupUpdateDetection() {
    if (!this.registration) return;

    // Listen for new service worker installing
    this.registration.addEventListener('updatefound', () => {
      console.log('🆕 Service Worker: Update found');

      const newWorker = this.registration.installing;
      if (newWorker) {
        this.trackInstalling(newWorker);
      }
    });
  }

  trackInstalling(worker) {
    worker.addEventListener('statechange', () => {
      console.log(`🔄 Service Worker state: ${worker.state}`);

      if (worker.state === 'installed') {
        if (navigator.serviceWorker.controller) {
          // New service worker available
          console.log('🆕 New Service Worker available');
          this.updateAvailable = true;
          this.notifyUpdateAvailable();
        } else {
          // Service worker installed for the first time
          console.log('✅ Service Worker installed for the first time');
          this.notifyInstalled();
        }
      } else if (worker.state === 'activated') {
        console.log('✅ Service Worker activated');
        this.notifyStatusChange('activated');
      }
    });
  }

  async checkForUpdates() {
    if (!this.registration) return;

    try {
      console.log('🔍 Checking for Service Worker updates...');
      await this.registration.update();
    } catch (error) {
      console.warn('⚠️ Service Worker update check failed:', error);
    }
  }

  async skipWaiting() {
    if (!this.registration || !this.registration.waiting) {
      console.warn('⚠️ No waiting Service Worker to skip');
      return;
    }

    console.log('⏭️ Skipping waiting Service Worker...');

    // Send message to waiting service worker
    this.registration.waiting.postMessage({ type: 'SKIP_WAITING' });

    // Wait for controller change, then reload
    return new Promise((resolve) => {
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        console.log('🔄 Controller changed, reloading page...');
        window.location.reload();
        resolve();
      }, { once: true });
    });
  }

  async unregister() {
    if (!this.registration) {
      console.warn('⚠️ No Service Worker registered');
      return false;
    }

    try {
      console.log('🗑️ Unregistering Service Worker...');
      const success = await this.registration.unregister();

      if (success) {
        console.log('✅ Service Worker unregistered');
        this.registration = null;
      }

      return success;
    } catch (error) {
      console.error('❌ Service Worker unregistration failed:', error);
      return false;
    }
  }

  async getCacheStats() {
    if (!this.registration || !this.registration.active) {
      return null;
    }

    return new Promise((resolve, reject) => {
      const messageChannel = new MessageChannel();

      messageChannel.port1.onmessage = (event) => {
        if (event.data.error) {
          reject(event.data.error);
        } else {
          resolve(event.data);
        }
      };

      this.registration.active.postMessage(
        { type: 'CACHE_STATS' },
        [messageChannel.port2]
      );
    });
  }

  async clearCache() {
    if (!this.registration || !this.registration.active) {
      return false;
    }

    return new Promise((resolve, reject) => {
      const messageChannel = new MessageChannel();

      messageChannel.port1.onmessage = (event) => {
        if (event.data.success) {
          console.log('✅ Service Worker cache cleared');
          resolve(true);
        } else {
          reject(event.data.error);
        }
      };

      this.registration.active.postMessage(
        { type: 'CLEAR_CACHE' },
        [messageChannel.port2]
      );
    });
  }

  // Notification methods
  notifyStatusChange(status) {
    if (this.onStatusChange) {
      this.onStatusChange(status);
    }

    // Update UI if elements exist
    this.updateStatusUI(status);
  }

  notifyUpdateAvailable() {
    if (this.onUpdateAvailable) {
      this.onUpdateAvailable();
    }

    // Show update notification
    this.showUpdateNotification();
  }

  notifyInstalled() {
    if (this.onInstalled) {
      this.onInstalled();
    }

    console.log('🎉 Romanian Septica is now available offline!');
  }

  // UI update methods
  updateStatusUI(status) {
    const statusElement = document.getElementById('sw-status');
    if (statusElement) {
      statusElement.textContent = status;
      statusElement.className = `sw-status sw-status-${status}`;
    }
  }

  showUpdateNotification() {
    // Remove existing notification
    const existing = document.getElementById('sw-update-notification');
    if (existing) {
      existing.remove();
    }

    // Create update notification
    const notification = document.createElement('div');
    notification.id = 'sw-update-notification';
    notification.className = 'sw-update-notification';
    notification.innerHTML = `
      <div class="sw-update-content">
        <span class="sw-update-icon">🔄</span>
        <span class="sw-update-message">New version available!</span>
        <button class="sw-update-button" id="sw-update-button">Update</button>
        <button class="sw-dismiss-button" id="sw-dismiss-button">Later</button>
      </div>
    `;

    document.body.appendChild(notification);

    // Setup button handlers
    document.getElementById('sw-update-button').addEventListener('click', () => {
      this.skipWaiting();
    });

    document.getElementById('sw-dismiss-button').addEventListener('click', () => {
      notification.remove();
    });

    // Auto-show notification
    setTimeout(() => {
      notification.classList.add('show');
    }, 100);
  }

  // Utility methods
  isOnline() {
    return navigator.onLine;
  }

  getConnectionType() {
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
    return connection ? connection.effectiveType : 'unknown';
  }

  async getNetworkStatus() {
    return {
      online: this.isOnline(),
      connectionType: this.getConnectionType(),
      downlink: navigator.connection?.downlink || null,
      rtt: navigator.connection?.rtt || null,
      saveData: navigator.connection?.saveData || false
    };
  }
}

// ========================================
// Online/Offline Status Manager
// ========================================

class NetworkStatusManager {
  constructor() {
    this.isOnline = navigator.onLine;
    this.onStatusChange = null;

    this.initialize();
  }

  initialize() {
    window.addEventListener('online', () => {
      console.log('🌐 Network: Online');
      this.isOnline = true;
      this.updateStatusUI(true);

      if (this.onStatusChange) {
        this.onStatusChange(true);
      }

      // Trigger sync when coming back online
      if (window.offlineStorage) {
        window.offlineStorage.syncPendingMoves();
      }
    });

    window.addEventListener('offline', () => {
      console.log('🔌 Network: Offline');
      this.isOnline = false;
      this.updateStatusUI(false);

      if (this.onStatusChange) {
        this.onStatusChange(false);
      }
    });

    // Initial status
    this.updateStatusUI(this.isOnline);

    console.log('✅ Network Status Manager initialized');
  }

  updateStatusUI(online) {
    // Update offline indicator
    let indicator = document.getElementById('offline-indicator');

    if (!online) {
      if (!indicator) {
        indicator = document.createElement('div');
        indicator.id = 'offline-indicator';
        indicator.className = 'offline-indicator';
        indicator.innerHTML = `
          <span class="offline-icon">🔌</span>
          <span class="offline-text">Offline Mode</span>
        `;
        document.body.appendChild(indicator);
      }

      setTimeout(() => {
        indicator.classList.add('show');
      }, 100);
    } else {
      if (indicator) {
        indicator.classList.remove('show');
        setTimeout(() => {
          indicator.remove();
        }, 300);
      }
    }

    // Update connection status indicator if it exists
    const connectionDot = document.getElementById('connection-dot');
    if (connectionDot) {
      if (online) {
        connectionDot.classList.add('connected');
      } else {
        connectionDot.classList.remove('connected');
      }
    }

    const connectionText = document.getElementById('connection-text');
    if (connectionText) {
      connectionText.textContent = online ? 'Online' : 'Offline';
    }
  }
}

// ========================================
// Initialize on page load
// ========================================

// Global instances
window.swManager = null;
window.networkManager = null;

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeServiceWorker);
} else {
  initializeServiceWorker();
}

function initializeServiceWorker() {
  console.log('🚀 Initializing Romanian Septica PWA...');

  // Initialize Service Worker Manager
  window.swManager = new ServiceWorkerManager();

  // Initialize Network Status Manager
  window.networkManager = new NetworkStatusManager();

  // Setup callbacks
  window.swManager.onUpdateAvailable = () => {
    console.log('🆕 PWA update available');
  };

  window.swManager.onInstalled = () => {
    console.log('✅ PWA installed successfully');
    showInstallSuccessMessage();
  };

  window.networkManager.onStatusChange = (online) => {
    console.log(`🌐 Network status changed: ${online ? 'Online' : 'Offline'}`);

    if (online) {
      // Show reconnected message
      showNotification('🌐 Back online - syncing data...', 'success');
    } else {
      // Show offline message
      showNotification('🔌 Offline mode - changes will sync later', 'info');
    }
  };

  console.log('✅ Romanian Septica PWA initialized');
}

// ========================================
// Helper Functions
// ========================================

function showInstallSuccessMessage() {
  showNotification('🎉 Romanian Septica is now available offline!', 'success', 5000);
}

function showNotification(message, type = 'info', duration = 3000) {
  const notification = document.createElement('div');
  notification.className = `pwa-notification pwa-notification-${type}`;
  notification.textContent = message;

  document.body.appendChild(notification);

  setTimeout(() => {
    notification.classList.add('show');
  }, 100);

  setTimeout(() => {
    notification.classList.remove('show');
    setTimeout(() => {
      notification.remove();
    }, 300);
  }, duration);
}

// Export for modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    ServiceWorkerManager,
    NetworkStatusManager
  };
}

console.log('🎮 Romanian Septica Service Worker Registration loaded');

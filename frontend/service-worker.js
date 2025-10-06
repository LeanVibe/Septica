// Romanian Septica PWA - Service Worker
// Offline-first caching strategy with background sync

const CACHE_VERSION = 'v1.0.0';
const CACHE_NAME = `septica-pwa-${CACHE_VERSION}`;
const CACHE_MAX_SIZE = 50 * 1024 * 1024; // 50MB max cache size
const CACHE_MAX_AGE = 7 * 24 * 60 * 60 * 1000; // 7 days

// Critical assets to cache for offline functionality
const CRITICAL_ASSETS = [
  '/',
  '/index.html',
  '/premium-3d-demo.html',
  '/manifest.json',

  // Core CSS
  '/css/premium-glass-morphism.css',
  '/css/styles.css',
  '/css/mobile-optimizations.css',
  '/css/modern-styles.css',

  // Core JavaScript - Premium Components
  '/js/premium-card-material.js',
  '/js/premium-card-animations.js',
  '/js/romanian-ambient-lighting.js',
  '/js/premium-septica-game.js',

  // Core JavaScript - Game Engine
  '/js/romanian-septica-rules.js',
  '/js/romanian-septica-integration.js',
  '/js/card-renderer-3d.js',
  '/js/playable-card-interface.js',

  // Core JavaScript - Mobile & Performance
  '/js/mobile-lod-system.js',
  '/js/mobile-touch-system.js',
  '/js/mobile-performance-test.js',
  '/js/performance-monitor.js',
  '/js/performance-dashboard.js',

  // Core JavaScript - Multiplayer
  '/js/websocket-client.js',
  '/js/game-ui.js',
  '/js/app.js',
  '/js/dev-auth.js',

  // Utilities
  '/js/offline-storage.js',
  '/js/sw-register.js'
];

// External libraries (cached with network-first strategy)
const EXTERNAL_LIBRARIES = [
  'https://unpkg.com/three@0.152.2/build/three.min.js',
  'https://unpkg.com/three@0.152.2/examples/js/controls/OrbitControls.js',
  'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js'
];

// API endpoints that should use network-first
const API_ENDPOINTS = [
  '/api/',
  '/ws/',
  '/matchmaking/',
  '/game/'
];

// Install Event - Cache critical assets
self.addEventListener('install', (event) => {
  console.log('🔧 Service Worker: Installing...');

  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('📦 Service Worker: Caching critical assets');

        // Cache critical assets
        return cache.addAll(CRITICAL_ASSETS)
          .then(() => {
            console.log(`✅ Service Worker: Cached ${CRITICAL_ASSETS.length} critical assets`);

            // Cache external libraries separately (non-blocking)
            return cache.addAll(EXTERNAL_LIBRARIES).catch((err) => {
              console.warn('⚠️ Service Worker: Failed to cache external libraries:', err);
            });
          });
      })
      .then(() => {
        console.log('✅ Service Worker: Installation complete');
        return self.skipWaiting(); // Activate immediately
      })
      .catch((error) => {
        console.error('❌ Service Worker: Installation failed:', error);
      })
  );
});

// Activate Event - Clean up old caches
self.addEventListener('activate', (event) => {
  console.log('🚀 Service Worker: Activating...');

  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((cacheName) => {
              // Delete old caches
              return cacheName.startsWith('septica-pwa-') && cacheName !== CACHE_NAME;
            })
            .map((cacheName) => {
              console.log(`🗑️ Service Worker: Deleting old cache: ${cacheName}`);
              return caches.delete(cacheName);
            })
        );
      })
      .then(() => {
        console.log('✅ Service Worker: Activation complete');
        return self.clients.claim(); // Take control of all pages immediately
      })
  );
});

// Fetch Event - Implement caching strategies
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip chrome extensions and other protocols
  if (!url.protocol.startsWith('http')) {
    return;
  }

  // Determine caching strategy based on request type
  if (isAPIRequest(url)) {
    // Network-first for API calls (real-time data)
    event.respondWith(networkFirstStrategy(request));
  } else if (isExternalLibrary(url)) {
    // Cache-first for external libraries (stable resources)
    event.respondWith(cacheFirstStrategy(request));
  } else {
    // Stale-while-revalidate for static assets
    event.respondWith(staleWhileRevalidateStrategy(request));
  }
});

// Background Sync - Queue game moves when offline
self.addEventListener('sync', (event) => {
  console.log('🔄 Service Worker: Background sync triggered:', event.tag);

  if (event.tag === 'sync-game-moves') {
    event.waitUntil(syncPendingGameMoves());
  } else if (event.tag === 'sync-player-stats') {
    event.waitUntil(syncPlayerStats());
  }
});

// Message handling from main thread
self.addEventListener('message', (event) => {
  console.log('📨 Service Worker: Message received:', event.data);

  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  } else if (event.data && event.data.type === 'CACHE_STATS') {
    getCacheStats().then((stats) => {
      event.ports[0].postMessage(stats);
    });
  } else if (event.data && event.data.type === 'CLEAR_CACHE') {
    clearAllCaches().then(() => {
      event.ports[0].postMessage({ success: true });
    });
  }
});

// ========================================
// Caching Strategies
// ========================================

// Network-first: Try network, fallback to cache
async function networkFirstStrategy(request) {
  try {
    const networkResponse = await fetch(request);

    // Cache successful responses
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.log('🔌 Service Worker: Network failed, using cache:', request.url);

    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }

    // Return offline fallback for API requests
    return new Response(
      JSON.stringify({
        error: 'offline',
        message: 'You are currently offline. Game moves will sync when connection is restored.'
      }),
      {
        status: 503,
        statusText: 'Service Unavailable',
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

// Cache-first: Try cache, fallback to network
async function cacheFirstStrategy(request) {
  const cachedResponse = await caches.match(request);

  if (cachedResponse) {
    return cachedResponse;
  }

  try {
    const networkResponse = await fetch(request);

    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.error('❌ Service Worker: Failed to fetch:', request.url);
    return new Response('Offline - Resource not cached', { status: 503 });
  }
}

// Stale-while-revalidate: Return cache immediately, update in background
async function staleWhileRevalidateStrategy(request) {
  const cache = await caches.open(CACHE_NAME);
  const cachedResponse = await cache.match(request);

  // Fetch from network in background
  const networkFetch = fetch(request)
    .then((networkResponse) => {
      if (networkResponse.ok) {
        cache.put(request, networkResponse.clone());
      }
      return networkResponse;
    })
    .catch((error) => {
      console.log('🔌 Service Worker: Background fetch failed:', request.url);
    });

  // Return cached response immediately if available
  return cachedResponse || networkFetch;
}

// ========================================
// Helper Functions
// ========================================

function isAPIRequest(url) {
  return API_ENDPOINTS.some(endpoint => url.pathname.startsWith(endpoint));
}

function isExternalLibrary(url) {
  return url.origin !== self.location.origin;
}

async function syncPendingGameMoves() {
  console.log('🎮 Service Worker: Syncing pending game moves...');

  try {
    // Open IndexedDB and get pending moves
    const db = await openGameDatabase();
    const moves = await getPendingMoves(db);

    if (moves.length === 0) {
      console.log('✅ Service Worker: No pending moves to sync');
      return;
    }

    console.log(`📤 Service Worker: Syncing ${moves.length} pending moves`);

    // Sync each move
    for (const move of moves) {
      try {
        const response = await fetch('/api/game/move', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(move)
        });

        if (response.ok) {
          // Remove from pending queue
          await removePendingMove(db, move.id);
          console.log(`✅ Service Worker: Synced move ${move.id}`);
        }
      } catch (error) {
        console.error(`❌ Service Worker: Failed to sync move ${move.id}:`, error);
      }
    }

    console.log('✅ Service Worker: Game move sync complete');
  } catch (error) {
    console.error('❌ Service Worker: Sync failed:', error);
  }
}

async function syncPlayerStats() {
  console.log('📊 Service Worker: Syncing player stats...');

  try {
    const db = await openGameDatabase();
    const stats = await getPendingStats(db);

    if (!stats) {
      console.log('✅ Service Worker: No pending stats to sync');
      return;
    }

    const response = await fetch('/api/player/stats', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(stats)
    });

    if (response.ok) {
      await clearPendingStats(db);
      console.log('✅ Service Worker: Player stats synced');
    }
  } catch (error) {
    console.error('❌ Service Worker: Stats sync failed:', error);
  }
}

async function getCacheStats() {
  const cache = await caches.open(CACHE_NAME);
  const keys = await cache.keys();

  let totalSize = 0;
  for (const request of keys) {
    const response = await cache.match(request);
    if (response && response.body) {
      const blob = await response.blob();
      totalSize += blob.size;
    }
  }

  return {
    version: CACHE_VERSION,
    assetCount: keys.length,
    totalSize: totalSize,
    totalSizeMB: (totalSize / (1024 * 1024)).toFixed(2),
    maxSizeMB: (CACHE_MAX_SIZE / (1024 * 1024)).toFixed(0)
  };
}

async function clearAllCaches() {
  const cacheNames = await caches.keys();
  await Promise.all(
    cacheNames.map(cacheName => caches.delete(cacheName))
  );
  console.log('🗑️ Service Worker: All caches cleared');
}

// IndexedDB helpers (basic implementation)
function openGameDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('SepticaGameDB', 1);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;

      if (!db.objectStoreNames.contains('pendingMoves')) {
        db.createObjectStore('pendingMoves', { keyPath: 'id', autoIncrement: true });
      }

      if (!db.objectStoreNames.contains('pendingStats')) {
        db.createObjectStore('pendingStats', { keyPath: 'timestamp' });
      }
    };
  });
}

function getPendingMoves(db) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(['pendingMoves'], 'readonly');
    const store = transaction.objectStore('pendingMoves');
    const request = store.getAll();

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result || []);
  });
}

function removePendingMove(db, moveId) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(['pendingMoves'], 'readwrite');
    const store = transaction.objectStore('pendingMoves');
    const request = store.delete(moveId);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve();
  });
}

function getPendingStats(db) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(['pendingStats'], 'readonly');
    const store = transaction.objectStore('pendingStats');
    const request = store.getAll();

    request.onerror = () => reject(request.error);
    request.onsuccess = () => {
      const results = request.result || [];
      resolve(results.length > 0 ? results[0] : null);
    };
  });
}

function clearPendingStats(db) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(['pendingStats'], 'readwrite');
    const store = transaction.objectStore('pendingStats');
    const request = store.clear();

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve();
  });
}

console.log('🎮 Romanian Septica Service Worker loaded successfully');
console.log(`📦 Cache version: ${CACHE_VERSION}`);
console.log(`📊 Caching ${CRITICAL_ASSETS.length} critical assets`);

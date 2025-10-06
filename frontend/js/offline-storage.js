// Romanian Septica - Offline Storage System
// IndexedDB-based game state persistence and background sync queue

class OfflineStorage {
  constructor() {
    this.dbName = 'SepticaGameDB';
    this.dbVersion = 1;
    this.db = null;

    // Store names
    this.STORES = {
      GAME_STATE: 'gameState',
      PENDING_MOVES: 'pendingMoves',
      PENDING_STATS: 'pendingStats',
      PLAYER_PROFILE: 'playerProfile',
      CACHED_GAMES: 'cachedGames'
    };

    this.initPromise = this.initialize();
  }

  // Initialize IndexedDB
  async initialize() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.dbVersion);

      request.onerror = () => {
        console.error('❌ IndexedDB: Failed to open database', request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
        this.db = request.result;
        console.log('✅ IndexedDB: Database opened successfully');
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        console.log('🔧 IndexedDB: Upgrading database schema...');

        // Game State Store
        if (!db.objectStoreNames.contains(this.STORES.GAME_STATE)) {
          const gameStateStore = db.createObjectStore(this.STORES.GAME_STATE, {
            keyPath: 'gameId'
          });
          gameStateStore.createIndex('timestamp', 'timestamp', { unique: false });
          gameStateStore.createIndex('status', 'status', { unique: false });
          console.log('📦 Created gameState store');
        }

        // Pending Moves Store
        if (!db.objectStoreNames.contains(this.STORES.PENDING_MOVES)) {
          const pendingMovesStore = db.createObjectStore(this.STORES.PENDING_MOVES, {
            keyPath: 'id',
            autoIncrement: true
          });
          pendingMovesStore.createIndex('gameId', 'gameId', { unique: false });
          pendingMovesStore.createIndex('timestamp', 'timestamp', { unique: false });
          console.log('📦 Created pendingMoves store');
        }

        // Pending Stats Store
        if (!db.objectStoreNames.contains(this.STORES.PENDING_STATS)) {
          db.createObjectStore(this.STORES.PENDING_STATS, {
            keyPath: 'timestamp'
          });
          console.log('📦 Created pendingStats store');
        }

        // Player Profile Store
        if (!db.objectStoreNames.contains(this.STORES.PLAYER_PROFILE)) {
          db.createObjectStore(this.STORES.PLAYER_PROFILE, {
            keyPath: 'playerId'
          });
          console.log('📦 Created playerProfile store');
        }

        // Cached Games Store
        if (!db.objectStoreNames.contains(this.STORES.CACHED_GAMES)) {
          const cachedGamesStore = db.createObjectStore(this.STORES.CACHED_GAMES, {
            keyPath: 'gameId'
          });
          cachedGamesStore.createIndex('playerId', 'playerId', { unique: false });
          cachedGamesStore.createIndex('completedAt', 'completedAt', { unique: false });
          console.log('📦 Created cachedGames store');
        }

        console.log('✅ IndexedDB: Schema upgrade complete');
      };
    });
  }

  // Ensure database is initialized
  async ensureInitialized() {
    if (!this.db) {
      await this.initPromise;
    }
  }

  // ========================================
  // Game State Management
  // ========================================

  async saveGameState(gameState) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.GAME_STATE], 'readwrite');
      const store = transaction.objectStore(this.STORES.GAME_STATE);

      const stateToSave = {
        ...gameState,
        timestamp: Date.now(),
        version: '1.0.0'
      };

      const request = store.put(stateToSave);

      request.onsuccess = () => {
        console.log(`💾 Saved game state for game ${gameState.gameId}`);
        resolve();
      };

      request.onerror = () => {
        console.error('❌ Failed to save game state:', request.error);
        reject(request.error);
      };
    });
  }

  async getGameState(gameId) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.GAME_STATE], 'readonly');
      const store = transaction.objectStore(this.STORES.GAME_STATE);
      const request = store.get(gameId);

      request.onsuccess = () => {
        resolve(request.result || null);
      };

      request.onerror = () => {
        console.error('❌ Failed to get game state:', request.error);
        reject(request.error);
      };
    });
  }

  async deleteGameState(gameId) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.GAME_STATE], 'readwrite');
      const store = transaction.objectStore(this.STORES.GAME_STATE);
      const request = store.delete(gameId);

      request.onsuccess = () => {
        console.log(`🗑️ Deleted game state for game ${gameId}`);
        resolve();
      };

      request.onerror = () => {
        console.error('❌ Failed to delete game state:', request.error);
        reject(request.error);
      };
    });
  }

  // ========================================
  // Pending Moves Queue (for offline play)
  // ========================================

  async queueMove(gameId, move) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.PENDING_MOVES], 'readwrite');
      const store = transaction.objectStore(this.STORES.PENDING_MOVES);

      const moveToQueue = {
        gameId,
        move,
        timestamp: Date.now(),
        retryCount: 0
      };

      const request = store.add(moveToQueue);

      request.onsuccess = () => {
        const moveId = request.result;
        console.log(`📤 Queued move ${moveId} for game ${gameId} (offline)`);
        resolve(moveId);

        // Trigger background sync if available
        this.triggerBackgroundSync();
      };

      request.onerror = () => {
        console.error('❌ Failed to queue move:', request.error);
        reject(request.error);
      };
    });
  }

  async getPendingMoves(gameId = null) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.PENDING_MOVES], 'readonly');
      const store = transaction.objectStore(this.STORES.PENDING_MOVES);

      let request;
      if (gameId) {
        const index = store.index('gameId');
        request = index.getAll(gameId);
      } else {
        request = store.getAll();
      }

      request.onsuccess = () => {
        resolve(request.result || []);
      };

      request.onerror = () => {
        console.error('❌ Failed to get pending moves:', request.error);
        reject(request.error);
      };
    });
  }

  async removePendingMove(moveId) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.PENDING_MOVES], 'readwrite');
      const store = transaction.objectStore(this.STORES.PENDING_MOVES);
      const request = store.delete(moveId);

      request.onsuccess = () => {
        console.log(`✅ Removed pending move ${moveId}`);
        resolve();
      };

      request.onerror = () => {
        console.error('❌ Failed to remove pending move:', request.error);
        reject(request.error);
      };
    });
  }

  async incrementMoveRetryCount(moveId) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.PENDING_MOVES], 'readwrite');
      const store = transaction.objectStore(this.STORES.PENDING_MOVES);

      const getRequest = store.get(moveId);

      getRequest.onsuccess = () => {
        const move = getRequest.result;
        if (move) {
          move.retryCount = (move.retryCount || 0) + 1;
          move.lastRetryAt = Date.now();

          const putRequest = store.put(move);
          putRequest.onsuccess = () => resolve(move.retryCount);
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          resolve(0);
        }
      };

      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  // ========================================
  // Player Profile
  // ========================================

  async savePlayerProfile(profile) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.PLAYER_PROFILE], 'readwrite');
      const store = transaction.objectStore(this.STORES.PLAYER_PROFILE);

      const profileToSave = {
        ...profile,
        lastUpdated: Date.now()
      };

      const request = store.put(profileToSave);

      request.onsuccess = () => {
        console.log(`💾 Saved player profile for player ${profile.playerId}`);
        resolve();
      };

      request.onerror = () => {
        console.error('❌ Failed to save player profile:', request.error);
        reject(request.error);
      };
    });
  }

  async getPlayerProfile(playerId) {
    await this.ensureInitialized();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.STORES.PLAYER_PROFILE], 'readonly');
      const store = transaction.objectStore(this.STORES.PLAYER_PROFILE);
      const request = store.get(playerId);

      request.onsuccess = () => {
        resolve(request.result || null);
      };

      request.onerror = () => {
        console.error('❌ Failed to get player profile:', request.error);
        reject(request.error);
      };
    });
  }

  // ========================================
  // Background Sync
  // ========================================

  async triggerBackgroundSync() {
    if ('serviceWorker' in navigator && 'sync' in registration) {
      try {
        const registration = await navigator.serviceWorker.ready;
        await registration.sync.register('sync-game-moves');
        console.log('🔄 Background sync registered for game moves');
      } catch (error) {
        console.warn('⚠️ Background sync not supported:', error);
        // Fallback: attempt immediate sync
        this.syncPendingMoves();
      }
    } else {
      // No service worker support, attempt immediate sync
      this.syncPendingMoves();
    }
  }

  async syncPendingMoves() {
    const pendingMoves = await this.getPendingMoves();

    if (pendingMoves.length === 0) {
      console.log('✅ No pending moves to sync');
      return;
    }

    console.log(`📤 Syncing ${pendingMoves.length} pending moves...`);

    for (const move of pendingMoves) {
      try {
        // Attempt to send move to server
        const response = await fetch(`/api/game/${move.gameId}/move`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(move.move)
        });

        if (response.ok) {
          // Successfully synced, remove from queue
          await this.removePendingMove(move.id);
          console.log(`✅ Synced move ${move.id}`);
        } else {
          // Failed to sync, increment retry count
          const retryCount = await this.incrementMoveRetryCount(move.id);
          console.warn(`⚠️ Failed to sync move ${move.id}, retry count: ${retryCount}`);

          // Remove after max retries
          if (retryCount >= 5) {
            console.error(`❌ Max retries reached for move ${move.id}, removing from queue`);
            await this.removePendingMove(move.id);
          }
        }
      } catch (error) {
        console.error(`❌ Error syncing move ${move.id}:`, error);
        await this.incrementMoveRetryCount(move.id);
      }
    }

    console.log('✅ Pending moves sync complete');
  }

  // ========================================
  // Utility Methods
  // ========================================

  async clearAllData() {
    await this.ensureInitialized();

    const stores = Object.values(this.STORES);

    return Promise.all(
      stores.map(storeName => {
        return new Promise((resolve, reject) => {
          const transaction = this.db.transaction([storeName], 'readwrite');
          const store = transaction.objectStore(storeName);
          const request = store.clear();

          request.onsuccess = () => {
            console.log(`🗑️ Cleared ${storeName} store`);
            resolve();
          };

          request.onerror = () => {
            console.error(`❌ Failed to clear ${storeName}:`, request.error);
            reject(request.error);
          };
        });
      })
    );
  }

  async getStorageStats() {
    await this.ensureInitialized();

    const stores = Object.values(this.STORES);
    const stats = {};

    for (const storeName of stores) {
      const transaction = this.db.transaction([storeName], 'readonly');
      const store = transaction.objectStore(storeName);
      const countRequest = store.count();

      stats[storeName] = await new Promise((resolve) => {
        countRequest.onsuccess = () => resolve(countRequest.result);
        countRequest.onerror = () => resolve(0);
      });
    }

    return stats;
  }

  async close() {
    if (this.db) {
      this.db.close();
      this.db = null;
      console.log('✅ IndexedDB connection closed');
    }
  }
}

// Export for use in modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = OfflineStorage;
}

// Global instance for convenience
window.offlineStorage = new OfflineStorage();

console.log('🎮 Romanian Septica Offline Storage System loaded');

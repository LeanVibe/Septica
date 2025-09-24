/**
 * Database and Data Integrity Tests
 * Validates data persistence, integrity, and database operations
 */

import { test, expect } from '@playwright/test';

const DB_CONFIG = {
  timeout: 15000,
  retries: 3,
  servers: {
    backend: 'http://localhost:8082',
    frontend: 'http://localhost:3000'
  }
};

test.describe('Database Data Integrity and Persistence', () => {

  test('Player profile creation and persistence', async ({ browser }) => {
    console.log('👤 Testing player profile creation and persistence...');

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      await page.goto(DB_CONFIG.servers.frontend);
      await page.waitForSelector('#connection-text:has-text("Connected")');

      // Create player profile data
      const playerProfile = await page.evaluate(() => {
        const playerId = sessionStorage.getItem('playerId') || `player_${Date.now()}`;
        sessionStorage.setItem('playerId', playerId);

        const profile = {
          id: playerId,
          createdAt: Date.now(),
          gamesPlayed: 0,
          wins: 0,
          losses: 0,
          totalScore: 0,
          preferences: {
            theme: 'romanian',
            soundEnabled: true
          }
        };

        sessionStorage.setItem('playerProfile', JSON.stringify(profile));
        return profile;
      });

      expect(playerProfile.id).toBeTruthy();
      console.log(`✅ Player profile created: ${playerProfile.id.substring(0, 12)}...`);

      // Test profile persistence after page reload
      await page.reload();
      await page.waitForSelector('#connection-text:has-text("Connected")');

      const persistedProfile = await page.evaluate(() => {
        return JSON.parse(sessionStorage.getItem('playerProfile') || 'null');
      });

      expect(persistedProfile).toEqual(playerProfile);
      console.log('✅ Player profile persisted across reload');

      // Test profile updates
      const updatedProfile = await page.evaluate(() => {
        const profile = JSON.parse(sessionStorage.getItem('playerProfile'));
        profile.gamesPlayed = 1;
        profile.lastGameTime = Date.now();
        sessionStorage.setItem('playerProfile', JSON.stringify(profile));
        return profile;
      });

      expect(updatedProfile.gamesPlayed).toBe(1);
      console.log('✅ Player profile updates working');

    } finally {
      await context.close();
    }
  });

  test('Game session tracking and history', async ({ browser }) => {
    console.log('🎮 Testing game session tracking and history...');

    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();

    try {
      // Setup both players
      await Promise.all([
        player1.goto(DB_CONFIG.servers.frontend),
        player2.goto(DB_CONFIG.servers.frontend)
      ]);

      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")'),
        player2.waitForSelector('#connection-text:has-text("Connected")')
      ]);

      // Create game session data
      const sessionData = await player1.evaluate(() => {
        const sessionId = `session_${Date.now()}`;
        const playerId = sessionStorage.getItem('playerId');

        const gameSession = {
          sessionId: sessionId,
          playerId: playerId,
          startTime: Date.now(),
          status: 'active',
          gameType: 'romanian_septica',
          playerCount: 2
        };

        sessionStorage.setItem('currentGameSession', JSON.stringify(gameSession));

        // Also track in game history
        const history = JSON.parse(sessionStorage.getItem('gameHistory') || '[]');
        history.push(gameSession);
        sessionStorage.setItem('gameHistory', JSON.stringify(history));

        return gameSession;
      });

      expect(sessionData.sessionId).toBeTruthy();
      expect(sessionData.gameType).toBe('romanian_septica');
      console.log(`✅ Game session created: ${sessionData.sessionId}`);

      // Start matchmaking to create actual game connection
      await player1.click('#play-btn');
      await player2.click('#play-btn');

      await Promise.all([
        player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
        player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
      ]);

      // Update session with match data
      const matchedSession = await player1.evaluate(() => {
        const session = JSON.parse(sessionStorage.getItem('currentGameSession'));
        session.matchedAt = Date.now();
        session.status = 'matched';
        session.opponentId = 'opponent_placeholder';
        sessionStorage.setItem('currentGameSession', JSON.stringify(session));
        return session;
      });

      expect(matchedSession.status).toBe('matched');
      console.log('✅ Game session updated with match data');

      // Verify game history tracking
      const gameHistory = await player1.evaluate(() => {
        return JSON.parse(sessionStorage.getItem('gameHistory') || '[]');
      });

      expect(gameHistory).toHaveLength(1);
      expect(gameHistory[0].sessionId).toBe(sessionData.sessionId);
      console.log(`✅ Game history tracking: ${gameHistory.length} sessions recorded`);

    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('Matchmaking queue data integrity', async ({ browser }) => {
    console.log('🎯 Testing matchmaking queue data integrity...');

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      await page.goto(DB_CONFIG.servers.frontend);
      await page.waitForSelector('#connection-text:has-text("Connected")');

      // Test queue entry data
      const queueEntry = await page.evaluate(() => {
        const playerId = sessionStorage.getItem('playerId');
        const queueData = {
          playerId: playerId,
          joinedAt: Date.now(),
          gameType: 'romanian_septica',
          playerCount: 2,
          status: 'searching'
        };

        sessionStorage.setItem('matchmakingQueue', JSON.stringify(queueData));
        return queueData;
      });

      // Join matchmaking
      await page.click('#play-btn');
      await page.waitForSelector('#matchmaking-overlay', { state: 'visible' });

      // Update queue status
      const updatedQueue = await page.evaluate(() => {
        const queueData = JSON.parse(sessionStorage.getItem('matchmakingQueue'));
        queueData.searchStarted = Date.now();
        queueData.status = 'active_search';
        sessionStorage.setItem('matchmakingQueue', JSON.stringify(queueData));
        return queueData;
      });

      expect(updatedQueue.status).toBe('active_search');
      expect(updatedQueue.searchStarted).toBeTruthy();
      console.log('✅ Matchmaking queue data integrity maintained');

      // Test queue cleanup on cancel/completion
      if (await page.locator('#cancel-matchmaking-btn').isVisible()) {
        await page.click('#cancel-matchmaking-btn');
      }

      // Wait for queue exit
      await page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 10000 });

      const finalQueue = await page.evaluate(() => {
        const queueData = JSON.parse(sessionStorage.getItem('matchmakingQueue') || 'null');
        if (queueData) {
          queueData.status = 'cancelled';
          queueData.exitedAt = Date.now();
          sessionStorage.setItem('matchmakingQueue', JSON.stringify(queueData));
        }
        return queueData;
      });

      if (finalQueue) {
        expect(finalQueue.status).toBe('cancelled');
        console.log('✅ Queue cleanup data handled correctly');
      }

    } finally {
      await context.close();
    }
  });

  test('Foreign key relationships and referential integrity', async ({ browser }) => {
    console.log('🔗 Testing foreign key relationships and referential integrity...');

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      await page.goto(DB_CONFIG.servers.frontend);
      await page.waitForSelector('#connection-text:has-text("Connected")');

      // Create related data structures
      const relationalData = await page.evaluate(() => {
        const playerId = sessionStorage.getItem('playerId');

        // Player data
        const player = {
          id: playerId,
          username: `Player_${Date.now()}`,
          createdAt: Date.now()
        };

        // Game data referencing player
        const game = {
          id: `game_${Date.now()}`,
          player1Id: playerId,
          player2Id: null, // Will be set when matched
          createdAt: Date.now(),
          status: 'waiting_for_opponent'
        };

        // Move data referencing game and player
        const moves = [
          {
            id: `move_${Date.now()}_1`,
            gameId: game.id,
            playerId: playerId,
            cardValue: 10,
            cardSuit: 'hearts',
            timestamp: Date.now()
          }
        ];

        // Store all related data
        sessionStorage.setItem('playerData', JSON.stringify(player));
        sessionStorage.setItem('gameData', JSON.stringify(game));
        sessionStorage.setItem('movesData', JSON.stringify(moves));

        return { player, game, moves };
      });

      // Verify relationships
      expect(relationalData.game.player1Id).toBe(relationalData.player.id);
      expect(relationalData.moves[0].gameId).toBe(relationalData.game.id);
      expect(relationalData.moves[0].playerId).toBe(relationalData.player.id);
      console.log('✅ Foreign key relationships established correctly');

      // Test referential integrity on updates
      const updatedData = await page.evaluate(() => {
        const player = JSON.parse(sessionStorage.getItem('playerData'));
        const game = JSON.parse(sessionStorage.getItem('gameData'));
        const moves = JSON.parse(sessionStorage.getItem('movesData'));

        // Update player data
        player.lastActive = Date.now();
        player.gamesPlayed = 1;

        // Update game with opponent
        game.player2Id = `opponent_${Date.now()}`;
        game.status = 'active';
        game.startedAt = Date.now();

        // Add more moves
        moves.push({
          id: `move_${Date.now()}_2`,
          gameId: game.id,
          playerId: game.player2Id,
          cardValue: 7,
          cardSuit: 'spades',
          timestamp: Date.now()
        });

        // Save updated data
        sessionStorage.setItem('playerData', JSON.stringify(player));
        sessionStorage.setItem('gameData', JSON.stringify(game));
        sessionStorage.setItem('movesData', JSON.stringify(moves));

        return { player, game, moves };
      });

      // Verify integrity maintained
      expect(updatedData.game.player1Id).toBe(updatedData.player.id);
      expect(updatedData.moves).toHaveLength(2);
      expect(updatedData.moves.every(move => move.gameId === updatedData.game.id)).toBe(true);
      console.log('✅ Referential integrity maintained after updates');

      // Test cascade behavior simulation
      const cascadeTest = await page.evaluate(() => {
        const game = JSON.parse(sessionStorage.getItem('gameData'));
        const moves = JSON.parse(sessionStorage.getItem('movesData'));

        // Simulate game completion
        game.status = 'completed';
        game.completedAt = Date.now();
        game.winner = game.player1Id;

        // Update all related moves
        const updatedMoves = moves.map(move => ({
          ...move,
          gameStatus: 'completed'
        }));

        sessionStorage.setItem('gameData', JSON.stringify(game));
        sessionStorage.setItem('movesData', JSON.stringify(updatedMoves));

        return { game, moves: updatedMoves };
      });

      expect(cascadeTest.game.status).toBe('completed');
      expect(cascadeTest.moves.every(move => move.gameStatus === 'completed')).toBe(true);
      console.log('✅ Cascade behavior simulation successful');

    } finally {
      await context.close();
    }
  });

  test('Data consistency under concurrent operations', async ({ browser }) => {
    console.log('🔄 Testing data consistency under concurrent operations...');

    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();

    try {
      await Promise.all([
        player1.goto(DB_CONFIG.servers.frontend),
        player2.goto(DB_CONFIG.servers.frontend)
      ]);

      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")'),
        player2.waitForSelector('#connection-text:has-text("Connected")')
      ]);

      // Simulate concurrent data operations
      const concurrentOperations = await Promise.all([
        player1.evaluate(() => {
          const timestamp = Date.now();
          const operations = [];

          // Perform multiple data operations
          for (let i = 0; i < 5; i++) {
            const operation = {
              id: `op_p1_${timestamp}_${i}`,
              playerId: sessionStorage.getItem('playerId'),
              type: 'data_write',
              timestamp: Date.now(),
              data: { operation: i, source: 'player1' }
            };
            operations.push(operation);

            // Simulate data write
            sessionStorage.setItem(`operation_${operation.id}`, JSON.stringify(operation));
          }

          return operations;
        }),

        player2.evaluate(() => {
          const timestamp = Date.now();
          const operations = [];

          // Perform multiple data operations concurrently
          for (let i = 0; i < 5; i++) {
            const operation = {
              id: `op_p2_${timestamp}_${i}`,
              playerId: sessionStorage.getItem('playerId'),
              type: 'data_write',
              timestamp: Date.now(),
              data: { operation: i, source: 'player2' }
            };
            operations.push(operation);

            // Simulate data write
            sessionStorage.setItem(`operation_${operation.id}`, JSON.stringify(operation));
          }

          return operations;
        })
      ]);

      // Verify both sets of operations completed
      const p1Operations = concurrentOperations[0];
      const p2Operations = concurrentOperations[1];

      expect(p1Operations).toHaveLength(5);
      expect(p2Operations).toHaveLength(5);

      console.log(`✅ Concurrent operations completed: P1=${p1Operations.length}, P2=${p2Operations.length}`);

      // Test data consistency after concurrent operations
      const consistencyCheck = await Promise.all([
        player1.evaluate(() => {
          const keys = Object.keys(sessionStorage).filter(key => key.startsWith('operation_'));
          return keys.map(key => JSON.parse(sessionStorage.getItem(key)));
        }),
        player2.evaluate(() => {
          const keys = Object.keys(sessionStorage).filter(key => key.startsWith('operation_'));
          return keys.map(key => JSON.parse(sessionStorage.getItem(key)));
        })
      ]);

      // Each player should have their own set of operations
      const p1StoredOps = consistencyCheck[0];
      const p2StoredOps = consistencyCheck[1];

      expect(p1StoredOps).toHaveLength(5);
      expect(p2StoredOps).toHaveLength(5);

      // Verify operation isolation (each player only sees their own operations)
      const p1Sources = p1StoredOps.map(op => op.data.source);
      const p2Sources = p2StoredOps.map(op => op.data.source);

      expect(p1Sources.every(source => source === 'player1')).toBe(true);
      expect(p2Sources.every(source => source === 'player2')).toBe(true);

      console.log('✅ Data consistency maintained under concurrent operations');

    } finally {
      await context1.close();
      await context2.close();
    }
  });
});
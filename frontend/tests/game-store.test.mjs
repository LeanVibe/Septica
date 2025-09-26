import assert from 'node:assert/strict';
import { gameStore } from '../src/state/game-store.js';

// reset helper
function resetStore() {
  gameStore.state = {
    status: '',
    player: { name: 'Test', country: 'ro', avatar: '', hand: [], score: 0 },
    opponent: { name: 'Opp', country: 'gb', avatar: '', cardCount: 0, score: 0 },
    table: [],
    score: { you: 0, opponent: 0 }
  };
}

resetStore();

// test playCard removes from hand and adds to table
{
  resetStore();
  gameStore.setState((prev) => ({
    ...prev,
    player: { ...prev.player, hand: [{ id: 'c1', rank: 'A', suit: 'hearts' }] }
  }));
  gameStore.playCard('c1');
  assert.equal(gameStore.state.player.hand.length, 0, 'card removed from hand');
  assert.equal(gameStore.state.table.length, 1, 'card added to table');
  assert.equal(gameStore.state.score.you, 1, 'score incremented');
}

console.log('game-store tests passed');

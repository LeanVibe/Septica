import './lib/simple-lit.js';
import './components/game-table.js';
import './components/player-badge.js';
import './components/score-track.js';
import { SepticaSocket } from './network/websocket-client.js';
import { createSocketController } from './network/socket-controller.js';
import { gameStore } from './state/game-store.js';

// Basic kick-off providing demo data. In production this will be driven by
// WebSocket updates.
const root = document.getElementById('app');

if (root) {
  root.querySelector('.fallback')?.remove();
  const table = document.createElement('game-table');
  root.appendChild(table);

  const playerBadge = document.createElement('player-badge');
  playerBadge.setAttribute('slot', 'player');
  table.appendChild(playerBadge);

  const opponentBadge = document.createElement('player-badge');
  opponentBadge.setAttribute('slot', 'opponent');
  table.appendChild(opponentBadge);

  const score = document.createElement('score-track');
  score.setAttribute('slot', 'score');
  table.appendChild(score);

  const actions = document.createElement('div');
  actions.setAttribute('slot', 'actions');
  actions.style.pointerEvents = 'auto';
  actions.innerHTML = `
    <button style="padding:0.6rem 1.2rem;border:none;border-radius:999px;background:#facc15;color:#2b2b2b;font-weight:600;cursor:pointer;">Pass</button>
  `;
  table.appendChild(actions);

  const passButton = actions.querySelector('button');
  passButton?.addEventListener('click', () => {
    gameStore.setState((prev) => ({
      ...prev,
      status: 'You chose to pass (demo)'
    }));
  });

  gameStore.subscribe((state) => {
    playerBadge.name = state.player.name || 'Player';
    playerBadge.country = state.player.country || 'ro';
    playerBadge.avatar = state.player.avatar || '';
    playerBadge.you = true;
    playerBadge.active = state.status?.toLowerCase().includes('your turn');

    opponentBadge.name = state.opponent.name || 'Opponent';
    opponentBadge.country = state.opponent.country || 'gb';
    opponentBadge.avatar = state.opponent.avatar || '';
    opponentBadge.active = state.status?.toLowerCase().includes('opponent');

    score.you = state.score.you ?? 0;
    score.opponent = state.score.opponent ?? 0;
  });

  gameStore.setState({
    status: 'Waiting for opponent…',
    player: {
      name: 'Maria',
      country: 'ro',
      hand: [
        { id: 'card-1', rank: 'A', suit: 'hearts' },
        { id: 'card-2', rank: '10', suit: 'clubs' },
        { id: 'card-3', rank: 'K', suit: 'diamonds' },
        { id: 'card-4', rank: '7', suit: 'spades' }
      ],
      score: 3
    },
    opponent: {
      name: 'Computer',
      country: 'gb',
      cardCount: 4,
      score: 2
    },
    table: [
      { id: 'table-1', rank: '10', suit: 'hearts' },
      { id: 'table-2', rank: 'A', suit: 'spades' }
    ],
    score: { you: 3, opponent: 2 }
  });

  setTimeout(() => {
    gameStore.setState((prev) => {
      const [first, ...rest] = prev.player.hand;
      if (!first) return prev;
      return {
        ...prev,
        status: 'Your turn!',
        player: { ...prev.player, hand: rest },
        table: [...prev.table, { ...first, id: `${first.id}-played` }],
        opponent: { ...prev.opponent },
        score: { ...prev.score, you: prev.score.you + 1 }
      };
    });
  }, 2800);
}

// expose socket helper for integration; do not auto connect to avoid errors
if (typeof window !== 'undefined') {
  window.SepticaSocket = SepticaSocket;
  window.gameStore = gameStore;
  window.createSepticaSocketController = (options = {}) => createSocketController({
    endpoint: options.endpoint,
    store: gameStore
  });
}

// When Three.js is available asynchronously (loaded via CDN), notify table to
// refresh layout once the library is ready.
if (typeof window !== 'undefined') {
  const waitForThree = () => {
    if (window.THREE) {
      document.querySelectorAll('game-table').forEach((el) => el.requestRender?.());
    } else {
      setTimeout(waitForThree, 200);
    }
  };
  waitForThree();
}

import { SepticaSocket, MESSAGE_TYPES } from './websocket-client.js';

function applyGameState(store, controller, payload = {}) {
  const playerId = controller.playerId;
  const opponentId = controller.opponentId;
  const yourCards = payload.your_cards ?? payload.yourCards ?? [];
  const tableCards = payload.table_cards ?? payload.tableCards ?? [];
  const opponentCount = payload.opponent_card_count ?? payload.opponentCardCount ?? controller.store.state.opponent.cardCount;
  const scores = payload.scores ?? {};
  const youScore = playerId ? (scores[playerId] ?? controller.store.state.score.you) : controller.store.state.score.you;
  const oppScore = opponentId ? (scores[opponentId] ?? controller.store.state.score.opponent) : controller.store.state.score.opponent;

  store.setState((prev) => ({
    ...prev,
    table: tableCards,
    player: { ...prev.player, hand: yourCards, score: youScore },
    opponent: { ...prev.opponent, cardCount: opponentCount, score: oppScore },
    score: { you: youScore, opponent: oppScore }
  }));
}

function handleMoveResult(store, result = {}) {
  if (result.valid === false && result.error) {
    store.setState({ status: `Invalid move: ${result.error}` });
    return;
  }
  if (result.game_complete) {
    store.setState({ status: 'Game complete!' });
  } else if (result.round_complete) {
    store.setState({ status: 'Round complete' });
  }
}

export function createSocketController({ endpoint, store }) {
  const socket = new SepticaSocket({ endpoint });
  const controller = {
    socket,
    store,
    playerId: null,
    opponentId: null,
    connect() {
      socket.onMessage = (message) => controller.handleMessage(message);
      socket.connect();
    },
    disconnect() {
      socket.disconnect();
    },
    handleMessage(message) {
      switch (message.type) {
        case MESSAGE_TYPES.CONNECTION_ACK: {
          controller.playerId = message.player_id ?? message.payload?.player_id ?? controller.playerId;
          store.setState({ status: 'Connected to server' });
          break;
        }
        case MESSAGE_TYPES.MATCH_FOUND: {
          const payload = message.payload ?? {};
          controller.opponentId = payload.opponent_id ?? payload.opponent?.id ?? null;
          controller.playerId = payload.player_id ?? payload.you_id ?? controller.playerId;
          store.setState({
            status: 'Match found! Shuffling…',
            opponent: {
              ...store.state.opponent,
              name: payload.opponent_name ?? payload.opponent?.name ?? 'Opponent',
              country: payload.opponent_country ?? payload.opponent?.country ?? 'gb',
              avatar: payload.opponent_avatar ?? payload.opponent?.avatar ?? ''
            }
          });
          break;
        }
        case MESSAGE_TYPES.MATCHMAKING_UPDATE: {
          const queuePos = message.payload?.queue_position;
          store.setState({ status: typeof queuePos === 'number' ? `Searching… position ${queuePos}` : 'Searching for opponent…' });
          break;
        }
        case MESSAGE_TYPES.GAME_STATE: {
          applyGameState(store, controller, message.payload ?? message);
          const waiting = message.payload?.waiting_for_objection;
          if (waiting) {
            store.setState({ status: 'Waiting for objection…' });
          } else if (message.payload?.current_player_id === controller.playerId) {
            store.setState({ status: 'Your turn!' });
          } else {
            store.setState({ status: "Opponent's turn" });
          }
          break;
        }
        case MESSAGE_TYPES.MOVE_RESULT: {
          handleMoveResult(store, message.payload ?? message);
          break;
        }
        case MESSAGE_TYPES.OBJECTION_WAIT: {
          store.setState({ status: 'Opponent may object…' });
          break;
        }
        case MESSAGE_TYPES.ROUND_COMPLETE: {
          store.setState({ status: 'Round complete!' });
          break;
        }
        case MESSAGE_TYPES.GAME_END: {
          const winner = message.payload?.winner_id === controller.playerId ? 'You won!' : 'Opponent won';
          store.setState({ status: winner });
          break;
        }
        case MESSAGE_TYPES.ERROR: {
          const msg = message.payload?.message ?? 'Server error';
          store.setState({ status: `Error: ${msg}` });
          break;
        }
        default:
          break;
      }
    }
  };
  return controller;
}

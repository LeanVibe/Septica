function mergeDeep(target = {}, source = {}) {
  const output = Array.isArray(target) ? target.slice() : { ...target };
  if (Array.isArray(source)) {
    return source.slice();
  }
  if (typeof source !== 'object' || source === null) {
    return source;
  }
  Object.entries(source).forEach(([key, value]) => {
    if (Array.isArray(value)) {
      output[key] = value.slice();
    } else if (value && typeof value === 'object') {
      output[key] = mergeDeep(output[key] ?? {}, value);
    } else {
      output[key] = value;
    }
  });
  return output;
}

class GameStore {
  constructor() {
    this.state = {
      status: '',
      player: { name: '', country: '', avatar: '', hand: [], score: 0 },
      opponent: { name: '', country: '', avatar: '', cardCount: 0, score: 0 },
      table: [],
      score: { you: 0, opponent: 0 }
    };
    this.listeners = new Set();
  }

  subscribe(listener) {
    this.listeners.add(listener);
    listener(this.state);
    return () => this.listeners.delete(listener);
  }

  setState(update) {
    const next = typeof update === 'function' ? update(this.state) : mergeDeep(this.state, update);
    this.state = next;
    this.listeners.forEach((listener) => listener(this.state));
  }

  playCard(cardId) {
    if (!cardId) return;
    const { player, table, score } = this.state;
    const index = player.hand.findIndex((card) => card && card.id === cardId);
    if (index === -1) return;
    const card = player.hand[index];
    const updatedHand = player.hand.filter((_, i) => i !== index);
    const updatedTable = [...table, { ...card, id: `${card.id}-played-${Date.now()}` }];
    const updatedScore = { ...score, you: (score.you ?? 0) + 1 };
    this.setState({
      status: `Played ${card.rank ?? ''} ${card.suit ?? ''}`.trim(),
      player: { ...player, hand: updatedHand },
      table: updatedTable,
      score: updatedScore
    });
  }
}

export const gameStore = new GameStore();

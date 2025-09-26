const CARD_KEY_CACHE = new Map();
const BACK_CACHE = new Map();

const SUIT_SYMBOL = {
  hearts: '♥',
  diamonds: '♦',
  clubs: '♣',
  spades: '♠'
};

const SUIT_COLOR = {
  hearts: '#dc2626',
  diamonds: '#dc2626',
  clubs: '#1e293b',
  spades: '#1e293b'
};

const RANK_LABEL = {
  A: 'A', K: 'K', Q: 'Q', J: 'J',
  10: '10', 9: '9', 8: '8', 7: '7', 6: '6', 5: '5', 4: '4', 3: '3', 2: '2'
};

function drawCardCanvas(rank, suit) {
  if (typeof document === 'undefined') return null;
  const width = 256;
  const height = 356;
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  const suitSymbol = SUIT_SYMBOL[suit] ?? '?';
  const label = RANK_LABEL[rank] ?? String(rank ?? '?');
  const primary = SUIT_COLOR[suit] ?? '#111827';

  ctx.fillStyle = '#fefefe';
  ctx.fillRect(0, 0, width, height);

  ctx.strokeStyle = '#d1d5db';
  ctx.lineWidth = 6;
  ctx.strokeRect(6, 6, width - 12, height - 12);

  ctx.fillStyle = primary;
  ctx.font = 'bold 54px "Trebuchet MS", sans-serif';
  ctx.textBaseline = 'top';
  ctx.fillText(label, 28, 24);
  ctx.font = 'bold 48px "Trebuchet MS", sans-serif';
  ctx.fillText(suitSymbol, 28, 90);

  ctx.save();
  ctx.translate(width - 28, height - 24);
  ctx.rotate(Math.PI);
  ctx.textBaseline = 'top';
  ctx.font = 'bold 54px "Trebuchet MS", sans-serif';
  ctx.fillText(label, 0, 0);
  ctx.font = 'bold 48px "Trebuchet MS", sans-serif';
  ctx.fillText(suitSymbol, 0, 66);
  ctx.restore();

  ctx.font = '120px "Trebuchet MS", sans-serif';
  ctx.textBaseline = 'middle';
  ctx.textAlign = 'center';
  ctx.fillText(suitSymbol, width / 2, height / 2);

  return canvas;
}

function createBackCanvas() {
  if (typeof document === 'undefined') return null;
  const width = 256;
  const height = 356;
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');

  const gradient = ctx.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, '#102a43');
  gradient.addColorStop(1, '#243b53');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);

  ctx.strokeStyle = '#d1fae5';
  ctx.lineWidth = 8;
  ctx.strokeRect(8, 8, width - 16, height - 16);

  ctx.strokeStyle = 'rgba(255,255,255,0.35)';
  ctx.lineWidth = 2;
  for (let i = 0; i < 6; i++) {
    ctx.strokeRect(20 + i * 10, 20 + i * 10, width - 40 - i * 20, height - 40 - i * 20);
  }

  ctx.lineWidth = 3;
  ctx.strokeStyle = 'rgba(255,255,255,0.4)';
  ctx.beginPath();
  const steps = 10;
  for (let x = 0; x <= steps; x++) {
    const px = 20 + (width - 40) * (x / steps);
    ctx.moveTo(px, 20);
    ctx.lineTo(px, height - 20);
  }
  for (let y = 0; y <= steps; y++) {
    const py = 20 + (height - 40) * (y / steps);
    ctx.moveTo(20, py);
    ctx.lineTo(width - 20, py);
  }
  ctx.stroke();

  return canvas;
}

function getThree(three) {
  if (three) return three;
  if (typeof window !== 'undefined') return window.THREE ?? null;
  return null;
}

export function getCardTexture(card, three) {
  const { rank, suit } = card ?? {};
  const key = `${rank}|${suit}`;
  const THREE = getThree(three);
  if (!THREE) return null;
  const cached = CARD_KEY_CACHE.get(key);
  if (cached) return cached;
  const canvas = drawCardCanvas(rank, suit);
  if (!canvas) return null;
  const texture = new THREE.CanvasTexture(canvas);
  texture.needsUpdate = true;
  CARD_KEY_CACHE.set(key, texture);
  return texture;
}

export function getCardBackTexture(three) {
  const THREE = getThree(three);
  if (!THREE) return null;
  if (BACK_CACHE.has(THREE)) return BACK_CACHE.get(THREE);
  const canvas = createBackCanvas();
  if (!canvas) return null;
  const texture = new THREE.CanvasTexture(canvas);
  texture.needsUpdate = true;
  BACK_CACHE.set(THREE, texture);
  return texture;
}

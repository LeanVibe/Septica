/**
 * Enhanced Romanian Card Texture System
 * Generates high-quality card textures with cultural authenticity
 */

// Romanian suit symbols and styling
const ROMANIAN_SUITS = {
  hearts: { symbol: '♥', color: '#dc2626', name: 'Inimi' },
  diamonds: { symbol: '♦', color: '#dc2626', name: 'Caro' },
  clubs: { symbol: '♣', color: '#1e293b', name: 'Treflă' },
  spades: { symbol: '♠', color: '#1e293b', name: 'Pică' }
};

// Romanian rank names and symbols
const ROMANIAN_RANKS = {
  A: { label: 'A', name: 'As', pointValue: 1 },
  K: { label: 'R', name: 'Rege', pointValue: 0 }, // R for Rege (King)
  Q: { label: 'D', name: 'Damă', pointValue: 0 }, // D for Damă (Queen)
  J: { label: 'V', name: 'Valet', pointValue: 0 }, // V for Valet (Jack)
  10: { label: '10', name: 'Zece', pointValue: 1 },
  9: { label: '9', name: 'Nouă', pointValue: 0 },
  8: { label: '8', name: 'Opt', pointValue: 0 },
  7: { label: '7', name: 'Șapte', pointValue: 0 } // Wild card in Septica
};

// Traditional Romanian decorative patterns
const ROMANIAN_PATTERNS = {
  geometric: {
    name: 'Geometric',
    colors: ['#8b1538', '#f4a261', '#2a5490']
  },
  floral: {
    name: 'Floral',
    colors: ['#1b4332', '#fdd835', '#ce1126']
  },
  folk: {
    name: 'Folk',
    colors: ['#6f4e37', '#e8b923', '#2a5490']
  }
};

// Global caches
const TEXTURE_CACHE = new Map();
const BACK_TEXTURE_CACHE = new Map();
const PATTERN_CACHE = new Map();

/**
 * Creates enhanced Romanian card face texture
 */
export function createRomanianCardTexture(card, THREE, options = {}) {
  const { rank, suit } = card || {};
  const {
    width = 512,
    height = 712,
    quality = 'high',
    region = 'traditional',
    enableShadows = true,
    enableGradients = true
  } = options;

  const cacheKey = `${rank}_${suit}_${width}_${height}_${quality}_${region}`;
  if (TEXTURE_CACHE.has(cacheKey)) {
    return TEXTURE_CACHE.get(cacheKey);
  }

  if (typeof document === 'undefined') return null;

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');

  // Enable high-quality rendering
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = 'high';

  const suitInfo = ROMANIAN_SUITS[suit] || { symbol: '?', color: '#666666', name: 'Necunoscut' };
  const rankInfo = ROMANIAN_RANKS[rank] || { label: String(rank || '?'), name: 'Necunoscut' };

  // Draw premium card background with gradient
  if (enableGradients) {
    const bgGradient = ctx.createLinearGradient(0, 0, width, height);
    bgGradient.addColorStop(0, '#fefefe');
    bgGradient.addColorStop(0.5, '#f9fafb');
    bgGradient.addColorStop(1, '#f3f4f6');
    ctx.fillStyle = bgGradient;
  } else {
    ctx.fillStyle = '#fefefe';
  }
  ctx.fillRect(0, 0, width, height);

  // Draw premium border with rounded corners
  drawRoundedBorder(ctx, width, height, enableShadows);

  // Draw corner elements with enhanced styling
  drawCornerElements(ctx, width, height, rankInfo, suitInfo, enableShadows);

  // Draw center symbol with Romanian styling
  drawCenterSymbol(ctx, width, height, suitInfo, rankInfo, quality);

  // Add point value indicator for Septica (Aces and 10s)
  if (rankInfo.pointValue > 0) {
    drawPointIndicator(ctx, width, height, rankInfo.pointValue);
  }

  // Highlight wild cards (7s) with special indicator
  if (rank === '7') {
    drawWildCardIndicator(ctx, width, height);
  }

  // Add subtle texture overlay
  if (quality === 'ultra' || quality === 'high') {
    addTextureOverlay(ctx, width, height);
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.needsUpdate = true;

  // Apply quality-based settings
  applyTextureQuality(texture, quality);

  TEXTURE_CACHE.set(cacheKey, texture);
  return texture;
}

/**
 * Creates authentic Romanian card back texture
 */
export function createRomanianBackTexture(THREE, options = {}) {
  const {
    width = 512,
    height = 712,
    pattern = 'geometric',
    region = 'traditional',
    quality = 'high',
    timeOfDay = 'afternoon'
  } = options;

  const cacheKey = `back_${pattern}_${region}_${quality}_${timeOfDay}_${width}_${height}`;
  if (BACK_TEXTURE_CACHE.has(cacheKey)) {
    return BACK_TEXTURE_CACHE.get(cacheKey);
  }

  if (typeof document === 'undefined') return null;

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');

  // Enable high-quality rendering
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = 'high';

  // Base gradient based on time of day
  const bgColors = getTimeOfDayColors(timeOfDay);
  const bgGradient = ctx.createLinearGradient(0, 0, width, height);
  bgGradient.addColorStop(0, bgColors.primary);
  bgGradient.addColorStop(0.5, bgColors.secondary);
  bgGradient.addColorStop(1, bgColors.tertiary);

  ctx.fillStyle = bgGradient;
  ctx.fillRect(0, 0, width, height);

  // Draw premium border
  drawRoundedBorder(ctx, width, height, true);

  // Draw Romanian pattern
  drawRomanianPattern(ctx, width, height, pattern, region);

  // Add "Septica Românească" text
  drawTitleText(ctx, width, height);

  // Add subtle Romanian flag colors accent
  drawFlagAccent(ctx, width, height);

  // Add texture overlay
  if (quality === 'ultra' || quality === 'high') {
    addBackTextureOverlay(ctx, width, height);
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.needsUpdate = true;

  applyTextureQuality(texture, quality);

  BACK_TEXTURE_CACHE.set(cacheKey, texture);
  return texture;
}

/**
 * Draws rounded border with premium styling
 */
function drawRoundedBorder(ctx, width, height, enableShadows) {
  const cornerRadius = 24;
  const borderWidth = 8;

  ctx.save();

  // Draw outer shadow if enabled
  if (enableShadows) {
    ctx.shadowColor = 'rgba(0, 0, 0, 0.1)';
    ctx.shadowBlur = 4;
    ctx.shadowOffsetX = 2;
    ctx.shadowOffsetY = 2;
  }

  // Draw border
  ctx.strokeStyle = '#d1d5db';
  ctx.lineWidth = borderWidth;
  ctx.beginPath();
  ctx.roundRect(borderWidth / 2, borderWidth / 2,
               width - borderWidth, height - borderWidth, cornerRadius);
  ctx.stroke();

  // Inner border for premium look
  ctx.shadowColor = 'transparent';
  ctx.strokeStyle = '#e5e7eb';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.roundRect(borderWidth + 2, borderWidth + 2,
               width - 2 * (borderWidth + 2), height - 2 * (borderWidth + 2),
               cornerRadius - 2);
  ctx.stroke();

  ctx.restore();
}

/**
 * Draws corner elements with Romanian styling
 */
function drawCornerElements(ctx, width, height, rankInfo, suitInfo, enableShadows) {
  ctx.save();

  // Configure text rendering
  ctx.textBaseline = 'top';
  ctx.fillStyle = suitInfo.color;

  if (enableShadows) {
    ctx.shadowColor = 'rgba(0, 0, 0, 0.3)';
    ctx.shadowBlur = 2;
    ctx.shadowOffsetX = 1;
    ctx.shadowOffsetY = 1;
  }

  // Top-left corner
  ctx.font = 'bold 64px "Georgia", serif';
  ctx.fillText(rankInfo.label, 32, 32);
  ctx.font = 'bold 56px "Georgia", serif';
  ctx.fillText(suitInfo.symbol, 32, 106);

  // Bottom-right corner (rotated)
  ctx.save();
  ctx.translate(width - 32, height - 32);
  ctx.rotate(Math.PI);
  ctx.font = 'bold 64px "Georgia", serif';
  ctx.fillText(rankInfo.label, 0, 0);
  ctx.font = 'bold 56px "Georgia", serif';
  ctx.fillText(suitInfo.symbol, 0, 74);
  ctx.restore();

  ctx.restore();
}

/**
 * Draws center symbol with Romanian styling
 */
function drawCenterSymbol(ctx, width, height, suitInfo, rankInfo, quality) {
  ctx.save();

  const centerX = width / 2;
  const centerY = height / 2;

  ctx.fillStyle = suitInfo.color;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';

  // Size based on quality
  const fontSize = quality === 'ultra' ? 160 : quality === 'high' ? 140 : 120;
  ctx.font = `${fontSize}px "Georgia", serif`;

  // Add glow effect for high quality
  if (quality === 'ultra' || quality === 'high') {
    ctx.shadowColor = suitInfo.color;
    ctx.shadowBlur = 8;
    ctx.globalAlpha = 0.3;
    ctx.fillText(suitInfo.symbol, centerX, centerY);
    ctx.shadowBlur = 0;
    ctx.globalAlpha = 1;
  }

  ctx.fillText(suitInfo.symbol, centerX, centerY);

  ctx.restore();
}

/**
 * Draws point value indicator for Aces and 10s
 */
function drawPointIndicator(ctx, width, height, pointValue) {
  ctx.save();

  const radius = 16;
  const x = width - 40;
  const y = 40;

  // Draw circle background
  ctx.fillStyle = '#059669';
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fill();

  // Draw point text
  ctx.fillStyle = 'white';
  ctx.font = 'bold 16px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(String(pointValue), x, y);

  ctx.restore();
}

/**
 * Draws wild card indicator for 7s
 */
function drawWildCardIndicator(ctx, width, height) {
  ctx.save();

  // Draw star icon to indicate wild card
  const centerX = width - 40;
  const centerY = height - 40;
  const size = 12;

  ctx.fillStyle = '#f59e0b';
  ctx.beginPath();

  // Draw 5-point star
  for (let i = 0; i < 5; i++) {
    const angle = (i * 2 * Math.PI) / 5 - Math.PI / 2;
    const x = centerX + Math.cos(angle) * size;
    const y = centerY + Math.sin(angle) * size;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);

    // Inner point
    const innerAngle = angle + Math.PI / 5;
    const innerX = centerX + Math.cos(innerAngle) * (size * 0.5);
    const innerY = centerY + Math.sin(innerAngle) * (size * 0.5);
    ctx.lineTo(innerX, innerY);
  }

  ctx.closePath();
  ctx.fill();

  ctx.restore();
}

/**
 * Gets time of day color scheme
 */
function getTimeOfDayColors(timeOfDay) {
  switch (timeOfDay) {
    case 'morning':
      return {
        primary: '#fef3c7',
        secondary: '#fde68a',
        tertiary: '#f59e0b'
      };
    case 'afternoon':
      return {
        primary: '#102a43',
        secondary: '#243b53',
        tertiary: '#334e68'
      };
    case 'evening':
      return {
        primary: '#7c2d12',
        secondary: '#9a3412',
        tertiary: '#c2410c'
      };
    case 'night':
      return {
        primary: '#1e1b4b',
        secondary: '#312e81',
        tertiary: '#3730a3'
      };
    default:
      return {
        primary: '#102a43',
        secondary: '#243b53',
        tertiary: '#334e68'
      };
  }
}

/**
 * Draws Romanian decorative pattern
 */
function drawRomanianPattern(ctx, width, height, pattern, region) {
  ctx.save();

  const patternInfo = ROMANIAN_PATTERNS[pattern] || ROMANIAN_PATTERNS.geometric;
  const colors = patternInfo.colors;

  // Set pattern style
  ctx.globalAlpha = 0.15;
  ctx.lineWidth = 3;

  // Draw geometric pattern
  if (pattern === 'geometric') {
    drawGeometricPattern(ctx, width, height, colors);
  } else if (pattern === 'floral') {
    drawFloralPattern(ctx, width, height, colors);
  } else if (pattern === 'folk') {
    drawFolkPattern(ctx, width, height, colors);
  }

  ctx.restore();
}

function drawGeometricPattern(ctx, width, height, colors) {
  const step = 40;

  for (let x = step; x < width - step; x += step) {
    for (let y = step; y < height - step; y += step) {
      ctx.strokeStyle = colors[Math.floor(Math.random() * colors.length)];
      ctx.beginPath();
      ctx.rect(x - 8, y - 8, 16, 16);
      ctx.stroke();

      // Add diagonal lines
      ctx.beginPath();
      ctx.moveTo(x - 8, y - 8);
      ctx.lineTo(x + 8, y + 8);
      ctx.moveTo(x + 8, y - 8);
      ctx.lineTo(x - 8, y + 8);
      ctx.stroke();
    }
  }
}

function drawFloralPattern(ctx, width, height, colors) {
  const step = 60;

  for (let x = step; x < width - step; x += step) {
    for (let y = step; y < height - step; y += step) {
      ctx.fillStyle = colors[Math.floor(Math.random() * colors.length)];

      // Draw simple flower shape
      const petals = 5;
      const petalSize = 8;

      for (let i = 0; i < petals; i++) {
        const angle = (i * 2 * Math.PI) / petals;
        const petalX = x + Math.cos(angle) * petalSize;
        const petalY = y + Math.sin(angle) * petalSize;

        ctx.beginPath();
        ctx.arc(petalX, petalY, 4, 0, Math.PI * 2);
        ctx.fill();
      }

      // Center dot
      ctx.beginPath();
      ctx.arc(x, y, 2, 0, Math.PI * 2);
      ctx.fill();
    }
  }
}

function drawFolkPattern(ctx, width, height, colors) {
  const step = 50;

  for (let x = step; x < width - step; x += step) {
    for (let y = step; y < height - step; y += step) {
      ctx.strokeStyle = colors[Math.floor(Math.random() * colors.length)];
      ctx.lineWidth = 2;

      // Draw traditional Romanian cross pattern
      ctx.beginPath();
      ctx.moveTo(x - 10, y);
      ctx.lineTo(x + 10, y);
      ctx.moveTo(x, y - 10);
      ctx.lineTo(x, y + 10);
      ctx.moveTo(x - 7, y - 7);
      ctx.lineTo(x + 7, y + 7);
      ctx.moveTo(x + 7, y - 7);
      ctx.lineTo(x - 7, y + 7);
      ctx.stroke();
    }
  }
}

/**
 * Draws title text
 */
function drawTitleText(ctx, width, height) {
  ctx.save();

  ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
  ctx.font = 'bold 24px "Georgia", serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';

  ctx.fillText('SEPTICA', width / 2, height / 2 - 40);
  ctx.font = 'italic 18px "Georgia", serif';
  ctx.fillText('Românească', width / 2, height / 2 + 40);

  ctx.restore();
}

/**
 * Draws Romanian flag accent
 */
function drawFlagAccent(ctx, width, height) {
  ctx.save();

  const barHeight = 8;
  const barWidth = width - 80;
  const startX = 40;
  const startY = height - 60;

  // Blue
  ctx.fillStyle = '#002c84';
  ctx.fillRect(startX, startY, barWidth / 3, barHeight);

  // Yellow
  ctx.fillStyle = '#fdd835';
  ctx.fillRect(startX + barWidth / 3, startY, barWidth / 3, barHeight);

  // Red
  ctx.fillStyle = '#ce1126';
  ctx.fillRect(startX + 2 * barWidth / 3, startY, barWidth / 3, barHeight);

  ctx.restore();
}

/**
 * Adds subtle texture overlay
 */
function addTextureOverlay(ctx, width, height) {
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;

  for (let i = 0; i < data.length; i += 4) {
    const noise = (Math.random() - 0.5) * 8;
    data[i] = Math.max(0, Math.min(255, data[i] + noise));
    data[i + 1] = Math.max(0, Math.min(255, data[i + 1] + noise));
    data[i + 2] = Math.max(0, Math.min(255, data[i + 2] + noise));
  }

  ctx.putImageData(imageData, 0, 0);
}

function addBackTextureOverlay(ctx, width, height) {
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;

  for (let i = 0; i < data.length; i += 4) {
    const noise = (Math.random() - 0.5) * 12;
    data[i] = Math.max(0, Math.min(255, data[i] + noise));
    data[i + 1] = Math.max(0, Math.min(255, data[i + 1] + noise));
    data[i + 2] = Math.max(0, Math.min(255, data[i + 2] + noise));
  }

  ctx.putImageData(imageData, 0, 0);
}

/**
 * Applies quality-based texture settings
 */
function applyTextureQuality(texture, quality) {
  const maxAnisotropy = 16; // Will be clamped by renderer capabilities

  switch (quality) {
    case 'ultra':
      texture.anisotropy = maxAnisotropy;
      texture.minFilter = texture.constructor.LinearMipmapLinearFilter;
      texture.magFilter = texture.constructor.LinearFilter;
      break;
    case 'high':
      texture.anisotropy = Math.min(8, maxAnisotropy);
      texture.minFilter = texture.constructor.LinearMipmapLinearFilter;
      texture.magFilter = texture.constructor.LinearFilter;
      break;
    case 'medium':
      texture.anisotropy = Math.min(4, maxAnisotropy);
      texture.minFilter = texture.constructor.LinearMipmapNearestFilter;
      texture.magFilter = texture.constructor.LinearFilter;
      break;
    case 'low':
      texture.anisotropy = 1;
      texture.minFilter = texture.constructor.NearestMipmapNearestFilter;
      texture.magFilter = texture.constructor.NearestFilter;
      break;
  }

  texture.generateMipmaps = quality !== 'low';
}

// Compatibility functions for existing code
export function getCardTexture(card, THREE, options = {}) {
  return createRomanianCardTexture(card, THREE, options);
}

export function getCardBackTexture(THREE, options = {}) {
  return createRomanianBackTexture(THREE, options);
}

export { ROMANIAN_SUITS, ROMANIAN_RANKS, ROMANIAN_PATTERNS };
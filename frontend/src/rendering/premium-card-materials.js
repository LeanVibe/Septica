/**
 * Premium Card Material System for Romanian Septica
 * Provides physically-based materials with Romanian cultural elements
 */

// Card material configurations for different quality levels
const MATERIAL_CONFIGS = {
  ultra: {
    clearcoat: 0.8,
    clearcoatRoughness: 0.1,
    roughness: 0.15,
    metalness: 0.02,
    reflectivity: 0.9,
    normalScale: 1.2,
    bumpScale: 0.05,
    envMapIntensity: 1.0
  },
  high: {
    clearcoat: 0.6,
    clearcoatRoughness: 0.2,
    roughness: 0.25,
    metalness: 0.01,
    reflectivity: 0.7,
    normalScale: 1.0,
    bumpScale: 0.03,
    envMapIntensity: 0.8
  },
  medium: {
    clearcoat: 0.3,
    clearcoatRoughness: 0.4,
    roughness: 0.4,
    metalness: 0.0,
    reflectivity: 0.5,
    normalScale: 0.8,
    bumpScale: 0.02,
    envMapIntensity: 0.6
  },
  low: {
    clearcoat: 0.0,
    clearcoatRoughness: 1.0,
    roughness: 0.8,
    metalness: 0.0,
    reflectivity: 0.3,
    normalScale: 0.5,
    bumpScale: 0.0,
    envMapIntensity: 0.4
  }
};

// Romanian cultural color palette
const ROMANIAN_COLORS = {
  primary: {
    blue: 0x002c84,    // Romanian blue
    yellow: 0xfdd835,  // Romanian yellow
    red: 0xce1126      // Romanian red
  },
  traditional: {
    forestGreen: 0x1b4332,
    crimsonRed: 0x8b1538,
    goldenYellow: 0xf4a261,
    earthBrown: 0x6f4e37,
    ivoryWhite: 0xfefae0
  },
  regional: {
    moldova: { primary: 0x2a5490, accent: 0xe8b923 },
    wallachia: { primary: 0x8b1538, accent: 0xf4a261 },
    transilvania: { primary: 0x1b4332, accent: 0xfdd835 }
  }
};

// Global texture cache
const textureCache = new Map();
const materialCache = new Map();

/**
 * Creates premium card material with clearcoat finish
 */
export function createPremiumCardMaterial(THREE, options = {}) {
  const {
    quality = 'high',
    region = 'traditional',
    enableClearcoat = true,
    envMap = null,
    normalMap = null,
    roughnessMap = null
  } = options;

  const config = MATERIAL_CONFIGS[quality] || MATERIAL_CONFIGS.high;
  const cacheKey = `${quality}_${region}_${enableClearcoat}_${!!envMap}_${!!normalMap}`;

  if (materialCache.has(cacheKey)) {
    return materialCache.get(cacheKey).clone();
  }

  const material = new THREE.MeshPhysicalMaterial({
    color: 0xffffff,
    roughness: config.roughness,
    metalness: config.metalness,
    reflectivity: config.reflectivity,
    clearcoat: enableClearcoat ? config.clearcoat : 0,
    clearcoatRoughness: config.clearcoatRoughness,
    side: THREE.FrontSide,
    transparent: false,
    alphaTest: 0.1
  });

  // Apply environment map for realistic reflections
  if (envMap) {
    material.envMap = envMap;
    material.envMapIntensity = config.envMapIntensity;
  }

  // Apply normal map for surface detail
  if (normalMap) {
    material.normalMap = normalMap;
    material.normalScale.set(config.normalScale, config.normalScale);
  }

  // Apply roughness map for varying surface properties
  if (roughnessMap) {
    material.roughnessMap = roughnessMap;
  }

  materialCache.set(cacheKey, material);
  return material.clone();
}

/**
 * Creates Romanian-style card back material
 */
export function createRomanianBackMaterial(THREE, options = {}) {
  const {
    quality = 'high',
    region = 'traditional',
    pattern = 'geometric',
    envMap = null
  } = options;

  const config = MATERIAL_CONFIGS[quality] || MATERIAL_CONFIGS.high;
  const colors = ROMANIAN_COLORS.traditional;

  // Create base material
  const material = new THREE.MeshPhysicalMaterial({
    color: colors.ivoryWhite,
    roughness: config.roughness + 0.1, // Slightly more rough for card backs
    metalness: 0.0, // Paper-like material
    reflectivity: config.reflectivity * 0.7,
    clearcoat: config.clearcoat * 0.8,
    clearcoatRoughness: config.clearcoatRoughness + 0.1,
    side: THREE.FrontSide
  });

  // Apply environment map
  if (envMap) {
    material.envMap = envMap;
    material.envMapIntensity = config.envMapIntensity * 0.6;
  }

  return material;
}

/**
 * Creates embossed normal map for card texture detail
 */
export function createCardNormalMap(THREE, width = 256, height = 356) {
  const cacheKey = `normal_${width}_${height}`;
  if (textureCache.has(cacheKey)) {
    return textureCache.get(cacheKey);
  }

  if (typeof document === 'undefined') return null;

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');

  // Create subtle embossed effect
  const gradient = ctx.createRadialGradient(
    width * 0.5, height * 0.5, 0,
    width * 0.5, height * 0.5, Math.min(width, height) * 0.4
  );

  gradient.addColorStop(0, 'rgb(128, 128, 255)'); // Center normal
  gradient.addColorStop(0.7, 'rgb(127, 127, 255)'); // Slight depression
  gradient.addColorStop(1, 'rgb(126, 126, 255)'); // Edge depression

  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);

  // Add subtle border emboss
  ctx.fillStyle = 'rgb(130, 130, 255)';
  ctx.fillRect(0, 0, width, 8); // Top
  ctx.fillRect(0, height - 8, width, 8); // Bottom
  ctx.fillRect(0, 0, 8, height); // Left
  ctx.fillRect(width - 8, 0, 8, height); // Right

  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.needsUpdate = true;

  textureCache.set(cacheKey, texture);
  return texture;
}

/**
 * Creates roughness map for varying surface properties
 */
export function createCardRoughnessMap(THREE, width = 256, height = 356) {
  const cacheKey = `roughness_${width}_${height}`;
  if (textureCache.has(cacheKey)) {
    return textureCache.get(cacheKey);
  }

  if (typeof document === 'undefined') return null;

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');

  // Base roughness (smoother center, rougher edges)
  const gradient = ctx.createRadialGradient(
    width * 0.5, height * 0.5, 0,
    width * 0.5, height * 0.5, Math.min(width, height) * 0.5
  );

  gradient.addColorStop(0, 'rgb(100, 100, 100)'); // Smoother center
  gradient.addColorStop(0.8, 'rgb(120, 120, 120)'); // Medium roughness
  gradient.addColorStop(1, 'rgb(140, 140, 140)'); // Rougher edges

  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);

  // Add subtle noise for realism
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;

  for (let i = 0; i < data.length; i += 4) {
    const noise = (Math.random() - 0.5) * 10; // Small random variation
    data[i] = Math.max(0, Math.min(255, data[i] + noise));
    data[i + 1] = data[i];
    data[i + 2] = data[i];
  }

  ctx.putImageData(imageData, 0, 0);

  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.needsUpdate = true;

  textureCache.set(cacheKey, texture);
  return texture;
}

/**
 * Creates HDRI environment map for realistic lighting
 */
export function createHDRIEnvironment(THREE, scene) {
  // For now, create a simple cube texture that mimics Romanian café lighting
  const size = 512;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');

  // Warm café lighting gradient
  const gradient = ctx.createRadialGradient(
    size * 0.5, size * 0.3, 0,
    size * 0.5, size * 0.3, size * 0.6
  );

  gradient.addColorStop(0, '#fff5e6'); // Warm light source
  gradient.addColorStop(0.4, '#e6d4b7'); // Mid tone
  gradient.addColorStop(0.8, '#8b6914'); // Darker edges
  gradient.addColorStop(1, '#2d1810'); // Dark corners

  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, size, size);

  // Create cube texture faces (simple approach)
  const texture = new THREE.CanvasTexture(canvas);
  texture.mapping = THREE.EquirectangularReflectionMapping;
  texture.needsUpdate = true;

  return texture;
}

/**
 * Quality preset configurations
 */
export const QUALITY_PRESETS = {
  ultra: {
    enableClearcoat: true,
    quality: 'ultra',
    anisotropy: 16,
    envMapIntensity: 1.0,
    normalMapEnabled: true,
    roughnessMapEnabled: true,
    shadowMapSize: 2048
  },
  high: {
    enableClearcoat: true,
    quality: 'high',
    anisotropy: 8,
    envMapIntensity: 0.8,
    normalMapEnabled: true,
    roughnessMapEnabled: true,
    shadowMapSize: 1024
  },
  medium: {
    enableClearcoat: false,
    quality: 'medium',
    anisotropy: 4,
    envMapIntensity: 0.6,
    normalMapEnabled: true,
    roughnessMapEnabled: false,
    shadowMapSize: 512
  },
  low: {
    enableClearcoat: false,
    quality: 'low',
    anisotropy: 1,
    envMapIntensity: 0.4,
    normalMapEnabled: false,
    roughnessMapEnabled: false,
    shadowMapSize: 256
  }
};

/**
 * Gets the appropriate quality preset based on device capabilities
 */
export function getAutoQualityPreset() {
  if (typeof navigator === 'undefined') return QUALITY_PRESETS.medium;

  const ua = navigator.userAgent.toLowerCase();
  const isMobile = /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/.test(ua);
  const isHighEnd = /iphone 1[2-9]|ipad.*os 1[4-9]|android.*chrome.*[8-9]\d/.test(ua);

  if (isMobile) {
    return isHighEnd ? QUALITY_PRESETS.medium : QUALITY_PRESETS.low;
  } else {
    // Desktop - check for discrete GPU hints
    const hasDiscreteGPU = typeof window !== 'undefined' &&
      window.devicePixelRatio > 1.5;
    return hasDiscreteGPU ? QUALITY_PRESETS.ultra : QUALITY_PRESETS.high;
  }
}

export { ROMANIAN_COLORS, MATERIAL_CONFIGS };
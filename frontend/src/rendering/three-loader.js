let cachedPromise = null;

async function importThreeModule() {
  const moduleUrl = 'https://unpkg.com/three@0.152.2/build/three.module.js';
  const mod = await import(moduleUrl);
  const three = { ...mod };
  if (typeof window !== 'undefined') {
    window.THREE = three;
  }
  return three;
}

export function loadThree() {
  if (typeof window === 'undefined') {
    return Promise.resolve(null);
  }
  if (window.THREE) {
    return Promise.resolve(window.THREE);
  }
  if (!cachedPromise) {
    cachedPromise = importThreeModule().catch((error) => {
      console.error('Failed to load Three.js module:', error);
      cachedPromise = null;
      return null;
    });
  }
  return cachedPromise;
}

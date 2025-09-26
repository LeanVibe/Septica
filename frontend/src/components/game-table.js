import { LitElement, html, css } from '../lib/simple-lit.js';
import { fanLayout } from '../utils/fan-layout.js';
import { getCardTexture, getCardBackTexture } from '../rendering/romanian-card-textures.js';
import {
  createPremiumCardMaterial,
  createRomanianBackMaterial,
  createCardNormalMap,
  createCardRoughnessMap,
  createHDRIEnvironment,
  getAutoQualityPreset,
  QUALITY_PRESETS
} from '../rendering/premium-card-materials.js';
import { gameStore } from '../state/game-store.js';

const DEFAULT_CARD_COLOR = 0xffffff;

export class GameTable extends LitElement {
  static properties = {
    playerCards: { attribute: false },
    opponentCount: { type: Number, attribute: 'opponent-count' },
    tableCards: { attribute: false },
    status: { type: String }
  };

  static styles = css`
    :host {
      display: block;
      position: relative;
      width: 100%;
      height: 100%;
      background: radial-gradient(circle at center, rgba(17,50,24,0.6) 0%, rgba(9,20,11,0.95) 60%);
      color: white;
      font-family: 'Segoe UI', sans-serif;
    }
    .viewport {
      width: 100%;
      height: 100%;
    }
    canvas {
      width: 100%;
      height: 100%;
      display: block;
    }
    .overlay {
      pointer-events: none;
      position: absolute;
      inset: 0;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      padding: 1.5rem;
    }
    .overlay-top,
    .overlay-bottom {
      display: flex;
      justify-content: space-between;
      align-items: center;
      pointer-events: none;
    }
    .overlay ::slotted(*) {
      pointer-events: auto;
    }
    .status {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      padding: 0.75rem 1.25rem;
      border-radius: 9999px;
      background: rgba(0,0,0,0.55);
      letter-spacing: 0.08em;
      text-transform: uppercase;
      font-size: 0.75rem;
    }
    .warning {
      position: absolute;
      bottom: 1rem;
      right: 1rem;
      font-size: 0.75rem;
      color: #fca5a5;
      background: rgba(0,0,0,0.4);
      padding: 0.5rem 0.75rem;
      border-radius: 0.5rem;
    }
  `;

  constructor() {
    super();
    this.playerCards = [];
    this.tableCards = [];
    this.opponentCount = 0;
    this.status = '';
    this.__three = typeof window !== 'undefined' ? window.THREE ?? null : null;
    this.__threeAvailable = !!this.__three;
    this.__loadingThree = false;
    this.__needsLayout = false;
    this.__playerMeshes = [];
    this.__tableMeshes = [];
    this.__opponentMeshes = [];
    this.__raycaster = null;
    this.__pointer = { x: 0, y: 0 };

    // Premium rendering settings
    this.__qualityPreset = getAutoQualityPreset();
    this.__envMap = null;
    this.__normalMap = null;
    this.__roughnessMap = null;
    this.__premiumMaterials = new Map();
    this.__timeOfDay = 'afternoon';
    this.__region = 'traditional';
  }

  connectedCallback() {
    super.connectedCallback?.();
    this.__storeUnsub = gameStore.subscribe((state) => {
      this.playerCards = state.player?.hand ?? [];
      this.tableCards = state.table ?? [];
      this.opponentCount = state.opponent?.cardCount ?? 0;
      this.status = state.status ?? '';
      this.requestUpdate();
    });
  }

  render() {
    return html`
      <div class="viewport">
        <canvas id="table-canvas" part="canvas"></canvas>
        <div class="overlay">
          <div class="overlay-top">
            <slot name="opponent"></slot>
            <slot name="score"></slot>
          </div>
          <div class="overlay-bottom">
            <slot name="player"></slot>
            <slot name="actions"></slot>
          </div>
        </div>
        ${this.status ? `<div class="status">${this.status}</div>` : ''}
        ${this.__three ? '' : '<div class="warning">Loading Three.js…</div>'}
      </div>
    `;
  }

  firstUpdated() {
    this.requestRender();
  }

  updated() {
    if (!this.__scene) return;
    this.__needsLayout = true;
  }

  requestRender() {
    if (!this.__three && !this.__loadingThree) {
      this.__loadingThree = true;
      loadThree().then((three) => {
        this.__loadingThree = false;
        if (three) {
          this.__three = three;
          this.__threeAvailable = true;
          this.__initThree();
          this.__needsLayout = true;
          this.requestRender();
        }
      });
    }
    if (!this.__three) return;
    if (!this.__scene) {
      this.__initThree();
      this.__needsLayout = true;
    }
    if (this.__raf) cancelAnimationFrame(this.__raf);
    const loop = () => {
      this.__raf = requestAnimationFrame(loop);
      if (this.__needsLayout) {
        this.__syncCardMeshes();
        this.__needsLayout = false;
      }
      const now = performance.now();
      const delta = ((now - (this.__lastFrameTime ?? now)) / 1000) || 0;
      this.__lastFrameTime = now;
      this.__animateCards(delta);
      this.__renderer?.render(this.__scene, this.__camera);
    };
    loop();
  }

  disconnectedCallback() {
    super.disconnectedCallback?.();
    cancelAnimationFrame(this.__raf);
    this.__storeUnsub?.();
  }

  __initThree() {
    if (this.__scene) return;
    const THREE = this.__three;
    if (!THREE) return;
    const canvas = this.shadowRoot.getElementById('table-canvas');

    // Initialize premium renderer with quality-based settings
    this.__renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: this.__qualityPreset.quality !== 'low',
      alpha: true,
      powerPreference: 'high-performance'
    });

    // Apply quality settings
    const pixelRatio = Math.min(
      window.devicePixelRatio || 1,
      this.__qualityPreset.quality === 'ultra' ? 2 : 1.5
    );
    this.__renderer.setPixelRatio(pixelRatio);
    this.__renderer.setSize(this.clientWidth || 1, this.clientHeight || 1);

    // Enable premium rendering features
    this.__renderer.outputEncoding = THREE.sRGBEncoding;
    this.__renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.__renderer.toneMappingExposure = 1.2;

    // Enable shadows for high quality
    if (this.__qualityPreset.quality !== 'low') {
      this.__renderer.shadowMap.enabled = true;
      this.__renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      this.__renderer.shadowMap.autoUpdate = true;
    }

    if (canvas && !canvas.__septicaPointerAttached) {
      canvas.__septicaPointerAttached = true;
      canvas.style.touchAction = 'none';
      canvas.addEventListener('pointerdown', (event) => this.__onPointerDown(event));
    }

    this.__scene = new THREE.Scene();
    this.__scene.background = null;

    // Initialize premium assets
    this.__initPremiumAssets(THREE);

    // Create premium Romanian café table
    this.__createPremiumTable(THREE);

    // Setup Romanian café lighting
    this.__setupRomanianLighting(THREE);

    // Setup camera with premium settings
    this.__setupPremiumCamera(THREE);

    window.addEventListener('resize', () => this.__onResize());

    // Create card groups
    this.__playerGroup = new THREE.Group();
    this.__playerGroup.position.y = 0.01;
    this.__tableGroup = new THREE.Group();
    this.__tableGroup.position.y = 0.02;
    this.__opponentGroup = new THREE.Group();
    this.__scene.add(this.__playerGroup);
    this.__scene.add(this.__tableGroup);
    this.__scene.add(this.__opponentGroup);
  }

  __onResize() {
    if (!this.__renderer || !this.__camera) return;
    const width = this.clientWidth || 1;
    const height = this.clientHeight || 1;
    this.__renderer.setSize(width, height, false);
    this.__camera.aspect = width / height;
    this.__camera.updateProjectionMatrix();
  }

  __syncCardMeshes() {
    if (!this.__three) return;
    const THREE = this.__three;
    this.__ensurePlayerMeshes(this.playerCards.length);
    this.__ensureTableMeshes(this.tableCards.length);
    this.__ensureOpponentMeshes(this.opponentCount);

    this.__playerMeshes.forEach((mesh, idx) => {
      const card = this.playerCards[idx];
      mesh.visible = idx < this.playerCards.length;
      if (!mesh.visible) {
        mesh.userData.initialized = false;
        mesh.userData.card = null;
        return;
      }
      this.__setCardTextures(mesh, card);
    });

    this.__tableMeshes.forEach((mesh, idx) => {
      const card = this.tableCards[idx];
      mesh.visible = idx < this.tableCards.length;
      if (!mesh.visible) {
        mesh.userData.initialized = false;
        mesh.userData.card = null;
        return;
      }
      this.__setCardTextures(mesh, card);
    });

    this.__opponentMeshes.forEach((mesh, idx) => {
      mesh.visible = idx < this.opponentCount;
      if (!mesh.visible) {
        mesh.userData.initialized = false;
        mesh.userData.card = null;
        return;
      }
      this.__setCardTextures(mesh, null, true);
    });

    this.__updateTargets();
  }

  __ensurePlayerMeshes(count) {
    const THREE = this.__three;
    if (!THREE) return;
    while (this.__playerMeshes.length < count) {
      const mesh = this.__createCardMesh(THREE);
      if (!mesh) break;
      mesh.visible = false;
      this.__playerGroup.add(mesh);
      this.__playerMeshes.push(mesh);
    }
  }

  __ensureTableMeshes(count) {
    const THREE = this.__three;
    if (!THREE) return;
    while (this.__tableMeshes.length < count) {
      const mesh = this.__createCardMesh(THREE);
      if (!mesh) break;
      mesh.visible = false;
      this.__tableGroup.add(mesh);
      this.__tableMeshes.push(mesh);
    }
  }

  __ensureOpponentMeshes(count) {
    const THREE = this.__three;
    if (!THREE) return;
    while (this.__opponentMeshes.length < count) {
      const mesh = this.__createCardMesh(THREE);
      if (!mesh) break;
      mesh.visible = false;
      this.__opponentGroup.add(mesh);
      this.__opponentMeshes.push(mesh);
    }
  }

  __createCardMesh(THREE) {
    const group = new THREE.Group();
    const geometry = new THREE.PlaneGeometry(0.63, 0.88);

    // Create premium materials for card faces
    const frontMaterial = createPremiumCardMaterial(THREE, {
      quality: this.__qualityPreset.quality,
      region: this.__region,
      enableClearcoat: this.__qualityPreset.enableClearcoat,
      envMap: this.__envMap,
      normalMap: this.__normalMap,
      roughnessMap: this.__roughnessMap
    });

    const backMaterial = createRomanianBackMaterial(THREE, {
      quality: this.__qualityPreset.quality,
      region: this.__region,
      pattern: 'geometric',
      envMap: this.__envMap
    });

    const front = new THREE.Mesh(geometry, frontMaterial);
    front.position.z = 0.0008; // Slightly thicker for premium feel
    front.castShadow = this.__qualityPreset.quality !== 'low';
    front.receiveShadow = true;

    const back = new THREE.Mesh(geometry, backMaterial);
    back.rotation.y = Math.PI;
    back.position.z = -0.0008;
    back.castShadow = this.__qualityPreset.quality !== 'low';
    back.receiveShadow = true;

    group.add(front, back);
    group.userData.front = front;
    group.userData.back = back;
    group.userData.targetPosition = new THREE.Vector3();
    group.userData.targetQuaternion = new THREE.Quaternion();
    group.userData.initialized = false;

    // Add premium card thickness with edge geometry
    if (this.__qualityPreset.quality === 'ultra' || this.__qualityPreset.quality === 'high') {
      this.__addCardEdgeGeometry(group, THREE);
    }

    return group;
  }

  __setCardTextures(mesh, card, backOnly = false) {
    const THREE = this.__three;

    // Use Romanian textures with enhanced options
    const textureOptions = {
      quality: this.__qualityPreset.quality,
      region: this.__region,
      timeOfDay: this.__timeOfDay,
      enableShadows: this.__qualityPreset.quality !== 'low',
      enableGradients: this.__qualityPreset.quality !== 'low'
    };

    const frontTexture = backOnly ?
      getCardBackTexture(THREE, textureOptions) :
      getCardTexture(card, THREE, textureOptions);
    const backTexture = getCardBackTexture(THREE, textureOptions);

    if (!frontTexture || !backTexture) return;

    // Apply quality-based texture settings
    const aniso = Math.min(
      this.__maxAnisotropy || 1,
      this.__qualityPreset.anisotropy
    );

    frontTexture.anisotropy = aniso;
    backTexture.anisotropy = aniso;
    frontTexture.encoding = THREE.sRGBEncoding;
    backTexture.encoding = THREE.sRGBEncoding;

    // Apply texture filtering based on quality
    if (this.__qualityPreset.quality === 'ultra' || this.__qualityPreset.quality === 'high') {
      frontTexture.minFilter = THREE.LinearMipmapLinearFilter;
      backTexture.minFilter = THREE.LinearMipmapLinearFilter;
      frontTexture.magFilter = THREE.LinearFilter;
      backTexture.magFilter = THREE.LinearFilter;
    }

    const front = mesh.userData.front;
    const back = mesh.userData.back;
    front.material.map = frontTexture;
    front.material.needsUpdate = true;
    back.material.map = backTexture;
    back.material.needsUpdate = true;

    // Store card reference for interactions
    mesh.userData.card = card;
  }

  __updateTargets() {
    const THREE = this.__three;
    const playerPoses = fanLayout(this.playerCards.length, { radius: 2.8, maxAngle: 62, facing: 0, lift: 0.22, tilt: -12 });
    this.__playerMeshes.forEach((mesh, idx) => {
      const target = mesh.userData.targetPosition;
      const quat = mesh.userData.targetQuaternion;
      if (idx >= this.playerCards.length) {
        mesh.visible = false;
        return;
      }
      mesh.visible = true;
      const pose = playerPoses[idx];
      target.set(pose.position.x, pose.position.y, pose.position.z + 1.8);
      quat.setFromEuler(new THREE.Euler(pose.rotation.x, pose.rotation.y, 0));
      if (!mesh.userData.initialized) {
        mesh.position.copy(target);
        mesh.quaternion.copy(quat);
        mesh.userData.initialized = true;
      }
    });

    const oppPoses = fanLayout(this.opponentCount, { radius: 3.1, maxAngle: 38, facing: 180, lift: 0.08, tilt: -12 });
    this.__opponentMeshes.forEach((mesh, idx) => {
      const target = mesh.userData.targetPosition;
      const quat = mesh.userData.targetQuaternion;
      if (idx >= this.opponentCount) {
        mesh.visible = false;
        return;
      }
      mesh.visible = true;
      const pose = oppPoses[idx];
      target.set(pose.position.x, pose.position.y, pose.position.z - 3.6);
      quat.setFromEuler(new THREE.Euler(pose.rotation.x, pose.rotation.y, 0));
      if (!mesh.userData.initialized) {
        mesh.position.copy(target);
        mesh.quaternion.copy(quat);
        mesh.userData.initialized = true;
      }
    });

    this.__tableMeshes.forEach((mesh, idx) => {
      const target = mesh.userData.targetPosition;
      const quat = mesh.userData.targetQuaternion;
      if (idx >= this.tableCards.length) {
        mesh.visible = false;
        return;
      }
      mesh.visible = true;
      target.set(-1.2 + idx * 0.75, 0.06 + idx * 0.005, 0);
      quat.setFromEuler(new THREE.Euler(-Math.PI / 2, 0, idx * 0.08));
      if (!mesh.userData.initialized) {
        mesh.position.copy(target);
        mesh.quaternion.copy(quat);
        mesh.userData.initialized = true;
      }
    });
  }

  __animateCards(delta) {
    if (!this.__scene || !this.__three) return;
    const damping = 1 - Math.pow(0.001, delta * 60);
    const groups = [this.__playerMeshes, this.__tableMeshes, this.__opponentMeshes];
    groups.forEach(meshes => {
      meshes.forEach(mesh => {
        if (!mesh.visible) return;
        const targetPos = mesh.userData.targetPosition;
        const targetQuat = mesh.userData.targetQuaternion;
        mesh.position.lerp(targetPos, damping);
        mesh.quaternion.slerp(targetQuat, damping);
      });
    });
  }

  __ensureRaycaster() {
    if (!this.__three) return null;
    if (!this.__raycaster) {
      this.__raycaster = new this.__three.Raycaster();
    }
    return this.__raycaster;
  }

  __onPointerDown(event) {
    if (!this.__scene || !this.__three) return;
    const canvas = this.shadowRoot.getElementById('table-canvas');
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    this.__pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this.__pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    const raycaster = this.__ensureRaycaster();
    if (!raycaster) return;
    raycaster.setFromCamera(this.__pointer, this.__camera);
    const targets = [...this.__playerMeshes, ...this.__tableMeshes];
    const children = targets.flatMap((group) => group.children ?? []);
    const intersects = raycaster.intersectObjects(children, true);
    if (!intersects.length) return;
    const mesh = intersects[0].object?.parent;
    const card = mesh?.userData?.card;
    if (card && card.id) {
      gameStore.playCard(card.id.replace(/-played-.*$/, ''));
    }
  }

  /**
   * Initialize premium assets (textures, materials)
   */
  __initPremiumAssets(THREE) {
    // Create environment map for realistic reflections
    this.__envMap = createHDRIEnvironment(THREE, this.__scene);

    // Create normal and roughness maps for card detail
    if (this.__qualityPreset.normalMapEnabled) {
      this.__normalMap = createCardNormalMap(THREE);
    }

    if (this.__qualityPreset.roughnessMapEnabled) {
      this.__roughnessMap = createCardRoughnessMap(THREE);
    }

    // Set max anisotropy for textures based on quality
    if (this.__renderer) {
      const maxAnisotropy = this.__renderer.capabilities.getMaxAnisotropy();
      this.__maxAnisotropy = Math.min(maxAnisotropy, this.__qualityPreset.anisotropy);
    }
  }

  /**
   * Create premium Romanian café table
   */
  __createPremiumTable(THREE) {
    // Create table geometry with higher detail
    const segments = this.__qualityPreset.quality === 'low' ? 32 : 64;
    const tableGeo = new THREE.CircleGeometry(6, segments);

    // Create premium table material
    const tableMat = new THREE.MeshPhysicalMaterial({
      color: 0x2d1810, // Rich dark wood
      roughness: 0.7,
      metalness: 0.02,
      clearcoat: 0.3,
      clearcoatRoughness: 0.4,
      envMap: this.__envMap,
      envMapIntensity: 0.4
    });

    const tableMesh = new THREE.Mesh(tableGeo, tableMat);
    tableMesh.rotation.x = -Math.PI / 2;
    tableMesh.receiveShadow = true;
    tableMesh.castShadow = false;

    this.__scene.add(tableMesh);

    // Add table cloth detail for authenticity
    if (this.__qualityPreset.quality !== 'low') {
      this.__createTableCloth(THREE);
    }
  }

  /**
   * Create Romanian table cloth detail
   */
  __createTableCloth(THREE) {
    const clothGeo = new THREE.CircleGeometry(5.8, 32);
    const clothMat = new THREE.MeshPhysicalMaterial({
      color: 0x8b1538, // Romanian red
      roughness: 0.8,
      metalness: 0.0,
      transparent: true,
      opacity: 0.15,
      side: THREE.DoubleSide
    });

    const clothMesh = new THREE.Mesh(clothGeo, clothMat);
    clothMesh.rotation.x = -Math.PI / 2;
    clothMesh.position.y = 0.001;

    this.__scene.add(clothMesh);
  }

  /**
   * Setup Romanian café lighting atmosphere
   */
  __setupRomanianLighting(THREE) {
    // Ambient light for general illumination
    const ambient = new THREE.AmbientLight(0x4a3728, 0.8);
    this.__scene.add(ambient);

    // Main key light (warm café lighting)
    const keyLight = new THREE.DirectionalLight(0xfff5d1, 1.2);
    keyLight.position.set(4, 9, 6);
    keyLight.castShadow = this.__qualityPreset.quality !== 'low';

    if (keyLight.castShadow) {
      keyLight.shadow.mapSize.width = this.__qualityPreset.shadowMapSize;
      keyLight.shadow.mapSize.height = this.__qualityPreset.shadowMapSize;
      keyLight.shadow.camera.near = 0.1;
      keyLight.shadow.camera.far = 50;
      keyLight.shadow.camera.left = -10;
      keyLight.shadow.camera.right = 10;
      keyLight.shadow.camera.top = 10;
      keyLight.shadow.camera.bottom = -10;
    }

    this.__scene.add(keyLight);

    // Rim light for card definition
    const rimLight = new THREE.DirectionalLight(0xe8b923, 0.6);
    rimLight.position.set(-4, 6, -4);
    this.__scene.add(rimLight);

    // Add subtle fill light
    const fillLight = new THREE.DirectionalLight(0x2a5490, 0.3);
    fillLight.position.set(0, 4, -8);
    this.__scene.add(fillLight);

    // Time-of-day specific lighting adjustments
    this.__updateTimeOfDayLighting();
  }

  /**
   * Update lighting based on time of day
   */
  __updateTimeOfDayLighting() {
    // This could be called to change atmosphere dynamically
    const timeColors = {
      morning: { key: 0xffeaa7, rim: 0xfdd835 },
      afternoon: { key: 0xfff5d1, rim: 0xe8b923 },
      evening: { key: 0xff9f43, rim: 0xd63031 },
      night: { key: 0x74b9ff, rim: 0x6c5ce7 }
    };

    const colors = timeColors[this.__timeOfDay] || timeColors.afternoon;
    // Color updates would be applied to existing lights here
  }

  /**
   * Setup premium camera with Romanian café perspective
   */
  __setupPremiumCamera(THREE) {
    this.__camera = new THREE.PerspectiveCamera(
      42, // FOV optimized for card games
      this.clientWidth / this.clientHeight,
      0.1,
      100
    );

    // Position for optimal Romanian Septica view
    this.__camera.position.set(0, 6.2, 8.4);
    this.__camera.lookAt(0, 0, 0);

    // Add subtle camera breathing animation for premium feel
    this.__camera.userData.originalPosition = this.__camera.position.clone();
    this.__camera.userData.breathingPhase = 0;
  }

  /**
   * Add card edge geometry for premium thickness effect
   */
  __addCardEdgeGeometry(group, THREE) {
    const edgeThickness = 0.002;
    const width = 0.63;
    const height = 0.88;

    // Create edge material
    const edgeMaterial = new THREE.MeshPhysicalMaterial({
      color: 0xf8f9fa,
      roughness: 0.6,
      metalness: 0.0,
      clearcoat: 0.1,
      clearcoatRoughness: 0.8
    });

    // Create edge geometry for card sides
    const edgeGeometries = [
      // Top edge
      new THREE.BoxGeometry(width, edgeThickness, edgeThickness),
      // Bottom edge
      new THREE.BoxGeometry(width, edgeThickness, edgeThickness),
      // Left edge
      new THREE.BoxGeometry(edgeThickness, height, edgeThickness),
      // Right edge
      new THREE.BoxGeometry(edgeThickness, height, edgeThickness)
    ];

    const edgePositions = [
      [0, height / 2, 0],
      [0, -height / 2, 0],
      [-width / 2, 0, 0],
      [width / 2, 0, 0]
    ];

    edgeGeometries.forEach((geometry, index) => {
      const edge = new THREE.Mesh(geometry, edgeMaterial.clone());
      edge.position.set(...edgePositions[index]);
      edge.castShadow = true;
      edge.receiveShadow = true;
      group.add(edge);
    });
  }

customElements.define('game-table', GameTable);

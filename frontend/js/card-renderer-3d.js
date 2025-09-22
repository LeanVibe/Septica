/**
 * Professional 3D Card Renderer using Three.js
 * Romanian Septica Game - ShuffleCats Quality Card Rendering
 */

class Card3DRenderer {
    constructor(container, options = {}) {
        this.container = container;
        
        // Initialize performance monitor
        this.performanceMonitor = new PerformanceMonitor();
        this.performanceMonitor.setCallbacks({
            onQualityChange: (newQuality, oldQuality, settings) => this.adaptQuality(newQuality, settings),
            onPerformanceAlert: (type, data) => this.handlePerformanceAlert(type, data)
        });
        
        // Initialize Mobile LOD System (if available) - temporarily disabled due to circular dependency
        this.mobileLODSystem = null;
        if (false && typeof MobileLODSystem !== 'undefined') {
            this.mobileLODSystem = new MobileLODSystem(null, this.performanceMonitor);
        }
        
        // Default options with mobile optimizations
        this.options = {
            width: options.width || 800,
            height: options.height || 600,
            cardWidth: options.cardWidth || 1.6,
            cardHeight: options.cardHeight || 2.4,
            cardThickness: options.cardThickness || 0.05,
            enableShadows: options.enableShadows !== false,
            enableAntialiasing: options.enableAntialiasing !== false,
            pixelRatio: options.pixelRatio || Math.min(window.devicePixelRatio, 2),
            adaptiveQuality: options.adaptiveQuality !== false,
            maxFPS: options.maxFPS || 60,
            targetFPS: options.targetFPS || 30,
            ...options
        };
        
        // Apply LOD settings if available
        if (this.mobileLODSystem) {
            const lodSettings = this.mobileLODSystem.getLODSettings();
            this.options.pixelRatio = lodSettings.pixelRatio;
            this.options.enableShadows = lodSettings.enableShadows;
            this.options.enableAntialiasing = lodSettings.enableAntialiasing;
            this.options.shadowMapSize = lodSettings.shadowMapSize;
        } else {
            // Fallback to performance monitor settings
            this.currentQuality = this.performanceMonitor.deviceCapabilities.tier;
            this.qualitySettings = this.performanceMonitor.getQualitySettings(this.currentQuality);
            this.applyQualitySettings();
        }
        
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.cards = [];
        this.animationFrameId = null;
        this.tableTexture = null;
        this.cardMaterials = {};
        
        // Performance tracking
        this.frameCount = 0;
        this.lastTime = performance.now();
        this.currentFPS = 0;
        this.fpsTarget = this.options.targetFPS;
        this.frameTimeThreshold = 1000 / this.fpsTarget;
        
        // Mobile optimizations
        this.isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        this.isLowEndDevice = this.performanceMonitor.isLowEndDevice;
        
        // Initialize systems
        this.initializeRenderer();
        this.createLighting();
        this.createTable();
        this.setupEventListeners();
        this.setupMobileOptimizations();
        this.initializeParticleEffects();
        this.initializeMobileTouchSystem();
        this.startRenderLoop();
        
        console.log(`3D Renderer initialized - Quality: ${this.currentQuality || 'LOD'}, Mobile: ${this.isMobile}, Low-end: ${this.isLowEndDevice}`);
    }
    
    /**
     * Apply quality settings to renderer options
     */
    applyQualitySettings() {
        // Use fallback values if quality settings are undefined
        if (!this.qualitySettings) {
            console.warn('Quality settings undefined, using fallback values');
            this.qualitySettings = {
                pixelRatio: Math.min(window.devicePixelRatio, 2),
                enableShadows: true,
                enableAntialiasing: true,
                shadowMapSize: 1024
            };
        }
        
        this.options.pixelRatio = this.qualitySettings.pixelRatio;
        this.options.enableShadows = this.qualitySettings.enableShadows;
        this.options.enableAntialiasing = this.qualitySettings.enableAntialiasing;
        this.options.shadowMapSize = this.qualitySettings.shadowMapSize;
    }
    
    /**
     * Setup mobile-specific optimizations
     */
    setupMobileOptimizations() {
        if (this.isMobile) {
            // Reduce shadow quality on mobile
            if (this.renderer.shadowMap.enabled) {
                this.renderer.shadowMap.type = THREE.BasicShadowMap;
            }
            
            // Optimize texture filtering
            this.scene.traverse((object) => {
                if (object.material && object.material.map) {
                    object.material.map.generateMipmaps = false;
                    object.material.map.minFilter = THREE.LinearFilter;
                }
            });
            
            // Pause rendering when page is not visible
            document.addEventListener('visibilitychange', () => {
                if (document.hidden) {
                    this.pauseRendering();
                } else {
                    this.resumeRendering();
                }
            });
        }
        
        // Touch event optimizations for mobile
        if ('ontouchstart' in window) {
            this.setupTouchControls();
        }
    }
    
    /**
     * Initialize mobile touch system
     */
    initializeMobileTouchSystem() {
        if (typeof MobileTouchSystem !== 'undefined' && this.isMobile) {
            this.mobileTouchSystem = new MobileTouchSystem(this.container, this);
            
            // Set up touch event listeners
            this.mobileTouchSystem.on('cardSelected', (data) => {
                this.handleCardSelected(data.detail.card, data.detail.position);
            });
            
            this.mobileTouchSystem.on('tap', (touchData) => {
                this.handleMobileTap(touchData);
            });
            
            this.mobileTouchSystem.on('longpress', (touchData) => {
                this.handleMobileLongPress(touchData);
            });
            
            console.log('Mobile Touch System initialized');
        }
    }
    
    /**
     * Handle mobile card selection
     */
    handleCardSelected(cardData, position) {
        console.log('Mobile card selected:', cardData);
        
        // Emit event for game logic
        const event = new CustomEvent('cardTapped', {
            detail: {
                suit: cardData.suit,
                value: cardData.value,
                mobile: true
            }
        });
        this.container.dispatchEvent(event);
    }
    
    /**
     * Handle mobile tap
     */
    handleMobileTap(touchData) {
        // Add touch ripple effect
        this.addTouchRipple(touchData.startX, touchData.startY);
    }
    
    /**
     * Handle mobile long press
     */
    handleMobileLongPress(touchData) {
        // Show card details or context menu
        console.log('Long press detected at:', touchData.startX, touchData.startY);
    }
    
    /**
     * Add touch ripple effect
     */
    addTouchRipple(x, y) {
        const ripple = document.createElement('div');
        ripple.className = 'touch-ripple';
        
        const rect = this.container.getBoundingClientRect();
        const size = 60;
        
        ripple.style.left = (x - rect.left - size/2) + 'px';
        ripple.style.top = (y - rect.top - size/2) + 'px';
        ripple.style.width = size + 'px';
        ripple.style.height = size + 'px';
        
        this.container.appendChild(ripple);
        
        // Remove after animation
        setTimeout(() => {
            if (ripple.parentNode) {
                ripple.parentNode.removeChild(ripple);
            }
        }, 600);
    }
    
    /**
     * Setup touch controls for mobile
     */
    setupTouchControls() {
        let touchStartX = 0;
        let touchStartY = 0;
        
        this.renderer.domElement.addEventListener('touchstart', (e) => {
            e.preventDefault();
            touchStartX = e.touches[0].clientX;
            touchStartY = e.touches[0].clientY;
        }, { passive: false });
        
        this.renderer.domElement.addEventListener('touchmove', (e) => {
            e.preventDefault();
        }, { passive: false });
        
        this.renderer.domElement.addEventListener('touchend', (e) => {
            e.preventDefault();
            const touchEndX = e.changedTouches[0].clientX;
            const touchEndY = e.changedTouches[0].clientY;
            
            // Simple tap detection
            const tapThreshold = 10;
            if (Math.abs(touchEndX - touchStartX) < tapThreshold && 
                Math.abs(touchEndY - touchStartY) < tapThreshold) {
                this.handleTap(touchEndX, touchEndY);
            }
        }, { passive: false });
    }
    
    /**
     * Handle tap/click on cards
     */
    handleTap(x, y) {
        const rect = this.renderer.domElement.getBoundingClientRect();
        const mouse = new THREE.Vector2();
        mouse.x = ((x - rect.left) / rect.width) * 2 - 1;
        mouse.y = -((y - rect.top) / rect.height) * 2 + 1;
        
        const raycaster = new THREE.Raycaster();
        raycaster.setFromCamera(mouse, this.camera);
        const intersects = raycaster.intersectObjects(this.scene.children, true);
        
        if (intersects.length > 0) {
            const tappedObject = intersects[0].object.parent;
            if (tappedObject.userData.isCard) {
                this.onCardTapped(tappedObject);
            }
        }
    }
    
    /**
     * Handle card tap event
     */
    onCardTapped(card) {
        console.log('Card tapped:', card.userData);
        
        // Trigger card selection particle effect
        if (this.particleEffects) {
            this.particleEffects.triggerCardSelect(card.position);
        }
        
        // Emit custom event for card selection
        const event = new CustomEvent('cardTapped', {
            detail: {
                suit: card.userData.suit,
                value: card.userData.value
            }
        });
        this.container.dispatchEvent(event);
        
        // Visual feedback
        this.highlightCard(card);
    }
    
    /**
     * Highlight selected card
     */
    highlightCard(card) {
        // Reset all cards
        this.cards.forEach(c => {
            if (!c.userData.isAnimating) {
                c.position.y = c.userData.originalPosition.y;
                c.rotation.x = c.userData.originalRotation.x;
            }
        });
        
        // Highlight selected card
        if (!card.userData.isAnimating) {
            card.position.y = card.userData.originalPosition.y + 0.3;
            card.rotation.x = card.userData.originalRotation.x - 0.2;
        }
    }
    
    /**
     * Adapt quality settings
     */
    adaptQuality(newQuality, settings) {
        console.log(`Adapting quality to ${newQuality}`, settings);
        
        // Validate settings parameter
        if (!settings) {
            console.warn('Settings undefined in adaptQuality, using fallback');
            settings = {
                pixelRatio: Math.min(window.devicePixelRatio, 2),
                enableShadows: true,
                enableAntialiasing: true,
                shadowMapSize: 1024
            };
        }
        
        this.currentQuality = newQuality;
        this.qualitySettings = settings;
        this.applyQualitySettings();
        
        // Update renderer settings
        if (this.renderer && settings.pixelRatio !== undefined) {
            this.renderer.setPixelRatio(settings.pixelRatio);
            this.renderer.shadowMap.enabled = settings.enableShadows;
            
            // Update shadow map size
            this.scene.traverse((object) => {
                if (object.isDirectionalLight && object.shadow) {
                    object.shadow.mapSize.width = settings.shadowMapSize;
                    object.shadow.mapSize.height = settings.shadowMapSize;
                    object.shadow.map?.dispose();
                    object.shadow.map = null;
                }
            });
            
            // Update antialiasing (requires renderer recreation for WebGL)
            if (this.options.enableAntialiasing !== settings.enableAntialiasing) {
                this.recreateRenderer(settings);
            }
            
            // Update particle effects quality
            if (this.particleEffects) {
                this.particleEffects.setQualityLevel(newQuality);
            }
        }
    }
    
    /**
     * Recreate renderer with new settings
     */
    recreateRenderer(settings) {
        const oldCanvas = this.renderer.domElement;
        const parent = oldCanvas.parentNode;
        
        // Dispose old renderer
        this.renderer.dispose();
        
        // Create new renderer
        this.renderer = new THREE.WebGLRenderer({
            antialias: settings.enableAntialiasing,
            alpha: false,
            powerPreference: 'high-performance',
            precision: 'highp',
            preserveDrawingBuffer: false
        });
        
        this.renderer.setSize(this.options.width, this.options.height);
        this.renderer.setPixelRatio(settings.pixelRatio);
        this.renderer.shadowMap.enabled = settings.enableShadows;
        this.renderer.shadowMap.type = this.isMobile ? THREE.BasicShadowMap : THREE.PCFSoftShadowMap;
        
        // Enhanced visual settings
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.2;
        this.renderer.outputEncoding = THREE.sRGBEncoding;
        this.renderer.physicallyCorrectLights = true;
        
        // Replace canvas
        parent.removeChild(oldCanvas);
        parent.appendChild(this.renderer.domElement);
        
        // Reattach event listeners
        this.setupEventListeners();
        if (this.isMobile) {
            this.setupTouchControls();
        }
    }
    
    /**
     * Handle performance alerts
     */
    handlePerformanceAlert(type, data) {
        console.warn(`Performance alert: ${type}`, data);
        
        switch (type) {
            case 'critical_memory':
                this.handleCriticalMemory();
                break;
            case 'low_fps':
                this.handleLowFPS();
                break;
            case 'high_latency':
                this.handleHighLatency();
                break;
        }
    }
    
    /**
     * Handle critical memory situation
     */
    handleCriticalMemory() {
        console.log('Handling critical memory situation');
        
        // Force garbage collection if available
        if (window.gc) {
            window.gc();
        }
        
        // Reduce texture quality
        this.scene.traverse((object) => {
            if (object.material && object.material.map) {
                const texture = object.material.map;
                if (texture.image && texture.image.width > 256) {
                    // Create smaller texture
                    const canvas = document.createElement('canvas');
                    canvas.width = 256;
                    canvas.height = 256;
                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(texture.image, 0, 0, 256, 256);
                    
                    texture.image = canvas;
                    texture.needsUpdate = true;
                }
            }
        });
        
        // Clear material cache
        this.cardMaterials = {};
    }
    
    /**
     * Handle low FPS situation
     */
    handleLowFPS() {
        console.log('Handling low FPS situation');
        
        // Reduce animation frequency
        this.fpsTarget = Math.max(15, this.fpsTarget - 5);
        this.frameTimeThreshold = 1000 / this.fpsTarget;
        
        // Disable shadows if enabled
        if (this.renderer.shadowMap.enabled && this.currentQuality !== 'low') {
            this.renderer.shadowMap.enabled = false;
        }
    }
    
    /**
     * Handle high network latency
     */
    handleHighLatency() {
        console.log('Handling high network latency');
        
        // Reduce network update frequency
        // This would be handled by the WebSocket client
        if (window.wsClient) {
            window.wsClient.heartbeatIntervalMs = Math.min(window.wsClient.heartbeatIntervalMs * 1.5, 60000);
        }
    }
    
    /**
     * Pause rendering for performance
     */
    pauseRendering() {
        this.renderingPaused = true;
        console.log('Rendering paused');
    }
    
    /**
     * Resume rendering
     */
    resumeRendering() {
        this.renderingPaused = false;
        console.log('Rendering resumed');
    }
    
    /**
     * Initialize particle effects system
     */
    initializeParticleEffects() {
        if (window.ParticleEffectsSystem) {
            this.particleEffects = new ParticleEffectsSystem(this.scene, {
                maxParticles: this.qualitySettings.particleCount,
                qualityLevel: this.currentQuality,
                enablePhysics: !this.isLowEndDevice
            });
            
            console.log('Particle effects system initialized');
        } else {
            console.warn('ParticleEffectsSystem not available');
        }
    }

    /**
     * Initialize Three.js renderer with professional settings
     */
    initializeRenderer() {
        // Scene setup
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x0F5132); // Romanian table felt color
        this.scene.fog = new THREE.Fog(0x0F5132, 10, 50);
        
        // Camera setup with professional perspective
        this.camera = new THREE.PerspectiveCamera(
            45, // Field of view
            this.options.width / this.options.height, // Aspect ratio
            0.1, // Near clipping plane
            1000 // Far clipping plane
        );
        this.camera.position.set(0, 8, 12);
        this.camera.lookAt(0, 0, 0);
        
        // Renderer setup with high quality settings
        this.renderer = new THREE.WebGLRenderer({
            antialias: this.options.enableAntialiasing,
            alpha: false,
            powerPreference: 'high-performance',
            precision: 'highp',
            preserveDrawingBuffer: false
        });
        
        this.renderer.setSize(this.options.width, this.options.height);
        this.renderer.setPixelRatio(this.options.pixelRatio);
        this.renderer.shadowMap.enabled = this.options.enableShadows;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        this.renderer.shadowMap.soft = true;
        
        // Enhanced visual settings
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.2;
        this.renderer.outputEncoding = THREE.sRGBEncoding;
        this.renderer.physicallyCorrectLights = true;
        
        // Add to DOM
        this.container.appendChild(this.renderer.domElement);
    }
    
    /**
     * Create professional lighting setup
     */
    createLighting() {
        // Main directional light (key light)
        const keyLight = new THREE.DirectionalLight(0xffffff, 1.0);
        keyLight.position.set(5, 10, 5);
        keyLight.castShadow = true;
        keyLight.shadow.mapSize.width = 2048;
        keyLight.shadow.mapSize.height = 2048;
        keyLight.shadow.camera.near = 0.5;
        keyLight.shadow.camera.far = 50;
        keyLight.shadow.camera.left = -10;
        keyLight.shadow.camera.right = 10;
        keyLight.shadow.camera.top = 10;
        keyLight.shadow.camera.bottom = -10;
        keyLight.shadow.radius = 8;
        keyLight.shadow.blurSamples = 25;
        this.scene.add(keyLight);
        
        // Fill light (softer, from opposite side)
        const fillLight = new THREE.DirectionalLight(0xffffff, 0.4);
        fillLight.position.set(-3, 5, -3);
        this.scene.add(fillLight);
        
        // Ambient light for overall scene illumination
        const ambientLight = new THREE.AmbientLight(0x404040, 0.3);
        this.scene.add(ambientLight);
        
        // Rim light for card edge definition
        const rimLight = new THREE.DirectionalLight(0xfcd116, 0.2); // Romanian yellow
        rimLight.position.set(0, 2, -8);
        this.scene.add(rimLight);
        
        // Point light for table warmth
        const tableLight = new THREE.PointLight(0x002b7f, 0.3, 20); // Romanian blue
        tableLight.position.set(0, 3, 0);
        this.scene.add(tableLight);
    }
    
    /**
     * Create professional card table surface
     */
    createTable() {
        const tableGeometry = new THREE.CylinderGeometry(8, 8, 0.2, 32);
        
        // Create felt texture
        const canvas = document.createElement('canvas');
        canvas.width = 512;
        canvas.height = 512;
        const ctx = canvas.getContext('2d');
        
        // Base felt color
        ctx.fillStyle = '#0F5132';
        ctx.fillRect(0, 0, 512, 512);
        
        // Add subtle texture pattern
        for (let i = 0; i < 1000; i++) {
            ctx.fillStyle = `rgba(${Math.random() * 50}, ${Math.random() * 50 + 100}, ${Math.random() * 50 + 50}, 0.1)`;
            ctx.fillRect(Math.random() * 512, Math.random() * 512, 2, 2);
        }
        
        // Romanian flag accent pattern
        const gradient = ctx.createRadialGradient(256, 256, 0, 256, 256, 200);
        gradient.addColorStop(0, 'rgba(252, 209, 22, 0.05)'); // Romanian yellow
        gradient.addColorStop(0.5, 'rgba(0, 43, 127, 0.03)'); // Romanian blue
        gradient.addColorStop(1, 'rgba(206, 17, 38, 0.02)'); // Romanian red
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, 512, 512);
        
        this.tableTexture = new THREE.CanvasTexture(canvas);
        this.tableTexture.wrapS = THREE.RepeatWrapping;
        this.tableTexture.wrapT = THREE.RepeatWrapping;
        this.tableTexture.repeat.set(4, 4);
        
        const tableMaterial = new THREE.MeshPhongMaterial({
            map: this.tableTexture,
            bumpMap: this.tableTexture,
            bumpScale: 0.02,
            shininess: 10
        });
        
        const table = new THREE.Mesh(tableGeometry, tableMaterial);
        table.position.y = -0.1;
        table.receiveShadow = true;
        this.scene.add(table);
    }
    
    /**
     * Create professional card material
     */
    createCardMaterial(suit, value, isBack = false) {
        const canvas = document.createElement('canvas');
        canvas.width = 256;
        canvas.height = 358; // Proper card proportions
        const ctx = canvas.getContext('2d');
        
        if (isBack) {
            // Romanian-themed card back
            const gradient = ctx.createLinearGradient(0, 0, 256, 358);
            gradient.addColorStop(0, '#002B7F'); // Romanian blue
            gradient.addColorStop(0.5, '#0039A6');
            gradient.addColorStop(1, '#002B7F');
            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, 256, 358);
            
            // Romanian flag pattern
            ctx.fillStyle = '#FCD116'; // Romanian yellow
            ctx.fillRect(20, 20, 216, 8);
            ctx.fillRect(20, 330, 216, 8);
            ctx.fillRect(20, 175, 216, 8);
            
            ctx.fillStyle = '#CE1126'; // Romanian red
            ctx.fillRect(20, 32, 216, 4);
            ctx.fillRect(20, 322, 216, 4);
            ctx.fillRect(20, 179, 216, 4);
            
            // Decorative pattern
            ctx.strokeStyle = '#FCD116';
            ctx.lineWidth = 2;
            ctx.setLineDash([5, 5]);
            ctx.strokeRect(30, 30, 196, 298);
        } else {
            // Card face
            ctx.fillStyle = '#FFFFFF';
            ctx.fillRect(0, 0, 256, 358);
            
            // Card border
            ctx.strokeStyle = '#000000';
            ctx.lineWidth = 2;
            ctx.strokeRect(1, 1, 254, 356);
            
            // Suit color
            const suitColor = (suit === 'hearts' || suit === 'diamonds') ? '#CE1126' : '#000000';
            ctx.fillStyle = suitColor;
            ctx.font = 'bold 48px serif';
            ctx.textAlign = 'center';
            
            // Value display
            const displayValue = this.getCardDisplayValue(value);
            ctx.fillText(displayValue, 128, 80);
            ctx.fillText(displayValue, 128, 300);
            
            // Suit symbols
            ctx.font = '64px serif';
            const suitSymbol = this.getSuitSymbol(suit);
            ctx.fillText(suitSymbol, 128, 180);
            
            // Corner indicators
            ctx.font = 'bold 24px serif';
            ctx.textAlign = 'left';
            ctx.fillText(displayValue, 15, 35);
            ctx.fillText(suitSymbol, 15, 65);
            
            // Rotate for bottom corner
            ctx.save();
            ctx.translate(256, 358);
            ctx.rotate(Math.PI);
            ctx.fillText(displayValue, 15, 35);
            ctx.fillText(suitSymbol, 15, 65);
            ctx.restore();
        }
        
        const texture = new THREE.CanvasTexture(canvas);
        texture.minFilter = THREE.LinearFilter;
        texture.magFilter = THREE.LinearFilter;
        texture.flipY = false;
        
        return new THREE.MeshPhongMaterial({
            map: texture,
            transparent: false,
            shininess: 50,
            specular: 0x111111
        });
    }
    
    /**
     * Get card display value (Jack, Queen, King, Ace)
     */
    getCardDisplayValue(value) {
        const valueMap = {
            7: '7', 8: '8', 9: '9', 10: '10',
            11: 'J', 12: 'Q', 13: 'K', 14: 'A'
        };
        return valueMap[value] || value.toString();
    }
    
    /**
     * Get suit symbol
     */
    getSuitSymbol(suit) {
        const symbols = {
            hearts: '♥',
            diamonds: '♦',
            clubs: '♣',
            spades: '♠'
        };
        return symbols[suit] || suit;
    }
    
    /**
     * Create a 3D card with professional geometry
     */
    createCard(suit, value, position = { x: 0, y: 0, z: 0 }, rotation = { x: 0, y: 0, z: 0 }) {
        const cardGroup = new THREE.Group();
        
        // Card dimensions
        const width = this.options.cardWidth;
        const height = this.options.cardHeight;
        const thickness = this.options.cardThickness;
        
        // Main card geometry with rounded corners
        const cardGeometry = new THREE.BoxGeometry(width, height, thickness);
        
        // Bevel the edges for realism
        const edges = new THREE.EdgesGeometry(cardGeometry);
        const lineMaterial = new THREE.LineBasicMaterial({ 
            color: 0x333333, 
            transparent: true, 
            opacity: 0.3 
        });
        const cardEdges = new THREE.LineSegments(edges, lineMaterial);
        cardGroup.add(cardEdges);
        
        // Create materials
        const frontMaterial = this.createCardMaterial(suit, value, false);
        const backMaterial = this.createCardMaterial(suit, value, true);
        const sideMaterial = new THREE.MeshPhongMaterial({ 
            color: 0xF5F5F5,
            shininess: 30
        });
        
        // Apply materials to different faces
        const materials = [
            sideMaterial, // Right
            sideMaterial, // Left
            sideMaterial, // Top
            sideMaterial, // Bottom
            frontMaterial, // Front
            backMaterial   // Back
        ];
        
        const card = new THREE.Mesh(cardGeometry, materials);
        card.castShadow = true;
        card.receiveShadow = true;
        
        cardGroup.add(card);
        
        // Position and rotation
        cardGroup.position.set(position.x, position.y, position.z);
        cardGroup.rotation.set(rotation.x, rotation.y, rotation.z);
        
        // Add interaction properties
        cardGroup.userData = {
            suit: suit,
            value: value,
            isCard: true,
            originalPosition: { ...position },
            originalRotation: { ...rotation },
            isAnimating: false
        };
        
        this.scene.add(cardGroup);
        this.cards.push(cardGroup);
        
        return cardGroup;
    }
    
    /**
     * Animate card to new position with physics
     */
    animateCard(card, targetPosition, targetRotation, duration = 1000) {
        if (!card || card.userData.isAnimating) return;
        
        card.userData.isAnimating = true;
        const startTime = Date.now();
        const startPosition = { ...card.position };
        const startRotation = { ...card.rotation };
        
        const animate = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Easing function for natural motion
            const easeProgress = this.easeOutCubic(progress);
            
            // Interpolate position
            card.position.x = startPosition.x + (targetPosition.x - startPosition.x) * easeProgress;
            card.position.y = startPosition.y + (targetPosition.y - startPosition.y) * easeProgress;
            card.position.z = startPosition.z + (targetPosition.z - startPosition.z) * easeProgress;
            
            // Interpolate rotation
            card.rotation.x = startRotation.x + (targetRotation.x - startRotation.x) * easeProgress;
            card.rotation.y = startRotation.y + (targetRotation.y - startRotation.y) * easeProgress;
            card.rotation.z = startRotation.z + (targetRotation.z - startRotation.z) * easeProgress;
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            } else {
                card.userData.isAnimating = false;
            }
        };
        
        animate();
    }
    
    /**
     * Easing function for natural animation
     */
    easeOutCubic(t) {
        return 1 - Math.pow(1 - t, 3);
    }
    
    /**
     * Deal cards animation
     */
    dealCards(gameState) {
        // Clear existing cards
        this.clearCards();
        
        if (!gameState || !gameState.players || !gameState.table_cards) return;
        
        let delay = 0;
        const dealDelay = 150; // Milliseconds between each card
        
        // Deal table cards
        gameState.table_cards.forEach((card, index) => {
            setTimeout(() => {
                const position = {
                    x: (index - gameState.table_cards.length / 2) * 2,
                    y: 0.1,
                    z: 0
                };
                this.createCard(card.suit, card.value, position);
            }, delay);
            delay += dealDelay;
        });
        
        // Deal player hands
        Object.entries(gameState.players).forEach(([playerId, player], playerIndex) => {
            if (player.hand) {
                player.hand.forEach((card, cardIndex) => {
                    setTimeout(() => {
                        const angle = (cardIndex - player.hand.length / 2) * 0.3;
                        const distance = 6;
                        const position = {
                            x: Math.sin(angle) * distance,
                            y: 0.1,
                            z: Math.cos(angle) * distance * (playerIndex === 0 ? 1 : -1)
                        };
                        const rotation = {
                            x: 0,
                            y: angle,
                            z: 0
                        };
                        this.createCard(card.suit, card.value, position, rotation);
                    }, delay);
                    delay += dealDelay;
                });
            }
        });
    }
    
    /**
     * Clear all cards from scene
     */
    clearCards() {
        this.cards.forEach(card => {
            this.scene.remove(card);
        });
        this.cards = [];
    }
    
    /**
     * Setup event listeners for interaction
     */
    setupEventListeners() {
        // Handle window resize
        window.addEventListener('resize', () => {
            const width = this.container.clientWidth;
            const height = this.container.clientHeight;
            
            this.camera.aspect = width / height;
            this.camera.updateProjectionMatrix();
            this.renderer.setSize(width, height);
        });
        
        // Mouse interaction
        const mouse = new THREE.Vector2();
        const raycaster = new THREE.Raycaster();
        
        this.renderer.domElement.addEventListener('mousemove', (event) => {
            const rect = this.renderer.domElement.getBoundingClientRect();
            mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
            mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
            
            raycaster.setFromCamera(mouse, this.camera);
            const intersects = raycaster.intersectObjects(this.scene.children, true);
            
            // Reset all cards
            this.cards.forEach(card => {
                if (!card.userData.isAnimating) {
                    card.position.y = card.userData.originalPosition.y;
                    card.rotation.x = card.userData.originalRotation.x;
                }
            });
            
            // Highlight hovered card
            if (intersects.length > 0) {
                const hoveredObject = intersects[0].object.parent;
                if (hoveredObject.userData.isCard && !hoveredObject.userData.isAnimating) {
                    hoveredObject.position.y = hoveredObject.userData.originalPosition.y + 0.2;
                    hoveredObject.rotation.x = hoveredObject.userData.originalRotation.x - 0.1;
                }
            }
        });
    }
    
    /**
     * Start the render loop with performance optimization
     */
    startRenderLoop() {
        let lastFrameTime = performance.now();
        let fpsAccumulator = 0;
        let framesSinceLastFPSUpdate = 0;
        
        const animate = (currentTime) => {
            if (this.renderingPaused) {
                this.animationFrameId = requestAnimationFrame(animate);
                return;
            }
            
            const deltaTime = currentTime - lastFrameTime;
            
            // Frame rate limiting for mobile devices
            if (this.isMobile && deltaTime < this.frameTimeThreshold) {
                this.animationFrameId = requestAnimationFrame(animate);
                return;
            }
            
            lastFrameTime = currentTime;
            
            // Update performance metrics
            this.performanceMonitor.updateRendererMetrics(this.renderer);
            fpsAccumulator += deltaTime;
            framesSinceLastFPSUpdate++;
            
            // Update FPS every 500ms
            if (fpsAccumulator >= 500) {
                const fps = Math.round((framesSinceLastFPSUpdate * 1000) / fpsAccumulator);
                this.currentFPS = fps;
                this.updateFPSDisplay(fps);
                
                // Update LOD system with current FPS
                if (this.mobileLODSystem) {
                    this.mobileLODSystem.updateLOD(fps);
                }
                
                fpsAccumulator = 0;
                framesSinceLastFPSUpdate = 0;
            }
            
            // Subtle camera movement for life (reduced on low-end devices)
            if (!this.isLowEndDevice) {
                const time = currentTime * 0.0005;
                this.camera.position.x = Math.sin(time) * 0.5;
                this.camera.position.z = 12 + Math.cos(time) * 0.3;
                this.camera.lookAt(0, 0, 0);
            }
            
            // Update particle effects
            if (this.particleEffects) {
                this.particleEffects.update();
            }
            
            // Render the scene
            const renderStart = performance.now();
            this.renderer.render(this.scene, this.camera);
            const renderTime = performance.now() - renderStart;
            
            // Track render performance
            if (renderTime > this.frameTimeThreshold * 1.5) {
                this.performanceMonitor.triggerPerformanceAlert('slow_render', {
                    renderTime: renderTime,
                    threshold: this.frameTimeThreshold
                });
            }
            
            this.animationFrameId = requestAnimationFrame(animate);
        };
        
        this.animationFrameId = requestAnimationFrame(animate);
    }
    
    /**
     * Update FPS display in UI
     */
    updateFPSDisplay(fps) {
        // Update FPS counter in UI if available
        const fpsCounter = document.getElementById('fpsCounter');
        if (fpsCounter) {
            fpsCounter.textContent = `FPS: ${fps}`;
            
            // Color code based on performance
            if (fps >= 50) {
                fpsCounter.className = 'fps-counter fps-good';
            } else if (fps >= 30) {
                fpsCounter.className = 'fps-counter fps-ok';
            } else {
                fpsCounter.className = 'fps-counter fps-poor';
            }
        }
        
        // Update render stats
        const renderStats = document.getElementById('renderStats');
        if (renderStats && this.renderer.info) {
            const triangles = this.renderer.info.render.triangles;
            const calls = this.renderer.info.render.calls;
            renderStats.textContent = `Triangles: ${triangles} | Calls: ${calls}`;
        }
    }
    
    /**
     * Stop the render loop and cleanup
     */
    destroy() {
        if (this.animationFrameId) {
            cancelAnimationFrame(this.animationFrameId);
        }
        
        // Cleanup Three.js resources
        this.scene.traverse((object) => {
            if (object.geometry) object.geometry.dispose();
            if (object.material) {
                if (Array.isArray(object.material)) {
                    object.material.forEach(material => material.dispose());
                } else {
                    object.material.dispose();
                }
            }
        });
        
        this.renderer.dispose();
        this.container.removeChild(this.renderer.domElement);
    }
    
    /**
     * Update game state and re-render cards
     */
    updateGameState(gameState) {
        this.dealCards(gameState);
    }
    
    /**
     * Get renderer performance stats
     */
    getStats() {
        const rendererStats = {
            triangles: this.renderer.info.render.triangles,
            calls: this.renderer.info.render.calls,
            points: this.renderer.info.render.points,
            lines: this.renderer.info.render.lines
        };
        
        if (this.particleEffects) {
            const particleStats = this.particleEffects.getStats();
            return { ...rendererStats, particles: particleStats };
        }
        
        return rendererStats;
    }
    
    /**
     * Trigger Romanian Septica specific game effects
     */
    triggerSevenBeatsEffect(position) {
        if (this.particleEffects) {
            return this.particleEffects.triggerSevenBeats(position);
        }
    }
    
    triggerCardCaptureEffect(position, cardCount = 1) {
        if (this.particleEffects) {
            return this.particleEffects.triggerCardCapture(position, cardCount);
        }
    }
    
    triggerTrickWinEffect(position) {
        if (this.particleEffects) {
            return this.particleEffects.triggerTrickWin(position);
        }
    }
    
    triggerGameWinEffect(position) {
        if (this.particleEffects) {
            return this.particleEffects.triggerGameWin(position);
        }
    }
    
    triggerInvalidMoveEffect(position) {
        if (this.particleEffects) {
            return this.particleEffects.triggerInvalidMove(position);
        }
    }
    
    /**
     * Handle game move result with appropriate effects
     */
    handleMoveResult(moveResult, cardPosition) {
        if (!moveResult || !this.particleEffects) return;
        
        switch (moveResult.result) {
            case 'seven_beats':
                this.triggerSevenBeatsEffect(cardPosition);
                break;
            case 'cards_captured':
                const capturedCount = moveResult.captured_cards?.length || 1;
                this.triggerCardCaptureEffect(cardPosition, capturedCount);
                break;
            case 'trick_won':
                this.triggerTrickWinEffect(cardPosition);
                break;
            case 'game_won':
                this.triggerGameWinEffect(cardPosition);
                break;
            case 'invalid_move':
                this.triggerInvalidMoveEffect(cardPosition);
                break;
            default:
                // Standard card play - small sparkle effect
                this.particleEffects.triggerCardSelect(cardPosition);
        }
    }
}

// Export for use in other modules
window.Card3DRenderer = Card3DRenderer;
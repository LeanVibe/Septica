/**
 * Premium Septica Game Integration
 * Combines all premium components with existing Three.js infrastructure
 * Implements ShuffleCats-quality gaming experience for Android and Desktop
 */

class PremiumSepticaGame {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.isInitialized = false;
        this.qualityLevel = 'high';
        this.romanianRegion = 'moldovan';
        
        // Core systems
        this.renderer = null;
        this.scene = null;
        this.camera = null;
        this.premiumMaterials = null;
        this.romanianLighting = null;
        this.premiumAnimations = null;
        this.performanceManager = null;
        
        // Game state
        this.gameState = null;
        this.playerHand = [];
        this.tableCards = [];
        this.validMoves = [];
        
        // WebSocket integration
        this.wsClient = null;
        this.isMultiplayer = false;
        
        // Performance monitoring
        this.frameCount = 0;
        this.lastFrameTime = 0;
        this.averageFPS = 60;
        
        console.log('🎮 Premium Septica Game initializing...');
        this.initialize();
    }
    
    /**
     * Initialize all premium systems
     */
    async initialize() {
        try {
            // Check WebGL support
            if (!this.checkWebGLSupport()) {
                throw new Error('WebGL not supported');
            }
            
            // Initialize core Three.js infrastructure
            await this.initializeThreeJS();
            
            // Initialize premium systems
            await this.initializePremiumSystems();
            
            // Setup user interface
            this.setupPremiumUI();
            
            // Initialize performance monitoring
            this.initializePerformanceMonitoring();
            
            // Setup responsive design
            this.setupResponsiveDesign();
            
            // Connect to existing WebSocket if available
            this.connectToMultiplayer();
            
            // Start render loop
            this.startRenderLoop();
            
            this.isInitialized = true;
            console.log('🎮 Premium Septica Game initialized successfully');
            
            // Trigger Romanian welcome animation
            this.playWelcomeAnimation();
            
        } catch (error) {
            console.error('🎮 Failed to initialize Premium Septica Game:', error);
            this.showFallbackInterface();
        }
    }
    
    /**
     * Check WebGL support and capabilities
     */
    checkWebGLSupport() {
        try {
            const canvas = document.createElement('canvas');
            const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
            
            if (!gl) {
                console.warn('🎮 WebGL not available, will use fallback');
                return false;
            }
            
            // Check for required extensions
            const requiredExtensions = [
                'EXT_texture_filter_anisotropic',
                'WEBGL_depth_texture'
            ];
            
            const supportedExtensions = requiredExtensions.filter(ext => 
                gl.getExtension(ext)
            );
            
            console.log(`🎮 WebGL supported with ${supportedExtensions.length}/${requiredExtensions.length} extensions`);
            return true;
            
        } catch (error) {
            console.warn('🎮 WebGL check failed:', error);
            return false;
        }
    }
    
    /**
     * Initialize Three.js rendering infrastructure
     */
    async initializeThreeJS() {
        // Create scene
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x1a1a1a);
        
        // Create camera with optimal settings for card game
        this.camera = new THREE.PerspectiveCamera(
            45,                                    // FOV
            this.container.clientWidth / this.container.clientHeight, // Aspect ratio
            0.1,                                   // Near plane
            1000                                   // Far plane
        );
        
        // Position camera for optimal card viewing
        this.camera.position.set(0, 15, 10);
        this.camera.lookAt(0, 0, 0);
        
        // Create renderer with premium settings
        this.renderer = new THREE.WebGLRenderer({
            antialias: true,
            alpha: true,
            powerPreference: "high-performance",
            stencil: false
        });
        
        // Configure renderer for premium quality
        this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        this.renderer.physicallyCorrectLights = true;
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.2;
        this.renderer.outputEncoding = THREE.sRGBEncoding;
        
        // Add to container
        this.container.appendChild(this.renderer.domElement);
        
        // Add orbit controls for testing (can be removed in production)
        if (typeof THREE.OrbitControls !== 'undefined') {
            this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
            this.controls.enableDamping = true;
            this.controls.dampingFactor = 0.05;
        }
        
        console.log('🎨 Three.js rendering infrastructure initialized');
    }
    
    /**
     * Initialize all premium systems
     */
    async initializePremiumSystems() {
        // Initialize material system
        this.premiumMaterials = new PremiumCardMaterial();
        
        // Initialize lighting system
        this.romanianLighting = new RomanianAmbientLighting(this.scene, this.renderer);
        this.romanianLighting.setTimeOfDay('evening');
        this.romanianLighting.setRegion(this.romanianRegion);
        
        // Initialize animation system
        this.premiumAnimations = new PremiumCardAnimations();
        
        // Initialize performance manager (extends existing MobileLODSystem if available)
        if (typeof MobileLODSystem !== 'undefined') {
            this.performanceManager = new MobileLODSystem(this.renderer, null);
        } else {
            this.performanceManager = new BasicPerformanceManager();
        }
        
        // Create premium game table
        this.createPremiumGameTable();
        
        console.log('🎨 Premium systems initialized');
    }
    
    /**
     * Create premium Romanian game table
     */
    createPremiumGameTable() {
        // Table geometry - realistic proportions
        const tableGeometry = new THREE.CylinderGeometry(8, 8, 0.2, 32);
        const tableMaterial = this.premiumMaterials.createTableMaterial(this.romanianRegion);
        
        this.gameTable = new THREE.Mesh(tableGeometry, tableMaterial);
        this.gameTable.position.set(0, -1, 0);
        this.gameTable.receiveShadow = true;
        
        this.scene.add(this.gameTable);
        
        // Add table felt texture and Romanian border patterns
        this.addTableDecorations();
        
        console.log('🎨 Premium game table created');
    }
    
    /**
     * Add Romanian cultural decorations to table
     */
    addTableDecorations() {
        // Traditional Romanian border decoration
        const borderGeometry = new THREE.RingGeometry(7.8, 8.0, 32);
        const borderMaterial = new THREE.MeshPhysicalMaterial({
            color: 0xffd700,  // Romanian gold
            metalness: 0.7,
            roughness: 0.2,
            opacity: 0.8,
            transparent: true
        });
        
        const border = new THREE.Mesh(borderGeometry, borderMaterial);
        border.position.set(0, -0.9, 0);
        border.rotation.x = -Math.PI / 2;
        
        this.scene.add(border);
        
        // Add center Romanian emblem area
        const centerGeometry = new THREE.CircleGeometry(1.5, 16);
        const centerMaterial = new THREE.MeshPhysicalMaterial({
            color: 0x002b7f,  // Romanian blue
            opacity: 0.1,
            transparent: true
        });
        
        const centerEmblem = new THREE.Mesh(centerGeometry, centerMaterial);
        centerEmblem.position.set(0, -0.85, 0);
        centerEmblem.rotation.x = -Math.PI / 2;
        
        this.scene.add(centerEmblem);
    }
    
    /**
     * Setup premium user interface
     */
    setupPremiumUI() {
        // Apply premium CSS to container
        this.container.classList.add('septica-premium-container');
        
        // Create UI overlay
        this.createUIOverlay();
        
        // Setup game controls
        this.setupGameControls();
        
        // Setup Romanian cultural elements
        this.setupCulturalElements();
        
        console.log('🎨 Premium UI setup complete');
    }
    
    /**
     * Create UI overlay for game information
     */
    createUIOverlay() {
        this.uiOverlay = document.createElement('div');
        this.uiOverlay.className = 'septica-ui-overlay';
        this.uiOverlay.innerHTML = `
            <div class="game-header romanian-glass-panel">
                <div class="player-info">
                    <span class="player-name">Player 1</span>
                    <span class="player-score">0</span>
                </div>
                <div class="game-info">
                    <span class="trick-number">Trick 1</span>
                    <span class="move-number">Move 1</span>
                </div>
                <div class="opponent-info">
                    <span class="opponent-name">Player 2</span>
                    <span class="opponent-score">0</span>
                </div>
            </div>
            
            <div class="game-status romanian-glass-panel">
                <span class="turn-indicator">Your turn</span>
                <div class="romanian-progress-indicator">
                    <div class="romanian-progress-bar" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="cultural-overlay">
                <div class="romanian-patterns ${this.romanianRegion}"></div>
            </div>
            
            <div class="performance-indicator">
                <span class="fps-counter">60 FPS</span>
                <span class="quality-level">${this.qualityLevel.toUpperCase()}</span>
            </div>
        `;
        
        this.container.appendChild(this.uiOverlay);
    }
    
    /**
     * Setup game controls and interaction
     */
    setupGameControls() {
        // Card interaction handling
        this.setupCardInteraction();
        
        // Touch and mouse event handling
        this.setupInputHandling();
        
        // Keyboard shortcuts
        this.setupKeyboardShortcuts();
    }
    
    /**
     * Setup basic input handling system
     */
    setupInputHandling() {
        // Initialize input state
        this.inputState = {
            isMouseDown: false,
            isDragging: false,
            lastMousePosition: { x: 0, y: 0 }
        };
        
        // Prevent context menu on right click
        this.renderer.domElement.addEventListener('contextmenu', (event) => {
            event.preventDefault();
        });
        
        // Handle window resize
        window.addEventListener('resize', () => {
            this.handleResize();
        });
        
        console.log('🎮 Basic input handling initialized');
    }
    
    /**
     * Setup keyboard shortcuts for Romanian cultural experience
     */
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (event) => {
            switch(event.key.toLowerCase()) {
                case 'q':
                    // Toggle quality between ultra/high/medium/low
                    this.cycleLODQuality();
                    break;
                case 'r':
                    // Change Romanian region (moldovan/transylvanian/carpathian)
                    this.cycleRegion();
                    break;
                case 'd':
                    // Deal cards
                    this.handleDealCards();
                    break;
                case 'p':
                    // Play card
                    this.handlePlayCard();
                    break;
                case 'c':
                    // Show performance stats
                    this.togglePerformanceStats();
                    break;
                case 'escape':
                    // Exit fullscreen or close menus
                    this.handleEscape();
                    break;
            }
        });
        
        console.log('⌨️ Romanian cultural keyboard shortcuts initialized');
    }
    
    /**
     * Handle window resize
     */
    handleResize() {
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(window.innerWidth, window.innerHeight);
    }
    
    /**
     * Setup card interaction system
     */
    setupCardInteraction() {
        this.raycaster = new THREE.Raycaster();
        this.mouse = new THREE.Vector2();
        this.hoveredCard = null;
        this.selectedCard = null;
        
        // Mouse/touch move for hover effects
        this.renderer.domElement.addEventListener('mousemove', (event) => {
            this.updateMousePosition(event);
            this.handleCardHover();
        });
        
        // Click/tap for card selection
        this.renderer.domElement.addEventListener('click', (event) => {
            this.updateMousePosition(event);
            this.handleCardClick();
        });
        
        // Touch events for mobile
        this.renderer.domElement.addEventListener('touchstart', (event) => {
            this.updateTouchPosition(event);
            this.handleCardClick();
        });
    }
    
    /**
     * Update mouse position for raycasting
     */
    updateMousePosition(event) {
        const rect = this.renderer.domElement.getBoundingClientRect();
        this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
        this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
    }
    
    /**
     * Update touch position for mobile interaction
     */
    updateTouchPosition(event) {
        if (event.touches.length > 0) {
            const rect = this.renderer.domElement.getBoundingClientRect();
            const touch = event.touches[0];
            this.mouse.x = ((touch.clientX - rect.left) / rect.width) * 2 - 1;
            this.mouse.y = -((touch.clientY - rect.top) / rect.height) * 2 + 1;
        }
    }
    
    /**
     * Handle card hover effects
     */
    handleCardHover() {
        this.raycaster.setFromCamera(this.mouse, this.camera);
        const intersects = this.raycaster.intersectObjects(this.scene.children, true);
        
        // Reset previous hover
        if (this.hoveredCard && this.hoveredCard !== this.selectedCard) {
            this.premiumAnimations.animateCardHover(this.hoveredCard, false);
            this.hoveredCard = null;
        }
        
        // Check for new hover
        if (intersects.length > 0) {
            const card = this.getCardFromIntersect(intersects[0]);
            if (card && card !== this.hoveredCard && card !== this.selectedCard) {
                this.hoveredCard = card;
                this.premiumAnimations.animateCardHover(card, true);
            }
        }
    }
    
    /**
     * Handle card click/selection
     */
    handleCardClick() {
        this.raycaster.setFromCamera(this.mouse, this.camera);
        const intersects = this.raycaster.intersectObjects(this.scene.children, true);
        
        if (intersects.length > 0) {
            const card = this.getCardFromIntersect(intersects[0]);
            if (card && this.isValidMove(card)) {
                this.selectCard(card);
            }
        }
    }
    
    /**
     * Get card object from intersection
     */
    getCardFromIntersect(intersect) {
        let object = intersect.object;
        while (object && !object.userData.isCard) {
            object = object.parent;
        }
        return object;
    }
    
    /**
     * Check if card is a valid move
     */
    isValidMove(card) {
        if (!card.userData.cardData) return false;
        return this.validMoves.some(validCard => 
            validCard.suit === card.userData.cardData.suit &&
            validCard.value === card.userData.cardData.value
        );
    }
    
    /**
     * Select and play a card
     */
    async selectCard(card) {
        if (this.selectedCard) {
            this.premiumAnimations.animateCardHover(this.selectedCard, false);
        }
        
        this.selectedCard = card;
        
        // Animate card selection
        this.premiumAnimations.animateCardHover(card, true);
        
        // Calculate target position (center of table)
        const targetPosition = { x: 0, y: 0, z: 0 };
        
        // Determine card type for animation
        const cardType = this.getCardType(card.userData.cardData);
        
        // Play card animation
        await this.premiumAnimations.playCardAnimation(card, targetPosition, cardType);
        
        // Send move to backend if multiplayer
        if (this.isMultiplayer && this.wsClient) {
            this.sendCardPlay(card.userData.cardData);
        }
        
        // Update local game state
        this.updateGameState(card.userData.cardData);
    }
    
    /**
     * Get card type for animation purposes
     */
    getCardType(cardData) {
        if (cardData.value === 7) return 'seven';
        if (cardData.value === 14) return 'ace';
        if (cardData.value === 10) return 'ten';
        if (cardData.value === 8) return 'eight';
        return 'normal';
    }
    
    /**
     * Setup Romanian cultural UI elements
     */
    setupCulturalElements() {
        // Add Romanian region selector
        const regionSelector = document.createElement('select');
        regionSelector.className = 'romanian-region-selector';
        regionSelector.innerHTML = `
            <option value="moldovan">Moldova</option>
            <option value="transylvanian">Transilvania</option>
            <option value="wallachian">Wallachia</option>
            <option value="traditional">Traditional</option>
        `;
        regionSelector.value = this.romanianRegion;
        
        regionSelector.addEventListener('change', (event) => {
            this.setRomanianRegion(event.target.value);
        });
        
        this.uiOverlay.appendChild(regionSelector);
        
        // Add time of day selector
        const timeSelector = document.createElement('select');
        timeSelector.className = 'time-of-day-selector';
        timeSelector.innerHTML = `
            <option value="morning">Morning</option>
            <option value="afternoon">Afternoon</option>
            <option value="evening">Evening</option>
            <option value="night">Night</option>
        `;
        timeSelector.value = 'evening';
        
        timeSelector.addEventListener('change', (event) => {
            this.romanianLighting.setTimeOfDay(event.target.value);
        });
        
        this.uiOverlay.appendChild(timeSelector);
    }
    
    /**
     * Connect to multiplayer WebSocket
     */
    connectToMultiplayer() {
        if (typeof SepticaWebSocketClient !== 'undefined') {
            this.wsClient = new SepticaWebSocketClient();
            
            // Setup message handlers
            this.wsClient.onGameState = (gameState) => {
                this.handleGameStateUpdate(gameState);
            };
            
            this.wsClient.onMoveResult = (result) => {
                this.handleMoveResult(result);
            };
            
            // Try to connect to local development server
            const serverUrl = 'ws://localhost:8080/ws/connect';
            this.wsClient.connect(serverUrl)
                .then(() => {
                    this.isMultiplayer = true;
                    console.log('🌐 Connected to multiplayer backend');
                })
                .catch(error => {
                    console.log('🌐 Multiplayer not available, using single-player mode');
                });
        }
    }
    
    /**
     * Handle game state updates from server
     */
    handleGameStateUpdate(gameState) {
        this.gameState = gameState;
        this.playerHand = gameState.your_cards || [];
        this.tableCards = gameState.table_cards || [];
        this.validMoves = gameState.valid_moves || [];
        
        // Update UI
        this.updateGameUI();
        
        // Update 3D scene
        this.update3DGameState();
    }
    
    /**
     * Update 3D scene based on game state
     */
    update3DGameState() {
        // Clear existing cards
        this.clearTableCards();
        
        // Add table cards
        this.tableCards.forEach((cardData, index) => {
            this.addCard3D(cardData, 'table', index);
        });
        
        // Update player hand
        this.updatePlayerHand3D();
    }
    
    /**
     * Send card play to server
     */
    sendCardPlay(cardData) {
        if (this.wsClient && this.wsClient.isConnected) {
            this.wsClient.sendMessage({
                type: 'play_card',
                payload: {
                    suit: cardData.suit,
                    value: cardData.value,
                    id: cardData.id
                }
            });
        }
    }
    
    /**
     * Initialize performance monitoring
     */
    initializePerformanceMonitoring() {
        this.performanceStats = {
            fps: 60,
            frameTime: 16.67,
            memoryUsage: 0,
            drawCalls: 0
        };
        
        // Update performance display every second
        setInterval(() => {
            this.updatePerformanceDisplay();
            this.optimizePerformance();
        }, 1000);
    }
    
    /**
     * Update performance display
     */
    updatePerformanceDisplay() {
        const fpsElement = this.uiOverlay.querySelector('.fps-counter');
        if (fpsElement) {
            fpsElement.textContent = `${Math.round(this.averageFPS)} FPS`;
        }
        
        // Update quality indicator color based on performance
        const qualityElement = this.uiOverlay.querySelector('.quality-level');
        if (qualityElement) {
            if (this.averageFPS > 55) {
                qualityElement.style.color = '#10b981'; // Green
            } else if (this.averageFPS > 45) {
                qualityElement.style.color = '#f59e0b'; // Yellow
            } else {
                qualityElement.style.color = '#ef4444'; // Red
            }
        }
    }
    
    /**
     * Optimize performance based on FPS
     */
    optimizePerformance() {
        if (this.averageFPS < 45) {
            this.reduceQuality();
        } else if (this.averageFPS > 58 && this.qualityLevel !== 'ultra') {
            this.increaseQuality();
        }
    }
    
    /**
     * Reduce quality for better performance
     */
    reduceQuality() {
        const levels = ['ultra', 'high', 'medium', 'low'];
        const currentIndex = levels.indexOf(this.qualityLevel);
        
        if (currentIndex < levels.length - 1) {
            this.qualityLevel = levels[currentIndex + 1];
            this.updateQualitySettings();
            console.log(`🎮 Quality reduced to ${this.qualityLevel}`);
        }
    }
    
    /**
     * Increase quality for better visuals
     */
    increaseQuality() {
        const levels = ['low', 'medium', 'high', 'ultra'];
        const currentIndex = levels.indexOf(this.qualityLevel);
        
        if (currentIndex < levels.length - 1) {
            this.qualityLevel = levels[currentIndex + 1];
            this.updateQualitySettings();
            console.log(`🎮 Quality increased to ${this.qualityLevel}`);
        }
    }
    
    /**
     * Update quality settings across all systems
     */
    updateQualitySettings() {
        // Update materials
        if (this.premiumMaterials) {
            this.premiumMaterials.updateLOD(this.qualityLevel);
        }
        
        // Update lighting
        if (this.romanianLighting) {
            this.romanianLighting.updateLOD(this.qualityLevel);
        }
        
        // Update animations
        if (this.premiumAnimations) {
            this.premiumAnimations.updateLOD(this.qualityLevel);
        }
        
        // Update renderer settings
        this.updateRendererQuality();
        
        // Update UI
        const qualityElement = this.uiOverlay.querySelector('.quality-level');
        if (qualityElement) {
            qualityElement.textContent = this.qualityLevel.toUpperCase();
        }
    }
    
    /**
     * Update renderer quality settings
     */
    updateRendererQuality() {
        switch (this.qualityLevel) {
            case 'ultra':
                this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
                this.renderer.shadowMap.enabled = true;
                break;
                
            case 'high':
                this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
                this.renderer.shadowMap.enabled = true;
                break;
                
            case 'medium':
                this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.25));
                this.renderer.shadowMap.enabled = false;
                break;
                
            case 'low':
                this.renderer.setPixelRatio(1);
                this.renderer.shadowMap.enabled = false;
                break;
        }
    }
    
    /**
     * Setup responsive design
     */
    setupResponsiveDesign() {
        // Handle window resize
        window.addEventListener('resize', () => {
            this.handleResize();
        });
        
        // Handle device orientation change
        window.addEventListener('orientationchange', () => {
            setTimeout(() => this.handleResize(), 100);
        });
    }
    
    /**
     * Handle window resize
     */
    handleResize() {
        if (!this.renderer || !this.camera) return;
        
        const width = this.container.clientWidth;
        const height = this.container.clientHeight;
        
        // Update camera
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
        
        // Update renderer
        this.renderer.setSize(width, height);
        
        console.log(`🎮 Resized to ${width}x${height}`);
    }
    
    /**
     * Start main render loop
     */
    startRenderLoop() {
        const animate = (currentTime) => {
            requestAnimationFrame(animate);
            
            // Calculate FPS
            if (this.lastFrameTime) {
                const deltaTime = currentTime - this.lastFrameTime;
                const fps = 1000 / deltaTime;
                this.averageFPS = this.averageFPS * 0.9 + fps * 0.1;
            }
            this.lastFrameTime = currentTime;
            
            // Update controls
            if (this.controls) {
                this.controls.update();
            }
            
            // Render scene
            this.renderer.render(this.scene, this.camera);
            
            this.frameCount++;
        };
        
        animate(0);
        console.log('🎮 Render loop started');
    }
    
    /**
     * Play Romanian welcome animation
     */
    async playWelcomeAnimation() {
        // Show welcome message with Romanian greeting
        const welcomeElement = document.createElement('div');
        welcomeElement.className = 'romanian-welcome-message';
        welcomeElement.innerHTML = `
            <h2>Bun venit la Septica!</h2>
            <p>Welcome to authentic Romanian Septica</p>
        `;
        
        this.container.appendChild(welcomeElement);
        
        // Animate welcome message
        if (typeof gsap !== 'undefined') {
            gsap.fromTo(welcomeElement, 
                { opacity: 0, scale: 0.8, y: 50 },
                { 
                    opacity: 1, 
                    scale: 1, 
                    y: 0, 
                    duration: 1, 
                    ease: "back.out(1.7)",
                    delay: 0.5
                }
            );
            
            // Remove after 3 seconds
            gsap.to(welcomeElement, {
                opacity: 0,
                scale: 0.8,
                y: -50,
                duration: 0.8,
                delay: 3,
                ease: "power2.in",
                onComplete: () => {
                    welcomeElement.remove();
                }
            });
        } else {
            // Fallback animation
            setTimeout(() => {
                welcomeElement.style.opacity = '1';
                welcomeElement.style.transform = 'scale(1) translateY(0)';
            }, 500);
            
            setTimeout(() => {
                welcomeElement.remove();
            }, 4000);
        }
    }
    
    /**
     * Show fallback interface if WebGL fails
     */
    showFallbackInterface() {
        this.container.innerHTML = `
            <div class="fallback-interface">
                <h2>Romanian Septica - Compatibility Mode</h2>
                <p>Your device doesn't support advanced 3D graphics, but you can still enjoy the game!</p>
                <button onclick="location.reload()" class="romanian-glass-button">Try Again</button>
            </div>
        `;
    }
    
    /**
     * Set Romanian region and update visuals
     */
    setRomanianRegion(region) {
        this.romanianRegion = region;
        
        if (this.romanianLighting) {
            this.romanianLighting.setRegion(region);
        }
        
        if (this.premiumMaterials && this.gameTable) {
            // Update table material
            const newMaterial = this.premiumMaterials.createTableMaterial(region);
            this.gameTable.material = newMaterial;
        }
        
        // Update UI cultural elements
        const culturalOverlay = this.uiOverlay.querySelector('.cultural-overlay');
        if (culturalOverlay) {
            culturalOverlay.className = `cultural-overlay ${region}`;
        }
        
        console.log(`🏛️ Romanian region changed to: ${region}`);
    }
    
    /**
     * Get current performance statistics
     */
    getPerformanceStats() {
        return {
            fps: this.averageFPS,
            qualityLevel: this.qualityLevel,
            frameCount: this.frameCount,
            initialized: this.isInitialized,
            multiplayer: this.isMultiplayer,
            romanianRegion: this.romanianRegion
        };
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        // Cancel animation frame
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
        
        // Dispose of Three.js resources
        if (this.renderer) {
            this.renderer.dispose();
        }
        
        // Dispose of premium systems
        if (this.premiumMaterials) {
            this.premiumMaterials.dispose();
        }
        
        if (this.romanianLighting) {
            this.romanianLighting.dispose();
        }
        
        if (this.premiumAnimations) {
            this.premiumAnimations.dispose();
        }
        
        // Disconnect WebSocket
        if (this.wsClient) {
            this.wsClient.disconnect();
        }
        
        console.log('🎮 Premium Septica Game disposed');
    }
}

/**
 * Basic Performance Manager (fallback if MobileLODSystem not available)
 */
class BasicPerformanceManager {
    constructor() {
        this.metrics = { averageFPS: 60 };
    }
    
    updateLOD(qualityLevel) {
        console.log(`📊 Performance level: ${qualityLevel}`);
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PremiumSepticaGame;
} else if (typeof window !== 'undefined') {
    window.PremiumSepticaGame = PremiumSepticaGame;
}
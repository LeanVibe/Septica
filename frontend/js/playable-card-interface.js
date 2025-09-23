/**
 * Playable Card Interface for Romanian Septica
 * ShuffleCats-style card game interface with proper hand, opponent, and table layout
 */

class PlayableCardInterface {
    constructor(gameInstance) {
        this.game = gameInstance;
        this.scene = gameInstance.scene;
        this.camera = gameInstance.camera;
        this.renderer = gameInstance.renderer;
        
        // Game state
        this.playerHand = [];
        this.opponentHand = [];
        this.tableCards = [];
        this.currentPlayer = 1; // 1 = player, 2 = opponent
        this.gameState = null;
        
        // Card dimensions and layout
        this.cardWidth = 0.8;
        this.cardHeight = 1.2;
        this.cardSpacing = 0.15;
        this.handRadius = 3.5;
        
        // UI elements
        this.cardMeshes = new Map();
        this.interactiveCards = [];
        this.hoveredCard = null;
        this.selectedCard = null;
        
        // Materials
        this.cardMaterial = null;
        this.cardBackMaterial = null;
        this.glowMaterial = null;
        
        this.initialize();
    }
    
    initialize() {
        this.createMaterials();
        this.setupInputHandling();
        this.createInitialLayout();
        
        console.log('🎮 Playable Card Interface initialized');
    }
    
    createMaterials() {
        // Card front material with Romanian patterns
        this.cardMaterial = new THREE.MeshPhysicalMaterial({
            color: 0xffffff,
            roughness: 0.1,
            metalness: 0.0,
            clearcoat: 0.3,
            clearcoatRoughness: 0.1
        });
        
        // Card back material with Romanian cultural design
        this.cardBackMaterial = new THREE.MeshPhysicalMaterial({
            color: 0x1e3a8a, // Romanian blue
            roughness: 0.2,
            metalness: 0.1,
            clearcoat: 0.4,
            clearcoatRoughness: 0.15
        });
        
        // Glow material for card selection/hover
        this.glowMaterial = new THREE.MeshBasicMaterial({
            color: 0xffd700, // Romanian yellow/gold
            transparent: true,
            opacity: 0.3
        });
    }
    
    createCard(suit, value, position, isPlayerCard = true, isRevealed = true) {
        const cardGeometry = new THREE.BoxGeometry(this.cardWidth, this.cardHeight, 0.02);
        const material = isRevealed ? this.cardMaterial : this.cardBackMaterial;
        const cardMesh = new THREE.Mesh(cardGeometry, material);
        
        // Position the card
        cardMesh.position.copy(position);
        
        // Add card data
        cardMesh.userData = {
            suit,
            value,
            isPlayerCard,
            isRevealed,
            canPlay: false
        };
        
        // Create card text/symbols (simplified for now)
        if (isRevealed) {
            this.addCardSymbols(cardMesh, suit, value);
        }
        
        this.scene.add(cardMesh);
        return cardMesh;
    }
    
    addCardSymbols(cardMesh, suit, value) {
        // Create a simple text representation
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = 128;
        canvas.height = 192;
        
        // Clear canvas
        context.fillStyle = '#ffffff';
        context.fillRect(0, 0, canvas.width, canvas.height);
        
        // Draw value
        context.fillStyle = (suit === 'hearts' || suit === 'diamonds') ? '#dc2626' : '#000000';
        context.font = 'bold 24px Arial';
        context.textAlign = 'center';
        context.fillText(this.getCardValueText(value), canvas.width / 2, 40);
        
        // Draw suit symbol
        context.font = '32px Arial';
        context.fillText(this.getSuitSymbol(suit), canvas.width / 2, canvas.height - 40);
        
        // Create texture and apply to card
        const texture = new THREE.CanvasTexture(canvas);
        cardMesh.material = cardMesh.material.clone();
        cardMesh.material.map = texture;
        cardMesh.material.needsUpdate = true;
    }
    
    getCardValueText(value) {
        const valueMap = {
            7: '7', 8: '8', 9: '9', 10: '10',
            11: 'J', 12: 'Q', 13: 'K', 14: 'A'
        };
        return valueMap[value] || value.toString();
    }
    
    getSuitSymbol(suit) {
        const symbols = {
            'hearts': '♥',
            'diamonds': '♦',
            'clubs': '♣',
            'spades': '♠'
        };
        return symbols[suit] || '?';
    }
    
    createInitialLayout() {
        // Clear existing cards
        this.clearAllCards();
        
        // Create sample hands for testing
        this.createSampleHands();
    }
    
    createSampleHands() {
        // Player hand (bottom, fan layout like ShuffleCats)
        const playerCards = [
            { suit: 'hearts', value: 7 },
            { suit: 'diamonds', value: 8 },
            { suit: 'clubs', value: 9 },
            { suit: 'spades', value: 10 },
            { suit: 'hearts', value: 11 }
        ];
        
        this.createPlayerHand(playerCards);
        
        // Opponent hand (top, face down)
        const opponentCardCount = 5;
        this.createOpponentHand(opponentCardCount);
        
        // Table cards (center, stacked)
        const tableCards = [
            { suit: 'diamonds', value: 9 },
            { suit: 'clubs', value: 7 }
        ];
        this.createTableCards(tableCards);
    }
    
    createPlayerHand(cards) {
        this.playerHand = [];
        const totalCards = cards.length;
        const startAngle = -Math.PI / 6; // Start angle for fan
        const angleStep = Math.PI / 3 / (totalCards - 1); // Distribute across 60 degrees
        
        cards.forEach((cardData, index) => {
            const angle = startAngle + (angleStep * index);
            const x = Math.sin(angle) * this.handRadius;
            const y = -2.5; // Bottom of screen
            const z = Math.cos(angle) * this.handRadius - 3;
            
            const position = new THREE.Vector3(x, y, z);
            const cardMesh = this.createCard(cardData.suit, cardData.value, position, true, true);
            
            // Rotate card to face player
            cardMesh.rotation.x = Math.PI / 8; // Slight tilt up
            cardMesh.rotation.y = -angle; // Fan rotation
            
            // Make interactive
            cardMesh.userData.canPlay = true;
            this.interactiveCards.push(cardMesh);
            this.playerHand.push(cardMesh);
            this.cardMeshes.set(`player_${index}`, cardMesh);
        });
    }
    
    createOpponentHand(cardCount) {
        this.opponentHand = [];
        const spacing = 0.3;
        const startX = -(cardCount - 1) * spacing / 2;
        
        for (let i = 0; i < cardCount; i++) {
            const x = startX + (i * spacing);
            const position = new THREE.Vector3(x, 2.5, -1); // Top of screen
            const cardMesh = this.createCard(null, null, position, false, false);
            
            // Rotate card to face down toward player
            cardMesh.rotation.x = -Math.PI / 8; // Slight tilt down
            
            this.opponentHand.push(cardMesh);
            this.cardMeshes.set(`opponent_${i}`, cardMesh);
        }
    }
    
    createTableCards(cards) {
        this.tableCards = [];
        const stackOffset = 0.1; // Slight offset for stacking
        
        cards.forEach((cardData, index) => {
            const x = index * stackOffset;
            const y = 0; // Center table
            const z = index * 0.01; // Slight z-offset for stacking
            
            const position = new THREE.Vector3(x, y, z);
            const cardMesh = this.createCard(cardData.suit, cardData.value, position, false, true);
            
            // Lay flat on table
            cardMesh.rotation.x = 0;
            
            this.tableCards.push(cardMesh);
            this.cardMeshes.set(`table_${index}`, cardMesh);
        });
    }
    
    setupInputHandling() {
        // Mouse interaction for card selection
        this.raycaster = new THREE.Raycaster();
        this.mouse = new THREE.Vector2();
        
        // Add event listeners
        this.renderer.domElement.addEventListener('mousemove', this.onMouseMove.bind(this));
        this.renderer.domElement.addEventListener('click', this.onClick.bind(this));
    }
    
    onMouseMove(event) {
        const rect = this.renderer.domElement.getBoundingClientRect();
        this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
        this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
        
        this.updateCardHover();
    }
    
    onClick(event) {
        this.updateCardHover();
        
        if (this.hoveredCard && this.hoveredCard.userData.canPlay) {
            this.selectCard(this.hoveredCard);
        }
    }
    
    updateCardHover() {
        this.raycaster.setFromCamera(this.mouse, this.camera);
        const intersects = this.raycaster.intersectObjects(this.interactiveCards);
        
        // Clear previous hover
        if (this.hoveredCard && this.hoveredCard !== this.selectedCard) {
            this.clearCardHighlight(this.hoveredCard);
        }
        
        if (intersects.length > 0) {
            const card = intersects[0].object;
            if (card.userData.canPlay) {
                this.hoveredCard = card;
                this.highlightCard(card, 0x90ee90); // Light green hover
            }
        } else {
            this.hoveredCard = null;
        }
    }
    
    selectCard(card) {
        // Check if it's the player's turn
        if (this.currentPlayer !== 1) {
            console.log('⚠️ Not your turn - cannot select card');
            return;
        }

        // Check if card is valid according to Romanian Septica rules
        if (!this.isValidRomanianSepticaMove(card)) {
            console.log('⚠️ Invalid Romanian Septica move');
            return;
        }

        // Clear previous selection
        if (this.selectedCard) {
            this.clearCardHighlight(this.selectedCard);
        }

        this.selectedCard = card;
        this.highlightCard(card, 0xffd700); // Gold selection

        // Animate card up slightly
        card.position.y += 0.2;

        console.log(`🃏 Selected Romanian Septica card: ${this.getCardValueText(card.userData.value)} of ${card.userData.suit}`);

        // Enable play button or auto-play after selection
        this.playSelectedCard();
    }
    
    playSelectedCard() {
        if (!this.selectedCard) return;

        const card = this.selectedCard;
        console.log(`🎮 Playing Romanian Septica card: ${this.getCardValueText(card.userData.value)} of ${card.userData.suit}`);

        // Send move to server first (before UI updates)
        if (this.game.wsClient && this.game.wsClient.isConnected) {
            this.game.wsClient.playCard(card.userData.suit, card.userData.value, card.userData.id);
        } else if (window.gameUI && window.gameUI.wsClient && window.gameUI.wsClient.isConnected) {
            window.gameUI.wsClient.playCard(card.userData.suit, card.userData.value, card.userData.id);
        }

        // Animate card to table
        this.animateCardToTable(card);

        // Disable card interaction until server response
        this.disableCardInteraction();

        // Clear selection
        this.clearCardHighlight(card);
        this.selectedCard = null;

        // Note: Don't update game state locally - wait for server response
        console.log('📤 Romanian Septica move sent to server, waiting for response...');
    }
    
    animateCardToTable(card) {
        // Calculate target position on table
        const targetX = this.tableCards.length * 0.1;
        const targetY = 0;
        const targetZ = this.tableCards.length * 0.01;
        
        // Animate using simple interpolation
        const startPos = card.position.clone();
        const targetPos = new THREE.Vector3(targetX, targetY, targetZ);
        const duration = 500; // ms
        const startTime = Date.now();
        
        const animate = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Ease out animation
            const easeProgress = 1 - Math.pow(1 - progress, 3);
            
            card.position.lerpVectors(startPos, targetPos, easeProgress);
            card.rotation.x = THREE.MathUtils.lerp(card.rotation.x, 0, easeProgress);
            card.rotation.y = THREE.MathUtils.lerp(card.rotation.y, 0, easeProgress);
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        };
        
        animate();
    }
    
    highlightCard(card, color) {
        if (!card.glowMesh) {
            const glowGeometry = new THREE.BoxGeometry(
                this.cardWidth * 1.1, 
                this.cardHeight * 1.1, 
                0.01
            );
            const glowMaterial = this.glowMaterial.clone();
            glowMaterial.color.setHex(color);
            
            card.glowMesh = new THREE.Mesh(glowGeometry, glowMaterial);
            card.glowMesh.position.z = -0.02; // Behind the card
            card.add(card.glowMesh);
        } else {
            card.glowMesh.material.color.setHex(color);
            card.glowMesh.visible = true;
        }
    }
    
    clearCardHighlight(card) {
        if (card.glowMesh) {
            card.glowMesh.visible = false;
        }
    }
    
    updateTurnIndicator() {
        // Update UI to show whose turn it is
        const turnElement = document.getElementById('turn-indicator');
        if (turnElement) {
            turnElement.textContent = this.currentPlayer === 1 ? 'Your turn' : 'Opponent\'s turn';
        }
    }
    
    clearAllCards() {
        // Remove all existing cards from scene
        this.cardMeshes.forEach(card => {
            this.scene.remove(card);
            if (card.geometry) card.geometry.dispose();
            if (card.material) card.material.dispose();
        });
        
        this.cardMeshes.clear();
        this.playerHand = [];
        this.opponentHand = [];
        this.tableCards = [];
        this.interactiveCards = [];
    }
    
    // WebSocket integration methods
    onGameStateUpdate(gameState) {
        this.gameState = gameState;
        this.updateFromGameState(gameState);
    }
    
    updateFromGameState(gameState) {
        if (!gameState) return;

        console.log('🎮 Updating Romanian Septica cards from game state:', gameState);

        // Handle backend format normalization
        const playerHand = gameState.your_cards || gameState.playerHand || [];
        const tableCards = gameState.table_cards || gameState.tableCards || [];
        const yourTurn = gameState.your_turn !== undefined ? gameState.your_turn : gameState.yourTurn;
        const validMoves = gameState.valid_moves || gameState.validMoves || [];

        // Update valid moves for Romanian Septica rules
        this.validMoves = validMoves;

        // Update player hand
        if (playerHand.length > 0) {
            this.clearAllCards();
            this.createPlayerHand(playerHand);
        }

        // Update table cards
        if (tableCards.length > 0) {
            this.createTableCards(tableCards);
        }

        // Update turn with Romanian Septica context
        this.currentPlayer = yourTurn ? 1 : 2;
        this.updateTurnIndicator();

        // Update opponent hand count
        const opponentHandSize = gameState.opponent_hand_size || gameState.opponentHandSize || 5;
        this.createOpponentHand(opponentHandSize);

        // Update card interactivity based on Romanian Septica rules
        this.updateCardInteractivity();

        // Re-enable card interaction after server response
        this.enableCardInteraction();
    }
    
    dispose() {
        // Clean up resources
        this.clearAllCards();

        if (this.cardMaterial) this.cardMaterial.dispose();
        if (this.cardBackMaterial) this.cardBackMaterial.dispose();
        if (this.glowMaterial) this.glowMaterial.dispose();

        // Remove event listeners
        this.renderer.domElement.removeEventListener('mousemove', this.onMouseMove.bind(this));
        this.renderer.domElement.removeEventListener('click', this.onClick.bind(this));
    }

    // ===== ROMANIAN SEPTICA SPECIFIC METHODS =====

    /**
     * Check if a card is a valid Romanian Septica move
     */
    isValidRomanianSepticaMove(card) {
        if (!card.userData.cardData) return false;

        // Check against valid moves from server
        return this.validMoves.some(validCard =>
            validCard.suit === card.userData.cardData.suit &&
            validCard.value === card.userData.cardData.value
        );
    }

    /**
     * Update card interactivity based on Romanian Septica rules
     */
    updateCardInteractivity() {
        this.scene.traverse((child) => {
            if (child.userData && child.userData.isCard && child.userData.cardType === 'player') {
                const canPlay = this.currentPlayer === 1 && this.isValidRomanianSepticaMove(child);
                child.userData.canPlay = canPlay;

                // Update visual indicators
                if (canPlay) {
                    child.material.emissive.setHex(0x002200); // Slight green glow
                } else {
                    child.material.emissive.setHex(0x000000); // No glow
                }
            }
        });
    }

    /**
     * Disable card interaction during move processing
     */
    disableCardInteraction() {
        this.interactiveCards.forEach(card => {
            card.userData.canPlay = false;
            if (card.material) {
                card.material.opacity = 0.5;
                card.material.transparent = true;
            }
        });
    }

    /**
     * Enable card interaction
     */
    enableCardInteraction() {
        this.updateCardInteractivity();

        this.interactiveCards.forEach(card => {
            if (card.material) {
                card.material.opacity = 1.0;
                card.material.transparent = false;
            }
        });
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PlayableCardInterface;
}
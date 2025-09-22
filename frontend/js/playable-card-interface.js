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
        // Clear previous selection
        if (this.selectedCard) {
            this.clearCardHighlight(this.selectedCard);
        }
        
        this.selectedCard = card;
        this.highlightCard(card, 0xffd700); // Gold selection
        
        // Animate card up slightly
        card.position.y += 0.2;
        
        console.log(`🃏 Selected card: ${this.getCardValueText(card.userData.value)} of ${card.userData.suit}`);
        
        // Enable play button or auto-play after selection
        this.playSelectedCard();
    }
    
    playSelectedCard() {
        if (!this.selectedCard) return;
        
        const card = this.selectedCard;
        console.log(`🎮 Playing card: ${this.getCardValueText(card.userData.value)} of ${card.userData.suit}`);
        
        // Animate card to table
        this.animateCardToTable(card);
        
        // Remove from player hand
        const index = this.playerHand.indexOf(card);
        if (index > -1) {
            this.playerHand.splice(index, 1);
        }
        
        // Add to table
        this.tableCards.push(card);
        
        // Clear selection
        this.clearCardHighlight(card);
        this.selectedCard = null;
        
        // Switch to opponent turn
        this.currentPlayer = 2;
        this.updateTurnIndicator();
        
        // Send move to server if connected
        if (this.game.client && this.game.client.isConnected) {
            this.game.client.playCard(card.userData.suit, card.userData.value);
        }
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
        
        console.log('🎮 Updating from game state:', gameState);
        
        // Update player hand
        if (gameState.playerHand) {
            this.clearAllCards();
            this.createPlayerHand(gameState.playerHand);
        }
        
        // Update table cards
        if (gameState.tableCards) {
            this.createTableCards(gameState.tableCards);
        }
        
        // Update turn
        if (gameState.currentPlayer !== undefined) {
            this.currentPlayer = gameState.currentPlayer;
            this.updateTurnIndicator();
        }
        
        // Update opponent hand count
        if (gameState.opponentHandSize !== undefined) {
            this.createOpponentHand(gameState.opponentHandSize);
        }
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
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PlayableCardInterface;
}
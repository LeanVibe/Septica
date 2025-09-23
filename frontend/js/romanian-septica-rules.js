/**
 * Romanian Septica Rules Engine
 * Implements complete Romanian Septica game rules for frontend validation
 * Ensures cultural authenticity and proper game flow
 */

class RomanianSepticaRules {
    constructor() {
        // Romanian Septica card hierarchy (7s are highest)
        this.cardHierarchy = {
            7: 15,   // 7s beat everything (including other 7s by suit priority)
            14: 14,  // Ace
            10: 13,  // 10
            13: 12,  // King
            12: 11,  // Queen
            11: 10,  // Jack
            9: 9,    // 9
            8: 8     // 8 (weakest, conditional beating)
        };

        // Suit priority for 7s: spades > hearts > diamonds > clubs
        this.suitPriority = {
            'spades': 4,
            'hearts': 3,
            'diamonds': 2,
            'clubs': 1
        };

        // Point values (only 10s and Aces count for points)
        this.pointValues = {
            10: 1,   // 10 = 1 point
            14: 1    // Ace = 1 point
        };

        console.log('🎯 Romanian Septica Rules Engine initialized');
    }

    /**
     * Validate if a card can be played according to Romanian Septica rules
     */
    validateMove(card, tableCards, playerCards, gameState) {
        if (!card || !playerCards) {
            return { valid: false, reason: 'Invalid card or player cards' };
        }

        // Check if player has the card
        const hasCard = playerCards.some(playerCard =>
            playerCard.suit === card.suit && playerCard.value === card.value
        );

        if (!hasCard) {
            return { valid: false, reason: 'Player does not have this card' };
        }

        // If no cards on table, any card can be played
        if (!tableCards || tableCards.length === 0) {
            return { valid: true, reason: 'First card of trick' };
        }

        // Get the top card on the table (last played)
        const topCard = tableCards[tableCards.length - 1];

        // Apply Romanian Septica beating rules
        return this.canCardBeatTopCard(card, topCard, tableCards);
    }

    /**
     * Check if a card can beat the top card according to Romanian Septica rules
     */
    canCardBeatTopCard(card, topCard, tableCards) {
        // Rule 1: 7s beat everything
        if (card.value === 7) {
            if (topCard.value === 7) {
                // 7 vs 7 - higher suit priority wins
                const cardSuitPriority = this.suitPriority[card.suit] || 0;
                const topCardSuitPriority = this.suitPriority[topCard.suit] || 0;

                if (cardSuitPriority > topCardSuitPriority) {
                    return { valid: true, reason: 'Seven beats seven (higher suit)' };
                } else {
                    return { valid: false, reason: 'Seven cannot beat higher seven' };
                }
            }
            return { valid: true, reason: 'Seven beats all other cards' };
        }

        // Rule 2: If top card is 7, nothing else can beat it
        if (topCard.value === 7) {
            return { valid: false, reason: 'Cannot beat a seven' };
        }

        // Rule 3: Same value beats same value (Romanian Septica rule)
        if (card.value === topCard.value) {
            return { valid: true, reason: 'Same value beats same value' };
        }

        // Rule 4: 8s beat when (table_cards % 3 == 0)
        if (card.value === 8) {
            const tableCardCount = tableCards.length;
            if ((tableCardCount + 1) % 3 === 0) {
                return { valid: true, reason: 'Eight beats when table cards mod 3 equals 0' };
            } else {
                return { valid: false, reason: 'Eight can only beat at specific intervals' };
            }
        }

        // Rule 5: Higher hierarchy cards beat lower ones
        const cardHierarchy = this.cardHierarchy[card.value] || 0;
        const topCardHierarchy = this.cardHierarchy[topCard.value] || 0;

        if (cardHierarchy > topCardHierarchy) {
            return { valid: true, reason: 'Higher card beats lower card' };
        }

        return { valid: false, reason: 'Card cannot beat top card' };
    }

    /**
     * Get all valid moves for a player according to Romanian Septica rules
     */
    getValidMoves(playerCards, tableCards, gameState) {
        if (!playerCards || playerCards.length === 0) {
            return [];
        }

        const validMoves = [];

        playerCards.forEach(card => {
            const validation = this.validateMove(card, tableCards, playerCards, gameState);
            if (validation.valid) {
                validMoves.push({
                    ...card,
                    reason: validation.reason
                });
            }
        });

        return validMoves;
    }

    /**
     * Determine trick winner according to Romanian Septica rules
     */
    determineTrickWinner(playedCards, playerIds) {
        if (!playedCards || playedCards.length === 0) {
            return null;
        }

        let winningCard = playedCards[0];
        let winningPlayerIndex = 0;

        for (let i = 1; i < playedCards.length; i++) {
            const currentCard = playedCards[i];

            if (this.doesCardBeat(currentCard, winningCard)) {
                winningCard = currentCard;
                winningPlayerIndex = i;
            }
        }

        return {
            winnerId: playerIds[winningPlayerIndex],
            winningCard: winningCard,
            winningPlayerIndex: winningPlayerIndex
        };
    }

    /**
     * Check if card A beats card B according to Romanian Septica rules
     */
    doesCardBeat(cardA, cardB) {
        // 7s beat everything except higher 7s
        if (cardA.value === 7) {
            if (cardB.value === 7) {
                return this.suitPriority[cardA.suit] > this.suitPriority[cardB.suit];
            }
            return true;
        }

        if (cardB.value === 7) {
            return false; // Nothing beats a 7 except a higher 7
        }

        // Same values - first played wins in Romanian Septica
        if (cardA.value === cardB.value) {
            return false; // In trick determination, first played wins
        }

        // Higher hierarchy wins
        return this.cardHierarchy[cardA.value] > this.cardHierarchy[cardB.value];
    }

    /**
     * Calculate points won in a trick
     */
    calculateTrickPoints(trickCards) {
        let points = 0;

        trickCards.forEach(card => {
            if (this.pointValues[card.value]) {
                points += this.pointValues[card.value];
            }
        });

        return points;
    }

    /**
     * Check if game is complete according to Romanian Septica rules
     */
    isGameComplete(gameState) {
        if (!gameState) return false;

        // Game ends when all cards are played
        const totalCardsPlayed = (gameState.table_cards || []).length;
        const playerHandSize = (gameState.your_cards || []).length;
        const opponentHandSize = gameState.opponent_hand_size || 0;

        return playerHandSize === 0 && opponentHandSize === 0;
    }

    /**
     * Determine game winner based on points
     */
    determineGameWinner(scores) {
        if (!scores || typeof scores !== 'object') {
            return null;
        }

        let highestScore = -1;
        let winnerId = null;

        Object.entries(scores).forEach(([playerId, score]) => {
            if (score > highestScore) {
                highestScore = score;
                winnerId = playerId;
            }
        });

        return { winnerId, score: highestScore };
    }

    /**
     * Get Romanian cultural description for a card
     */
    getCardDescription(card) {
        const descriptions = {
            7: 'Septica - cea mai puternică carte!', // Seven - strongest card!
            14: 'As - carte de puncte',              // Ace - point card
            10: 'Zece - carte de puncte',            // Ten - point card
            13: 'Rege - carte nobilă',               // King - noble card
            12: 'Damă - carte nobilă',               // Queen - noble card
            11: 'Valet - carte de serviciu',         // Jack - service card
            9: 'Nouă - carte obișnuită',             // Nine - common card
            8: 'Opt - carte specială'                // Eight - special card
        };

        const suitNames = {
            'hearts': 'Inimi',
            'diamonds': 'Caro',
            'clubs': 'Trefla',
            'spades': 'Pica'
        };

        const valueDesc = descriptions[card.value] || 'Carte necunoscută';
        const suitName = suitNames[card.suit] || card.suit;

        return `${valueDesc} (${suitName})`;
    }

    /**
     * Get play suggestion for Romanian cultural experience
     */
    getPlaySuggestion(validMoves, tableCards, gameState) {
        if (!validMoves || validMoves.length === 0) {
            return 'Nu aveți mutări valide'; // No valid moves
        }

        if (validMoves.length === 1) {
            return `Jucați ${this.getCardDescription(validMoves[0])}`;
        }

        // Strategic suggestions based on Romanian Septica tactics
        const sevens = validMoves.filter(card => card.value === 7);
        if (sevens.length > 0) {
            return 'Jucați Septica pentru putere maximă!'; // Play seven for maximum power!
        }

        const pointCards = validMoves.filter(card => this.pointValues[card.value]);
        if (pointCards.length > 0 && (!tableCards || tableCards.length === 0)) {
            return 'Păstrați cărțile de puncte pentru final'; // Save point cards for later
        }

        return 'Alegeți cu înțelepciune!'; // Choose wisely!
    }

    /**
     * Validate complete game state
     */
    validateGameState(gameState) {
        const errors = [];

        if (!gameState) {
            errors.push('Game state is missing');
            return { valid: false, errors };
        }

        // Check required fields
        if (gameState.your_cards && !Array.isArray(gameState.your_cards)) {
            errors.push('Your cards must be an array');
        }

        if (gameState.table_cards && !Array.isArray(gameState.table_cards)) {
            errors.push('Table cards must be an array');
        }

        // Validate card structures
        const allCards = [
            ...(gameState.your_cards || []),
            ...(gameState.table_cards || [])
        ];

        allCards.forEach((card, index) => {
            if (!card.suit || !card.value) {
                errors.push(`Card ${index} missing suit or value`);
            }

            if (!['hearts', 'diamonds', 'clubs', 'spades'].includes(card.suit)) {
                errors.push(`Card ${index} has invalid suit: ${card.suit}`);
            }

            if (![7, 8, 9, 10, 11, 12, 13, 14].includes(card.value)) {
                errors.push(`Card ${index} has invalid value: ${card.value}`);
            }
        });

        return { valid: errors.length === 0, errors };
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = RomanianSepticaRules;
} else if (typeof window !== 'undefined') {
    window.RomanianSepticaRules = RomanianSepticaRules;
}
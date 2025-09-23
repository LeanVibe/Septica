package main

import (
	"fmt"
	"septica-backend/internal/game"
	"github.com/google/uuid"
)

func main() {
	fmt.Println("🎮 Debug Valid Moves Logic")

	// Simulate the exact scenario that caused the issue
	engine := game.NewEngine()
	player1 := uuid.New()
	player2 := uuid.New()

	// Create a game and manually set up the problematic scenario
	gameState := engine.CreateGame(player1, player2)

	// Simulate Player 1 playing clubs 9
	tableCard := game.Card{Suit: "clubs", Value: 9, ID: "test-card"}

	// Simulate Player 2's hand: hearts Queen, spades Jack, spades Queen, spades Ace
	player2Hand := []game.Card{
		{Suit: "hearts", Value: 12, ID: "card1"}, // Queen of hearts
		{Suit: "spades", Value: 11, ID: "card2"}, // Jack of spades
		{Suit: "spades", Value: 12, ID: "card3"}, // Queen of spades
		{Suit: "spades", Value: 14, ID: "card4"}, // Ace of spades
	}

	fmt.Printf("🎴 Table card: %s %d\n", tableCard.Suit, tableCard.Value)
	fmt.Printf("🃏 Player 2 hand: \n")
	for i, card := range player2Hand {
		fmt.Printf("   %d: %s %d\n", i+1, card.Suit, card.Value)
	}

	fmt.Printf("\n🔍 Testing each card against Romanian Septica rules:\n")

	// Test each card manually
	tableCards := []game.Card{tableCard}

	for i, card := range player2Hand {
		// Test the isValidMove function directly
		fmt.Printf("\n   Card %d (%s %d):\n", i+1, card.Suit, card.Value)

		// Check each rule manually
		fmt.Printf("     - Is 7? %t\n", card.Value == 7)
		fmt.Printf("     - Same value as table card? %t (table: %d, card: %d)\n",
			card.Value == tableCard.Value, tableCard.Value, card.Value)
		fmt.Printf("     - Is 8 and table count %% 3 == 0? %t (table count: %d, %d %% 3 = %d)\n",
			card.Value == 8 && len(tableCards)%3 == 0,
			len(tableCards), len(tableCards), len(tableCards)%3)

		// This would be the call to the actual function if we could access it
		// For now, let's see what GetValidMoves returns
	}

	// Create a temporary game state to test GetValidMoves
	gameState.TableCards = tableCards
	gameState.Player2Hand = player2Hand

	validMoves, err := engine.GetValidMoves(gameState.ID, player2)
	if err != nil {
		fmt.Printf("\n❌ Error getting valid moves: %v\n", err)
	} else {
		fmt.Printf("\n✅ GetValidMoves returned %d moves:\n", len(validMoves))
		for i, card := range validMoves {
			fmt.Printf("   %d: %s %d\n", i+1, card.Suit, card.Value)
		}
	}

	fmt.Printf("\n🤔 According to Romanian Septica rules:\n")
	fmt.Printf("   - Table has: clubs 9\n")
	fmt.Printf("   - Player 2 needs: any 7, any 9, or 8 when table count divisible by 3\n")
	fmt.Printf("   - Player 2 has: no 7s, no 9s, no 8s\n")
	fmt.Printf("   - Therefore Player 2 should have 0 valid moves\n")
}
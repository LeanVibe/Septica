package main

import (
	"fmt"
	"github.com/google/uuid"
	"septica-backend/internal/game"
)

func main() {
	fmt.Println("🎮 Debug Failing Test Case")

	// Run multiple games to find the failing scenario
	for i := 0; i < 50; i++ {
		fmt.Printf("\n🎲 Game %d:\n", i+1)

		engine := game.NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		gameState := engine.CreateGame(player1, player2)

		// Player 1 plays first card (any card from their hand)
		firstCard := gameState.Player1Hand[0]
		fmt.Printf("   Player 1 plays: %s %d\n", firstCard.Suit, firstCard.Value)

		result, err := engine.PlayCard(gameState.ID, player1, firstCard)
		if err != nil {
			fmt.Printf("❌ Error: %v\n", err)
			continue
		}

		if result.UpdatedState != nil {
			currentPlayer := result.UpdatedState.CurrentPlayerID
			turnSwitched := currentPlayer == player2

			fmt.Printf("   Turn switched to Player 2: %t\n", turnSwitched)
			fmt.Printf("   Current Player: %s\n", currentPlayer)

			if !turnSwitched {
				fmt.Printf("❌ FOUND THE ISSUE! Turn did not switch to Player 2\n")
				fmt.Printf("   Trick Complete: %t\n", result.TrickComplete)
				fmt.Printf("   Player 1 Hand: %+v\n", gameState.Player1Hand)
				fmt.Printf("   Player 2 Hand: %+v\n", gameState.Player2Hand)

				// Check Player 2 valid moves
				validMoves, _ := engine.GetValidMoves(result.UpdatedState.ID, player2)
				fmt.Printf("   Player 2 valid moves: %+v\n", validMoves)
				fmt.Printf("   Player 2 has %d valid moves\n", len(validMoves))

				return
			}
		}
	}

	fmt.Println("\n✅ All 50 games had correct turn switching")
}

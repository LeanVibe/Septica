package main

import (
	"fmt"
	"github.com/google/uuid"
	"septica-backend/internal/game"
)

func main() {
	fmt.Println("🎮 Debug Romanian Septica Game Engine")

	engine := game.NewEngine()
	player1 := uuid.New()
	player2 := uuid.New()

	gameState := engine.CreateGame(player1, player2)

	fmt.Printf("🎲 Initial game state:\n")
	fmt.Printf("   Current Player: %s\n", gameState.CurrentPlayerID)
	fmt.Printf("   Player 1: %s\n", player1)
	fmt.Printf("   Player 2: %s\n", player2)
	fmt.Printf("   Player 1 Hand: %+v\n", gameState.Player1Hand)
	fmt.Printf("   Player 2 Hand: %+v\n", gameState.Player2Hand)
	fmt.Printf("   Table Cards: %+v\n", gameState.TableCards)

	// Player 1 plays first card
	firstCard := gameState.Player1Hand[0]
	fmt.Printf("\n🎴 Player 1 plays: %+v\n", firstCard)

	result, err := engine.PlayCard(gameState.ID, player1, firstCard)
	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
		return
	}

	fmt.Printf("✅ Move result:\n")
	fmt.Printf("   Valid: %t\n", result.Valid)
	fmt.Printf("   Error: %s\n", result.Error)
	fmt.Printf("   Trick Complete: %t\n", result.TrickComplete)
	fmt.Printf("   Game Complete: %t\n", result.GameComplete)
	fmt.Printf("   Points Awarded: %d\n", result.PointsAwarded)

	if result.UpdatedState != nil {
		fmt.Printf("\n🎮 Updated game state:\n")
		fmt.Printf("   Current Player: %s\n", result.UpdatedState.CurrentPlayerID)
		fmt.Printf("   Turn switched to Player 2: %t\n", result.UpdatedState.CurrentPlayerID == player2)
		fmt.Printf("   Table Cards: %+v\n", result.UpdatedState.TableCards)
		fmt.Printf("   Player 1 Hand: %d cards\n", len(result.UpdatedState.Player1Hand))
		fmt.Printf("   Player 2 Hand: %d cards\n", len(result.UpdatedState.Player2Hand))

		// Check if Player 2 has valid moves
		validMoves, err := engine.GetValidMoves(result.UpdatedState.ID, player2)
		if err != nil {
			fmt.Printf("❌ Error getting valid moves: %v\n", err)
		} else {
			fmt.Printf("   Player 2 valid moves: %+v\n", validMoves)
			fmt.Printf("   Player 2 has %d valid moves\n", len(validMoves))
		}
	}
}

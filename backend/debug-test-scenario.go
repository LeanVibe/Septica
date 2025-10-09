package main

import (
	"fmt"
	"github.com/google/uuid"
	"septica-backend/internal/game"
)

// Simulate the exact test scenario to understand the expectation
func main() {
	fmt.Println("🎮 Debug Test Scenario")

	// This simulates the exact failing test
	engine := game.NewEngine()
	player1 := uuid.New()
	player2 := uuid.New()

	gameState := engine.CreateGame(player1, player2)

	fmt.Printf("🎲 Initial state:\n")
	fmt.Printf("   Player 1 starts: %t\n", gameState.CurrentPlayerID == player1)
	fmt.Printf("   Player 1 Hand: %+v\n", gameState.Player1Hand)
	fmt.Printf("   Player 2 Hand: %+v\n", gameState.Player2Hand)

	// Player 2 tries to play out of turn (this should fail)
	player2Card := gameState.Player2Hand[0]
	fmt.Printf("\n🚫 Player 2 tries to play out of turn: %s %d\n", player2Card.Suit, player2Card.Value)
	result, err := engine.PlayCard(gameState.ID, player2, player2Card)

	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
	} else {
		fmt.Printf("✅ Result: Valid=%t, Error=%s\n", result.Valid, result.Error)
	}

	// Player 1 plays correctly
	player1Card := gameState.Player1Hand[0]
	fmt.Printf("\n✅ Player 1 plays correctly: %s %d\n", player1Card.Suit, player1Card.Value)

	// Check Player 2 valid moves BEFORE Player 1 plays
	player2ValidMovesBefore, _ := engine.GetValidMoves(gameState.ID, player2)
	fmt.Printf("   Player 2 valid moves before P1 plays: %d moves\n", len(player2ValidMovesBefore))

	result, err = engine.PlayCard(gameState.ID, player1, player1Card)

	if err != nil {
		fmt.Printf("❌ Error: %v\n", err)
		return
	}

	fmt.Printf("✅ Player 1 move result:\n")
	fmt.Printf("   Valid: %t\n", result.Valid)
	fmt.Printf("   Trick Complete: %t\n", result.TrickComplete)

	if result.UpdatedState != nil {
		turnSwitched := result.UpdatedState.CurrentPlayerID == player2
		fmt.Printf("   Turn switched to Player 2: %t\n", turnSwitched)
		fmt.Printf("   Current Player: %s\n", result.UpdatedState.CurrentPlayerID)
		fmt.Printf("   Table Cards: %+v\n", result.UpdatedState.TableCards)

		// Check Player 2 valid moves AFTER Player 1 plays
		player2ValidMovesAfter, _ := engine.GetValidMoves(result.UpdatedState.ID, player2)
		fmt.Printf("   Player 2 valid moves after P1 plays: %d moves\n", len(player2ValidMovesAfter))

		// The test expects the turn to be with Player 2
		fmt.Printf("\n🎯 Test expectation: Turn should be with Player 2\n")
		fmt.Printf("🎯 Actual result: Turn is with %s\n",
			func() string {
				if result.UpdatedState.CurrentPlayerID == player1 {
					return "Player 1"
				}
				return "Player 2"
			}())

		if !turnSwitched {
			fmt.Printf("❌ TEST WOULD FAIL: Turn did not switch to Player 2\n")
		} else {
			fmt.Printf("✅ TEST WOULD PASS: Turn correctly switched to Player 2\n")
		}
	}
}

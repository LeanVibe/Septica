package main

import (
	"fmt"
	"septica-backend/internal/game"
	"github.com/google/uuid"
)

func main() {
	fmt.Println("🎮 Check Test Success Rate")

	successCount := 0
	totalGames := 1000

	for i := 0; i < totalGames; i++ {
		engine := game.NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		gameState := engine.CreateGame(player1, player2)

		// Player 1 plays first card
		player1Card := gameState.Player1Hand[0]
		result, err := engine.PlayCard(gameState.ID, player1, player1Card)

		if err != nil {
			continue
		}

		if result.UpdatedState != nil && result.UpdatedState.CurrentPlayerID == player2 {
			successCount++
		}
	}

	successRate := float64(successCount) / float64(totalGames) * 100
	fmt.Printf("✅ Success rate: %d/%d (%.1f%%)\n", successCount, totalGames, successRate)
	fmt.Printf("❌ Failure rate: %d/%d (%.1f%%)\n", totalGames-successCount, totalGames, 100-successRate)

	if successRate > 90 {
		fmt.Println("🎯 Test should pass most of the time")
	} else {
		fmt.Println("⚠️  Test will fail frequently due to random card dealing")
	}

	// Analyze why failures occur
	fmt.Println("\n🔍 Analyzing failure scenarios...")

	failuresByCard := make(map[string]int)

	for i := 0; i < 100; i++ {
		engine := game.NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		gameState := engine.CreateGame(player1, player2)

		// Player 1 plays first card
		player1Card := gameState.Player1Hand[0]
		result, err := engine.PlayCard(gameState.ID, player1, player1Card)

		if err != nil {
			continue
		}

		if result.UpdatedState != nil && result.UpdatedState.CurrentPlayerID != player2 {
			cardKey := fmt.Sprintf("%s_%d", player1Card.Suit, player1Card.Value)
			failuresByCard[cardKey]++
		}
	}

	fmt.Println("Cards that commonly cause test failures:")
	for card, count := range failuresByCard {
		if count > 0 {
			fmt.Printf("   %s: %d failures\n", card, count)
		}
	}
}
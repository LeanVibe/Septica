import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'

// Import types to verify they compile correctly
import type {
  Card,
  GameMode,
  ServerMessageUnion,
  GameStateMessage,
  ErrorMessage,
  PlayCardMessage,
} from './types'

// Import values/functions
import {
  isServerMessage,
  isClientMessage,
  createPlayCard,
  createJoinGame,
  CardValueNames,
  CardSuitSymbols,
  isWildCard,
  calculateCardPoints,
} from './types'

// Type verification - these should compile without errors
const verifyTypes = () => {
  // Card type
  const card: Card = {
    suit: 'hearts',
    value: 7,
    id: 'card-123',
  }

  // Game mode (used to type-check game config)
  const gameMode: GameMode = '2_player'

  // Server message with discriminated union
  const gameStateMsg: GameStateMessage = {
    type: 'game_state',
    id: 'msg-1',
    timestamp: new Date().toISOString(),
    playerId: 'player-1',
    gameId: 'game-1',
    payload: {
      gameId: 'game-1',
      currentPlayerId: 'player-1',
      yourTurn: true,
      yourPlayerId: 'player-1',
      yourCards: [card],
      yourCardCount: 1,
      opponentCardCounts: {},
      tableCards: [],
      validMoves: [card],
      scores: {},
      trickNumber: 1,
      moveNumber: 1,
      waitingForObjection: false,
      lastPlayedCard: null,
      lastPlayerId: null,
      canPass: false,
      objectionTimeout: 0,
      validObjections: [],
      gameMode: gameMode, // Use gameMode here
      players: [],
      sequenceNumber: 1,
      status: 'playing',
      createdAt: new Date().toISOString(),
    },
  }

  // Error message
  const errorMsg: ErrorMessage = {
    type: 'error',
    id: 'msg-2',
    timestamp: new Date().toISOString(),
    payload: {
      errorType: 'invalid_move',
      message: 'Invalid move',
    },
  }

  // Union type with type narrowing - actually use it
  const processServerMessage = (msg: ServerMessageUnion) => {
    if (msg.type === 'game_state') {
      console.log('Game state:', msg.payload.yourCards.length, 'cards in hand')
      return 'game_state'
    } else if (msg.type === 'error') {
      console.log('Error:', msg.payload.message)
      return 'error'
    } else if (msg.type === 'objection_wait') {
      console.log('Objection wait:', msg.payload.validObjections.length, 'valid objections')
      return 'objection_wait'
    }
    return 'other'
  }

  // Use the handler
  const result1 = processServerMessage(gameStateMsg)
  const result2 = processServerMessage(errorMsg)
  console.log('Message types processed:', result1, result2)

  // Client message
  const playCardMsg: PlayCardMessage = {
    type: 'play_card',
    id: 'msg-3',
    timestamp: new Date().toISOString(),
    gameId: 'game-1',
    payload: {
      suit: 'hearts',
      value: 7,
      id: 'card-123',
    },
  }

  // Message creators
  const joinGame = createJoinGame({ gameMode: '2_player' })
  const playCard = createPlayCard({ suit: 'spades', value: 14, id: 'ace-spades' })

  // Type guards - actually use them
  const serverCheck = isServerMessage(gameStateMsg)
  const clientCheck = isClientMessage(playCardMsg)
  console.log('Type guards:', { serverCheck, clientCheck })

  // Utilities
  const cardName = CardValueNames[7]
  const suitSymbol = CardSuitSymbols['hearts']
  const isWild = isWildCard(card, '2_player')
  const points = calculateCardPoints(card)

  return {
    card,
    gameStateMsg,
    errorMsg,
    joinGame,
    playCard,
    cardName,
    suitSymbol,
    isWild,
    points,
  }
}

function App() {
  const [count, setCount] = useState(0)
  const [typeCheckResult] = useState(() => verifyTypes())

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Septica v2</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>TypeScript types loaded successfully!</p>
        <p>
          Card: {CardValueNames[typeCheckResult.card.value]}
          {CardSuitSymbols[typeCheckResult.card.suit]}
          (Wild: {typeCheckResult.isWild ? 'Yes' : 'No'}, Points: {typeCheckResult.points})
        </p>
      </div>
      <p className="read-the-docs">
        Septica frontend-v2 with comprehensive TypeScript types
      </p>
    </>
  )
}

export default App

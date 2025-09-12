# Septica Backend API Documentation

## 🌐 API Overview

The Septica backend provides a comprehensive RESTful API built with Go and Gin framework. It handles user authentication, player profiles, matchmaking, game statistics, and social features.

**Base URL:** `https://api.septica.game`  
**API Version:** `v1`  
**Authentication:** Bearer JWT tokens  
**Content Type:** `application/json`

## 🔐 Authentication

### Authentication Flow
```
1. POST /api/v1/auth/register → Get user account
2. POST /api/v1/auth/login → Get JWT token  
3. Include token in Authorization header: "Bearer <token>"
4. Token expires in 24 hours, use refresh endpoint
```

### Auth Endpoints

#### Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "player123",
  "email": "player@example.com",
  "password": "securePassword123"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "player123",
    "email": "player@example.com",
    "created_at": "2024-01-15T10:30:00Z"
  },
  "message": "User registered successfully"
}
```

**Error Responses:**
```json
// 400 Bad Request - Validation errors
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Username must be 3-20 characters",
    "details": {
      "username": "too short"
    }
  }
}

// 409 Conflict - User exists
{
  "success": false,
  "error": {
    "code": "USER_EXISTS",
    "message": "Username or email already taken"
  }
}
```

#### Login User
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "player123",
  "password": "securePassword123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "dGhpc2lzYXJlZnJlc2h0b2tlbmV4YW1wbGU...",
    "expires_in": 86400,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "player123",
      "email": "player@example.com"
    }
  }
}
```

#### Refresh Token
```http
POST /api/v1/auth/refresh
Authorization: Bearer <refresh_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400
  }
}
```

#### Logout
```http
POST /api/v1/auth/logout
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

## 👤 Player Profile Endpoints

### Get Player Profile
```http
GET /api/v1/profile/{player_id}
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "player123",
    "level": 15,
    "xp": 4250,
    "rating": 1450,
    "arena": 5,
    "coins": 5000,
    "gems": 150,
    "statistics": {
      "games_played": 234,
      "games_won": 156,
      "win_rate": 0.667,
      "average_game_duration": 185,
      "best_win_streak": 8,
      "current_win_streak": 3,
      "total_points_collected": 1456,
      "mars_wins": 12
    },
    "achievements": [
      {
        "id": "first_win",
        "name": "First Victory",
        "description": "Win your first game",
        "unlocked_at": "2024-01-15T11:15:30Z"
      }
    ],
    "cosmetics": {
      "selected_card_back": "traditional_romanian",
      "selected_table_theme": "carpathian_mountains",
      "selected_avatar": "default"
    },
    "created_at": "2024-01-15T10:30:00Z",
    "last_active": "2024-01-20T14:22:15Z"
  }
}
```

### Update Player Profile
```http
PUT /api/v1/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "cosmetics": {
    "selected_card_back": "traditional_romanian",
    "selected_table_theme": "bucharest_cafe"
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "cosmetics": {
      "selected_card_back": "traditional_romanian",
      "selected_table_theme": "bucharest_cafe",
      "selected_avatar": "default"
    }
  },
  "message": "Profile updated successfully"
}
```

### Get Player Statistics
```http
GET /api/v1/stats/{player_id}
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `period` (optional): `all`, `daily`, `weekly`, `monthly`
- `season` (optional): season identifier

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "player_id": "550e8400-e29b-41d4-a716-446655440000",
    "period": "monthly",
    "statistics": {
      "games_played": 45,
      "games_won": 28,
      "win_rate": 0.622,
      "rating_change": +125,
      "average_game_duration": 178,
      "points_collected": 285,
      "cards_played": {
        "7": {"played": 89, "win_rate": 0.754},
        "8": {"played": 67, "win_rate": 0.642},
        "10": {"played": 123, "win_rate": 0.618},
        "ace": {"played": 98, "win_rate": 0.683}
      },
      "vs_ai_stats": {
        "easy": {"played": 12, "won": 11},
        "medium": {"played": 8, "won": 5},
        "hard": {"played": 3, "won": 1}
      }
    }
  }
}
```

## 🎮 Game Management Endpoints

### Start Quick Match
```http
POST /api/v1/game/quick-match
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "opponent_type": "ai", // "ai" or "human"
  "ai_difficulty": "medium" // only if opponent_type is "ai"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
    "players": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "player123",
        "rating": 1450,
        "is_ai": false
      },
      {
        "id": "ai_medium_001",
        "username": "AI Medium",
        "rating": 1400,
        "is_ai": true
      }
    ],
    "game_state": {
      "status": "starting",
      "current_player": "550e8400-e29b-41d4-a716-446655440000",
      "your_cards": [
        {"suit": "hearts", "value": 7},
        {"suit": "diamonds", "value": 10},
        {"suit": "clubs", "value": 12},
        {"suit": "spades", "value": 14}
      ],
      "table_cards": [],
      "scores": {
        "550e8400-e29b-41d4-a716-446655440000": 0,
        "ai_medium_001": 0
      },
      "deck_remaining": 24
    },
    "created_at": "2024-01-20T15:30:00Z"
  }
}
```

### Get Game State
```http
GET /api/v1/game/{game_id}
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "game_550e8400-e29b-41d4-a716-446655440000",
    "status": "in_progress",
    "players": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "player123",
        "connected": true
      },
      {
        "id": "ai_medium_001",
        "username": "AI Medium",
        "connected": true
      }
    ],
    "game_state": {
      "current_player": "550e8400-e29b-41d4-a716-446655440000",
      "your_turn": true,
      "your_cards": [
        {"suit": "hearts", "value": 7},
        {"suit": "diamonds", "value": 10}
      ],
      "table_cards": [
        {"suit": "clubs", "value": 9, "played_by": "ai_medium_001"}
      ],
      "valid_moves": [
        {"suit": "clubs", "value": 9}, // Same value
        {"suit": "hearts", "value": 7}  // 7 always beats
      ],
      "scores": {
        "550e8400-e29b-41d4-a716-446655440000": 2,
        "ai_medium_001": 1
      },
      "trick_number": 3,
      "cards_remaining": {
        "550e8400-e29b-41d4-a716-446655440000": 2,
        "ai_medium_001": 3
      }
    },
    "move_history": [
      {
        "player_id": "550e8400-e29b-41d4-a716-446655440000",
        "card": {"suit": "spades", "value": 14},
        "timestamp": "2024-01-20T15:31:15Z"
      }
    ],
    "created_at": "2024-01-20T15:30:00Z",
    "updated_at": "2024-01-20T15:31:15Z"
  }
}
```

### Forfeit Game
```http
POST /api/v1/game/{game_id}/forfeit
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
    "status": "completed",
    "winner": "ai_medium_001",
    "reason": "forfeit",
    "rating_change": -15
  },
  "message": "Game forfeited"
}
```

## 🏆 Matchmaking Endpoints

### Join Matchmaking Queue
```http
POST /api/v1/matchmaking/queue
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "game_mode": "ranked", // "ranked", "casual", "tournament"
  "max_rating_difference": 150 // optional, default 100
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "queue_id": "queue_550e8400-e29b-41d4-a716-446655440000",
    "position": 3,
    "estimated_wait_time": 45,
    "your_rating": 1450,
    "rating_range": {
      "min": 1300,
      "max": 1600
    }
  },
  "message": "Joined matchmaking queue"
}
```

### Leave Matchmaking Queue
```http
DELETE /api/v1/matchmaking/queue
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Left matchmaking queue"
}
```

### Get Queue Status
```http
GET /api/v1/matchmaking/status
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "in_queue": true,
    "queue_id": "queue_550e8400-e29b-41d4-a716-446655440000",
    "position": 1,
    "wait_time": 67,
    "players_in_queue": 12
  }
}
```

## 🏅 Leaderboard Endpoints

### Get Global Leaderboard
```http
GET /api/v1/leaderboard
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `type`: `rating`, `wins`, `win_rate` (default: `rating`)
- `period`: `all_time`, `season`, `monthly`, `weekly` (default: `season`)
- `limit`: number of entries (default: 50, max: 100)
- `offset`: pagination offset (default: 0)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "leaderboard_type": "rating",
    "period": "season",
    "season": "2024_q1",
    "total_players": 15420,
    "your_rank": 156,
    "entries": [
      {
        "rank": 1,
        "player": {
          "id": "player_001",
          "username": "SepticaMaster",
          "level": 45,
          "rating": 2150,
          "arena": 15
        },
        "stats": {
          "games_played": 847,
          "games_won": 623,
          "win_rate": 0.735
        }
      },
      {
        "rank": 2,
        "player": {
          "id": "player_002", 
          "username": "CardShark",
          "level": 42,
          "rating": 2098,
          "arena": 15
        },
        "stats": {
          "games_played": 654,
          "games_won": 467,
          "win_rate": 0.714
        }
      }
    ]
  },
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 15420,
    "has_next": true
  }
}
```

### Get Friends Leaderboard
```http
GET /api/v1/leaderboard/friends
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "your_rank": 3,
    "entries": [
      {
        "rank": 1,
        "player": {
          "id": "friend_001",
          "username": "BestFriend",
          "rating": 1650
        },
        "stats": {
          "games_played": 234,
          "games_won": 167,
          "win_rate": 0.713
        }
      }
    ]
  }
}
```

## 🏪 Shop Endpoints

### Get Shop Items
```http
GET /api/v1/shop
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `category`: `card_backs`, `table_themes`, `avatars`, `bundles`
- `show_owned`: `true`, `false` (default: `false`)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "card_backs",
        "name": "Card Backs",
        "items": [
          {
            "id": "traditional_romanian",
            "name": "Traditional Romanian",
            "description": "Classic Romanian folk art patterns",
            "type": "card_back",
            "rarity": "common",
            "price": {
              "coins": 1000,
              "gems": null
            },
            "owned": false,
            "preview_image": "https://cdn.septica.game/card_backs/traditional_romanian.jpg"
          },
          {
            "id": "premium_gold",
            "name": "Premium Gold",
            "description": "Luxurious golden card back",
            "type": "card_back", 
            "rarity": "legendary",
            "price": {
              "coins": null,
              "gems": 500
            },
            "owned": false,
            "preview_image": "https://cdn.septica.game/card_backs/premium_gold.jpg"
          }
        ]
      }
    ],
    "player_currency": {
      "coins": 5000,
      "gems": 150
    }
  }
}
```

### Purchase Item
```http
POST /api/v1/shop/purchase
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "item_id": "traditional_romanian",
  "currency": "coins" // "coins" or "gems"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "transaction_id": "tx_550e8400-e29b-41d4-a716-446655440000",
    "item": {
      "id": "traditional_romanian",
      "name": "Traditional Romanian",
      "type": "card_back"
    },
    "cost": {
      "currency": "coins",
      "amount": 1000
    },
    "remaining_currency": {
      "coins": 4000,
      "gems": 150
    }
  },
  "message": "Item purchased successfully"
}
```

## 👥 Social Features Endpoints

### Get Friends List
```http
GET /api/v1/friends
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "friends": [
      {
        "id": "friend_001",
        "username": "BestFriend",
        "status": "online",
        "level": 25,
        "rating": 1650,
        "last_active": "2024-01-20T15:45:00Z",
        "in_game": false
      }
    ],
    "friend_requests": {
      "sent": [
        {
          "id": "request_001",
          "to_username": "NewPlayer",
          "sent_at": "2024-01-20T14:30:00Z"
        }
      ],
      "received": [
        {
          "id": "request_002", 
          "from_username": "AnotherPlayer",
          "from_id": "player_456",
          "sent_at": "2024-01-20T13:15:00Z"
        }
      ]
    }
  }
}
```

### Send Friend Request
```http
POST /api/v1/friends/invite
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "username": "NewPlayer"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "request_id": "request_550e8400-e29b-41d4-a716-446655440000",
    "to_username": "NewPlayer"
  },
  "message": "Friend request sent"
}
```

### Accept Friend Request
```http
POST /api/v1/friends/accept/{request_id}
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "friend": {
      "id": "player_456",
      "username": "AnotherPlayer",
      "level": 18,
      "rating": 1380
    }
  },
  "message": "Friend request accepted"
}
```

### Challenge Friend
```http
POST /api/v1/friends/{friend_id}/challenge
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "message": "Ready for a game?" // optional
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "challenge_id": "challenge_550e8400-e29b-41d4-a716-446655440000",
    "expires_at": "2024-01-20T16:15:00Z"
  },
  "message": "Challenge sent"
}
```

## 🏟️ Tournament Endpoints

### Get Active Tournaments
```http
GET /api/v1/tournaments
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "tournaments": [
      {
        "id": "tournament_001",
        "name": "Weekend Warriors",
        "type": "single_elimination",
        "entry_fee": {
          "coins": 100,
          "gems": null
        },
        "prize_pool": {
          "1st": {"coins": 5000, "gems": 100},
          "2nd": {"coins": 2000, "gems": 50},
          "3rd": {"coins": 1000, "gems": 25}
        },
        "max_participants": 128,
        "current_participants": 67,
        "start_time": "2024-01-21T18:00:00Z",
        "registration_end": "2024-01-21T17:45:00Z",
        "status": "registration_open"
      }
    ]
  }
}
```

### Join Tournament
```http
POST /api/v1/tournaments/{tournament_id}/join
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "tournament_id": "tournament_001",
    "participant_id": "participant_550e8400-e29b-41d4-a716-446655440000",
    "bracket_position": 68,
    "entry_fee_paid": {
      "coins": 100
    }
  },
  "message": "Successfully joined tournament"
}
```

## ⚠️ Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {} // Additional error context (optional)
  },
  "timestamp": "2024-01-20T15:30:00Z",
  "request_id": "req_550e8400-e29b-41d4-a716-446655440000"
}
```

### Common Error Codes

#### Authentication Errors (401)
- `UNAUTHORIZED`: Missing or invalid token
- `TOKEN_EXPIRED`: JWT token has expired
- `INVALID_CREDENTIALS`: Wrong username/password

#### Authorization Errors (403)
- `FORBIDDEN`: User lacks permission
- `ACCOUNT_SUSPENDED`: Account temporarily suspended
- `ACCOUNT_BANNED`: Account permanently banned

#### Validation Errors (400)
- `VALIDATION_ERROR`: Request validation failed
- `INVALID_JSON`: Malformed JSON in request body
- `MISSING_PARAMETER`: Required parameter missing

#### Resource Errors (404)
- `USER_NOT_FOUND`: User doesn't exist
- `GAME_NOT_FOUND`: Game doesn't exist
- `TOURNAMENT_NOT_FOUND`: Tournament doesn't exist

#### Conflict Errors (409)
- `ALREADY_IN_QUEUE`: Player already in matchmaking
- `GAME_IN_PROGRESS`: Player already in active game
- `USERNAME_TAKEN`: Username not available

#### Server Errors (500)
- `INTERNAL_ERROR`: Unexpected server error
- `DATABASE_ERROR`: Database operation failed
- `NETWORK_ERROR`: External service unavailable

## 🔄 Rate Limiting

### Rate Limits by Endpoint Category
- **Authentication:** 10 requests/minute
- **Profile Updates:** 5 requests/minute
- **Game Actions:** 60 requests/minute
- **Shop Purchases:** 10 requests/hour
- **General API:** 120 requests/minute

### Rate Limit Headers
```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 115
X-RateLimit-Reset: 1642694400
Retry-After: 60
```

## 📊 Response Times & SLA

### Performance Targets
- **Authentication:** < 200ms
- **Profile/Stats:** < 100ms  
- **Game State:** < 50ms
- **Leaderboards:** < 300ms
- **Shop Items:** < 200ms

### Availability SLA
- **Uptime:** 99.9% (< 8.77 hours downtime/year)
- **Maintenance Windows:** Sundays 2-4 AM UTC
- **Response Time:** 95th percentile under target

This API provides complete backend functionality for the Septica mobile game, supporting authentication, gameplay, social features, monetization, and competitive systems.
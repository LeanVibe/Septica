# Romanian Septica Test Suite

## Overview

This comprehensive test suite validates the 2-player Romanian Septica card game implementation. The tests ensure correct game logic, rule enforcement, performance, and edge case handling.

## Test Files

### 1. Core Game Logic Tests

#### `GameRulesComprehensiveTests.swift`
- **Deck Creation Tests**: Validates 32-card Romanian deck
- **Card Beating Logic**: Tests all Romanian Septica rules
- **Game Flow Tests**: 2-player game progression
- **Edge Cases**: Unusual scenarios and boundary conditions
- **Move Validation**: Card play validation
- **Constants**: Game configuration validation

#### `GameStateIntegrationTests.swift`
- **Game Initialization**: Player setup and initial state
- **Card Playing Flow**: Turn management and game progression
- **Trick Completion**: Point calculation and winner determination
- **Game Completion**: End game conditions
- **Multiplayer Integration**: Online/offline game features
- **State Management**: Batch updates and performance optimization

### 2. Performance and Stress Tests

#### `GamePerformanceTests.swift`
- **Deck Operations**: Creation, shuffling, card drawing
- **Card Beating Logic**: Performance under load
- **Game State**: Initialization and updates
- **Memory Management**: Leak detection and stability
- **Algorithmic Complexity**: Scalability testing
- **Real-world Usage**: Typical gameplay patterns

#### `GameEdgeCaseTests.swift`
- **Multiple 7s**: All cutting cards interactions
- **8s with Various Table States**: Special beating conditions
- **Boundary Values**: Min/max scenarios
- **Empty/Full Hands**: Extreme hand sizes
- **Error Recovery**: Invalid state handling
- **Stress Scenarios**: Rapid state changes

### 3. Test Infrastructure

#### `TestDataFixtures.swift`
- **Card Fixtures**: Predefined common cards
- **Hand Fixtures**: Test hands for various scenarios
- **Game Scenarios**: Complete gameplay sequences
- **Validation Cases**: Move validation test data
- **Helper Functions**: Assertion utilities
- **Mock Objects**: Isolated testing support

#### `SampleFixtureUsageTests.swift`
- **Examples**: How to use test fixtures
- **Best Practices**: Testing patterns
- **Documentation**: Usage examples

## Romanian Septica Rules Tested

### 1. Deck Composition
- ✅ 32 cards total (7-A in each suit)
- ✅ 8 point cards (4 tens + 4 aces)
- ✅ 4 suits with 8 cards each
- ✅ No cards below 7

### 2. Card Beating Rules
- ✅ **7s always beat** (cutting cards)
- ✅ **8s beat when table count % 3 == 0**
- ✅ **Same value cards beat each other**
- ✅ **Regular cards cannot beat different values**

### 3. 2-Player Game Rules
- ✅ **Exactly 2 players required**
- ✅ **4 cards dealt to each player initially**
- ✅ **Turn-based gameplay**
- ✅ **Hand replenishment until deck empty**

### 4. Scoring System
- ✅ **Only 10s and Aces count as points**
- ✅ **Each point card = 1 point**
- ✅ **Winner determined by highest score**
- ✅ **Game ends when all cards played**

## Test Coverage

### Functional Coverage
- ✅ All game rules implemented correctly
- ✅ All card combinations tested
- ✅ All edge cases covered
- ✅ Error conditions handled properly

### Performance Coverage
- ✅ Operations complete within acceptable time
- ✅ Memory usage remains stable
- ✅ No memory leaks detected
- ✅ Concurrent access safe

### Integration Coverage
- ✅ GameState + GameRules integration
- ✅ Player management
- ✅ Multiplayer features
- ✅ State persistence

## Running the Tests

### All Tests
```bash
xcodebuild test -project Septica.xcodeproj -scheme Septica
```

### Specific Test Classes
```bash
# Core logic tests
xcodebuild test -project Septica.xcodeproj -scheme Septica -only-testing:SepticaTests/GameRulesComprehensiveTests

# Integration tests  
xcodebuild test -project Septica.xcodeproj -scheme Septica -only-testing:SepticaTests/GameStateIntegrationTests

# Performance tests
xcodebuild test -project Septica.xcodeproj -scheme Septica -only-testing:SepticaTests/GamePerformanceTests

# Edge case tests
xcodebuild test -project Septica.xcodeproj -scheme Septica -only-testing:SepticaTests/GameEdgeCaseTests
```

### Individual Tests
```bash
# Specific test method
xcodebuild test -project Septica.xcodeproj -scheme Septica -only-testing:SepticaTests/GameRulesComprehensiveTests/testSevenAlwaysBeats
```

## Test Data and Fixtures

### Using Predefined Test Data
```swift
// Use common cards
let seven = TestDataFixtures.commonCards.sevenHearts
let pointCards = TestDataFixtures.commonCards.allPointCards

// Use test hands
let strongHand = TestDataFixtures.testHands.mixedStrong
let weakHand = TestDataFixtures.testHands.regularCards

// Use game scenarios
let scenario = TestDataFixtures.gameScenarios.SevenBeatsAll()
```

### Helper Functions
```swift
// Assert card beating
assertCanBeat(attackingCard, targetCard, tableCardsCount: 3, expected: true)

// Assert valid moves count
assertValidMovesCount(hand: playerHand, against: topCard, tableCardsCount: 1, expectedCount: 2)

// Assert trick winner
assertTrickWinner(tableCards: trick, expectedWinnerIndex: 1)
```

## Performance Benchmarks

### Target Performance
- **Deck Creation**: < 1ms
- **Card Beating Check**: < 0.1ms per check
- **Valid Moves Calculation**: < 1ms for full hand
- **Game State Update**: < 5ms
- **Memory Usage**: < 50MB total

### Stress Test Limits
- **1000 games**: Should complete without issues
- **10000 card beating checks**: < 100ms total
- **Concurrent operations**: Thread-safe
- **Large hands (32 cards)**: Performance degradation < 10%

## Debugging Failed Tests

### Common Issues
1. **Metal Toolchain Missing**: Install from Xcode Settings > Components
2. **Simulator Unavailable**: Use available simulator from xcodebuild output
3. **Timeout**: Increase test timeout for performance tests
4. **Memory Issues**: Check for retain cycles in game objects

### Debug Tips
1. Use `print()` statements in test methods for debugging
2. Set breakpoints in GameRules methods
3. Check test output for specific assertion failures
4. Use Instruments for performance analysis

## Adding New Tests

### Best Practices
1. Use TestDataFixtures for consistent test data
2. Follow naming convention: `test[Feature][Scenario]()`
3. Include both positive and negative test cases
4. Add performance tests for new algorithms
5. Document complex test scenarios

### Test Structure
```swift
func testNewFeature() {
    // Arrange: Set up test data
    let testData = TestDataFixtures.commonCards.sevenHearts
    
    // Act: Perform the operation
    let result = GameRules.someNewMethod(testData)
    
    // Assert: Verify the result
    XCTAssertEqual(result, expectedValue, "Description of what should happen")
}
```

## Test Quality Metrics

### Code Coverage
- Target: 90%+ line coverage
- Critical paths: 100% coverage
- Edge cases: Comprehensive coverage

### Test Reliability
- Flaky test rate: < 1%
- All tests deterministic
- No external dependencies
- Fast execution (< 60 seconds total)

### Maintainability
- Self-documenting test names
- Minimal code duplication
- Reusable test fixtures
- Clear assertion messages
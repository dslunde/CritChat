# Gamification System Integration Guide

## Overview

The CritChat gamification system provides a comprehensive XP (Experience Points) and leveling system that rewards users for engaging with the app. The system is built using clean architecture principles and can be easily integrated into any feature.

## Architecture

### Domain Layer
- `XpEntity`: Core business entity with level calculations and progress tracking
- `XpRewardType`: Enum defining all possible XP rewards (2-50 XP per action)
- `XpTransactionEntity`: Represents individual XP transactions
- `GamificationRepository`: Interface defining all gamification operations

### Data Layer
- `XpModel`: Firestore model with automatic level calculation
- `GamificationFirestoreDataSource`: Firebase integration with batch operations
- `GamificationRepositoryImpl`: Repository implementation

### Presentation Layer
- `GamificationBloc`: Complete state management with real-time updates
- `XpProgressWidget`: Beautiful UI component for displaying user progress
- `LevelUpDialog`: Celebratory dialog when users level up

### Core Service
- `GamificationService`: Main interface for other features to use

## XP System Design

### Level Calculation
The system uses an exponential formula for level requirements:
- **Formula**: `xp_required = (level - 1)² × 100`
- **Level 1**: 0 XP (starting level)
- **Level 2**: 100 XP
- **Level 3**: 400 XP
- **Level 4**: 900 XP
- **Level 5**: 1,600 XP
- **Level 10**: 8,100 XP
- **Level 20**: 36,100 XP

### Level Titles
- **Levels 1-4**: Novice
- **Levels 5-9**: Apprentice
- **Levels 10-19**: Adventurer
- **Levels 20-34**: Veteran
- **Levels 35-49**: Expert
- **Levels 50-74**: Master
- **Levels 75-99**: Grandmaster
- **Level 100+**: Legend

### XP Rewards

#### Authentication & Profile (One-time)
- **Sign Up**: 10 XP
- **Complete Profile**: 25 XP

#### Social Actions
- **Send Message**: 2 XP
- **Receive Friend Request**: 5 XP
- **Accept Friend Request**: 10 XP

#### Fellowship Actions
- **Create Fellowship**: 50 XP
- **Join Fellowship**: 25 XP
- **Invite Friend**: 15 XP

#### Poll Actions
- **Create Poll**: 20 XP
- **Vote on Poll**: 5 XP
- **Add Custom Option**: 10 XP

#### Content Creation
- **Create Post**: 15 XP
- **Create Story**: 10 XP
- **Create Session Recap**: 30 XP

#### Engagement
- **Like Post**: 1 XP
- **Comment on Post**: 3 XP
- **Share Content**: 5 XP

#### Special Achievements (One-time)
- **First Message**: 25 XP
- **First Fellowship**: 50 XP
- **First Poll**: 25 XP
- **Weekly Active**: 20 XP
- **Monthly Active**: 50 XP

## Integration Examples

### 1. Basic XP Award

```dart
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/core/di/injection_container.dart';

// Award XP for any action
final gamificationService = sl<GamificationService>();
final updatedXp = await gamificationService.awardXp(
  XpRewardType.sendMessage,
  metadata: {'chatId': chatId},
);

// Check if user leveled up
if (updatedXp != null) {
  print('User now has ${updatedXp.totalXp} XP and is level ${updatedXp.currentLevel}');
}
```

### 2. Convenience Methods

```dart
// Use specific convenience methods
await gamificationService.awardMessageSent(chatId: chatId);
await gamificationService.awardFellowshipCreated(fellowshipId);
await gamificationService.awardPollCreated(pollId, fellowshipId);
await gamificationService.awardFriendAdded(friendId);
```

### 3. Batch XP Awards

```dart
// Award multiple XP types at once
await gamificationService.batchAwardXp([
  XpRewardType.createPost,
  XpRewardType.firstPost, // One-time reward
]);
```

### 4. Real-time XP Display

```dart
// Get real-time XP stream
final xpStream = gamificationService.getCurrentUserXpStream();
if (xpStream != null) {
  StreamBuilder<XpEntity>(
    stream: xpStream,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return XpProgressWidget(
          xpEntity: snapshot.data!,
          compact: true, // Use compact version for app bars
        );
      }
      return const CircularProgressIndicator();
    },
  );
}
```

### 5. Level Up Detection with BLoC

```dart
BlocListener<GamificationBloc, GamificationState>(
  listener: (context, state) {
    if (state is XpAwarded && state.leveledUp) {
      // Show level up dialog
      LevelUpDialog.show(
        context,
        xpEntity: state.xpEntity,
        previousLevel: state.xpEntity.currentLevel - 1,
        xpGained: state.rewardType.xpAmount,
      );
    }
  },
  child: YourWidget(),
)
```

## UI Components

### XP Progress Widget

```dart
// Full version for profile pages
XpProgressWidget(
  xpEntity: xpEntity,
  showLabel: true,
  compact: false,
)

// Compact version for app bars
XpProgressWidget(
  xpEntity: xpEntity,
  showLabel: false,
  compact: true,
)
```

### Level Up Dialog

```dart
// Automatically shown by BLoC listener, or manually:
LevelUpDialog.show(
  context,
  xpEntity: newXpEntity,
  previousLevel: oldLevel,
  xpGained: xpAmount,
);
```

## Database Structure

### Firestore Collections

#### `user_xp` Collection
```json
{
  "userId": "auto-document-id",
  "totalXp": 250,
  "lastUpdated": "2024-01-15T10:30:00Z"
}
```

#### `xp_transactions` Collection
```json
{
  "userId": "user123",
  "rewardType": "sendMessage",
  "xpAwarded": 2,
  "description": "Message Sent",
  "timestamp": "2024-01-15T10:30:00Z",
  "metadata": {
    "chatId": "fellowship_abc123"
  }
}
```

## Integration Checklist

### For New Features

1. **Identify XP Opportunities**: Determine what actions should award XP
2. **Add XP Rewards**: Use `GamificationService` to award XP
3. **Import Dependencies**: Add gamification imports where needed
4. **Handle Level Ups**: Add BLoC listener for level up celebrations
5. **Display Progress**: Add XP widgets where appropriate

### For Existing Features

1. **Import Service**: Add `GamificationService` import
2. **Get Service Instance**: Use `sl<GamificationService>()`
3. **Award XP**: Call appropriate method after successful actions
4. **Error Handling**: Service methods return null on error (safe to ignore)

## Best Practices

### 1. Error Handling
```dart
// The service handles errors gracefully
final result = await gamificationService.awardXp(XpRewardType.sendMessage);
// result will be null if error occurs, safe to continue
```

### 2. One-time Rewards
```dart
// The service automatically prevents duplicate one-time rewards
await gamificationService.awardSignUp(); // Only awarded once per user
await gamificationService.awardFirstMessage(); // Only awarded once per user
```

### 3. Metadata Usage
```dart
// Include relevant context in metadata
await gamificationService.awardXp(
  XpRewardType.createPoll,
  metadata: {
    'pollId': pollId,
    'fellowshipId': fellowshipId,
    'pollTitle': title,
  },
);
```

### 4. Performance
- XP awards are asynchronous and don't block UI
- Use batch awards for multiple simultaneous actions
- Real-time streams are optimized for minimal database reads

### 5. User Experience
- Always show level up celebrations
- Display XP progress in relevant locations
- Use compact widgets in space-constrained areas

## Testing

### Unit Tests
```dart
// Test XP calculations
test('should calculate correct level from XP', () {
  expect(XpEntity.calculateLevelFromXp(0), 1);
  expect(XpEntity.calculateLevelFromXp(100), 2);
  expect(XpEntity.calculateLevelFromXp(400), 3);
});

// Test level up detection
test('should detect level up', () {
  final oldXp = XpEntity(/* level 1 data */);
  final newXp = XpEntity(/* level 2 data */);
  expect(newXp.didLevelUp(oldXp), true);
});
```

### Integration Tests
```dart
// Test XP service integration
testWidgets('should award XP and show level up dialog', (tester) async {
  // Setup mock data
  // Trigger action that awards XP
  // Verify XP was awarded
  // Verify level up dialog appears if applicable
});
```

## Security Considerations

- All XP awards require authenticated users
- XP data is stored securely in Firestore
- Transaction history provides audit trail
- One-time rewards are enforced server-side

## Future Extensions

The system is designed to be easily extensible:

1. **New Reward Types**: Add to `XpRewardType` enum
2. **Achievement System**: Build on top of transaction history
3. **Leaderboards**: Use existing leaderboard functionality
4. **Seasonal Events**: Temporary XP multipliers
5. **Guild/Fellowship XP**: Collective XP systems

## Troubleshooting

### Common Issues

1. **XP Not Awarded**: Check user authentication and network connectivity
2. **Level Up Not Showing**: Ensure BLoC listener is properly configured
3. **Progress Not Updating**: Verify stream subscription is active
4. **Import Errors**: Ensure all required dependencies are added

### Debug Information

The service includes comprehensive debug logging:
```dart
debugPrint('Awarding ${rewardType.xpAmount} XP for ${rewardType.description}');
debugPrint('XP awarded successfully. Total XP: ${updatedXp.totalXp}, Level: ${updatedXp.currentLevel}');
```

---

**Ready to gamify your feature?** Start with the `GamificationService` and add XP rewards to user actions. The system handles all the complexity while providing a smooth, rewarding user experience! 
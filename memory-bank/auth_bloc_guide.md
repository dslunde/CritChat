# AuthBloc Guide for CritChat

## Overview
This guide provides essential knowledge for working with the AuthBloc in CritChat, covering common patterns, pitfalls, and solutions learned through implementation and debugging.

## Architecture Overview

The AuthBloc follows clean architecture principles with proper dependency injection:

```
AuthBloc
├── Use Cases (injected dependencies)
│   ├── GetCurrentUserUseCase
│   ├── SignInUseCase
│   ├── SignUpUseCase
│   ├── SignOutUseCase
│   ├── GetAuthStateChangesUseCase
│   └── CompleteOnboardingUseCase
└── Services (injected dependencies)
    └── GamificationService
```

## Key Principles

### 1. Firebase Auth Stream as Single Source of Truth
- **NEVER** manually emit `AuthAuthenticated` states after sign-in/sign-up
- Let Firebase Auth stream handle all state transitions
- The `_onAuthStateChanged` method is the ONLY place that should emit `AuthAuthenticated`

### 2. Dependency Injection Pattern
- **ALWAYS** inject dependencies through constructor, never use `sl<>()` directly in methods
- This ensures testability and follows clean architecture principles

```dart
// ✅ CORRECT - Inject dependencies
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GamificationService gamificationService,
    // ... other dependencies
  }) : _gamificationService = gamificationService;

  final GamificationService _gamificationService;

  // Use _gamificationService in methods
}

// ❌ WRONG - Using service locator directly
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  void someMethod() {
    final service = sl<GamificationService>(); // DON'T DO THIS
  }
}
```

## State Flow Patterns

### Sign-Up Flow
1. User submits sign-up → `AuthSignUpRequested` event
2. AuthBloc calls `_signUp` use case → emits `AuthLoading`
3. Firebase Auth creates user → Firebase stream emits user
4. `_onAuthStateChanged` receives user → checks if needs onboarding
5. Emits `AuthAuthenticated(needsOnboarding: true)`

### Onboarding Flow
1. User completes onboarding → `AuthOnboardingCompleted` event
2. AuthBloc calls `_completeOnboarding` use case
3. Awards XP for sign-up and profile completion
4. Emits `AuthOnboardingSuccess` with total XP earned
5. After delay, transitions to main app via `AuthStarted`

### Sign-Out Flow
1. User requests sign-out → `AuthSignOutRequested` event
2. AuthBloc emits `AuthSigningOut` state
3. Calls `_signOut` use case
4. Firebase Auth stream emits null
5. `_onAuthStateChanged` checks if state is `AuthSigningOut`
6. If so, ignores null user to prevent immediate state override
7. Eventually transitions to `AuthUnauthenticated`

## Common Pitfalls and Solutions

### 1. Race Conditions with Firebase Auth Stream
**Problem**: Manually emitting states that conflict with Firebase auth stream

**Solution**: 
- Only use manual state emissions for temporary states (`AuthLoading`, `AuthSigningOut`)
- Let Firebase stream handle all `AuthAuthenticated`/`AuthUnauthenticated` transitions

### 2. Service Locator in Methods
**Problem**: Using `sl<Service>()` directly in bloc methods breaks testing

**Solution**: 
- Inject all services through constructor
- Create mocks for all injected services in tests
- Use `registerFallbackValue()` for complex types in tests

### 3. Missing Test Setup
**Problem**: Tests fail because services aren't mocked properly

**Solution**:
```dart
// Always register fallback values for enums/complex types
setUpAll(() {
  registerFallbackValue(XpRewardType.signUp);
});

// Mock all service methods used by the bloc
setUp(() {
  when(() => mockGamificationService.initializeUserXp(any()))
      .thenAnswer((_) async => null);
  when(() => mockGamificationService.awardXp(any()))
      .thenAnswer((_) async {});
});
```

### 4. Navigation State Conflicts
**Problem**: Pages don't dismiss after successful authentication

**Solution**: Add `BlocListener` to pages that need to respond to auth state changes:

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      Navigator.pop(context); // Dismiss current page
    }
  },
  child: YourPageContent(),
)
```

## Testing Patterns

### Required Mocks
```dart
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockGetAuthStateChangesUseCase extends Mock implements GetAuthStateChangesUseCase {}
class MockCompleteOnboardingUseCase extends Mock implements CompleteOnboardingUseCase {}
class MockGamificationService extends Mock implements GamificationService {}
```

### Test Setup Template
```dart
void main() {
  // Declare all mocks
  late MockGamificationService mockGamificationService;
  // ... other mocks

  setUpAll(() {
    // Register fallback values for complex types
    registerFallbackValue(XpRewardType.signUp);
  });

  setUp(() {
    // Initialize mocks
    mockGamificationService = MockGamificationService();
    
    // Setup default behaviors
    when(() => mockGamificationService.initializeUserXp(any()))
        .thenAnswer((_) async => null);
    when(() => mockGamificationService.awardXp(any()))
        .thenAnswer((_) async {});
  });
}
```

## State Expectations

### Onboarding Completion Test
```dart
// Expect AuthOnboardingSuccess, not AuthAuthenticated
expect: () => [
  const AuthLoading(),
  const AuthOnboardingSuccess(
    xpAmount: 35, // 10 for sign-up + 25 for profile completion
    message: 'Your profile is all set!',
  ),
],
```

## Integration with Other Systems

### Gamification Integration
- XP is awarded during onboarding completion
- Sign-up: 10 XP
- Profile completion: 25 XP
- Always handle XP operations in try-catch blocks

### Fellowship Sync
- User fellowship memberships are synced when auth state changes
- Failures are logged but don't break auth flow

## Debugging Tips

1. **Enable debug prints**: The AuthBloc has extensive debug logging
2. **Check Firebase Auth stream**: Most issues stem from stream conflicts
3. **Verify dependency injection**: Ensure all services are properly registered
4. **Test state transitions**: Use `blocTest` to verify expected state flows
5. **Mock all external dependencies**: Never let tests hit real Firebase/services

## Common Error Messages and Solutions

### "GetIt: Object/factory with type X is not registered"
- **Cause**: Missing dependency injection or test mock
- **Solution**: Register the service in DI container or create mock in tests

### "Could not find the correct Provider<AuthBloc>"
- **Cause**: BlocProvider scope issues
- **Solution**: Ensure BlocProvider wraps the widget tree properly

### "type 'Null' is not a subtype of type 'Future<X>'"
- **Cause**: Mock returning wrong type
- **Solution**: Update mock to return correct type: `when(...).thenAnswer((_) async => expectedValue)`

## Best Practices

1. **Always inject dependencies** - Never use service locator in methods
2. **Let Firebase stream lead** - Don't fight the auth stream with manual emissions
3. **Handle errors gracefully** - Wrap external service calls in try-catch
4. **Test thoroughly** - Mock all dependencies and test all state transitions
5. **Use proper state types** - Don't reuse states for different purposes
6. **Debug systematically** - Follow the state flow from event to emission 
# System Patterns: CritChat

## Architecture Overview
CritChat uses a mobile-first, client-server architecture. The frontend is a Flutter application, and the backend is powered by Firebase services, with Weaviate integrated for advanced search capabilities.

## Frontend Architecture Patterns

### State Management
The application uses the BLoC (Business Logic Component) pattern for state management across all features:
- **Event-Driven**: All state changes triggered by events (Auth, Friends, Fellowship, Notifications)
- **Reactive**: UI rebuilds automatically when state changes
- **Testable**: Clear separation between business logic and UI
- **Scalable**: Pattern proven effective across 4+ major features
- **Real-time Integration**: BLoC pattern works excellently with Firebase streams
- **Use Case Architecture**: BLoCs depend only on use cases, not directly on repositories for proper clean architecture

### Clean Architecture Implementation
Consistent 3-layer architecture across all features with proper abstraction:
- **Domain Layer**: Entities, repository interfaces, and use cases (business logic abstraction)
- **Data Layer**: Models, data sources (Firebase/Mock), and repository implementations
- **Presentation Layer**: BLoC state management, pages, and widgets
- **Use Case Pattern**: All BLoCs interact with domain layer through use cases, eliminating direct repository dependencies

### Dependency Injection Pattern
GetIt service locator pattern used throughout with modular organization:
- **Firebase Services**: FirebaseAuth, FirebaseFirestore, FirebaseDatabase registered as singletons
- **Data Sources**: All Firebase data sources registered with proper dependencies
- **Repositories**: Repository implementations injected with data source dependencies
- **Use Cases**: Domain use cases registered with repository dependencies
- **BLoCs**: Registered with use case dependencies for clean separation
- **Modular Initialization**: Feature-specific initialization functions (`_initAuth()`, `_initFriends()`, `_initFellowships()`, `_initNotifications()`, `_initChat()`)

### Authentication Architecture Patterns
Enhanced authentication system with proper stream management:
- **Single Source of Truth**: Firebase `authStateChanges` stream is the only trigger for authentication state changes
- **Use Case Abstraction**: `GetAuthStateChangesUseCase` and `CompleteOnboardingUseCase` abstract repository access
- **Race Condition Prevention**: Eliminated duplicate `AuthStarted` events that caused UI flashing
- **Stream Management**: Proper stream subscription and disposal in BLoCs
- **State Consistency**: Clean state transitions without duplicate emissions

### Testing Strategy
Comprehensive testing approach with multiple layers:
- **Widget Tests**: UI component behavior and user interactions
- **BLoC Tests**: State management and business logic validation with 18 comprehensive authentication test cases
- **Integration Tests**: End-to-end authentication and Firebase integration
- **Mocking Strategy**: Clean, isolated testing with mocktail
- **Race Condition Testing**: Specific tests ensuring no duplicate state emissions
- **Use Case Testing**: Testing business logic abstraction layer
- **CI/CD Ready**: All tests designed for automated pipeline execution

### Code Quality Standards
- **Zero Linting Issues**: Strict adherence to Flutter analyzer rules
- **Import Standardization**: All imports use absolute package imports (`package:critchat/...`) for better maintainability
- **Modern APIs**: Use current Flutter APIs, avoid deprecated methods
- **Clean Architecture**: Proper separation of domain, data, and presentation layers with use case abstraction
- **Consistent Logging**: `debugPrint()` for development, no production `print()` statements
- **Dependency Management**: Clear, organized imports and dependencies
- **BuildContext Safety**: Proper `if (mounted)` checks in async operations

## Data Models & Storage

### Firestore (Primary Database)
Firestore is the primary database for structured, persistent data.

- **`users`**: Enhanced user documents with comprehensive profile information
  - Basic profile: displayName, email, bio, experienceLevel, preferredSystems
  - Social relationships: friends array (user document references)
  - Group memberships: fellowships array (fellowship document references)
  - Metadata: createdAt, updatedAt timestamps
  
- **`fellowships`**: Campaign/group management with comprehensive member handling
  - Basic info: name, description, gameSystem, isPublic
  - Membership: creatorId, memberIds array with batch operation management
  - Metadata: createdAt, updatedAt timestamps
  - Privacy controls and visibility settings

- **`notifications`**: Real-time notification system with comprehensive types
  - Core data: userId, senderId, type, title, message, isRead
  - Metadata: data object for additional context, timestamps
  - Types: friendRequest, friendRequestAccepted, fellowshipInvite, fellowshipJoined, fellowshipMessage, directMessage, fellowshipCreated, systemMessage
  - Real-time streaming with Firestore snapshots
  - **See**: `memory-bank/notifications.md` for a full breakdown of the implementation.

- **`posts`**: Holds media and text updates linked to a specific group. These are persistent posts, unlike stories.
- **`stories`**: Manages ephemeral content that expires after 24 hours. Each document is linked to a group.
- **`recaps`**: Stores structured session summaries. These are used for generating XP and feeding into the RAG system.
- **`lfgPosts`**: Contains "Looking for Group" posts, which are queryable for discovery.

### Firebase Realtime Database (for Real-time Features)
The Realtime Database is used for low-latency, high-concurrency features.

- **`direct_userId1_userId2`**: Direct messaging between friends
  - Message structure: senderId, message, timestamp, isRead
  - Sorted by timestamp for chronological order
  - Real-time streaming for live chat experience

- **`fellowship_fellowshipId`**: Group chat for fellowship members
  - Message structure: senderId, senderName, message, timestamp, isRead
  - System messages for member join/leave events
  - Real-time streaming for group communication

- **`polls`**: Real-time polling data for scheduling (future implementation)
- **`storyViews`**: Tracks views on ephemeral stories in real-time (future implementation)

### Firebase Storage
Used for storing user-generated media content, such as images and videos for posts and stories.

## Backend Logic & APIs

### Firebase Integration Patterns

#### User Relationship Management
- **Friend Relationships**: Bidirectional friend arrays in user documents
- **Fellowship Memberships**: User documents track fellowship memberships, fellowship documents track members
- **Batch Operations**: Used for complex operations affecting multiple documents (friend requests, fellowship joins)

#### Real-time Data Patterns
- **Firestore Streams**: Used for notifications and fellowship lists with automatic UI updates
- **Realtime Database Streams**: Used for chat messages with live message delivery
- **Optimistic Updates**: UI updates immediately with server confirmation

#### Search Implementation
- **User Search**: Firestore queries using `isGreaterThanOrEqualTo` and `isLessThan` for name-based search
- **Debounced Search**: 500ms debounce to prevent excessive Firebase queries
- **Result Limiting**: Maximum 20 results for performance optimization

### API Endpoints
A RESTful-like API is implemented for core CRUD operations on the main data models.

- `POST /groups`, `GET /groups/:id`, `PATCH /groups/:id`
- `POST /posts`, `GET /groups/:id/posts`
- `POST /stories`, `GET /groups/:id/stories`
- `POST /recaps`, `GET /groups/:id/recaps`
- `POST /lfg`, `GET /lfg`
- `POST /xp/reward`, `GET /users/:id`

### Cloud Functions (Serverless Logic)
Firebase Cloud Functions handle backend processing and business logic.

- **`recommendGroups`**: A callable function that suggests new groups to users.
- **`autoTagPost`**: A function (likely triggered by a Firestore event) that automatically tags posts with relevant metadata.
- **`generateRecapEmbedding`**: Triggered on the creation of a new recap, this function generates a vector embedding of the recap's content and stores it in Weaviate for semantic search.
- **XP Logic**: Functions that automatically calculate and award XP based on user actions (e.g., posting content, reacting, receiving kudos on a recap).

## Feature Implementation Patterns

### BLoC Event/State Patterns
Consistent event and state patterns across all features:

#### Events
- **Load Events**: `GetFriends`, `GetFellowships`, `GetNotifications`
- **Action Events**: `CreateFellowship`, `SendFriendRequest`, `AcceptFriendRequest`
- **Stream Events**: `NotificationsUpdated`, `AuthStateChanged` for real-time data

#### States
- **Initial**: Feature not yet loaded
- **Loading**: Data being fetched or action in progress
- **Loaded**: Data successfully loaded with content
- **Success**: Action completed successfully (creation, invitation, etc.)
- **Error**: Error state with detailed error information

### Use Case Implementation Patterns
Consistent use case patterns across all features:
- **Repository Abstraction**: Use cases abstract repository access from BLoCs
- **Business Logic**: Use cases contain business logic and validation
- **Error Handling**: Use cases handle and transform errors appropriately
- **Testability**: Use cases are easily testable in isolation
- **Single Responsibility**: Each use case has a single, well-defined purpose

### UI Component Patterns
- **Cards**: Consistent card design for Friends, Fellowships, and Notifications
- **Action Buttons**: Standardized button styling and behavior
- **Loading States**: Consistent loading indicators across features
- **Empty States**: Proper empty state handling with helpful messaging
- **Error Handling**: User-friendly error messages with retry options

### Navigation Patterns
- **Result-based Navigation**: Pages return success/failure results for proper state management
- **BLoC Context Management**: Proper BLoC provider setup for complex navigation flows
- **Deep Linking**: Prepared for deep linking to specific fellowships and chats

### Firebase Security Patterns
- **User Authentication**: All Firebase operations require authenticated users
- **Document-level Security**: Users can only access their own data and fellowships they're members of
- **Batch Operations**: Complex multi-document operations use Firestore batches for consistency
- **Real-time Security**: Realtime Database rules ensure users can only access appropriate chat rooms

### Import Organization Patterns
- **Absolute Package Imports**: All imports use `package:critchat/...` format for better maintainability
- **Consistent Import Order**: Flutter imports, package imports, relative imports (when necessary)
- **Clear Dependency Relationships**: Absolute imports make dependency relationships explicit
- **IDE Support**: Better IDE support with absolute imports for refactoring and navigation 

## Poll System Architecture

### Domain Layer
- **PollEntity**: Core business entity with voting logic, expiration checks, vote counting
- **PollOptionEntity**: Individual poll options with metadata
- **PollRepository**: Interface defining all poll operations
- **Use Cases**: CreatePollUseCase, VoteOnPollUseCase, GetFellowshipPollsUseCase, AddCustomOptionUseCase

### Data Layer
- **PollModel**: Firebase-compatible model with JSON serialization
- **PollRealtimeDataSource**: Firebase Realtime Database integration with Firestore for user names
- **Database Structure**: `polls/fellowship_{fellowshipId}/{pollId}` with options and votes
- **User Display Names**: Helper method `_getUserDisplayName()` fetches from Firestore with email fallback

### Presentation Layer
- **PollBloc**: State management with StreamController pattern for stream reuse
- **Poll States**: PollStateWithData base class ensures data persistence across UI operations
- **PollCard**: Auto-collapse for expired polls with winning results display
- **Stream Caching**: `_lastPolls` cache for immediate data replay to new listeners

## Stream Management Pattern

### Problem Solved
- "Stream has already been listened to" errors when switching tabs
- Data persistence across UI interactions
- Efficient resource management

### Solution Architecture
```dart
class DataBloc {
  StreamController<List<Entity>> _streamController = StreamController.broadcast();
  List<Entity> _lastData = [];
  StreamSubscription? _subscription;

  Stream<List<Entity>> get stream => _streamController.stream;

  void _initializeStream() {
    _subscription = _dataSource.getStream().listen((data) {
      _lastData = data;
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
    });
    
    // Replay last data to new listeners
    _streamController.onListen = () {
      if (_lastData.isNotEmpty && !_streamController.isClosed) {
        _streamController.add(_lastData);
      }
    };
  }
}
```

### Benefits
- Multiple UI components can listen to same stream
- Immediate data availability for new listeners
- Proper resource cleanup and memory management
- Seamless tab switching without data loss

## Display Name Resolution Pattern

### Architecture
```dart
Future<String> _getUserDisplayName(String userId) async {
  try {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final displayName = userDoc.data()?['displayName'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
    }
    // Fallback to email prefix
    final currentUser = _auth.currentUser;
    if (currentUser?.email != null) {
      return currentUser!.email!.split('@')[0];
    }
    return 'User';
  } catch (e) {
    debugPrint('Failed to get user display name: $e');
    return 'User';
  }
}
```

### Implementation Points
- Used in both ChatRealtimeDataSourceImpl and PollRealtimeDataSourceImpl
- Firestore lookup for display names with smart fallback
- Error handling prevents crashes on network issues
- Consistent user experience across chat and polls

## UI State Persistence Pattern

### Problem
- UI components losing data during state transitions
- Loading states causing visual flicker
- Inconsistent user experience during operations

### Solution: PollStateWithData Pattern
```dart
abstract class PollState extends Equatable {}

abstract class PollStateWithData extends PollState {
  final List<PollEntity> polls;
  const PollStateWithData(this.polls);
}

class PollsLoaded extends PollStateWithData {
  const PollsLoaded(super.polls);
}

class PollVoteSuccess extends PollStateWithData {
  const PollVoteSuccess(super.polls);
}

class PollCreated extends PollStateWithData {
  const PollCreated(super.polls);
}
```

### UI Handling
```dart
Widget build(BuildContext context) {
  return BlocBuilder<PollBloc, PollState>(
    builder: (context, state) {
      if (state is PollStateWithData) {
        return _buildPollsList(state.polls);
      }
      // Handle other states...
    },
  );
}
```

### Benefits
- Polls remain visible during all operations
- No loading flicker during user interactions
- Consistent data availability across state transitions
- Better user experience with persistent UI

## RAG (Retrieval-Augmented Generation) System Architecture

### Complete AI-Powered Character Interaction System
The RAG system enables AI-powered character-based messaging using vector databases and large language models, following clean architecture principles throughout.

### Domain Layer - Character Management
- **CharacterEntity**: Core character model with personality, backstory, speech patterns, quotes, and AI indexing status
- **CharacterMemoryEntity**: Vector-enabled memory storage with content, embeddings, metadata, and similarity scores
- **CharacterRepository**: Interface for character CRUD operations with validation (one character per user)
- **CharacterMemoryRepository**: Interface for memory storage, vectorization, and similarity search operations
- **Use Cases**: 
  - `CreateCharacterUseCase`: Character creation with comprehensive validation
  - `GetUserCharacterUseCase`: Retrieve user's character with error handling
  - `UpdateCharacterUseCase`: Character modification with validation
  - `StoreCharacterMemoryUseCase`: Memory vectorization and storage
  - `SearchCharacterMemoriesUseCase`: Vector similarity search with configurable limits

### RAG Service Architecture
- **RAG Service Interface**: Defines character response generation, memory indexing, and vector operations
- **RAG Service Implementation**: Complete pipeline orchestrating embedding, vector search, and LLM generation
- **Context Management**: Retrieves character profile + up to 10 relevant memories + recent chat history
- **Response Generation**: Personality-driven LLM prompts ensuring character consistency

### Vector Database Integration (Weaviate)
- **WeaviateService**: Complete vector database integration with schema management
- **Character Memory Schema**: Optimized vector storage for character memories with metadata
- **Similarity Search**: Configurable threshold and limit-based memory retrieval
- **Health Monitoring**: Service availability checking with graceful degradation
- **Batch Operations**: Efficient bulk memory storage and retrieval

### LLM Integration Architecture
- **LlmService Interface**: Abstracts language model operations for character response generation
- **OpenAI Integration**: GPT-4o-mini with personality-driven prompt engineering
- **Context Window Management**: Optimal prompt construction using character + memories + context
- **Mock LLM Service**: Development service with realistic response generation patterns

### Embedding Service Architecture
- **EmbeddingService Interface**: Text vectorization abstraction for memory storage
- **OpenAI Embedding Integration**: text-embedding-3-small model for high-quality vectors
- **Text Preprocessing**: Content optimization for embedding generation
- **Mock Embedding Service**: Development service with realistic vector generation

### @as Command System Architecture
- **ChatCommandParser**: Advanced parsing for `@as <character> <message>` and quoted character names
- **CommandValidator**: Comprehensive validation with helpful error messages and suggestions
- **AsCommandData**: Structured command representation with character and message separation
- **Integration Pipeline**: Command → Character Validation → Memory Retrieval → LLM Generation → Response

### Enhanced Message Architecture
- **Extended Message Class**: Added characterId, characterName, originalPrompt for character messages
- **Message Type Identification**: Distinguishes AI-generated character messages from regular messages
- **Notification Integration**: Special handling for character message notifications
- **Real-time Integration**: Seamless integration with existing chat infrastructure

### Configuration Management Architecture
- **AppConfig**: Environment-based configuration with development overrides
- **LocalConfig**: Development setup with secure API key management via .env.local
- **Service Selection**: Automatic mock/real service selection based on configuration
- **Security Patterns**: API keys never in code, template-based team onboarding

### Character Memory UI Architecture
- **CharacterMemoryWidget**: Seamless memory addition interface with expandable UI
- **Content Type Inference**: Automatic categorization (session, journal, backstory, NPC interactions)
- **Memory Display**: Recent memories with status indicators and availability checking
- **Integration Pattern**: Embedded within character management flow for seamless UX

### Production Deployment Patterns
- **Environment Separation**: Clear development (mock) vs production (real AI) service modes
- **Docker Integration**: Automated Weaviate deployment with setup scripts
- **API Key Management**: Secure .env.local pattern with template files for team onboarding
- **Health Monitoring**: Service availability checking with user-friendly status reporting
- **Graceful Degradation**: Comprehensive fallbacks when AI services unavailable

### RAG Data Flow Architecture
```
User Input: @as Gandalf Welcome to my realm!
    ↓
Command Parser: Extract character="Gandalf", message="Welcome to my realm!"
    ↓
Character Validation: Verify user owns character, character exists
    ↓
Memory Retrieval: Vector search for relevant memories (up to 10)
    ↓
Context Assembly: Character profile + memories + recent chat history
    ↓
LLM Generation: GPT-4o-mini with personality-driven prompt
    ↓
Response Delivery: Character message with metadata sent to chat
```

### Testing Patterns for RAG System
- **Use Case Testing**: Isolated business logic testing with comprehensive validation scenarios
- **Mock Service Testing**: Realistic AI service behavior simulation for development
- **Integration Testing**: End-to-end RAG pipeline testing with actual vector operations
- **Error Scenario Testing**: Comprehensive failure mode testing (AI unavailable, invalid characters, etc.)
- **Performance Testing**: Vector search efficiency and LLM response time validation 
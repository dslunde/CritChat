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

### Clean Architecture Implementation
Consistent 3-layer architecture across all features:
- **Domain Layer**: Entities, repository interfaces, and use cases
- **Data Layer**: Models, data sources (Firebase/Mock), and repository implementations
- **Presentation Layer**: BLoC state management, pages, and widgets

### Dependency Injection Pattern
GetIt service locator pattern used throughout:
- **Firebase Services**: FirebaseAuth, FirebaseFirestore, FirebaseDatabase registered as singletons
- **Data Sources**: All Firebase data sources registered with proper dependencies
- **Repositories**: Repository implementations injected with data source dependencies
- **BLoCs**: Registered with repository dependencies for clean separation

### Testing Strategy
Comprehensive testing approach with multiple layers:
- **Widget Tests**: UI component behavior and user interactions
- **BLoC Tests**: State management and business logic validation
- **Integration Tests**: End-to-end authentication and Firebase integration
- **Mocking Strategy**: Clean, isolated testing with mocktail
- **CI/CD Ready**: All tests designed for automated pipeline execution

### Code Quality Standards
- **Zero Linting Issues**: Strict adherence to Flutter analyzer rules
- **Modern APIs**: Use current Flutter APIs, avoid deprecated methods
- **Clean Architecture**: Proper separation of domain, data, and presentation layers
- **Consistent Logging**: `debugPrint()` for development, no production `print()` statements
- **Dependency Management**: Clear, organized imports and dependencies

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
- **Stream Events**: `NotificationsUpdated` for real-time data

#### States
- **Initial**: Feature not yet loaded
- **Loading**: Data being fetched or action in progress
- **Loaded**: Data successfully loaded with content
- **Success**: Action completed successfully (creation, invitation, etc.)
- **Error**: Error state with detailed error information

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
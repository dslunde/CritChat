# System Patterns: CritChat

## Architecture Overview
CritChat uses a mobile-first, client-server architecture. The frontend is a Flutter application, and the backend is powered by Firebase services, with Weaviate integrated for advanced search capabilities.

## Frontend Architecture Patterns

### State Management
The application uses the BLoC (Business Logic Component) pattern for state management:
- **Event-Driven**: All state changes triggered by events
- **Reactive**: UI rebuilds automatically when state changes
- **Testable**: Clear separation between business logic and UI
- **Scalable**: Pattern works well for both simple and complex features

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

-   **`users`**: Stores user profile information, preferences, total XP, and a list of joined group IDs.
-   **`groups`**: Contains campaign-specific information, including member lists, the designated TTRPG system, and visibility settings (public/private).
-   **`posts`**: Holds media and text updates linked to a specific group. These are persistent posts, unlike stories.
-   **`stories`**: Manages ephemeral content that expires after 24 hours. Each document is linked to a group.
-   **`recaps`**: Stores structured session summaries. These are used for generating XP and feeding into the RAG system.
-   **`lfgPosts`**: Contains "Looking for Group" posts, which are queryable for discovery.

### Firebase Realtime Database (for Real-time Features)
The Realtime Database is used for low-latency, high-concurrency features.

-   **`groupChats`**: Live chat messages within each group.
-   **`polls`**: Real-time polling data for scheduling.
-   **`storyViews`**: Tracks views on ephemeral stories in real-time.

### Firebase Storage
Used for storing user-generated media content, such as images and videos for posts and stories.

## Backend Logic & APIs

### API Endpoints
A RESTful-like API is implemented for core CRUD operations on the main data models.

-   `POST /groups`, `GET /groups/:id`, `PATCH /groups/:id`
-   `POST /posts`, `GET /groups/:id/posts`
-   `POST /stories`, `GET /groups/:id/stories`
-   `POST /recaps`, `GET /groups/:id/recaps`
-   `POST /lfg`, `GET /lfg`
-   `POST /xp/reward`, `GET /users/:id`

### Cloud Functions (Serverless Logic)
Firebase Cloud Functions handle backend processing and business logic.

-   **`recommendGroups`**: A callable function that suggests new groups to users.
-   **`autoTagPost`**: A function (likely triggered by a Firestore event) that automatically tags posts with relevant metadata.
-   **`generateRecapEmbedding`**: Triggered on the creation of a new recap, this function generates a vector embedding of the recap's content and stores it in Weaviate for semantic search.
-   **XP Logic**: Functions that automatically calculate and award XP based on user actions (e.g., posting content, reacting, receiving kudos on a recap). 
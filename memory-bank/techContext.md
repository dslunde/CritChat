# Technical Context: CritChat

This document outlines the specific technologies, frameworks, and services used to build and run the CritChat application.

## Frontend

-   **Framework**: Flutter 3.x with Material 3 design
-   **State Management**: BLoC Pattern with flutter_bloc
    -   *Note: Originally considered Zustand-inspired solution, but BLoC pattern was chosen for its excellent Flutter integration, comprehensive tooling, and robust testing capabilities.*
    -   *Proven effective across 4+ major features: Auth, Friends, Fellowship, Notifications*
-   **Navigation**: Native Flutter navigation with planned migration to go_router
-   **Form Validation**: Formz for type-safe form field validation
-   **Dependency Injection**: GetIt for clean service location and testing

## Testing & Quality Assurance

-   **Widget Testing**: flutter_test for UI component testing
-   **BLoC Testing**: bloc_test for comprehensive state management testing
-   **Mocking**: mocktail for clean, type-safe mocking in tests
-   **Code Quality**: flutter_lints for consistent code standards
-   **Analyzer**: Zero-tolerance policy for linting issues and warnings

## Backend & Services

### Firebase (Primary Platform)
Complete Firebase integration across all features:

#### Authentication & User Management
-   **Firebase Auth**: User sign-up, login, and session management
-   **User Profiles**: Comprehensive user documents in Firestore with social relationships
-   **Security**: All backend access secured through Firebase Auth

#### Database Architecture
-   **Cloud Firestore**: Primary database for structured data
    -   Users collection with enhanced social relationship tracking
    -   Fellowships collection with comprehensive group management
    -   Notifications collection with real-time streaming
    -   Future: posts, stories, recaps, lfgPosts collections
-   **Firebase Realtime Database**: Low-latency features requiring real-time synchronization
    -   Direct messaging: `direct_userId1_userId2` chat rooms
    -   Fellowship chat: `fellowship_fellowshipId` group messaging
    -   Real-time message delivery with read receipts
    -   Future: live polls, story views tracking

#### Cloud Functions & Storage
-   **Cloud Functions**: Serverless backend logic for XP calculation, media processing, Weaviate integration
-   **Cloud Storage**: User-uploaded media (images, videos) for posts and stories

### Real-time Features Implementation
-   **Chat Messaging**: Firebase Realtime Database with live message streaming
-   **Notifications**: Firestore snapshots for real-time notification delivery
-   **Presence System**: Online/offline status tracking (future implementation)
-   **Live Updates**: Automatic UI updates for fellowship membership changes

## Search & AI

-   **Vector Database**: Weaviate
    -   **Purpose**: Used for advanced search and discovery features.
    -   **Functionality**:
        -   **Semantic Search**: Allows users to find similar content or groups based on meaning rather than just keywords.
        -   **Retrieval-Augmented Generation (RAG)**: Stores vector embeddings of session recaps, enabling features that can intelligently summarize or reference past game events.

## Key Dependencies & Integrations

### Core Flutter Dependencies
-   `flutter_bloc: ^8.1.3` - State management (proven across 4+ features)
-   `equatable: ^2.0.5` - Value equality for state objects
-   `formz: ^0.7.0` - Form validation
-   `get_it: ^8.0.0` - Dependency injection

### Firebase Dependencies
-   `firebase_core: ^2.24.2` - Firebase core functionality
-   `firebase_auth: ^4.16.0` - Authentication services
-   `cloud_firestore: ^4.14.0` - Firestore database with real-time streaming
-   `firebase_database: ^10.4.0` - Realtime Database for chat messaging

### Testing Dependencies
-   `bloc_test: ^9.1.7` - BLoC testing utilities
-   `mocktail: ^1.0.4` - Mocking framework

### Development Standards
-   Modern Flutter APIs (avoiding deprecated methods)
-   Proper logging with `debugPrint()` for development
-   Clean architecture principles with proper separation of concerns
-   Zero-tolerance policy for analyzer warnings and errors

## Architecture Patterns Implemented

### Clean Architecture
Consistent 3-layer architecture across all features:
1. **Domain Layer**: Entities, repository interfaces, use cases
2. **Data Layer**: Models, Firebase data sources, repository implementations  
3. **Presentation Layer**: BLoC state management, UI pages, widgets

### Firebase Integration Patterns
-   **Service Registration**: Firebase instances registered as singletons in GetIt
-   **Data Source Pattern**: Dedicated Firebase data sources for each feature
-   **Repository Pattern**: Clean separation between data sources and business logic
-   **Stream Management**: Proper stream subscription and disposal in BLoCs

### Real-time Data Patterns
-   **Firestore Streams**: For notifications and fellowship updates
-   **Realtime Database Streams**: For chat messages and live features
-   **Optimistic Updates**: UI updates immediately with server confirmation
-   **Error Recovery**: Robust error handling for network issues

### Search Implementation
-   **Firebase Queries**: Optimized Firestore queries for user search
-   **Debounced Search**: 500ms debounce to prevent excessive queries
-   **Result Limiting**: Performance optimization with query limits
-   **Case-insensitive Search**: Using Firestore range queries

## Feature-Specific Technical Details

### Fellowship Management
-   **Batch Operations**: Firestore batches for complex multi-document updates
-   **Member Relationship Tracking**: Bidirectional references between users and fellowships
-   **Privacy Controls**: Public/private fellowship visibility with proper security rules

### Chat System
-   **Message Structure**: Standardized message format across direct and group chats
-   **Read Receipts**: Real-time read status tracking
-   **System Messages**: Automated messages for member join/leave events
-   **Message Ordering**: Timestamp-based message chronology

### Notifications System
-   **Real-time Delivery**: Firestore snapshots for instant notification updates
-   **Interactive Elements**: Accept/Decline buttons for friend requests and invitations
-   **Notification Types**: 8 comprehensive notification types with proper categorization
-   **Batch Processing**: Efficient notification creation for complex workflows

### User Search & Discovery
-   **Firebase Search**: Firestore range queries for name-based user search
-   **Performance Optimization**: Debounced input and result limiting
-   **Social Integration**: Friend request system integrated with notifications
-   **Privacy Respect**: Proper user discovery with privacy considerations 
# Technical Context: CritChat

This document outlines the specific technologies, frameworks, and services used to build and run the CritChat application.

## Frontend

-   **Framework**: Flutter 3.x with Material 3 design
-   **State Management**: BLoC Pattern with flutter_bloc
    -   *Note: Originally considered Zustand-inspired solution, but BLoC pattern was chosen for its excellent Flutter integration, comprehensive tooling, and robust testing capabilities.*
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

-   **Primary Platform**: Firebase
    -   **Authentication**: Firebase Auth for user sign-up, login, and session management. Secures all backend access.
    -   **Primary Database**: Cloud Firestore for storing core application data (users, groups, posts, etc.).
    -   **Real-time Database**: Firebase Realtime Database for features requiring low-latency synchronization, such as live chat and polls.
    -   **Serverless Functions**: Cloud Functions for Firebase to run backend logic for tasks like calculating XP, processing media, and communicating with the Weaviate API.
    -   **File Storage**: Cloud Storage for Firebase to store user-uploaded media like images and videos.

## Search & AI

-   **Vector Database**: Weaviate
    -   **Purpose**: Used for advanced search and discovery features.
    -   **Functionality**:
        -   **Semantic Search**: Allows users to find similar content or groups based on meaning rather than just keywords.
        -   **Retrieval-Augmented Generation (RAG)**: Stores vector embeddings of session recaps, enabling features that can intelligently summarize or reference past game events.

## Key Dependencies & Integrations

-   **Core Flutter Dependencies**:
    -   `flutter_bloc: ^8.1.3` - State management
    -   `equatable: ^2.0.5` - Value equality for state objects
    -   `formz: ^0.7.0` - Form validation
    -   `get_it: ^8.0.0` - Dependency injection
-   **Firebase Dependencies**:
    -   `firebase_core: ^2.24.2` - Firebase core functionality
    -   `firebase_auth: ^4.16.0` - Authentication services
    -   `cloud_firestore: ^4.14.0` - Firestore database
-   **Testing Dependencies**:
    -   `bloc_test: ^9.1.7` - BLoC testing utilities
    -   `mocktail: ^1.0.4` - Mocking framework
-   **Development Standards**:
    -   Modern Flutter APIs (avoiding deprecated methods)
    -   Proper logging with `debugPrint()` for development
    -   Clean architecture principles with proper separation of concerns 
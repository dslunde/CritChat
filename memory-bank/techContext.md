# Technical Context: CritChat

This document outlines the specific technologies, frameworks, and services used to build and run the CritChat application.

## Frontend

-   **Framework**: Flutter
-   **State Management**: Zustand
    -   *Note: Zustand is primarily a JavaScript library. For Flutter, a similar light-weight, hook-based state management solution inspired by Zustand will be used (e.g., a custom implementation or a library with a similar philosophy).*

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

-   The project will rely on the official Flutter and Firebase SDKs.
-   An HTTP client will be needed to communicate with the Weaviate API from Cloud Functions.
-   Specific Flutter packages for handling state management, routing, and UI components will be added as development progresses. 
# Active Context: CritChat

## Current Goal: MVP Launch

The primary focus is to implement all features required for the Minimum Viable Product (MVP) launch, as defined in the Project Requirement Document.

## Immediate Focus
The current work is centered on documentation and project setup. Having established the foundational documentation (`README.md` and Memory Bank), the next phase is to begin feature implementation.

## Next Steps

The development will proceed by tackling the core features outlined in the MVP requirements. The logical starting point is user identity and basic data structures.

1.  **User Authentication & Profile Creation**:
    -   Implement user sign-up and login using Firebase Auth.
    -   Create the user onboarding flow to capture TTRPG preferences.
    -   Build the initial user profile page.
    -   Set up the `users` collection in Firestore.

2.  **Group Management**:
    -   Develop the functionality to create, join, and manage groups.
    -   Implement group visibility settings and system tagging.
    -   Set up the `groups` collection in Firestore.

3.  **Core Content Features**:
    -   Begin implementation of ephemeral stories and the persistent post feed.

## Active Decisions & Considerations

-   **State Management**: The PRD specifies `Zustand`. As this is a JavaScript library, the immediate technical decision is to select a Flutter equivalent that mirrors its simplicity and hook-based approach. This needs to be researched and decided upon before UI development begins in earnest.
-   **Security Rules**: Initial, secure Firebase rules for Firestore and Realtime Database need to be written alongside feature development to ensure data integrity from the start. 
# CritChat

CritChat is a mobile-first, Snapchat-style social app for Tabletop Role-Playing Game (TTRPG) players and groups. It enables tight-knit campaign parties to share ephemeral stories, organize sessions, post recaps, and discover new games through system-tagged content and gamified engagement.

## User Roles & Core Workflows

-   **Player**: Creates or joins a group, posts session stories, and earns XP from engagement.
-   **Game Master (GM)**: Manages group settings, posts session recaps, and runs polls to coordinate scheduling.
-   **Seeker**: Uses the discovery and Looking for Group (LFG) tools to find new campaigns and join active groups.

All users interact with ephemeral media, create content tagged by system/style, and build their in-app profile.

## Technical Foundation

-   **Frontend**: Flutter with Zustand for state management.
-   **Backend**: Firebase (Authentication, Firestore, Realtime Database, Cloud Functions, Storage).
-   **Search & Discovery**: Weaviate for semantic search and Retrieval-Augmented Generation (RAG).

### Data Models

-   `users`: Profile, XP, preferences, joined groups.
-   `groups`: Campaigns with members, system tag, visibility.
-   `posts`: Media/text updates linked to groups.
-   `stories`: 24-hour ephemeral group content.
-   `recaps`: Structured session summaries for XP + RAG.
-   `lfgPosts`: Discoverable player/GM recruiting posts.
-   **Realtime DB**: Used for `groupChats`, `polls`, and `storyViews`.

### API Endpoints & Functions

-   **Core API**:
    -   `POST /groups`, `GET /groups/:id`, `PATCH /groups/:id`
    -   `POST /posts`, `GET /groups/:id/posts`
    -   `POST /stories`, `GET /groups/:id/stories`
    -   `POST /recaps`, `GET /groups/:id/recaps`
    -   `POST /lfg`, `GET /lfg`
    -   `POST /xp/reward`, `GET /users/:id`
-   **Callable Functions**: `recommendGroups`, `autoTagPost`, `generateRecapEmbedding`

## MVP Launch Requirements

1.  **User Management**: Sign up, onboard with TTRPG preferences, and create a profile.
2.  **Group Management**: Create, join, and manage groups with visibility and system tags.
3.  **Ephemeral Stories**: Post ephemeral stories with media and view them within group feeds.
4.  **Session Recaps**: Upload session recaps and earn XP, triggering Weaviate embeddings.
5.  **Content Feed**: Post media-rich updates and browse a story/post feed within groups.
6.  **Real-time Interaction**: Chat and session polling available in groups via Realtime DB.
7.  **Discovery**: Discover and filter LFG posts by system, type, and availability.
8.  **Gamification**: XP awarded automatically through content actions using Cloud Functions.
9.  **Smart Search**: View similar groups or content through Weaviate-powered search.
10. **Security**: All content access is secured via Firebase Auth and Firestore/RTDB rules.
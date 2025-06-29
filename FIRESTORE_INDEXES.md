# Firestore Composite Indexes Required

## LFG (Looking for Group) Feature

The LFG feature requires the following composite indexes in Firestore:

### 1. LFG Posts Query Index
**Collection**: `lfgPosts`
**Fields**:
- `isClosed` (Ascending)
- `createdAt` (Descending)
- `__name__` (Ascending)

**Purpose**: Enables querying for active LFG posts ordered by creation date

### How to Create

#### Option 1: Automatic Creation
1. Run the app and navigate to the LFG page
2. The error message will contain a direct link to create the index
3. Click the link and Firebase will auto-generate the index

#### Option 2: Manual Creation
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`critchat-906b4`)
3. Navigate to Firestore Database → Indexes
4. Click "Create Index"
5. Set:
   - Collection ID: `lfgPosts`
   - Add fields:
     - Field: `isClosed`, Order: Ascending
     - Field: `createdAt`, Order: Descending
6. Click "Create"

#### Option 3: Firebase CLI
```bash
# Create firestore.indexes.json in your project root
{
  "indexes": [
    {
      "collectionGroup": "lfgPosts",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isClosed",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}

# Deploy indexes
firebase deploy --only firestore:indexes
```

## Status

✅ **LFG Posts Index**: Successfully deployed via Firebase CLI  
⏳ **Building**: Index is currently building on Firebase servers (typically takes 2-5 minutes)

## Notes

- The app gracefully handles missing indexes by showing an empty state instead of errors
- Index creation typically takes a few minutes to complete
- Once created, the LFG feature will work at full performance with proper sorting
- Index was deployed on: $(date) 
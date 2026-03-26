# Production Firebase Backend Setup

This plan ensures a "legit" production-ready configuration for the "Roze" app, moving away from test setups to a secure, siloed environment.

## 1. Security & Data Privacy (LEGIT Setup)

Crucially, journals are private. We must enforce this at the database level.

### Firestore Security Rules
Paste these in the **Firestore > Rules** tab. They ensure users can ONLY read/write their own data.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Legacy support for the 'test' collection (optional, can delete later)
    match /test/{doc} {
      allow read, write: if false; // Disable public test access
    }

    match /journals/{userId} {
      // Allow user to read/write their own journal document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /entries/{dateKey} {
        // Allow user to read/write their own entries
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Storage Security Rules
Paste these in the **Storage > Rules** tab to protect private photos and videos.

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /videos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 2. Authentication Setup
Ensure **Google Sign-In** and **Email/Password** are enabled in the **Firebase Console > Authentication > Sign-in method**.

## 3. Code Refinement

### [MODIFY] [main.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/main.dart)
- Remove the "dummy test" read.
- Implement robust initialization.

### [NEW] [firebase_options.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/firebase_options.dart)
- Configure for multiple platforms.

## 4. Verification Plan
- [ ] Attempt to save a journal entry; verify it appears in Firestore under the user's UID.
- [ ] Attempt to upload a photo; verify it appears in the private Storage folder.
- [ ] Verify that a second user *cannot* see the first user's data (Security Rule validation).

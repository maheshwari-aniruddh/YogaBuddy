# Fix Logout Freeze

## Goal
Resolve the issue where the app gets stuck on the splash screen after logging out.

## Root Cause
In `AuthWrapper`, after `signInSilently` completes (returning null), `_isLoading` becomes `false`. However, the `StreamBuilder` listening to `authStateChanges` starts in `ConnectionState.waiting`. Since the current user is `null`, the existing logic falls through to return `SplashScreen()`, expecting the stream to emit an event. When no event is emitted immediately, the app remains stuck on the splash screen.

## Proposed Changes
### `lib/screens/auth_wrapper.dart`
- [MODIFY] inside `StreamBuilder`, in the `ConnectionState.waiting` block.
- Change the fallback return from `SplashScreen()` to `LoginScreen()`.
- Since we have already awaited `_trySilentSignIn` (controlled by `_isLoading`), we know that if `currentUser` is null, we are indeed logged out.

```dart
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (snapshot.hasData || _authService.currentUser != null) {
             // ... existing logic ...
             return MainScreen(user: user);
          }
          // Change this:
          // return const SplashScreen();
          // To this:
          return const LoginScreen(); 
        }
```

## Verification Plan
### Manual Verification
- **Logout Flow**:
    -   Log in to the app.
    -   Go to Settings -> Log Out.
    -   Verify the app transitions to the **Login Screen** ("Get Started" or Google Sign In button) instead of freezing on the splash screen.

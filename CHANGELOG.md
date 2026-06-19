# Changelog

## [1.1.0] - 2024-06-14

### Added
- **Guest Mode**: Implemented non-authenticated browsing.
  - Users can now view the map and object details without logging in.
  - Search and filtering are available for guest users.
  - Login prompts are shown only when attempting account-based actions (Publish, Claim, Comment, Favorite, etc.).
- **Sign in with Apple**: Fully integrated and configured for iOS/iPadOS.
  - Added native Apple Sign-In support via `sign_in_with_apple`.
  - Configured Entitlements for App Store compliance.
  - Fixed iPad-specific errors reported by Apple.

### Fixed
- Error in `AboutScreen` where statistics weren't rendering due to a missing widget method.
- Deprecated `withOpacity` calls updated to `withValues` (where applicable) or maintained for compatibility.
- Authentication logic in `SplashScreen` to prioritize immediate access to the map.

### Changed
- Improved `LoginScreen` layout with "Continue as Guest" and native Apple/Google buttons.
- Enhanced `ObjectDetailScreen` to handle guest state gracefully.

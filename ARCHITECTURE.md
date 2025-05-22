## RoSpins: Spin & Scratch Game App - Updated Architecture (No AdMob)

### Overview
This application is a Roblox-inspired game app with spin wheel and scratch card features, allowing users to earn and manage virtual points. The app no longer includes AdMob integration and all ad-related functionality has been removed while maintaining the core gameplay features.

### Core Features (MVP)
1. Simple login with username validation
2. Spin wheel game (3 spins per day)
3. Scratch card game (1 free card per day)
4. Local user data persistence
5. Roblox-inspired theme and design
6. Withdrawal Page: Users with >= 1500 points can send points to another valid username
7. Rewarded Page: Users can earn points through various activities (no ad rewards)
8. Privacy Policy page: Accessible from the HomeScreen's menu (removed AdMob references)

### Technical Architecture

#### Data Models
1. **User Model** (`lib/models/user_model.dart`) - Stores user data including username, points, spins left, etc.

#### File Structure (14 files total)
```
lib/
├── main.dart              # App entry point, theme setup
├── models/
│   └── user_model.dart    # User data model
├── services/
│   ├── storage_service.dart  # Shared preferences implementation
│   └── ad_service.dart    # Empty ad service with stub methods for compatibility
├── screens/
│   ├── login_screen.dart  # Username entry and validation
│   ├── home_screen.dart   # Main navigation hub with menu for Privacy Policy
│   ├── spin_screen.dart   # Spin wheel game
│   ├── scratch_screen.dart # Scratch card game
│   ├── withdrawal_screen.dart # Points withdrawal screen
│   ├── reward_screen.dart   # Screen for earning rewards
│   └── privacy_policy_screen.dart # Displays privacy policy using markdown
├── widgets/
│   ├── spin_wheel.dart    # Custom spin wheel widget
│   ├── scratch_card.dart  # Custom scratch card widget
│   └── custom_button.dart # Reusable styled button
```

### Implementation Details

#### Ad Service Replacement
- **AdService Class**: Replaced with a stub implementation that provides the same method signatures but no actual ad functionality.
- The stub AdService implements all the original methods to maintain API compatibility with the rest of the app.
- For rewarded content, the stub directly triggers the reward callback without showing an ad.

#### UI Modifications
- Removed all native ad container displays from various screens.
- Removed ad-related imports, particularly `google_mobile_ads`.
- Simplified initState methods by removing ad loading code.
- Modified the reward system to directly grant points without showing ads.

#### HomeScreen Changes
- Removed tab change interstitial ad logic.
- Removed native ad display.
- Simplified UI by removing ad-related components.

#### Privacy Policy Updates
- Removed all references to AdMob and Google's ad policies.
- Updated third-party services section to reflect the removal of advertising.

### Technical Dependencies
- Removed `google_mobile_ads` package from dependencies.
- Retained other dependencies like `shared_preferences`, `provider`, etc.

### Security & Data Privacy
- All user data is stored locally on the device using shared_preferences.
- No personally identifiable information is collected.
- No third-party ad services are used, increasing privacy protection.
- Includes clear data deletion options through app settings.
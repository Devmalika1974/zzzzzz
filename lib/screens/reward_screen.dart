import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:dreamflow/models/user_model.dart';
import 'package:dreamflow/services/ad_service.dart';
import 'package:dreamflow/services/storage_service.dart';
import 'package:dreamflow/widgets/custom_button.dart';
import 'package:dreamflow/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class RewardScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;
  final AdService adService;

  const RewardScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.adService,
  });

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> with SingleTickerProviderStateMixin {
  late UserModel _currentUser;
  final StorageService _storageService = StorageService();
  bool _isLoadingAd = false;
  bool _gameRewardClaimed = false;
  bool _quizRewardClaimed = false;
  bool _ratingRewardClaimed = false; // New state for rating reward

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String _gameUrl = 'https://10342.play.gamezop.com/';
  static const String _quizUrl = 'https://10378.play.quizzop.com/';
  // Placeholder store URLs - REPLACE WITH ACTUAL IDS
  static const String _androidStoreUrl = 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';
  static const String _iosStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';


  @override
  void initState() {
    super.initState();
    _currentUser = widget.user.clone();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuart),
    );

    _animationController.forward();
    _checkRewardEligibility();
  }

  Future<void> _checkRewardEligibility() async {
    final now = DateTime.now();
    const twelveHours = Duration(hours: 12);

    setState(() {
      if (_currentUser.lastGameRewardClaimTime != null &&
          now.difference(_currentUser.lastGameRewardClaimTime!) < twelveHours) {
        _gameRewardClaimed = true;
      } else {
        _gameRewardClaimed = false;
      }

      if (_currentUser.lastQuizRewardClaimTime != null &&
          now.difference(_currentUser.lastQuizRewardClaimTime!) < twelveHours) {
        _quizRewardClaimed = true;
      } else {
        _quizRewardClaimed = false;
      }

      if (_currentUser.lastRatingRewardClaimTime != null &&
          now.difference(_currentUser.lastRatingRewardClaimTime!) < twelveHours) {
        _ratingRewardClaimed = true;
      } else {
        _ratingRewardClaimed = false;
      }
    });
  }


  @override
  void didUpdateWidget(RewardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      _currentUser = widget.user.clone();
      _checkRewardEligibility();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateUserBalance(int pointsToAdd, String rewardType) async {
    setState(() {
      _currentUser.balance += pointsToAdd;
    });
    await _storageService.saveUser(_currentUser);
    widget.onUserUpdated(_currentUser.clone());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Congratulations! You earned \$pointsToAdd points for \$rewardType.'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  
  void _watchAd() async {
    if (_isLoadingAd) return;
    setState(() => _isLoadingAd = true);

    if (kDebugMode) print('RewardScreen: Simulating rewarded ad with stub implementation');
    
    // Our stub implementation in AdService will directly call the callback
    widget.adService.showRewardedAd(
      onUserEarnedReward: (ad, reward) {
        // Directly award points without showing an ad
        const rewardAmount = 50; // Fixed reward amount
        if (kDebugMode) print('RewardScreen: User earned reward: $rewardAmount');
        _updateUserBalance(rewardAmount, 'watched_ad');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You earned $rewardAmount points!'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          setState(() => _isLoadingAd = false);
        }
      },
      onAdShowed: null,
      onAdDismissed: null,
      onAdFailedToShow: null,
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch \$url'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _claimGameReward() {
    if (_gameRewardClaimed) {
       if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game reward can only be claimed once every 12 hours.')),
        );
      }
      return;
    }
    _updateUserBalance(100, 'playing a game');
    setState(() {
      _gameRewardClaimed = true;
      _currentUser.lastGameRewardClaimTime = DateTime.now();
    });
    _storageService.saveUser(_currentUser); // Save updated claim time
  }

  void _claimQuizReward() {
    if (_quizRewardClaimed) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz reward can only be claimed once every 12 hours.')),
        );
      }
      return;
    }
    _updateUserBalance(100, 'playing a quiz');
    setState(() {
      _quizRewardClaimed = true;
      _currentUser.lastQuizRewardClaimTime = DateTime.now();
    });
    _storageService.saveUser(_currentUser); // Save updated claim time
  }

  void _rateApp() {
    String storeUrl = Platform.isAndroid ? _androidStoreUrl : _iosStoreUrl;
    // Replace placeholder URLs before production
    if (storeUrl.contains("YOUR_PACKAGE_NAME") || storeUrl.contains("YOUR_APP_ID")) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('App store link not configured yet.'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                ),
            );
        }
        return;
    }
    _launchURL(storeUrl);
  }

  void _claimRatingReward() {
    if (_ratingRewardClaimed) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating reward can only be claimed once every 12 hours.')),
        );
      }
      return;
    }
    _updateUserBalance(300, 'rating the app');
    setState(() {
      _ratingRewardClaimed = true;
      _currentUser.lastRatingRewardClaimTime = DateTime.now();
    });
    _storageService.saveUser(_currentUser); // Save updated claim time
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earn Rewards!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete tasks to get more points.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),
                _buildRewardCard(
                  context: context,
                  icon: Icons.movie_creation_outlined,
                  title: 'Watch Ad & Earn',
                  description: 'Watch a short video to earn 50 points.',
                  points: 50,
                  buttonText: _isLoadingAd ? 'Loading Ad...' : 'Watch Video',
                  onPressed: _isLoadingAd ? null : _watchAd,
                  isClaimed: false, 
                  buttonColor: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 20),
                _buildRewardCard(
                  context: context,
                  icon: Icons.sports_esports_outlined,
                  title: 'Play Game & Earn',
                  description: 'Play a fun game and claim 100 points.',
                  points: 100,
                  buttonText: 'Play Game',
                  onPressed: () => _launchURL(_gameUrl),
                  claimButtonText: 'Claim 100 Points',
                  onClaimPressed: _gameRewardClaimed ? null : _claimGameReward,
                  isClaimed: _gameRewardClaimed,
                  buttonColor: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 20),
                _buildRewardCard(
                  context: context,
                  icon: Icons.quiz_outlined,
                  title: 'Play Quiz & Earn',
                  description: 'Test your knowledge and claim 100 points.',
                  points: 100,
                  buttonText: 'Play Quiz',
                  onPressed: () => _launchURL(_quizUrl),
                  claimButtonText: 'Claim 100 Points',
                  onClaimPressed: _quizRewardClaimed ? null : _claimQuizReward,
                  isClaimed: _quizRewardClaimed,
                  buttonColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20), // Spacing for the new card
                _buildRewardCard(
                  context: context,
                  icon: Icons.star_outline,
                  title: 'Rate App & Earn',
                  description: 'Give us 5 stars and claim 300 points!',
                  points: 300,
                  buttonText: 'Rate App',
                  onPressed: _rateApp,
                  claimButtonText: 'Claim 300 Points',
                  onClaimPressed: _ratingRewardClaimed ? null : _claimRatingReward,
                  isClaimed: _ratingRewardClaimed,
                  buttonColor: Colors.amber, // A distinct color for rating
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required int points,
    required String buttonText,
    required VoidCallback? onPressed,
    String? claimButtonText,
    VoidCallback? onClaimPressed,
    required bool isClaimed,
    required Color buttonColor,
  }) {
    final theme = Theme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          gradient: LinearGradient(
            colors: isClaimed 
              ? [theme.colorScheme.surface.withOpacity(0.5), theme.colorScheme.surface.withOpacity(0.3)]
              : [buttonColor.withOpacity(isDark ? 0.25 : 0.1), theme.colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: isClaimed ? theme.colorScheme.onSurface.withOpacity(0.5) : buttonColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isClaimed ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Earn \$points Points',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isClaimed ? theme.colorScheme.onSurface.withOpacity(0.4) : buttonColor.withGreen(isDark ? 180 : 150).withBlue(isDark ? 100 : 50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isClaimed ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: buttonText,
              onPressed: isClaimed && claimButtonText == null ? (){} : onPressed ?? (){},
              isDisabled: (isClaimed && claimButtonText == null) || onPressed == null,
              icon: buttonText == "Watch Video" ? Icons.smart_display : 
                    (buttonText == "Play Game" ? Icons.sports_esports : 
                    (buttonText == "Play Quiz" ? Icons.quiz : Icons.star_rate)), // Added star icon for rate
              isSecondary: isClaimed && claimButtonText == null, // Only secondary if claimed AND no separate claim button
              height: 45,
            ),
            if (claimButtonText != null) ...[
              const SizedBox(height: 10),
              CustomButton(
                text: claimButtonText,
                onPressed: onClaimPressed ?? (){},
                isDisabled: onClaimPressed == null || isClaimed, // Disable if already claimed or no action
                icon: Icons.check_circle_outline,
                isSecondary: isClaimed || onClaimPressed == null,
                height: 45,
              ),
            ],
            if (isClaimed && claimButtonText != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade300, size: 18),
                    const SizedBox(width: 5),
                    Text('Reward Claimed!', style: theme.textTheme.labelMedium?.copyWith(color: Colors.green.shade400)),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

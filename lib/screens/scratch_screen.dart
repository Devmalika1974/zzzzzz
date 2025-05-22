import 'dart:math';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:flutter/material.dart';
import 'package:dreamflow/models/user_model.dart';
import 'package:dreamflow/services/ad_service.dart';
import 'package:dreamflow/widgets/scratch_card.dart'; // Contains ScratchCardTheme
import 'package:dreamflow/widgets/custom_button.dart';
import 'package:dreamflow/theme.dart'; // For theme colors

class ScratchScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;
  final AdService adService;

  const ScratchScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.adService,
  });

  @override
  State<ScratchScreen> createState() => _ScratchScreenState();
}

class _ScratchScreenState extends State<ScratchScreen> with TickerProviderStateMixin {
  late UserModel _user;
  int _rewardAmount = 0;
  bool _isScratchCompleted = false;
  bool _isNewCardReady = true;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Theme selection
  final List<ScratchCardTheme> _availableThemes = [
    ScratchCardTheme.defaultTheme,
    ScratchCardTheme.goldRush,
    ScratchCardTheme.spaceAdventure,
    ScratchCardTheme.oceanTreasure,
  ];
  late ScratchCardTheme _currentTheme;

  @override
  void initState() {
    super.initState(); // CRITICAL: Must be first
    _user = widget.user;
    // Initialize with the first theme or a random one if you prefer
    _currentTheme = _availableThemes[Random().nextInt(_availableThemes.length)]; 
    _generateRewardAmount();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Slide in from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutQuart,
    ));

    // Delay the animation start slightly for better visual effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  // Future<void> _loadInterstitialAd() async {
  //   if (kDebugMode) print('ScratchScreen: Loading Interstitial Ad...');
  //   await widget.adService.loadInterstitialAd();
  // }

  @override
  void didUpdateWidget(ScratchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      setState(() { // Ensure UI updates if user model changes externally
        _user = widget.user;
      });
    }
  }

  void _generateRewardAmount() {
    final Random random = Random();
    final int baseReward = random.nextInt(20) + 5; // 5-24 base
    
    if (random.nextDouble() < 0.1) { // 10% chance for a bonus reward
      _rewardAmount = baseReward * 5; // Bonus reward (25-120)
    } else {
      _rewardAmount = baseReward;
    }
  }

  void _handleScratchComplete() {
    if (_isScratchCompleted) return; // Prevent multiple triggers
    
    setState(() {
      _isScratchCompleted = true;
      _user.scratchCardsLeft--;
      _user.balance += _rewardAmount;
    });
    
    widget.onUserUpdated(_user.clone()); // Pass a cloned user to ensure state update
    
    // Show an interstitial ad after scratch completion
    widget.adService.showInterstitialAd();
  }

  void _prepareNewCard() {
    if (!mounted) return;
    setState(() {
      _isScratchCompleted = false;
      _isNewCardReady = false; // Show loading indicator
    });
    
    _slideController.reset(); // Reset animation for the new card
    
    // Short delay to reset card and generate new reward
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      _generateRewardAmount();
      // Select a new random theme for the next card, different from the current one
      final Random random = Random();
      ScratchCardTheme newTheme = _currentTheme;
      if (_availableThemes.length > 1) {
        while (newTheme == _currentTheme) {
          newTheme = _availableThemes[random.nextInt(_availableThemes.length)];
        }
      }
      _currentTheme = newTheme;

      setState(() {
        _isNewCardReady = true; // Make new card visible
      });
      _slideController.forward(); // Animate new card in
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.surface.withOpacity(0.8), colorScheme.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Daily card counter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.style, // Changed icon for variety
                  color: colorScheme.onPrimary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'Cards Left: ${_user.scratchCardsLeft} / 1',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Scratch card area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_user.scratchCardsLeft > 0 && !_isScratchCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Scratch to Win!',
                        style: theme.textTheme.headlineSmall!.copyWith(color: colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  if (_user.scratchCardsLeft == 0 && !_isScratchCompleted)
                     Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'No cards left for today!\nCome back tomorrow.',
                        style: theme.textTheme.titleLarge!.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  if (_isScratchCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        '🎉 You Won! 🎉',
                        style: theme.textTheme.headlineSmall!.copyWith(
                          color: colorScheme.tertiary,
                           fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (_isNewCardReady)
                    SlideTransition(
                      position: _slideAnimation,
                      child: ScratchCard(
                        rewardAmount: _rewardAmount,
                        onScratchComplete: _handleScratchComplete,
                        isAvailable: _user.scratchCardsLeft > 0 && !_isScratchCompleted,
                        theme: _currentTheme,
                      ),
                    )
                  else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
          
          // Action button
          if (_isScratchCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: CustomButton(
                text: _user.scratchCardsLeft > 0
                    ? 'Next Card!'
                    : 'All Done!',
                icon: _user.scratchCardsLeft > 0
                    ? Icons.skip_next_rounded
                    : Icons.celebration_rounded,
                onPressed: _user.scratchCardsLeft > 0
                    ? _prepareNewCard
                    : () { // If no cards left, but was completed, just reset view
                        if (mounted) {
                          setState(() { _isScratchCompleted = false; });
                        }
                      },
                isSecondary: _user.scratchCardsLeft == 0,
              ),
            ),
          
          // Helper text
          if (!_isScratchCompleted && _user.scratchCardsLeft > 0)
             Padding(
              padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Rub the card to reveal your prize.',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

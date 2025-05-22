import 'dart:math';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:flutter/material.dart';
import 'package:dreamflow/models/user_model.dart';
import 'package:dreamflow/services/ad_service.dart';
import 'package:dreamflow/widgets/spin_wheel.dart';
import 'package:dreamflow/widgets/custom_button.dart';

class SpinScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;
  final AdService adService;

  const SpinScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.adService,
  });

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> with SingleTickerProviderStateMixin {
  late UserModel _user;
  SpinWheelItem? _lastWin;
  bool _isRewarded = false;
  late AnimationController _confettiController;
  late List<SpinWheelItem> _spinItems;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _initializeSpinItems();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  // Future<void> _loadInterstitialAd() async {
  //   if (kDebugMode) print('SpinScreen: Loading Interstitial Ad...');
  //   await widget.adService.loadInterstitialAd();
  // }

  void _initializeSpinItems() {
    // ... (rest of the method remains the same)
    _spinItems = [
      SpinWheelItem(label: '10', icon: Icons.monetization_on, color: Colors.green.shade300, value: 10, weight: 20),
      SpinWheelItem(label: '0', icon: Icons.refresh, color: Colors.grey.shade400, value: 0, weight: 30),
      SpinWheelItem(label: '25', icon: Icons.monetization_on, color: Colors.blue.shade300, value: 25, weight: 15),
      SpinWheelItem(label: '50', icon: Icons.monetization_on, color: Colors.purple.shade300, value: 50, weight: 10),
      SpinWheelItem(label: '5', icon: Icons.monetization_on, color: Colors.orange.shade300, value: 5, weight: 25),
      SpinWheelItem(label: '100', icon: Icons.star, color: Colors.yellow.shade600, value: 100, weight: 5),
    ];
  }

  @override
  void didUpdateWidget(SpinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _user = widget.user;
    }
  }

  void _handleSpinResult(SpinWheelItem item) {
    setState(() {
      _lastWin = item;
      _user.spinsLeft--;
      _user.balance += item.value;
      _isRewarded = true;
    });

    _confettiController.forward(from: 0.0);
    widget.onUserUpdated(_user);

    // Show an interstitial ad after every 2 spins
    if (_user.spinsLeft % 2 == 0) {
      widget.adService.showInterstitialAd();
    }
  }

  void _claimReward() {
    setState(() {
      _isRewarded = false;
      _lastWin = null;
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _isRewarded && _lastWin != null
                  ? _buildRewardScreen()
                  : _buildSpinScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        _buildSpinCounterBanner(),
        const SizedBox(height: 20),
        
        // Spin wheel
        SpinWheel(
          items: _spinItems,
          onSpinEnd: _handleSpinResult,
          canSpin: _user.spinsLeft > 0,
        ),
        
        const SizedBox(height: 20),
        
        // Instructions text
        if (_user.spinsLeft > 0)
          Text(
            'Spin the wheel to win rewards!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          )
        else
          Text(
            'You\'ve used all your spins for today.\nCome back tomorrow for more!',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildRewardScreen() {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Confetti animation
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              painter: ConfettiPainter(
                progress: _confettiController.value,
              ),
              child: Container(
                width: double.infinity,
                height: 200,
              ),
            );
          },
        ),
        
        // Reward card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _lastWin!.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _lastWin!.color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events,
                color: _lastWin!.color,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations!',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You won',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: _lastWin!.color,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_lastWin!.value}',
                    style: theme.textTheme.headlineLarge!.copyWith(
                      color: _lastWin!.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your new balance: ${_user.balance}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Claim Reward',
                icon: Icons.check_circle_outline,
                onPressed: _claimReward,
              ),
              const SizedBox(height: 8),
              Text(
                'You have ${_user.spinsLeft} spins left today',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpinCounterBanner() {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh_rounded,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            'Spins remaining: ${_user.spinsLeft} / 3',
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random random = Random();
  final List<Color> confettiColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
  ];

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final confettiCount = 100;
    final paint = Paint();

    for (int i = 0; i < confettiCount; i++) {
      // Each confetti has a slightly different start time for staggered effect
      final delay = i % 10 * 0.1;
      final adjustedProgress = (progress - delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      // Generate random position and color for each confetti piece
      final x = random.nextDouble() * size.width;
      final initialY = -20.0;
      final color = confettiColors[random.nextInt(confettiColors.length)];

      // Calculate current y position based on progress (falling effect)
      final y = initialY + (size.height + 40) * adjustedProgress;

      // Draw confetti
      paint.color = color;
      final confettiSize = 3.0 + random.nextDouble() * 4.0;
      final shape = random.nextInt(3);

      // Different shapes for variety
      if (shape == 0) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: confettiSize, height: confettiSize * 2),
          paint,
        );
      } else if (shape == 1) {
        // Circle
        canvas.drawCircle(Offset(x, y), confettiSize / 2, paint);
      } else {
        // Triangle
        final path = Path();
        path.moveTo(x, y - confettiSize);
        path.lineTo(x + confettiSize, y + confettiSize);
        path.lineTo(x - confettiSize, y + confettiSize);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
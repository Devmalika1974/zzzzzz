import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'dart:math';
import 'package:dreamflow/theme.dart'; // Assuming theme.dart exists for colors
 // For themed images

enum ScratchCardTheme {
  defaultTheme,
  goldRush,
  spaceAdventure,
  oceanTreasure,
}

class ScratchCard extends StatefulWidget {
  final int rewardAmount;
  final VoidCallback onScratchComplete;
  final bool isAvailable;
  final ScratchCardTheme theme;

  const ScratchCard({
    super.key,
    required this.rewardAmount,
    required this.onScratchComplete,
    this.isAvailable = true,
    this.theme = ScratchCardTheme.defaultTheme,
  });

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard> with TickerProviderStateMixin {
  final scratchKey = GlobalKey<ScratcherState>();
  double _scratchProgress = 0;
  bool _isRevealed = false;
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.linear),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );

    if (widget.isAvailable) {
      _bounceController.forward().then((_) => _bounceController.reverse());
    }
  }

  @override
  void didUpdateWidget(covariant ScratchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAvailable && !oldWidget.isAvailable) {
      scratchKey.currentState?.reset();
      setState(() {
        _scratchProgress = 0;
        _isRevealed = false;
      });
      _bounceController.forward().then((_) => _bounceController.reverse());
    }
    if (widget.theme != oldWidget.theme) {
       scratchKey.currentState?.reset();
       setState(() {
        _scratchProgress = 0;
        _isRevealed = false;
      });
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onScratchComplete() {
    if (!_isRevealed) {
      setState(() {
        _isRevealed = true;
      });
      widget.onScratchComplete();
      _bounceController.forward().then((_) => _bounceController.reverse());
    }
  }

  Widget _buildForegroundLayer(BuildContext context, ScratchCardTheme currentTheme) {
    final colors = Theme.of(context).colorScheme;
    switch (currentTheme) {
      case ScratchCardTheme.goldRush:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.yellow[600]!, Colors.yellow[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.star, color: Colors.white.withOpacity(0.7), size: 100),
          ),
        );
      case ScratchCardTheme.spaceAdventure:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.indigo[700]!, Colors.purple[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
             boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.rocket_launch, color: Colors.white.withOpacity(0.7), size: 100),
          ),
        );
      case ScratchCardTheme.oceanTreasure:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.teal[400]!, Colors.cyan[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
             boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.anchor, color: Colors.white.withOpacity(0.7), size: 100),
          ),
        );
      case ScratchCardTheme.defaultTheme:
      default:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [colors.secondary, colors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _shineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _shineAnimation.value * 200, // Adjust width of shine effect
                  top: 0,
                  bottom: 0,
                  width: 100, // Width of the shine
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
            Text(
              'SCRATCH HERE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.onPrimary,
                letterSpacing: 2,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBackgroundLayer(BuildContext context, ScratchCardTheme currentTheme) {
    final colors = Theme.of(context).colorScheme;
    String imageUrl;
    IconData iconData;
    Color iconColor;

    switch (currentTheme) {
      case ScratchCardTheme.goldRush:
        imageUrl = "https://pixabay.com/get/g0cb0fc666c97106182b0d261d4e37ad40eb5a3ddd4d2bd7dc416e6765a8441d4a61b429c02d24cc12b117b927b5ac55d26fa3858d1265c38f15e7b2ffd193b0b_1280.jpg";
        iconData = Icons.monetization_on;
        iconColor = Colors.amber;
        break;
      case ScratchCardTheme.spaceAdventure:
        imageUrl = "https://pixabay.com/get/g1e01ee9244156e6a88a47e1d3225cc009c37f9ed87065e35f4d23e3e23907e0afb6c4d2d42787244e67792a7e27d1eb5f9365a5e845b089900497ed91ee9da1b_1280.jpg";
        iconData = Icons.public;
        iconColor = Colors.lightBlueAccent;
        break;
      case ScratchCardTheme.oceanTreasure:
        imageUrl = "https://pixabay.com/get/gab1f0b4076d0d57035a99dc5d7635f80373fb25d046b2f1a86e6d40c2554247ae22e9deb5e82f45a3130d3dc230f0bff5e96631e28ad489ff15964a203f3dbcb_1280.jpg";
        iconData = Icons.ac_unit; // Placeholder, ideally a treasure chest icon
        iconColor = Colors.cyanAccent;
        break;
      case ScratchCardTheme.defaultTheme:
      default:
        imageUrl = "https://pixabay.com/get/g90cc03cfdaa096a6fd2e33237034a6be70a6b8ebe0f6ad1e1569828cf00748b7a4211ad8265fbc51d37e4ad12237e2861f4e5e1478c2cbf0316ede27a2d74708_1280.jpg";
        iconData = Icons.card_giftcard;
        iconColor = colors.tertiary;
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 80, color: iconColor),
            const SizedBox(height: 16),
            Text(
              'You Won!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.rewardAmount} Points',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardWidth = MediaQuery.of(context).size.width * 0.8;
    final cardHeight = cardWidth * 0.6; // Maintain aspect ratio

    return ScaleTransition(
      scale: _bounceAnimation,
      child: Opacity(
        opacity: widget.isAvailable ? 1.0 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.isAvailable,
          child: Scratcher(
            key: scratchKey,
            brushSize: 50,
            threshold: 50,
            accuracy: ScratchAccuracy.medium,
            color: Colors.transparent, // Handled by foreground layer
            onChange: (value) {
              setState(() {
                _scratchProgress = value;
              });
            },
            onThreshold: _onScratchComplete,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: _isRevealed ? colors.primary.withOpacity(0.5) : colors.outline,
                    width: 2),
              ),
              child: _isRevealed || _scratchProgress > 50
                  ? _buildBackgroundLayer(context, widget.theme)
                  : _buildForegroundLayer(context, widget.theme),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

class SpinWheel extends StatefulWidget {
  final List<SpinWheelItem> items;
  final Function(SpinWheelItem) onSpinEnd;
  final bool canSpin;

  const SpinWheel({
    super.key,
    required this.items,
    required this.onSpinEnd,
    this.canSpin = true,
  });

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel> with SingleTickerProviderStateMixin {
  StreamController<int> selected = StreamController<int>();
  bool isSpinning = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    selected.close();
    _animationController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (!widget.canSpin || isSpinning) return;

    setState(() {
      isSpinning = true;
    });

    // Animate button scale
    _animationController.forward().then((_) => _animationController.reverse());

    // Randomly select an item based on its weight
    int selectedIndex = _getWeightedRandomIndex();
    selected.add(selectedIndex);

    // Play haptic feedback for added engagement
    // HapticFeedback.heavyImpact(); // Uncomment when using services package

    // Schedule a callback for when the spin ends
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        isSpinning = false;
      });
      widget.onSpinEnd(widget.items[selectedIndex]);
    });
  }

  int _getWeightedRandomIndex() {
    // Calculate total weight
    int totalWeight = widget.items.fold(0, (sum, item) => sum + item.weight);
    
    // Generate a random number between 0 and total weight
    int randomValue = Random().nextInt(totalWeight);
    
    // Find the item that corresponds to the random value
    int currentWeight = 0;
    for (int i = 0; i < widget.items.length; i++) {
      currentWeight += widget.items[i].weight;
      if (randomValue < currentWeight) {
        return i;
      }
    }
    
    // Default to the last item (shouldn't happen with proper weights)
    return widget.items.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(children: [
      Container(
        height: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fortune wheel
            FortuneWheel(
              selected: selected.stream,
              animateFirst: false,
              duration: const Duration(seconds: 3),
              curve: Curves.elasticOut,
              physics: CircularPanPhysics(
                duration: const Duration(seconds: 1),
                curve: Curves.decelerate,
              ),
              items: widget.items.map((item) {
                return FortuneItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        RotatedBox(
                          quarterTurns: 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.label,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: FortuneItemStyle(
                    color: item.color,
                    borderWidth: 1,
                    borderColor: Colors.white30,
                    textAlign: TextAlign.start,
                  ),
                );
              }).toList(),
            ),

            // Center button to spin
            GestureDetector(
              onTap: widget.canSpin && !isSpinning ? _spinWheel : null,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondary,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.secondary.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.onSecondary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),
      
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isSpinning
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Spinning...',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              )
            : Text(
                widget.canSpin ? 'Tap to Spin!' : 'No spins left today',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: widget.canSpin
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    ]);
  }
}

class SpinWheelItem {
  final String label;
  final IconData icon;
  final Color color;
  final int value;
  final int weight; // Higher weight = higher chance of landing

  const SpinWheelItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    this.weight = 1,
  });
}
import 'package:flutter/material.dart';
import 'package:dreamflow/models/user_model.dart';
import 'package:dreamflow/screens/spin_screen.dart';
import 'package:dreamflow/screens/scratch_screen.dart';
import 'package:dreamflow/screens/withdrawal_screen.dart';
import 'package:dreamflow/screens/reward_screen.dart';
import 'package:dreamflow/services/storage_service.dart';
import 'package:dreamflow/services/ad_service.dart';
import 'package:dreamflow/screens/privacy_policy_screen.dart';
import 'package:dreamflow/widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel?) onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late UserModel _user;
  final StorageService _storageService = StorageService();
  final AdService _adService = AdService();
  late TabController _tabController;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isAnimating = false;
  int _previousTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _initializeAnimations();
    _initializeTabController();
    _previousTabIndex = _tabController.index; // Initialize previous tab index
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.9),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.1),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticIn,
    ));
  }

  void _initializeTabController() {
    _tabController = TabController(length: 4, vsync: this); // Increased length to 4
    _tabController.addListener(() {
      _previousTabIndex = _tabController.index; // Update previous tab index
    });
  }

  // void _loadNativeAd() {
  //   _nativeAd = NativeAd(
  //     adUnitId: AdService.nativeAdUnitId,
  //     factoryId: 'listTile',
  //     listener: NativeAdListener(
  //       onAdLoaded: (ad) {
  //         setState(() {
  //           _isNativeAdLoaded = true;
  //         });
  //       },
  //       onAdFailedToLoad: (ad, error) {
  //         ad.dispose();
  //         debugPrint('Native Ad failed to load: \${error.message}');
  //       },
  //     ),
  //     request: const AdRequest(),
  //   )..load();
  // }

  void _animateBalance() {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      _animationController.reset();
      setState(() {
        _isAnimating = false;
      });
    });
  }

  Future<void> _updateUser(UserModel updatedUser) async {
    _user = updatedUser;
    _animateBalance();
    await _storageService.saveUser(_user);
    setState(() {});
  }

  Future<void> _handleLogout() async {
    _showConfirmationDialog(
      title: 'Logout',
      content: 'Are you sure you want to logout? Your data will be saved.',
      confirmText: 'Logout',
      onConfirm: () {
        // Show interstitial ad on logout
        _adService.showInterstitialAd();
        widget.onLogout(null);
      },
    );
  }

  Future<void> _handleResetData() async {
    _showConfirmationDialog(
      title: 'Reset Data',
      content: 'Are you sure you want to reset all your data? This cannot be undone.',
      confirmText: 'Reset',
      isDestructive: true,
      onConfirm: () async {
        await _storageService.deleteUser(_user.username);
        // Show interstitial ad after reset
        _adService.showInterstitialAd();
        widget.onLogout(null);
      },
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.casino_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'RoSpins',
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface,
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'reset') {
                _handleResetData();
              } else if (value == 'privacy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reset Data',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined),
                    SizedBox(width: 8),
                    Text('Privacy Policy'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.casino),
              text: 'Spin Wheel',
            ),
            Tab(
              icon: Icon(Icons.credit_card),
              text: 'Scratch Cards',
            ),
            Tab(
              icon: Icon(Icons.star_outline_rounded),
              text: 'Rewards',
            ),
            Tab(
              icon: Icon(Icons.send_to_mobile_rounded),
              text: 'Withdraw',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // User info and stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    _user.username.substring(0, 1).toUpperCase(),
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${_user.username}',
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Daily limits reset at midnight',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Balance
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, 
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.secondary.withOpacity(0.3),
                                blurRadius: _isAnimating ? 10 : 0,
                                spreadRadius: _isAnimating ? 1 : 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: theme.colorScheme.onSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _user.balance.toString(),
                                style: theme.textTheme.titleMedium!.copyWith(
                                  color: theme.colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Games counter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildGameCounter(
                    icon: Icons.casino,
                    label: 'Spins Left',
                    count: _user.spinsLeft,
                    total: 3,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGameCounter(
                    icon: Icons.credit_card,
                    label: 'Scratch Cards',
                    count: _user.scratchCardsLeft,
                    total: 1,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),

          // Spacing element
          const SizedBox(height: 8),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Spin Wheel Tab
                SpinScreen(
                  user: _user,
                  onUserUpdated: _updateUser,
                  adService: _adService,
                ),

                // Scratch Card Tab
                ScratchScreen(
                  user: _user,
                  onUserUpdated: _updateUser,
                  adService: _adService,
                ),

                // Reward Screen Tab
                RewardScreen(
                  user: _user,
                  onUserUpdated: _updateUser,
                  adService: _adService,
                ),

                // Withdrawal Tab
                WithdrawalScreen(
                  user: _user,
                  onUserUpdated: _updateUser,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCounter({
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: count / total,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count/$total',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
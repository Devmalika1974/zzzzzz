import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dreamflow/models/user_model.dart';
import 'package:dreamflow/services/storage_service.dart';
import 'package:dreamflow/widgets/custom_button.dart';
import 'package:dreamflow/theme.dart';
import 'package:dreamflow/services/ad_service.dart';

class WithdrawalScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const WithdrawalScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _recipientUsernameController = TextEditingController();
  final _amountController = TextEditingController();
  final StorageService _storageService = StorageService();

  late UserModel _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const int _withdrawalThreshold = 1500;

  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _recipientUsernameController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Future<void> _loadNativeAd() async {
  //   _nativeAd = NativeAd(
  //     adUnitId: AdService.nativeAdUnitId,
  //     factoryId: 'listTile', 
  //     request: const AdRequest(),
  //     listener: NativeAdListener(
  //       onAdLoaded: (Ad ad) {
  //         setState(() {
  //           _isNativeAdLoaded = true;
  //         });
  //       },
  //       onAdFailedToLoad: (Ad ad, LoadAdError error) {
  //         ad.dispose();
  //         debugPrint('Native ad failed to load: $error');
  //       },
  //     ),
  //   );
  //   await _nativeAd?.load();
  // }
  
  Future<void> _handleWithdrawal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final recipientUsername = _recipientUsernameController.text.trim();
    final amount = int.tryParse(_amountController.text);

    if (amount == null) {
      setState(() {
        _errorMessage = 'Invalid amount.';
        _isLoading = false;
      });
      return;
    }

    if (recipientUsername == _currentUser.username) {
      setState(() {
        _errorMessage = 'You cannot send points to yourself.';
        _isLoading = false;
      });
      return;
    }

    final recipientExists = await _storageService.userExists(recipientUsername);
    if (!recipientExists) {
      setState(() {
        _errorMessage = 'Recipient username does not exist.';
        _isLoading = false;
      });
      return;
    }

    if (_currentUser.balance < _withdrawalThreshold) {
       setState(() {
        _errorMessage = 'You need at least $_withdrawalThreshold points to make a withdrawal.';
        _isLoading = false;
      });
      return;
    }
    
    if (amount <= 0) {
       setState(() {
        _errorMessage = 'Amount must be positive.';
        _isLoading = false;
      });
      return;
    }

    if (amount > _currentUser.balance) {
      setState(() {
        _errorMessage = 'Insufficient balance.';
        _isLoading = false;
      });
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Withdrawal',
      content: 'Are you sure you want to send $amount points to $recipientUsername?',
      confirmText: 'Send',
    );

    if (!confirmed) {
      setState(() => _isLoading = false);
      return;
    }


    try {
      UserModel? recipientUser = await _storageService.getUser(recipientUsername);
      if (recipientUser == null) { // Should not happen due to userExists check, but good practice
        setState(() {
          _errorMessage = 'Failed to retrieve recipient data.';
          _isLoading = false;
        });
        return;
      }

      // Perform transaction
      _currentUser.balance -= amount;
      recipientUser.balance += amount;

      // Save both users
      await _storageService.saveUser(_currentUser);
      await _storageService.saveUser(recipientUser);

      widget.onUserUpdated(_currentUser); // Update user in HomeScreen

      setState(() {
        _successMessage = '$amount points sent successfully to $recipientUsername!';
        _recipientUsernameController.clear();
        _amountController.clear();
        _isLoading = false;
      });
       _animationController.forward(from:0); // Re-run animation for success message
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              content: Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(confirmText, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canWithdraw = _currentUser.balance >= _withdrawalThreshold;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.send_rounded, size: 80, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Withdraw Points',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send points to another RoSpins user.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5))
                    ),
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your Balance:', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          Text(
                            '${_currentUser.balance} Points',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
               if (!canWithdraw)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.5))
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: theme.colorScheme.tertiary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You need at least $_withdrawalThreshold points to make a withdrawal.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),_buildNativeAdContainer(),
              const SizedBox(height: 24),
              if (canWithdraw) ...[
                _buildTextField(
                  controller: _recipientUsernameController,
                  labelText: 'Recipient Username',
                  hintText: 'Enter recipient\'s username',
                  icon: Icons.person_search_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username.';
                    }
                    if (value.trim().length < 3 || value.trim().length > 20) {
                      return 'Username must be 3-20 characters.';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
                       return 'Only alphanumeric characters allowed.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _amountController,
                  labelText: 'Amount to Send',
                  hintText: 'Enter amount',
                  icon: Icons.monetization_on_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount.';
                    }
                    final amount = int.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Amount must be a positive number.';
                    }
                    if (amount > _currentUser.balance) {
                      return 'Insufficient balance.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: theme.colorScheme.onSecondaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                CustomButton(
                  text: _isLoading ? 'Sending...' : 'Send Points',
                  onPressed: _isLoading || !canWithdraw ? () {} : _handleWithdrawal,
                  isDisabled: _isLoading || !canWithdraw,
                  icon: Icons.send_to_mobile_rounded,
                  width: double.infinity,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativeAdContainer() {
    // Removed ad widget, return empty space with the same margin
    return const SizedBox(height: 16);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.8)),
            labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onTap: () {
             setState(() {
              _errorMessage = null;
              _successMessage = null;
            });
          }
        ),
      ),
    );
  }
}

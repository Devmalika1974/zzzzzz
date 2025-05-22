import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dreamflow/models/user_model.dart';
import 'package:dreamflow/services/storage_service.dart';
import 'package:dreamflow/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserModel) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _storageService = StorageService();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  List<String> _recentUsernames = [];
  bool _showRecentUsers = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _loadRecentUsers();
  }

  Future<void> _loadRecentUsers() async {
    final usernames = await _storageService.getAllUsernames();
    if (mounted) {
      setState(() {
        _recentUsernames = usernames;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Username validation
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    final RegExp alphanumericRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null; // Valid username
  }

  Future<void> _handleLogin() async {
    // Clear any previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      try {
        final username = _usernameController.text.trim();
        
        // Check if user exists
        final existingUser = await _storageService.getUser(username);
        
        // Create new user or use existing one
        final user = existingUser ?? UserModel(username: username);
        
        // Check if daily limits need to be reset
        if (user.shouldResetDailyLimits()) {
          user.resetDailyLimits();
        }
        
        // Save user to storage
        await _storageService.saveUser(user);
        
        // Notify parent widget that login was successful
        widget.onLogin(user);
        
        // Add a slight delay to show loading state for better UX
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _selectRecentUser(String username) {
    _usernameController.text = username;
    setState(() {
      _showRecentUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: 400,
                        minHeight: size.height * 0.5,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.casino_outlined,
                                color: theme.colorScheme.onPrimary,
                                size: 60,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // App title
                          Text(
                            'RoSpins',
                            style: theme.textTheme.headlineLarge!.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          Text(
                            'Spin & Scratch Game',
                            style: theme.textTheme.titleMedium!.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Username',
                                  style: theme.textTheme.labelLarge!.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  children: [
                                    TextFormField(
                                      controller: _usernameController,
                                      validator: _validateUsername,
                                      onTap: () {
                                        if (_recentUsernames.isNotEmpty) {
                                          setState(() {
                                            _showRecentUsers = true;
                                          });
                                        }
                                      },
                                      onChanged: (_) {
                                        if (_showRecentUsers) {
                                          setState(() {
                                            _showRecentUsers = false;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter your username',
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: theme.colorScheme.primary,
                                        ),
                                        suffixIcon: _usernameController.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear,
                                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                ),
                                                onPressed: () {
                                                  _usernameController.clear();
                                                },
                                              )
                                            : null,
                                        filled: true,
                                        fillColor: theme.colorScheme.onPrimary,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.outline.withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ),
                                      inputFormatters: [
                                        // Allow only alphanumeric characters and underscore
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _handleLogin(),
                                    ),
                                    if (_showRecentUsers && _recentUsernames.isNotEmpty)
                                      Positioned(
                                        top: 60,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 10,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            padding: EdgeInsets.zero,
                                            itemCount: _recentUsernames.length,
                                            itemBuilder: (context, index) {
                                              final username = _recentUsernames[index];
                                              return ListTile(
                                                leading: Icon(
                                                  Icons.history,
                                                  color: theme.colorScheme.primary.withOpacity(0.7),
                                                ),
                                                title: Text(username),
                                                onTap: () => _selectRecentUser(username),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Error message
                          if (_errorMessage != null) ...[  
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Login button
                          CustomButton(
                            text: 'Start Playing',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _isLoading ? () {} : _handleLogin,
                            isDisabled: _isLoading,
                          ),
                          
                          // Loading indicator
                          if (_isLoading) ...[  
                            const SizedBox(height: 20),
                            const CircularProgressIndicator(),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Info text
                          Text(
                            'Only username is needed. No password required.',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
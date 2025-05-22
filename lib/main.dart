

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:dreamflow/models/user_model.dart';
import 'package:dreamflow/screens/login_screen.dart';
import 'package:dreamflow/screens/home_screen.dart';
import 'package:dreamflow/services/ad_service.dart';
import 'theme.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AdService _adService = AdService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize the ad service (empty implementation now)
    _adService.initialize();
  }

  void _handleLogin(UserModel user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _handleLogout(UserModel? user) {
    setState(() {
      _currentUser = user;
    });
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AdService>.value(
      value: _adService,
      child: MaterialApp(
        title: 'RoSpins',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: _currentUser == null
            ? LoginScreen(onLogin: _handleLogin)
            : HomeScreen(
                user: _currentUser!,
                onLogout: _handleLogout,
              ),
      ),
    );
  }
}
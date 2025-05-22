import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dreamflow/models/user_model.dart';

class StorageService {
  static const String _userPrefix = 'user_';
  
  // Save user data
  Future<bool> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(user.username);
      final userData = jsonEncode(user.toJson());
      return await prefs.setString(key, userData);
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Get user data by username
  Future<UserModel?> getUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(username);
      final userData = prefs.getString(key);
      
      if (userData == null) {
        return null;
      }
      
      final userJson = jsonDecode(userData) as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);
      
      // Check if daily limits should be reset
      if (user.shouldResetDailyLimits()) {
        user.resetDailyLimits();
        await saveUser(user);
      }
      
      return user;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Delete user data
  Future<bool> deleteUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(username);
      return await prefs.remove(key);
    } catch (e) {
      print('Error deleting user data: $e');
      return false;
    }
  }

  // Check if user exists
  Future<bool> userExists(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(username);
      return prefs.containsKey(key);
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Get all usernames stored in the app
  Future<List<String>> getAllUsernames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_userPrefix))
          .map((key) => key.substring(_userPrefix.length))
          .toList();
    } catch (e) {
      print('Error getting all usernames: $e');
      return [];
    }
  }

  // Helper method to generate user key
  String _getUserKey(String username) {
    return '$_userPrefix$username';
  }
}
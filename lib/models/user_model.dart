class UserModel {
  final String username;
  int balance;
  int spinsLeft;
  int scratchCardsLeft;
  DateTime lastResetTimestamp;
  DateTime? lastGameRewardClaimTime;
  DateTime? lastQuizRewardClaimTime;
  DateTime? lastRatingRewardClaimTime;

  UserModel({
    required this.username,
    this.balance = 0,
    this.spinsLeft = 3,
    this.scratchCardsLeft = 1,
    DateTime? lastResetTimestamp,
    this.lastGameRewardClaimTime,
    this.lastQuizRewardClaimTime,
    this.lastRatingRewardClaimTime,
  }) : lastResetTimestamp = lastResetTimestamp ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String,
      balance: json['balance'] as int,
      spinsLeft: json['spinsLeft'] as int,
      scratchCardsLeft: json['scratchCardsLeft'] as int,
      lastResetTimestamp: DateTime.parse(json['lastResetTimestamp'] as String),
      lastGameRewardClaimTime: json['lastGameRewardClaimTime'] != null
          ? DateTime.parse(json['lastGameRewardClaimTime'])
          : null,
      lastQuizRewardClaimTime: json['lastQuizRewardClaimTime'] != null
          ? DateTime.parse(json['lastQuizRewardClaimTime'])
          : null,
      lastRatingRewardClaimTime: json['lastRatingRewardClaimTime'] != null
          ? DateTime.parse(json['lastRatingRewardClaimTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'balance': balance,
      'spinsLeft': spinsLeft,
      'scratchCardsLeft': scratchCardsLeft,
      'lastResetTimestamp': lastResetTimestamp.toIso8601String(),
      'lastGameRewardClaimTime': lastGameRewardClaimTime?.toIso8601String(),
      'lastQuizRewardClaimTime': lastQuizRewardClaimTime?.toIso8601String(),
      'lastRatingRewardClaimTime': lastRatingRewardClaimTime?.toIso8601String(),
    };
  }

  // Check if daily limits need to be reset
  bool shouldResetDailyLimits() {
    final now = DateTime.now();
    final lastMidnight = DateTime(lastResetTimestamp.year, 
        lastResetTimestamp.month, lastResetTimestamp.day);
    final currentMidnight = DateTime(now.year, now.month, now.day);
    
    return currentMidnight.isAfter(lastMidnight);
  }

  // Reset daily limits
  void resetDailyLimits() {
    spinsLeft = 3;
    scratchCardsLeft = 1;
    lastResetTimestamp = DateTime.now();
  }

  // Clone the user model (useful for state management)
  UserModel clone() {
    return UserModel(
      username: username,
      balance: balance,
      spinsLeft: spinsLeft,
      scratchCardsLeft: scratchCardsLeft,
      lastResetTimestamp: lastResetTimestamp,
      lastGameRewardClaimTime: lastGameRewardClaimTime,
      lastQuizRewardClaimTime: lastQuizRewardClaimTime,
      lastRatingRewardClaimTime: lastRatingRewardClaimTime,
    );
  }
}
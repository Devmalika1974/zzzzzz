import 'package:flutter/material.dart';
import 'package:dreamflow/theme.dart';
import 'package:markdown/markdown.dart' as md;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String policyText = """
**Privacy Policy for RoSpins**

**Last Updated: {{CURRENT_DATE}}**

Welcome to RoSpins! This Privacy Policy explains how we handle your information when you use our mobile application ("App"). Your privacy is important to us. By using RoSpins, you agree to the collection and use of information in accordance with this policy.

**1. Information We Collect**

RoSpins is designed to minimize data collection. We only collect and store the following information locally on your device using shared_preferences:

*   **Username:** The alphanumeric identifier (3-20 characters) you choose to identify yourself within the App. This is not linked to any personal online accounts.
*   **Game Data:** This includes your virtual currency balance, number of spins left, number of scratch cards left, and timestamps related to daily game resets and reward claims. This data is solely for the functioning of the game mechanics.

We DO NOT collect any personally identifiable information (PII) such as your real name, email address, phone number, location, or device identifiers that can be used to track you outside of the App.

**2. How We Use Information**

The information collected is used exclusively for the following purposes:

*   **To Provide and Maintain the App:** Your username and game data are essential for saving your progress, managing daily limits, and enabling game features like spins, scratches, and withdrawals.
*   **To Personalize Your Experience:** Your username is used to identify your local game profile.
*   **To Manage Game Mechanics:** Timestamps are used to reset daily spin/scratch limits and reward eligibility.

**3. Data Storage and Security**

All collected information (username and game data) is stored locally on your device using Flutter's `shared_preferences` plugin. This data is not transmitted to or stored on any external servers.

*   **Local Storage:** Since data is stored on your device, its security is tied to the security of your device. We recommend you secure your device appropriately (e.g., with a passcode, biometric authentication).
*   **Data Deletion:** You can delete your local game data associated with a username through the "Reset Data" option in the App's settings on the Home Screen. Clearing the app's cache or uninstalling the app will also remove this data.

**4. Third-Party Services**

RoSpins uses the following third-party services:

*   **External Game and Quiz Links (Gamezop, Quizzop):** The "Rewarded" section of our App may provide links to external game (Gamezop) and quiz (Quizzop) websites. When you click these links, you will be directed to third-party sites. These sites have their own privacy policies, and we encourage you to review them. We are not responsible for the content or privacy practices of these external sites. We do not share your RoSpins username or game data with these services.
*   **App Store Links (Google Play Store, Apple App Store):** The "Rate App" feature directs you to our app's page on the respective app store. Your interaction with the app store is governed by their privacy policies.

**5. Children's Privacy**

RoSpins is not intended for use by children under the age of 13 (or a higher age threshold if applicable in your jurisdiction). We do not knowingly collect any personal information from children. If you are a parent or guardian and you believe that your child has provided us with information without your consent, please contact us. If we become aware that we have inadvertently collected information from a child, we will take steps to delete such information.

**6. Changes to This Privacy Policy**

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new PrivacyPolicy within the App and updating the "Last Updated" date at the top of this Privacy Policy. You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.

**7. Contact Us**

If you have any questions about this Privacy Policy, please contact us at:
[Provide a placeholder email or contact method, e.g., rospins.support@example.com - this should be replaced by the developer with a real contact]

**By using RoSpins, you signify your acceptance of this Privacy Policy. If you do not agree to this policy, please do not use our App.**
""";

  @override
  Widget build(BuildContext context) {
    final String formattedPolicyText = policyText.replaceAll('{{CURRENT_DATE}}', _getFormattedCurrentDate());
    final theme = Theme.of(context);
    
    // Convert markdown to HTML
    final String htmlContent = md.markdownToHtml(formattedPolicyText);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the formatted policy text with styling for better readability
            Text(
              formattedPolicyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedCurrentDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
import 'package:flutter/material.dart';
import '../widgets/settings_list_tile.dart';
import '../widgets/theme_toggle.dart';
import '../utils/theme_service.dart';
import 'package:provider/provider.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  // MOCK DATA - Replace with actual data from backend
  String userName = 'Allen Vijay';
  String userEmail = 'Allenvijay@gmail.com';
  String userAvatar = 'https://api.dicebear.com/7.x/avataaars/svg?seed=Allen';

  @override
  void initState() {
    super.initState();
    // TODO: ADD BACKEND API - Load user profile
    // _loadUserProfile();
  }

  // TODO: ADD BACKEND API - Load user profile from backend
  // Future<void> _loadUserProfile() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('YOUR_API_URL/api/user/profile'),
  //       headers: {'Authorization': 'Bearer YOUR_TOKEN'},
  //     );
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       setState(() {
  //         userName = data['name'] ?? 'User';
  //         userEmail = data['email'] ?? 'user@email.com';
  //         userAvatar = data['avatar'] ?? '';
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading user profile: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: NetworkImage(userAvatar),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // TODO: Navigate to Edit Profile page
                    _editProfile();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // General Settings Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'General Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // ==================== USE THEME COLOR ====================
                color: theme.textTheme.bodyLarge?.color ?? const Color(0xFF2C3E50),
                // ==================================================
              ),
            ),
          ),

          // Dark/Light Mode Toggle
          SettingsListTile(
            icon: Icons.brightness_6,
            title: 'Mode',
            subtitle: themeService.isDarkMode ? 'Dark Mode' : 'Light Mode',
            trailing: ThemeToggle(
              isDarkMode: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleTheme();
              },
            ),
            onTap: () {
              // Toggle on tile tap as well
              themeService.toggleTheme();
            },
          ),

          // Language
          SettingsListTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // TODO: ADD BACKEND API - Get available languages
              _showLanguageDialog();
            },
          ),

          // About
          SettingsListTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              _showAboutDialog();
            },
          ),

          // Terms & Conditions
          SettingsListTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              // TODO: ADD BACKEND API - Fetch T&C from backend
              _showTermsAndConditions();
            },
          ),

          // Privacy Policy
          SettingsListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              // TODO: ADD BACKEND API - Fetch Privacy Policy from backend
              _showPrivacyPolicy();
            },
          ),

          // Rate This App
          SettingsListTile(
            icon: Icons.star_outline,
            title: 'Rate This App',
            iconColor: const Color(0xFFFFC107),
            onTap: () {
              // TODO: ADD BACKEND API - Log rating action
              _rateApp();
            },
          ),

          // Share This App
          SettingsListTile(
            icon: Icons.share_outlined,
            title: 'Share This App',
            iconColor: const Color(0xFF4CAF50),
            onTap: () {
              // TODO: ADD BACKEND API - Log share action
              _shareApp();
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _editProfile() {
    // TODO: ADD BACKEND API - Navigate to edit profile
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Edit profile feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // TODO: ADD BACKEND API CALL
    // Future<void> _updateProfile(String name, String email) async {
    //   try {
    //     await http.put(
    //       Uri.parse('YOUR_API_URL/api/user/profile'),
    //       headers: {
    //         'Authorization': 'Bearer YOUR_TOKEN',
    //         'Content-Type': 'application/json',
    //       },
    //       body: json.encode({
    //         'name': name,
    //         'email': email,
    //       }),
    //     );
    //   } catch (e) {
    //     print('Error updating profile: $e');
    //   }
    // }
  }

  void _showLanguageDialog() {
    // TODO: ADD BACKEND API - Get available languages list
    // GET /api/settings/languages

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('English', true),
            _languageOption('Tamil', false),
            _languageOption('Hindi', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // TODO: ADD BACKEND API - Save language preference
    // Future<void> _saveLanguage(String lang) async {
    //   try {
    //     await http.put(
    //       Uri.parse('YOUR_API_URL/api/user/preferences'),
    //       body: json.encode({'language': lang}),
    //     );
    //   } catch (e) {
    //     print('Error saving language: $e');
    //   }
    // }
  }

  Widget _languageOption(String language, bool isSelected) {
    return ListTile(
      title: Text(language),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFFFF6B35))
          : null,
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language changed to $language')),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FLOE'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('FLOE - Handwriting Assessment Platform'),
            SizedBox(height: 8),
            Text('Helping children improve their handwriting skills.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    // TODO: ADD BACKEND API - Fetch terms & conditions
    // GET /api/settings/terms-and-conditions

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms & Conditions content will be loaded from backend...\n\n'
            '1. User Agreement\n'
            '2. Privacy Terms\n'
            '3. Usage Guidelines\n'
            '4. Data Protection\n',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    // TODO: ADD BACKEND API - Fetch privacy policy
    // GET /api/settings/privacy-policy

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content will be loaded from backend...\n\n'
            '1. Data Collection\n'
            '2. Data Usage\n'
            '3. Data Security\n'
            '4. User Rights\n',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    // TODO: ADD BACKEND API - Log rating action
    // POST /api/user/rate-app

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate FLOE'),
        content: const Text(
          'Thank you for using FLOE! Please rate us on the App Store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open app store link
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    // TODO: ADD BACKEND API - Log share action
    // POST /api/user/share-app

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
}
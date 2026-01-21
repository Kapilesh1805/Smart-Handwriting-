import 'package:flutter/material.dart';
import '../widgets/settings_list_tile.dart';
import '../widgets/theme_toggle.dart';
import '../utils/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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
    // Load user profile from SharedPreferences (local store)
    _loadUserProfile();
  }

  // TODO: ADD BACKEND API - Load user profile from backend
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedName = prefs.getString('user_name');
      final storedEmail = prefs.getString('user_email');
      setState(() {
        if (storedName != null && storedName.isNotEmpty) userName = storedName;
        if (storedEmail != null && storedEmail.isNotEmpty) userEmail = storedEmail;
      });
    } catch (e) {
      // ignore errors and keep defaults
      print('Error loading profile from prefs: $e');
    }
  }

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
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
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
    final formKey = GlobalKey<FormState>();
    String newName = userName;
    String newEmail = userEmail;
    String newPassword = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: userName,
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (v) => newName = v.trim(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: userEmail,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => newEmail = v.trim(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (v) => newPassword = v,
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  // Try to call backend update_profile to persist changes (password will be hashed on server)
                  final userId = await Config.getUserId();

                  if (userId != null && userId.isNotEmpty) {
                    final body = {
                      'user_id': userId,
                      'name': newName,
                      'email': newEmail,
                    };
                    if (newPassword.isNotEmpty) {
                      body['password'] = newPassword;
                    }

                    final resp = await apiCall('PUT', '/auth/update_profile', body: body);
                    if (resp.statusCode == 200) {
                      // update local copy of name/email but DO NOT store password locally
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_name', newName);
                      await prefs.setString('user_email', newEmail);
                      setState(() {
                        userName = newName;
                        userEmail = newEmail;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                    } else {
                      final msg = resp.body.isNotEmpty ? resp.body : 'Failed to update profile';
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating profile: $msg')),
                      );
                    }
                  } else {
                    // Not logged in - fallback to local prefs (insecure)
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_name', newName);
                    await prefs.setString('user_email', newEmail);
                    await prefs.setString('user_password', newPassword);
                    setState(() {
                      userName = newName;
                      userEmail = newEmail;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated locally')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving profile: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
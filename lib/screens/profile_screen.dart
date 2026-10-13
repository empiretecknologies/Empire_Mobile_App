import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _choosePhoto(BuildContext context) async {
    final hasPhoto = AppSession.instance.profileImage.value != null;
    final choice = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, _PhotoChoice.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, _PhotoChoice.camera),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo'),
                  onTap: () => Navigator.pop(context, _PhotoChoice.remove),
                ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || choice == null) return;
    if (choice == _PhotoChoice.remove) {
      AppSession.instance.profileImage.value = null;
      return;
    }
    await _pick(
      context,
      choice == _PhotoChoice.camera ? ImageSource.camera : ImageSource.gallery,
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (image == null || !context.mounted) return;
      final bytes = await image.readAsBytes();
      if (!context.mounted) return;
      AppSession.instance.profileImage.value = bytes;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to update the profile picture.'),
          ),
        );
    }
  }

  Future<void> _logout() async {
    setState(() => _signingOut = true);
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final username = session.username?.trim() ?? '';
    final horizontal = MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 16.0;

    return AppThemeScope(
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppTheme.pageBackground(context),
            appBar: AppBar(
              backgroundColor: AppColors.forestDeep,
              foregroundColor: AppColors.onForest,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 24),
              children: [
                Center(
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _choosePhoto(context),
                          child: const UserAvatar(radius: 48),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            tooltip: 'Change profile picture',
                            onPressed: () => _choosePhoto(context),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: AppColors.onForest,
                              fixedSize: const Size(36, 36),
                              minimumSize: const Size(36, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  username.isEmpty ? 'Signed in user' : username,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the photo to change it',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: AppTheme.cardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.dividerColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'User Name',
                          value: username.isEmpty ? '-' : username,
                        ),
                        Divider(
                          height: 1,
                          color: AppTheme.dividerColor(context),
                        ),
                        _InfoRow(
                          label: 'Company',
                          value: _text(session.company?.name),
                        ),
                        Divider(
                          height: 1,
                          color: AppTheme.dividerColor(context),
                        ),
                        _InfoRow(
                          label: 'Branch',
                          value: _text(session.branch?.name),
                        ),
                        Divider(
                          height: 1,
                          color: AppTheme.dividerColor(context),
                        ),
                        _InfoRow(
                          label: 'Period',
                          value: _text(session.period?.name),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  loading: _signingOut,
                  onPressed: _signingOut ? null : _logout,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _text(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }
}

enum _PhotoChoice { gallery, camera, remove }

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.secondaryText(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.primaryText(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

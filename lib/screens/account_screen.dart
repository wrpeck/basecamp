import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';
import 'gear_lists_screen.dart';

const appVersion = '1.0.0';

/// Account and app settings. Sign-in is a local placeholder until a real
/// auth provider and backend are connected (see [AuthService]).
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _signInWithEmail(BuildContext context) async {
    final auth = AuthScope.of(context);
    final v = await showFormSheet(
      context,
      title: 'Sign in',
      submitLabel: 'Sign in',
      fields: [
        const FieldSpec.text(
          'name',
          'Your name',
          required: true,
          icon: Icons.person_outline,
        ),
        FieldSpec.text(
          'email',
          'Email',
          required: true,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
          validator: (s) => s.contains('@') ? null : 'Enter a valid email',
        ),
      ],
    );
    if (v == null) return;
    await auth.signInWithEmail(
      displayName: v.str('name'),
      email: v.str('email'),
    );
  }

  Future<void> _editProfile(BuildContext context, AppUser user) async {
    final auth = AuthScope.of(context);
    final v = await showFormSheet(
      context,
      title: 'Edit profile',
      fields: [
        FieldSpec.text(
          'name',
          'Your name',
          initial: user.displayName,
          required: true,
          icon: Icons.person_outline,
        ),
        FieldSpec.text(
          'email',
          'Email',
          initial: user.email,
          required: true,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
          validator: (s) => s.contains('@') ? null : 'Enter a valid email',
        ),
      ],
    );
    if (v == null) return;
    await auth.updateProfile(displayName: v.str('name'), email: v.str('email'));
  }

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final settings = SettingsScope.of(context);
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Account & settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: user == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.person_outline,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You\'re not signed in',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Trips are saved on this device only.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProviderButton(
                          icon: Icons.g_mobiledata,
                          label: 'Continue with Google',
                          available: auth.supports(AuthProvider.google),
                          onPressed: () =>
                              _comingSoon(context, 'Google sign-in'),
                        ),
                        const SizedBox(height: 8),
                        _ProviderButton(
                          icon: Icons.apple,
                          label: 'Continue with Apple',
                          available: auth.supports(AuthProvider.apple),
                          onPressed: () =>
                              _comingSoon(context, 'Apple sign-in'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _signInWithEmail(context),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Sign in with email'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preview: signing in only saves your profile on '
                          'this device. Accounts and sync will connect to a '
                          'server later.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    user.email,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit profile',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editProfile(context, user),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await confirm(
                              context,
                              'Sign out?',
                              'Your trips stay on this device.',
                              action: 'Sign out',
                            );
                            if (ok) await auth.signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.themeMode = s.first,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Trips & data',
            icon: Icons.storage_outlined,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.checklist_outlined),
                  title: const Text('Gear lists'),
                  subtitle: Text(
                    '${store.templates.length} reusable packing list'
                    '${store.templates.length == 1 ? '' : 's'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GearListsScreen()),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Sync across devices'),
                  subtitle: const Text('Coming soon · needs an account'),
                  value: false,
                  onChanged: null,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.group_add_outlined),
                  title: const Text('Invite crew to a trip'),
                  subtitle: const Text('Coming soon'),
                  enabled: false,
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restart_alt, color: scheme.error),
                  title: Text(
                    'Reset all data',
                    style: TextStyle(color: scheme.error),
                  ),
                  subtitle: const Text(
                    'Delete every trip and gear list on this device',
                  ),
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      'Reset all data?',
                      'This deletes every trip and gear list on this device '
                          'and restores the sample trip. It can\'t be undone.',
                      action: 'Reset',
                    );
                    if (ok) store.resetAll();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'About',
            icon: Icons.info_outline,
            child: Column(
              children: [
                const InfoRow(label: 'Version', value: appVersion),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy policy'),
                  enabled: false,
                  subtitle: const Text('Coming soon'),
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of service'),
                  enabled: false,
                  subtitle: const Text('Coming soon'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.available,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool available;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (!available) ...[
            const SizedBox(width: 8),
            Text(
              'Soon',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

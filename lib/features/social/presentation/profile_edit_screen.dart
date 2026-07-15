import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../application/social_providers.dart';
import '../domain/profile.dart';

/// 簡易プロフィール編集（追加要件 §1 / §9）。
///
/// 表示名・アイコン・ひとこと・推し名・フレンド申請受付・検索可否を編集する。
/// 本人のみ編集でき、保存はサーバー RLS（`profiles_*_self`）が強制する。
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _favoriteName = TextEditingController();
  bool _acceptsRequests = true;
  bool _searchable = false;
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _favoriteName.dispose();
    super.dispose();
  }

  void _seed(Profile? profile) {
    if (_seeded) return;
    _seeded = true;
    if (profile == null) return;
    _displayName.text = profile.displayName;
    _bio.text = profile.bio ?? '';
    _favoriteName.text = profile.favoriteName ?? '';
    _acceptsRequests = profile.acceptsFriendRequests;
    _searchable = profile.searchable;
  }

  Future<void> _save() async {
    final error = profileInvariantError(
      displayName: _displayName.text,
      bio: _bio.text.isEmpty ? null : _bio.text,
      favoriteName: _favoriteName.text.isEmpty ? null : _favoriteName.text,
    );
    if (error != null) {
      _snack(error);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(profileRepositoryProvider).upsertMyProfile(
          displayName: _displayName.text,
          bio: _bio.text.isEmpty ? null : _bio.text,
          favoriteName: _favoriteName.text.isEmpty ? null : _favoriteName.text,
          acceptsFriendRequests: _acceptsRequests,
          searchable: _searchable,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        ref.invalidate(myProfileProvider);
        _snack('プロフィールを保存しました');
        Navigator.of(context).maybePop();
      },
      err: (f) => _snack(f.message),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return AppScaffold(
      title: 'プロフィール',
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ProfileUnavailable(),
        data: (profile) {
          _seed(profile);
          return ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              Center(
                child: _AvatarPreview(
                  nameListenable: _displayName,
                  avatarUrl: profile?.avatarUrl,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Center(
                child: Text(
                  'アイコン画像の設定は次のアップデートで対応します',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              TextField(
                controller: _displayName,
                maxLength: kDisplayNameMaxLength,
                decoration: const InputDecoration(
                  labelText: '表示名 *',
                  hintText: '共有メンバーやフレンドに表示されます',
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _bio,
                maxLength: kBioMaxLength,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ひとこと',
                  hintText: '推し活の意気込みなど（任意）',
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _favoriteName,
                maxLength: kFavoriteNameMaxLength,
                decoration: const InputDecoration(
                  labelText: '推し名・推しカテゴリ',
                  hintText: '任意',
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acceptsRequests,
                      onChanged: (v) => setState(() => _acceptsRequests = v),
                      title: const Text('フレンド申請を受け付ける'),
                      subtitle: const Text('オフにすると誰からも申請が届きません'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _searchable,
                      onChanged: (v) => setState(() => _searchable = v),
                      title: const Text('検索を許可する'),
                      subtitle: const Text(
                        'オフでも、同じ現場に参加した相手からは申請できます',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 表示名の先頭文字でプレビューするアバター（入力に追従）。
class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.nameListenable, this.avatarUrl});

  final TextEditingController nameListenable;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: nameListenable,
      builder: (context, value, _) => OshiAvatar(
        name: value.text.isEmpty ? '?' : value.text,
        size: 88,
        ringColor: Theme.of(context).colorScheme.primary,
        altText: 'プロフィールアイコン',
      ),
    );
  }
}

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable();

  @override
  Widget build(BuildContext context) => const EmptyState(
        icon: Icons.person_off_outlined,
        message: 'プロフィールを利用できません',
        description: 'ログインするとプロフィールを設定できます',
      );
}

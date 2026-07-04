import 'dart:io';

import 'package:flutter/material.dart';

/// 推しアバター（design-spec §4/§10）。
///
/// 写真 → イニシャルフォールバックの順で表示し、推しカラーのリングを付ける。
/// 選択中（最推し等）はリングを太くし、色だけに依存しないよう
/// [selected] を Semantics でも伝える。
class OshiAvatar extends StatelessWidget {
  const OshiAvatar({
    super.key,
    required this.name,
    this.imageFile,
    this.ringColor,
    this.selected = false,
    this.size = 48,
    this.altText,
  });

  /// イニシャルフォールバックに使う名前（先頭1文字）。
  final String name;
  final File? imageFile;

  /// 推しカラーリング（null はリングなし＝テーマの境界色）。
  final Color? ringColor;
  final bool selected;
  final double size;

  /// 画像の代替説明（読み上げ用, §14）。
  final String? altText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ring = ringColor ?? theme.colorScheme.outlineVariant;
    final initial = name.isEmpty ? '?' : name.characters.first;
    return Semantics(
      label: altText ?? name,
      selected: selected,
      image: imageFile != null,
      container: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: selected ? 3 : 1.5),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: imageFile != null
              ? Image.file(
                  imageFile!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _InitialFallback(initial: initial),
                )
              : _InitialFallback(initial: initial),
        ),
      ),
    );
  }
}

class _InitialFallback extends StatelessWidget {
  const _InitialFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

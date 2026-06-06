import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppProfileAvatar extends StatelessWidget {
  const AppProfileAvatar({
    super.key,
    required this.url,
    this.size = 88,
    this.borderColor,
    this.borderWidth = 3,
  });

  final String url;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(child: _buildImage(context)),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (url.startsWith('data:image')) {
      return _buildDataUri();
    }
    if (_isLocalFile) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, err, stack) => _placeholder(context),
      );
    }
    if (url.endsWith('.svg') || url.contains('dicebear.com')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _placeholder(context),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, url) => _placeholder(context),
      errorWidget: (_, err, stack) => _placeholder(context),
    );
  }

  Widget _buildDataUri() {
    final comma = url.indexOf(',');
    if (comma == -1) return const SizedBox.shrink();
    final base64 = url.substring(comma + 1);
    try {
      return Image.memory(base64Decode(base64), fit: BoxFit.cover);
    } on Object {
      return const SizedBox.shrink();
    }
  }

  bool get _isLocalFile =>
      !url.startsWith('http') && !url.startsWith('data:');

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        LucideIcons.user,
        size: size * 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool isOnline;
  final bool showBorder;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.isOnline = false,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceLight,
            border: showBorder
                ? Border.all(color: AppColors.secondary, width: 2)
                : null,
          ),
          child: ClipOval(
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceLight,
                      child: Icon(
                        Icons.person,
                        size: size * 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceLight,
                      child: Icon(
                        Icons.person,
                        size: size * 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: size * 0.5,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

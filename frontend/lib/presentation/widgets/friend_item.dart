import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/friend_model.dart';

class FriendItem extends StatelessWidget {
  final Friend friend;

  const FriendItem({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: friend.isOnline && friend.status.contains('Stream')
                      ? AppColors.primaryGradient
                      : null,
                  border: !friend.isOnline
                      ? Border.all(color: AppColors.surfaceLight)
                      : null,
                ),
                child: ClipOval(
                  child: friend.avatar.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: friend.avatar,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          placeholder: (context, url) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(
                              Icons.person,
                              size: 28,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(
                              Icons.person,
                              size: 28,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: AppColors.surfaceLight,
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              if (friend.isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              if (friend.status.contains('Stream'))
                Positioned(
                  bottom: -2,
                  left: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.background, width: 1),
                    ),
                    child: const Text(
                      'LIVE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            friend.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

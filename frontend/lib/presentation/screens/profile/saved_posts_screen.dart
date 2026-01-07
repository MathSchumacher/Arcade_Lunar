import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/post_card.dart';

/// Saved Posts Screen
/// Shows user's bookmarked posts with search functionality
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _savedPosts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPosts({String? query}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final posts = await ApiService.getSavedPosts(searchQuery: query);
      if (mounted) {
        setState(() {
          _savedPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved posts: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadSavedPosts(query: query.isEmpty ? null : query);
  }

  Future<void> _unsavePost(int postId) async {
    try {
      await ApiService.unsavePost(postId);
      setState(() {
        _savedPosts.removeWhere((p) => p['id'] == postId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed from saved')),
        );
      }
    } catch (e) {
      print('Error unsaving post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Saved'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search saved posts...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
              const Text(
                'Error loading saved posts',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadSavedPosts(),
                child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_savedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.bookmark_border,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No posts found for "$_searchQuery"'
                  : 'No saved posts yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Save posts to see them here',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSavedPosts(query: _searchQuery.isEmpty ? null : _searchQuery),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedPosts.length,
        itemBuilder: (context, index) {
          final post = _savedPosts[index];
          return Dismissible(
            key: Key('saved_${post['id']}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bookmark_remove, color: Colors.white),
            ),
            onDismissed: (_) => _unsavePost(post['id']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post['author']?['avatar'] != null
                            ? NetworkImage(post['author']['avatar'])
                            : null,
                        child: post['author']?['avatar'] == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  post['author']?['displayName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (post['author']?['isVerified'] == true)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              '@${post['author']?['username'] ?? ''}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark, color: Colors.amber),
                        onPressed: () => _unsavePost(post['id']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Content
                  Text(
                    post['content'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Stats
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${post['likes'] ?? 0}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.comment, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${post['comments'] ?? 0}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

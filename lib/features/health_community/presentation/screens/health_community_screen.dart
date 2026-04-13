import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/storage_provider.dart';
import '../../../../models/app_backend_models.dart';
import '../../../../services/community_service.dart';
import '../../../../services/firebase_backend_service.dart';
import '../../../../shared/widgets/widgets.dart';

class HealthCommunityScreen extends ConsumerStatefulWidget {
  const HealthCommunityScreen({super.key});
  @override
  ConsumerState<HealthCommunityScreen> createState() => _HealthCommunityScreenState();
}

class _HealthCommunityScreenState extends ConsumerState<HealthCommunityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _postController = TextEditingController();
  String _selectedTopic = 'All';

  static const _topics = [
    'All', 'Mental Wellness', 'Nutrition Tips',
    'Fitness Motivation', 'Stress Management', 'Sleep Health', 'General',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation  = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;
    final user = ref.read(firebaseServiceProvider).getCurrentUser();
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final topic = _selectedTopic == 'All' ? 'General' : _selectedTopic;
    final ok = await ref.read(communityServiceProvider).createPost(user.uid, content, topic);
    if (ok) {
      _postController.clear();
      await ref.read(communityPostsProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityPostsProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.navy900, AppTheme.navy800],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Connect, share and learn with others',
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // ---------- Post Composer ----------
                  _buildPostComposer(),
                  const SizedBox(height: 24),

                  // ---------- Topic Filter ----------
                  _buildTopicFilter(),
                  const SizedBox(height: 24),

                  // ---------- Feed ----------
                  postsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent)),
                    error:   (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
                    data: (posts) {
                      final filtered = _selectedTopic == 'All'
                          ? posts
                          : posts.where((p) => p.topic == _selectedTopic).toList();
                      return filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No posts yet. Be the first!', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Community Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                                const SizedBox(height: 16),
                                ...filtered.map((p) => Column(children: [
                                  _PostCard(post: p, onUpdate: () => ref.read(communityPostsProvider.notifier).reload()),
                                  const SizedBox(height: 16),
                                ])),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ---------- Expert Advice ----------
                  _buildExpertAdvice(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostComposer() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share with the Community', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          // Topic selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _topics.where((t) => t != 'All').map((t) {
                final sel = (_selectedTopic == 'All' ? 'General' : _selectedTopic) == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t, style: TextStyle(fontSize: 12, color: sel ? AppTheme.navy900 : AppTheme.onSurface)),
                    selected: sel,
                    selectedColor: AppTheme.cyanAccent,
                    backgroundColor: AppTheme.navy700,
                    onSelected: (_) => setState(() => _selectedTopic = t),
                    side: BorderSide(color: sel ? AppTheme.cyanAccent : AppTheme.outline),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const CircleAvatar(radius: 18, backgroundColor: AppTheme.navy600, child: Icon(Icons.person, color: AppTheme.cyanAccent, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _postController,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Share a health tip or question...',
                    hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                    filled: true,
                    fillColor: AppTheme.navy700,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.outline)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.outline)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cyanAccent)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _submitPost,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(color: AppTheme.cyanAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: AppTheme.navy900, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter by Topic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _topics.map((t) {
            final sel = _selectedTopic == t;
            return GestureDetector(
              onTap: () => setState(() => _selectedTopic = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.cyanAccent : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppTheme.cyanAccent : AppTheme.outline),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    color: sel ? AppTheme.navy900 : AppTheme.onSurface,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpertAdvice() {
    final advice = ref.watch(expertAdviceProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.cyanAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.verified_rounded, color: AppTheme.cyanAccent, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Expert Advice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice.title, style: const TextStyle(color: AppTheme.cyanAccent, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(advice.content, style: const TextStyle(color: AppTheme.onSurface, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('— ${advice.author}', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
          ),
        ],
      ),
    );
  }

}

// --------------------------------------------------------
// Post Card widget
// --------------------------------------------------------
class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.onUpdate});
  final CommunityPost post;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now  = DateTime.now();
    final diff = now.difference(post.createdAt);
    String timeAgo;
    if (diff.inMinutes < 1)        timeAgo = 'just now';
    else if (diff.inMinutes < 60)  timeAgo = '${diff.inMinutes}m ago';
    else if (diff.inHours < 24)    timeAgo = '${diff.inHours}h ago';
    else                           timeAgo = '${diff.inDays}d ago';

    final user    = ref.read(firebaseServiceProvider).getCurrentUser();
    final uid     = user?.uid ?? '';
    final liked   = ref.read(communityServiceProvider).isLiked(post.postID, uid);
    final initials = post.username.isNotEmpty ? post.username[0].toUpperCase() : '?';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.cyanAccent.withOpacity(0.15),
                  child: Text(initials, style: const TextStyle(color: AppTheme.cyanAccent, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.username, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(timeAgo, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                ]),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.navy600,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
                ),
                child: Text(post.topic, style: const TextStyle(color: AppTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Content
          Text(post.content, style: const TextStyle(color: AppTheme.onSurface, fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.outline, height: 1),
          const SizedBox(height: 8),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionBtn(
                icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: post.likesCount > 0 ? '${post.likesCount} Like' : 'Like',
                color: liked ? Colors.redAccent : AppTheme.onSurfaceVariant,
                onTap: () async {
                  if (uid.isEmpty) return;
                  await ref.read(communityServiceProvider).likePost(post.postID, uid);
                  onUpdate();
                },
              ),
              _ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comment',
                onTap: () => _showComments(context, ref),
              ),
              _ActionBtn(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Link: medmind.app/post/${post.postID}'), behavior: SnackBarBehavior.floating, backgroundColor: AppTheme.navy700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(post: post),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Icon(icon, color: color ?? AppTheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color ?? AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// --------------------------------------------------------
// Comments Bottom Sheet
// --------------------------------------------------------
class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post});
  final CommunityPost post;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<CommunityComment> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await ref.read(communityServiceProvider).fetchComments(widget.post.postID);
    if (mounted) setState(() { _comments = c; _loading = false; });
  }

  Future<void> _send() async {
    final content = _ctrl.text.trim();
    if (content.isEmpty) return;
    final user = ref.read(firebaseServiceProvider).getCurrentUser();
    if (user == null) return;
    final ok = await ref.read(communityServiceProvider).createComment(widget.post.postID, user.uid, content);
    if (ok) { _ctrl.clear(); _load(); }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.navy800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Comments on ${widget.post.username}\'s post',
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const Divider(color: AppTheme.outline, height: 1),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent))
              : _comments.isEmpty
                  ? const Center(child: Text('No comments yet — be the first!', style: TextStyle(color: AppTheme.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.outline),
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.cyanAccent.withOpacity(0.15),
                            child: Text(c.username.isNotEmpty ? c.username[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppTheme.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(c.username, style: const TextStyle(color: AppTheme.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(c.content, style: const TextStyle(color: AppTheme.onSurface, fontSize: 14)),
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.navy900,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                    filled: true,
                    fillColor: AppTheme.navy700,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.send_rounded, color: AppTheme.cyanAccent), onPressed: _send),
            ]),
          ),
        ],
      ),
    );
  }
}

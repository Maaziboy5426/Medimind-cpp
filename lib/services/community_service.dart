import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_backend_models.dart';
import 'base_providers.dart';
import 'firebase_backend_service.dart';
import 'storage_provider.dart';

// --- Mock community users that seed the feed ---
const _mockUsers = [
  {'uid': 'mock_u1', 'name': 'Priya Sharma', 'initials': 'PS'},
  {'uid': 'mock_u2', 'name': 'Amir Khan',   'initials': 'AK'},
  {'uid': 'mock_u3', 'name': 'Sofia Torres', 'initials': 'ST'},
  {'uid': 'mock_u4', 'name': 'James Lee',    'initials': 'JL'},
];

const _seedPosts = [
  {
    'userIdx': 0,
    'content': 'Started a 10-minute morning walk today after logging my sleep. Feeling so much better! Anyone else using step tracking?',
    'topic': 'Fitness Motivation',
    'likes': 12,
  },
  {
    'userIdx': 1,
    'content': 'Reminder: drinking a glass of water first thing in the morning boosts metabolism. Tiny habit, big results! 💧',
    'topic': 'Nutrition Tips',
    'likes': 8,
  },
  {
    'userIdx': 2,
    'content': 'Been struggling with anxiety lately. The breathing exercises in the Mental Health section really helped. 5-4-3-2-1 grounding technique is a lifesaver.',
    'topic': 'Mental Wellness',
    'likes': 24,
  },
  {
    'userIdx': 3,
    'content': 'Anyone notice that cutting screen time an hour before bed dramatically improves sleep quality? My data confirms it!',
    'topic': 'Sleep Health',
    'likes': 17,
  },
  {
    'userIdx': 0,
    'content': 'Pro tip: track your water intake AND your energy levels. There\'s a huge correlation I never noticed before using MediMind.',
    'topic': 'Nutrition Tips',
    'likes': 5,
  },
];

class CommunityService {
  final SharedPreferences _prefs;
  final FirebaseService _firebase;

  CommunityService(this._prefs, this._firebase);

  static const _postsKey    = 'community_posts_v2';
  static const _commentsKey = 'community_comments_v2';
  static const _likedKey    = 'community_liked_posts';

  // --- Internal helpers ---
  List<Map<String, dynamic>> _loadRaw(String key) {
    final str = _prefs.getString(key);
    if (str == null) return [];
    try {
      final decoded = jsonDecode(str) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveRaw(String key, List<Map<String, dynamic>> data) =>
      _prefs.setString(key, jsonEncode(data));

  // --- Seed initial posts if empty ---
  Future<void> _seedIfEmpty() async {
    final raw = _loadRaw(_postsKey);
    if (raw.isNotEmpty) return;

    final now = DateTime.now();
    final seeded = <Map<String, dynamic>>[];
    for (int i = 0; i < _seedPosts.length; i++) {
      final s     = _seedPosts[i];
      final u     = _mockUsers[s['userIdx'] as int];
      seeded.add({
        'postID':    'seed_${i}',
        'userID':    u['uid'],
        'username':  u['name'],
        'initials':  u['initials'],
        'avatar':    '',
        'content':   s['content'],
        'topic':     s['topic'],
        'likesCount': s['likes'],
        'createdAt': now.subtract(Duration(hours: (i + 1) * 4)).toIso8601String(),
      });
    }
    await _saveRaw(_postsKey, seeded);
  }

  // --- Public API ---
  Future<List<CommunityPost>> fetchPosts() async {
    await _seedIfEmpty();
    final raw = _loadRaw(_postsKey);
    // newest first
    raw.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
    return raw.map((m) {
      return CommunityPost(
        postID:     m['postID'] ?? '',
        userID:     m['userID'] ?? '',
        username:   m['username'] ?? 'User',
        avatar:     m['avatar'] ?? '',
        content:    m['content'] ?? '',
        topic:      m['topic'] ?? 'General',
        likesCount: m['likesCount'] as int? ?? 0,
        createdAt:  DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<bool> createPost(String userID, String content, String topic) async {
    if (content.trim().isEmpty) return false;
    final user = _firebase.getCurrentUser();
    final username = user?.name ?? 'You';

    final raw = _loadRaw(_postsKey);
    final newPost = {
      'postID':     'post_${DateTime.now().millisecondsSinceEpoch}',
      'userID':     userID,
      'username':   username,
      'initials':   username.isNotEmpty ? username[0].toUpperCase() : 'U',
      'avatar':     '',
      'content':    content.trim(),
      'topic':      topic,
      'likesCount': 0,
      'createdAt':  DateTime.now().toIso8601String(),
    };
    raw.insert(0, newPost);
    await _saveRaw(_postsKey, raw);
    return true;
  }

  Future<bool> likePost(String postID, String userID) async {
    // Track which posts user has liked to debounce
    final liked = _prefs.getStringList(_likedKey) ?? [];
    final key   = '${userID}_$postID';
    final isLiked = liked.contains(key);

    final raw = _loadRaw(_postsKey);
    final idx = raw.indexWhere((m) => m['postID'] == postID);
    if (idx == -1) return false;

    raw[idx] = Map<String, dynamic>.from(raw[idx])
      ..['likesCount'] = ((raw[idx]['likesCount'] as int? ?? 0) + (isLiked ? -1 : 1)).clamp(0, 9999);

    if (isLiked) {
      liked.remove(key);
    } else {
      liked.add(key);
    }
    await _prefs.setStringList(_likedKey, liked);
    await _saveRaw(_postsKey, raw);
    return true;
  }

  bool isLiked(String postID, String userID) {
    final liked = _prefs.getStringList(_likedKey) ?? [];
    return liked.contains('${userID}_$postID');
  }

  Future<List<CommunityComment>> fetchComments(String postID) async {
    final all = _loadRaw(_commentsKey);
    return all
        .where((m) => m['postID'] == postID)
        .map((m) => CommunityComment(
              commentID: m['commentID'] ?? '',
              postID:    m['postID'] ?? '',
              userID:    m['userID'] ?? '',
              username:  m['username'] ?? 'User',
              avatar:    m['avatar'] ?? '',
              content:   m['content'] ?? '',
              createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
            ))
        .toList();
  }

  Future<bool> createComment(String postID, String userID, String content) async {
    if (content.trim().isEmpty) return false;
    final user     = _firebase.getCurrentUser();
    final username = user?.name ?? 'You';

    final all = _loadRaw(_commentsKey);
    all.add({
      'commentID': 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      'postID':    postID,
      'userID':    userID,
      'username':  username,
      'avatar':    '',
      'content':   content.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _saveRaw(_commentsKey, all);
    return true;
  }

  List<ExpertAdvice> get expertAdvices => [
    ExpertAdvice(adviceID: 'a1', topic: 'Hydration', title: 'Hydration & Energy', content: 'Aim for 8 glasses of water a day — even mild dehydration reduces cognitive performance by up to 20%.', author: 'Dr. Sarah Moore, MD'),
    ExpertAdvice(adviceID: 'a2', topic: 'Sleep', title: 'Sleep Hygiene', content: 'Consistent sleep and wake times regulate your circadian rhythm. Even on weekends, try to stay within a 30-minute window.', author: 'Dr. Arun Mehta, Neurologist'),
    ExpertAdvice(adviceID: 'a3', topic: 'Fitness', title: 'Movement Snacks', content: 'Standing up and moving for 2 minutes every 30 minutes can offset the metabolic effects of prolonged sitting.', author: 'Dr. Lisa Chang, Sports Medicine'),
  ];

  ExpertAdvice get randomAdvice {
    final hour = DateTime.now().hour;
    return expertAdvices[hour % expertAdvices.length];
  }

  List<SupportGroup> get supportGroups => [
    SupportGroup(groupID: 'g1', name: 'Anxiety & Stress Relief', description: 'A safe space to share coping strategies for daily stress and anxiety.'),
    SupportGroup(groupID: 'g2', name: 'Healthy Eating Together', description: 'Swap healthy recipes and nutritional tips with fellow members.'),
    SupportGroup(groupID: 'g3', name: 'Better Sleep Club', description: 'Track, discuss, and improve your sleep habits as a community.'),
    SupportGroup(groupID: 'g4', name: 'Fitness Accountability', description: 'Set goals and keep each other accountable for daily movement.'),
  ];
}

// --- Providers ---

final communityServiceProvider = Provider<CommunityService>((ref) {
  final prefs   = ref.watch(sharedPreferencesProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return CommunityService(prefs, firebase);
});

// Riverpod notifier so UI can react to post changes
class CommunityPostsNotifier extends AsyncNotifier<List<CommunityPost>> {
  @override
  Future<List<CommunityPost>> build() {
    return ref.watch(communityServiceProvider).fetchPosts();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(communityServiceProvider).fetchPosts());
  }
}

final communityPostsProvider = AsyncNotifierProvider<CommunityPostsNotifier, List<CommunityPost>>(
  CommunityPostsNotifier.new,
);

final expertAdviceProvider = Provider<ExpertAdvice>((ref) {
  return ref.watch(communityServiceProvider).randomAdvice;
});

final supportGroupsProvider = Provider<List<SupportGroup>>((ref) {
  return ref.watch(communityServiceProvider).supportGroups;
});

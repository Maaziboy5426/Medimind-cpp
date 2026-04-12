import '../models/mental_health_models.dart';

class MentalHealthEngine {
  static double calculateWellnessScore({
    required int moodScore, // 1-5
    required double sleepHours,
    required int stressScore, // 0-100
    required int activityLevel, // 1-10
    required int journalSentiment, // -50 to 50 or similar
  }) {
    final moodWeighted = (moodScore - 1) * 25.0;
    final sleepScore = (sleepHours >= 8 ? 100.0 : (sleepHours / 8.0) * 100.0);
    final activityScore = (activityLevel / 10.0) * 100.0;
    final sentimentNormalized = ((journalSentiment + 10) / 20.0) * 100.0;

    double score = (0.30 * moodWeighted) +
        (0.25 * sleepScore) +
        (0.20 * (100 - stressScore)) +
        (0.15 * activityScore) +
        (0.10 * sentimentNormalized);

    return score.clamp(0.0, 100.0);
  }

  static int calculateStressScore({
    required double sleepHours,
    required int moodScore,
    required int activityLevel,
    required int hydrationLevel,
  }) {
    int stress = 50;
    if (sleepHours < 6) stress += 20;
    if (moodScore <= 2) stress += 20;
    if (activityLevel < 4) stress += 10;
    if (hydrationLevel < 4) stress += 10;
    if (sleepHours >= 8) stress -= 10;
    if (moodScore >= 4) stress -= 10;
    return stress.clamp(0, 100);
  }

  // ---------------------------------------------------------------------------
  // Weighted keyword banks
  // Strong = ±3 | Moderate = ±2 | Mild = ±1
  // ---------------------------------------------------------------------------
  static const _positiveStrong = {
    'ecstatic', 'elated', 'overjoyed', 'thrilled', 'blissful', 'euphoric',
    'fantastic', 'amazing', 'wonderful', 'joyful', 'exhilarated', 'radiant',
    'incredible', 'blessed', 'grateful', 'thankful', 'inspired', 'energized',
    'pumped', 'motivated', 'productive', 'accomplished', 'proud', 'victorious',
    'magnificent', 'phenomenal', 'outstanding', 'brilliant', 'glowing',
  };

  static const _positiveModerate = {
    'happy', 'good', 'great', 'excited', 'cheerful', 'content', 'pleased',
    'optimistic', 'hopeful', 'positive', 'upbeat', 'lively', 'refreshed',
    'confident', 'determined', 'focused', 'enthusiastic', 'eager', 'glad',
    'satisfied', 'comfortable', 'peaceful', 'serene', 'loving', 'affectionate',
    'appreciated', 'supported', 'connected', 'fulfilled', 'joyous', 'delighted',
    'buoyant', 'energetic', 'vibrant', 'alive', 'sunny', 'warm',
    'secure', 'capable', 'empowered', 'clear', 'light', 'free', 'open',
    'engaged', 'trusting', 'charitable', 'generous', 'playful',
  };

  static const _positiveMild = {
    'calm', 'okay', 'fine', 'alright', 'decent', 'relaxed', 'steady',
    'balanced', 'stable', 'better', 'improving', 'manageable', 'rested',
    'easy', 'gentle', 'collected', 'grounded', 'comfortable', 'relieved',
    'neutral', 'still', 'composed', 'settled', 'refreshing', 'quiet',
    'simple', 'pleasant', 'nice', 'safe', 'normal', 'hopeful', 'mostly',
  };

  static const _negativeStrong = {
    'devastated', 'hopeless', 'suicidal', 'worthless', 'broken', 'miserable',
    'depressed', 'desperate', 'agonizing', 'traumatized', 'crushed', 'shattered',
    'empty', 'numb', 'destroyed', 'suffering', 'unbearable', 'catastrophic',
    'terrified', 'horrified', 'ruined', 'helpless', 'powerless', 'defeated',
    'collapsed', 'crumbling', 'failing', 'fractured', 'tormented', 'haunted',
  };

  static const _negativeModerate = {
    'stressed', 'anxious', 'worried', 'sad', 'angry', 'frustrated', 'upset',
    'unhappy', 'overwhelmed', 'exhausted', 'burned', 'burnt', 'drained',
    'nervous', 'afraid', 'scared', 'fearful', 'panicking', 'panicked',
    'irritated', 'annoyed', 'resentful', 'bitter', 'confused', 'lost',
    'lonely', 'isolated', 'disconnected', 'rejected', 'abandoned', 'betrayed',
    'embarrassed', 'ashamed', 'guilty', 'regret', 'regretful', 'demotivated',
    'misunderstood', 'pressured', 'trapped', 'stuck', 'suffocating', 'grief',
    'grieving', 'mourning', 'crying', 'tearful', 'weeping', 'heartbroken',
    'disappointed', 'discouraged', 'failure', 'failing', 'insecure', 'doubtful',
    'jealous', 'envious', 'spiteful', 'hostile', 'tense', 'agitated', 'restless',
  };

  static const _negativeMild = {
    'tired', 'sleepy', 'bored', 'meh', 'blah', 'gloomy', 'cloudy',
    'moody', 'distracted', 'unfocused', 'sluggish', 'slow', 'off',
    'low', 'flat', 'dull', 'uneasy', 'unsure', 'wary', 'hesitant',
    'reluctant', 'indifferent', 'apathetic', 'detached', 'withdrawn',
    'quiet', 'distant', 'foggy', 'heavy', 'stiff', 'achy', 'weak',
  };

  // Negation words — flip the score of the next keyword
  static const _negations = {
    'not', "don't", "doesn't", "didn't", 'never', 'no', 'neither',
    'barely', 'hardly', 'rarely', 'cannot', "can't", "wasn't", "isn't",
    'without', 'lack', 'lacking', 'absent', 'unable',
  };

  /// Returns a weighted sentiment score clamped to [-10, 10].
  static int analyzeSentiment(String text) {
    final tokens = text.toLowerCase().split(RegExp(r'[\s,\.!?;:]+'));
    double score = 0;
    bool negate = false;

    for (final word in tokens) {
      if (_negations.contains(word)) {
        negate = true;
        continue;
      }

      double wordScore = 0;
      if (_positiveStrong.contains(word))    wordScore = 3;
      else if (_positiveModerate.contains(word)) wordScore = 2;
      else if (_positiveMild.contains(word))     wordScore = 1;
      else if (_negativeStrong.contains(word))   wordScore = -3;
      else if (_negativeModerate.contains(word)) wordScore = -2;
      else if (_negativeMild.contains(word))     wordScore = -1;

      if (wordScore != 0) {
        if (negate) wordScore = -(wordScore * 0.75);
        negate = false;
        score += wordScore;
      }
    }

    return score.clamp(-10, 10).round();
  }

  /// Classifies the text into one of 10 mood labels.
  /// Labels: Happy | Grateful | Energetic | Calm | Neutral |
  ///         Anxious | Sad | Angry | Overwhelmed | Depressed
  static String classifyMood(String text, int sentimentScore) {
    final lower = text.toLowerCase();

    if (sentimentScore >= 4) {
      if (_containsAny(lower, ['grateful', 'thankful', 'blessed', 'appreciate', 'appreciation', 'gratitude'])) return 'Grateful';
      if (_containsAny(lower, ['energized', 'pumped', 'excited', 'motivated', 'productive', 'accomplished', 'energetic', 'fired up'])) return 'Energetic';
      return 'Happy';
    }

    if (sentimentScore >= 1) {
      if (_containsAny(lower, ['calm', 'peaceful', 'relaxed', 'serene', 'tranquil', 'balanced', 'at ease', 'settled'])) return 'Calm';
      return 'Calm';
    }

    if (sentimentScore == 0) return 'Neutral';

    if (sentimentScore <= -5) {
      if (_containsAny(lower, ['hopeless', 'worthless', 'empty', 'numb', 'broken', 'shattered', 'suicidal', 'no point', 'giving up'])) return 'Depressed';
      if (_containsAny(lower, ['overwhelmed', 'too much', 'cant cope', "can't cope", 'swamped', 'flooded', 'drowning'])) return 'Overwhelmed';
      return 'Depressed';
    }

    if (sentimentScore <= -2) {
      if (_containsAny(lower, ['angry', 'anger', 'furious', 'frustrated', 'irritated', 'annoyed', 'rage', 'resentful', 'livid', 'mad'])) return 'Angry';
      if (_containsAny(lower, ['anxious', 'anxiety', 'panic', 'nervous', 'worried', 'scared', 'fear', 'afraid', 'on edge', 'dread'])) return 'Anxious';
      if (_containsAny(lower, ['overwhelmed', 'too much', 'cant handle', "can't handle", 'flooded', 'swamped', 'buried', 'crushing'])) return 'Overwhelmed';
      return 'Sad';
    }

    // sentimentScore == -1
    if (_containsAny(lower, ['anxious', 'nervous', 'uneasy', 'tense', 'on edge', 'restless'])) return 'Anxious';
    return 'Sad';
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  /// Converts a mood label to a 1–7 numeric score.
  static int moodToScore(String label) {
    switch (label.toLowerCase()) {
      case 'happy':       return 7;
      case 'grateful':    return 7;
      case 'energetic':   return 6;
      case 'calm':        return 5;
      case 'neutral':     return 4;
      case 'anxious':     return 3;
      case 'sad':         return 3;
      case 'angry':       return 2;
      case 'overwhelmed': return 2;
      case 'depressed':   return 1;
      default:            return 4;
    }
  }

  /// Derives a stress score (0–100) from mood label + sentiment.
  static int stressFromMood(String moodLabel, int sentimentScore) {
    const moodBase = {
      'happy': 15, 'grateful': 12, 'energetic': 20, 'calm': 22, 'neutral': 40,
      'sad': 55, 'anxious': 70, 'angry': 75, 'overwhelmed': 82, 'depressed': 88,
    };
    int base = moodBase[moodLabel.toLowerCase()] ?? 40;
    base -= (sentimentScore * 2);
    return base.clamp(0, 100);
  }

  static List<String> generateInsights({
    required int stressScore,
    required List<MoodLog> recentMoods,
    required double sleepHours,
  }) {
    final List<String> insights = [];

    // ── Stress tier ──────────────────────────────────────────────────────────
    if (stressScore >= 80) {
      insights.add('🔴 Critical stress detected. Your body is in high-alert mode — try a 5-minute breathing session right now.');
    } else if (stressScore >= 60) {
      insights.add('🟠 Elevated stress. Step away from screens for 10 minutes and take a short walk to reset your nervous system.');
    } else if (stressScore >= 40) {
      insights.add('🟡 Mild stress present. A few minutes of deep breathing or light stretching can keep it in check.');
    } else {
      insights.add('🟢 Stress levels look healthy. Keep nurturing the habits that got you here!');
    }

    // ── Mood trend ────────────────────────────────────────────────────────────
    if (recentMoods.length >= 3) {
      final scores = recentMoods.take(5).map((l) => moodToScore(l.moodLabel)).toList();
      final recentAvg = scores.take(2).reduce((a, b) => a + b) / 2;
      final olderAvg  = scores.skip(2).reduce((a, b) => a + b) / (scores.length - 2);

      if (recentAvg < olderAvg - 1) {
        insights.add('📉 Your mood has been declining. Journaling your thoughts can help surface hidden triggers.');
      } else if (recentAvg > olderAvg + 1) {
        insights.add('📈 Your mood is trending upward — great work! Keep doing what\'s working for you.');
      } else {
        insights.add('〰 Your mood has been consistent. Stability is a real strength — keep building on it.');
      }
    }

    // ── Sleep ─────────────────────────────────────────────────────────────────
    if (sleepHours < 5) {
      insights.add('😴 Severe sleep deficit (under 5 hrs). Poor sleep amplifies stress and anxiety — prioritise 7–9 hours tonight.');
    } else if (sleepHours < 7) {
      insights.add('🌙 Slightly under the recommended sleep. Even 30 extra minutes meaningfully improves mood and focus.');
    } else if (sleepHours >= 9) {
      insights.add('⏰ Sleeping more than 9 hours can signal low energy or mood dips. A consistent wake time may help.');
    }

    // ── Mood-specific action tips ─────────────────────────────────────────────
    if (recentMoods.isNotEmpty) {
      final last = recentMoods.first.moodLabel.toLowerCase();
      switch (last) {
        case 'anxious':
          insights.add('💨 Try the 4-7-8 technique: inhale for 4 s, hold for 7 s, exhale for 8 s. Repeat 3 times to calm your nervous system.');
          break;
        case 'angry':
          insights.add('🥊 Physical movement is the fastest way to reduce anger. A brisk 10-minute walk can lower cortisol levels significantly.');
          break;
        case 'overwhelmed':
          insights.add('🗂️ Write down everything on your mind, then pick just ONE task to act on. Small steps break the overwhelm loop.');
          break;
        case 'depressed':
          insights.add('💙 You are not alone. Reaching out to someone you trust — even a brief message — can make a real difference today.');
          break;
        case 'sad':
          insights.add('🎵 Music, a warm drink, or a short walk can gently shift your mood. Be kind to yourself right now.');
          break;
        case 'grateful':
          insights.add('✨ Gratitude is one of the strongest mood boosters. Consider writing down 3 specific things you appreciate today.');
          break;
        case 'energetic':
          insights.add('⚡ High energy is the perfect time to tackle a goal you have been putting off. Ride this momentum!');
          break;
        case 'happy':
          insights.add('😊 You are in a great headspace. Consider sharing your positivity — helping others amplifies your own happiness.');
          break;
      }
    }

    return insights;
  }

  static int _moodToScore(String label) => moodToScore(label);
}

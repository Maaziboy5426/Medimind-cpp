import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../core/config/gemini_config.dart';
import '../models/chat_models.dart';
import 'activity_tracker_service.dart';
import 'mental_health_service.dart';

class GeminiService {
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  Future<String> sendMessage(String userText, List<ChatMessage> history) async {
    final context = await _getHealthContext();
    final systemPrompt =
        'You are MedMind AI, a friendly health and wellness assistant embedded in the MedMind app. '
        'Provide safe, helpful general health advice about fitness, nutrition, sleep, mental wellness, hydration, and lifestyle. '
        'Never diagnose diseases. Always recommend consulting a doctor for medical issues. '
        'Keep answers concise, warm, and practical. End with a brief disclaimer when giving medical-adjacent advice.';

    final contents = <Map<String, dynamic>>[];
    for (var msg in history.takeLast(10)) {
      contents.add({
        'role': msg.role == ChatRole.user ? 'user' : 'model',
        'parts': [{'text': msg.content}],
      });
    }
    final fullPrompt = context.isNotEmpty
        ? 'User Health Context:\n$context\n\nUser Message: $userText'
        : userText;
    contents.add({'role': 'user', 'parts': [{'text': fullPrompt}]});

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {'parts': [{'text': systemPrompt}]},
          'contents': contents,
          'generationConfig': {'maxOutputTokens': 512, 'temperature': 0.7},
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.toString().trim().isNotEmpty) return text;
      }
    } catch (_) {
      // Fall through to local responder
    }

    // --- Local intelligent fallback ---
    return _localRespond(userText, context);
  }

  /// Rule-based smart health responder — used when API is unavailable
  String _localRespond(String text, String ctx) {
    final q = text.toLowerCase();

    if (_matches(q, ['sleep', 'insomnia', 'tired', 'fatigue', 'rest', 'dose off', 'cant sleep'])) {
      return _pick([
        'Getting 7–9 hours of sleep is one of the most powerful things you can do for your health. '
        'Try setting a consistent bedtime, avoid screens for 30 minutes before bed, and keep your bedroom cool and dark. 🌙\n\n'
        '_Disclaimer: If you have chronic sleep issues, please consult a doctor._',
        'Poor sleep can affect mood, weight, and immunity. Wind-down routines like reading, light stretching, or meditation '
        'can help a lot. Avoiding caffeine after 2 PM is also very effective. 💤',
      ]);
    }

    if (_matches(q, ['water', 'hydrat', 'drink', 'dehydrat', 'thirst'])) {
      return _pick([
        'Staying well-hydrated is essential! The standard recommendation is 8 cups (2 litres) per day, '
        'but it depends on your size and activity level. A good rule: your urine should be pale yellow. 💧\n\n'
        'Try keeping a water bottle with you at all times and setting hourly reminders.',
        'Dehydration can cause headaches, fatigue, and poor concentration. '
        'If you struggle to drink plain water, try infusing it with lemon, mint, or cucumber. Your body will thank you! 💧',
      ]);
    }

    if (_matches(q, ['stress', 'anxious', 'anxiety', 'worry', 'nervous', 'panic', 'overwhelm'])) {
      return _pick([
        'Feeling stressed or anxious is very common. Here are some science-backed techniques:\n\n'
        '• **Box breathing**: Inhale 4s → Hold 4s → Exhale 4s → Hold 4s\n'
        '• **5-4-3-2-1 grounding**: Name 5 things you see, 4 you hear, 3 you can touch\n'
        '• **Light exercise**: Even a 10-minute walk reduces cortisol significantly\n\n'
        '_If anxiety is impacting your daily life, please consider speaking with a mental health professional._',
        'Chronic stress affects your heart, sleep, and immune system. Try journaling, limiting news intake, '
        'and scheduling one enjoyable activity per day. Small habits add up! 🧘\n\n'
        '_Please consult a professional if stress feels unmanageable._',
      ]);
    }

    if (_matches(q, ['exercise', 'workout', 'gym', 'fitness', 'active', 'sport', 'run', 'walk', 'steps'])) {
      return _pick([
        'The WHO recommends at least 150 minutes of moderate activity per week — that\'s just 30 minutes, 5 days a week! '
        '🏃 You can split this into 10-minute walks if needed.\n\nFor strength, aim for 2 muscle-strengthening sessions per week. '
        'Consistency beats intensity every time.',
        'Some great low-impact exercises for beginners:\n• Brisk walking (great start!)\n• Swimming\n• Cycling\n• Yoga\n\n'
        'The best exercise is one you actually enjoy and will stick with! 💪',
      ]);
    }

    if (_matches(q, ['eat', 'diet', 'food', 'nutrition', 'meal', 'calori', 'weight', 'fruit', 'vegetabl'])) {
      return _pick([
        'A balanced diet doesn\'t have to be complicated:\n\n'
        '• **Half your plate**: vegetables and fruits\n'
        '• **Quarter**: whole grains (brown rice, oats, wholemeal bread)\n'
        '• **Quarter**: lean protein (chicken, fish, beans, eggs)\n\n'
        'Try to minimise processed foods, sugary drinks, and excess salt. 🥗',
        'Meal prepping once a week can dramatically improve your eating habits. '
        'Even preparing 3-4 healthy meals in advance removes the temptation of ordering out. '
        'Focus on whole, minimally processed foods and your body will feel the difference! 🥦',
      ]);
    }

    if (_matches(q, ['mood', 'sad', 'depress', 'happy', 'mental health', 'emotion', 'feeling'])) {
      return _pick([
        'Your mental health is just as important as your physical health. '
        'Some evidence-based mood boosters:\n\n'
        '• **Exercise**: Releases endorphins naturally\n'
        '• **Social connection**: Call a friend or family member\n'
        '• **Sunlight**: 15-20 min outdoors improves serotonin\n'
        '• **Gratitude journaling**: Write 3 things you\'re grateful for\n\n'
        '_For persistent low mood, please reach out to a mental health professional._',
        'Low mood can sometimes be linked to poor sleep, low vitamin D, or nutritional deficiencies. '
        'Getting bloodwork done once a year is a great idea. 💙\n\n'
        '_Always consult a healthcare professional if you\'re struggling._',
      ]);
    }

    if (_matches(q, ['bmi', 'weight', 'overweight', 'obese', 'fat', 'slim'])) {
      return 'BMI (Body Mass Index) is one indicator of health, but it\'s not the full picture — '
          'it doesn\'t account for muscle mass, bone density, or where fat is distributed.\n\n'
          'A healthy BMI range is typically 18.5–24.9. Focus on sustainable habits:\n'
          '• Eating mostly whole foods\n'
          '• Moving your body daily\n'
          '• Getting enough sleep\n\n'
          'Weight management is a long game — consistency beats crash diets every time! 🎯\n\n'
          '_Consult a doctor or dietitian for personalised advice._';
    }

    if (_matches(q, ['headache', 'migrain', 'pain', 'ache'])) {
      return 'Common causes of headaches include:\n\n'
          '• **Dehydration** — drink a glass of water first\n'
          '• **Eye strain** — follow the 20-20-20 rule (every 20min, look 20ft away for 20s)\n'
          '• **Tension** — try neck stretches and shoulder rolls\n'
          '• **Lack of sleep** — aim for 7-8 hours\n'
          '• **Skipped meals** — blood sugar dips can trigger headaches\n\n'
          '_Frequent or severe headaches should be evaluated by a doctor._';
    }

    if (_matches(q, ['vitamin', 'supplement', 'mineral', 'deficien'])) {
      return 'Some common deficiencies and their signs:\n\n'
          '• **Vitamin D**: fatigue, bone pain, low mood — get 15-20 min of sunlight daily\n'
          '• **Iron**: tiredness, pale skin — eat more leafy greens and lean meat\n'
          '• **B12**: numbness, fatigue — common in vegetarians/vegans\n'
          '• **Magnesium**: muscle cramps, poor sleep — found in nuts, seeds, dark chocolate\n\n'
          'Always get a blood test before starting supplements! 💊\n\n'
          '_Consult your doctor before adding any supplement to your routine._';
    }

    if (_matches(q, ['hello', 'hi ', 'hey', 'good morning', 'good evening', 'how are you', 'help'])) {
      return 'Hello! 👋 I\'m MedMind AI, your personal health and wellness assistant.\n\n'
          'I can help you with:\n'
          '• 💤 Sleep improvement tips\n'
          '• 🏃 Exercise & fitness guidance\n'
          '• 🥗 Nutrition advice\n'
          '• 🧘 Stress & mental wellness\n'
          '• 💧 Hydration & lifestyle tips\n\n'
          'What would you like to talk about today?';
    }

    // Generic thoughtful response
    return 'That\'s a great health question! Here are some general principles that often help:\n\n'
        '• **Sleep well**: 7-9 hours is the foundation of good health\n'
        '• **Stay hydrated**: 2 litres of water per day minimum\n'
        '• **Move daily**: Even a 30-minute walk makes a big difference\n'
        '• **Eat whole foods**: Prioritise vegetables, lean protein, and whole grains\n'
        '• **Manage stress**: Breathing exercises and regular breaks help enormously\n\n'
        'For more specific advice on your question, I\'d recommend speaking with a healthcare professional. '
        'Is there a specific area of health you\'d like to focus on? 😊';
  }

  bool _matches(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  String _pick(List<String> options) =>
      options[Random().nextInt(options.length)];

  Future<String> _getHealthContext() async {
    try {
      final activityBox  = Hive.box(ActivityTrackerService.activityLogsBoxName);
      final sleepBox     = Hive.box(ActivityTrackerService.sleepLogsBoxName);
      final bodyBox      = Hive.box(ActivityTrackerService.bodyMetricsBoxName);
      final moodBox      = Hive.box(MentalHealthService.moodLogsBoxName);

      final parts = <String>[];

      if (bodyBox.values.isNotEmpty) {
        final b = bodyBox.values.last;
        if (b is Map) {
          if (b['age'] != null) parts.add('Age: ${b['age']}');
          if (b['bmi'] != null) parts.add('BMI: ${(b['bmi'] as num).toStringAsFixed(1)}');
        }
      }
      if (sleepBox.values.isNotEmpty) {
        final s = sleepBox.values.last;
        if (s is Map && s['sleepDuration'] != null) {
          parts.add('Last sleep: ${(s['sleepDuration'] as num).toStringAsFixed(1)} hours');
        }
      }
      if (activityBox.values.isNotEmpty) {
        final a = activityBox.values.last;
        if (a is Map && a['steps'] != null) {
          parts.add('Recent steps: ${a['steps']}');
        }
      }
      if (moodBox.values.isNotEmpty) {
        final m = moodBox.values.last;
        if (m is Map && m['moodLabel'] != null) {
          parts.add('Recent mood: ${m['moodLabel']}');
        }
      }

      return parts.join('\n');
    } catch (_) {
      return '';
    }
  }
}

extension on List {
  List takeLast(int n) => length <= n ? this : sublist(length - n);
}

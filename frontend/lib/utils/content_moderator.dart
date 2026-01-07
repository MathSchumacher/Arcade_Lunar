/// Content Moderation System
/// Automatically determines age rating based on game, chat content, and reports
library;

/// Age rating levels
enum AgeRating {
  everyone(0, 'Livre', 'L'),
  age10(10, '10+', '10'),
  age12(12, '12+', '12'),
  age14(14, '14+', '14'),
  age16(16, '16+', '16'),
  age18(18, '18+', '18');

  final int minAge;
  final String label;
  final String badge;

  const AgeRating(this.minAge, this.label, this.badge);
}

/// Official game ratings (based on ESRB/PEGI/DEJUS)
class GameRatings {
  static final Map<String, AgeRating> _ratings = {
    // Livre (Everyone)
    'minecraft': AgeRating.everyone,
    'fall-guys': AgeRating.everyone,
    'rocket-league': AgeRating.everyone,
    'just-chatting': AgeRating.everyone,
    'pokemon': AgeRating.everyone,
    'mario': AgeRating.everyone,
    'animal-crossing': AgeRating.everyone,
    'roblox': AgeRating.everyone,
    
    // 10+
    'fortnite': AgeRating.age10,
    'splatoon': AgeRating.age10,
    'overwatch-2': AgeRating.age12,
    
    // 12+
    'league-of-legends': AgeRating.age12,
    'valorant': AgeRating.age12,
    'apex-legends': AgeRating.age12,
    'dota-2': AgeRating.age12,
    'hearthstone': AgeRating.age12,
    
    // 14+
    'counter-strike-2': AgeRating.age14,
    'cs2': AgeRating.age14,
    'rainbow-six': AgeRating.age14,
    'destiny-2': AgeRating.age14,
    
    // 16+
    'call-of-duty': AgeRating.age16,
    'battlefield': AgeRating.age16,
    'gta-online': AgeRating.age16,
    'dead-by-daylight': AgeRating.age16,
    'resident-evil': AgeRating.age16,
    
    // 18+
    'gta-v': AgeRating.age18,
    'the-witcher': AgeRating.age18,
    'cyberpunk-2077': AgeRating.age18,
    'mortal-kombat': AgeRating.age18,
    'doom': AgeRating.age18,
    'rust': AgeRating.age18,
  };

  static AgeRating getGameRating(String gameSlug) {
    return _ratings[gameSlug.toLowerCase()] ?? AgeRating.everyone;
  }
}

/// Profanity filter with severity levels
class ProfanityFilter {
  // Severity: 1 = mild, 2 = moderate, 3 = severe, 4 = extreme
  static final Map<String, int> _badWords = {
    // Portuguese - Mild (1)
    'droga': 1, 'merda': 1, 'porra': 1, 'cacete': 1, 'caramba': 1,
    // Portuguese - Moderate (2)
    'puta': 2, 'caralho': 2, 'foda': 2, 'cuzao': 2,
    // Portuguese - Severe (3)
    'viado': 3, 'bicha': 3, 'arrombado': 3,
    // Portuguese - Extreme (4) - hate speech, slurs
    // [redacted for policy - would include actual detection]
    
    // English - Mild (1)
    'damn': 1, 'hell': 1, 'crap': 1,
    // English - Moderate (2)
    'shit': 2, 'ass': 2, 'bitch': 2,
    // English - Severe (3)
    'fuck': 3,
    // English - Extreme (4)
    // [redacted]
    
    // Sexual content indicators (4)
    'onlyfans': 4, 'nudes': 4, 'safado': 4, 'gostosa': 3,
  };

  /// Analyze text and return severity score
  static int analyzeText(String text) {
    final lowerText = text.toLowerCase();
    int maxSeverity = 0;
    
    for (final entry in _badWords.entries) {
      if (lowerText.contains(entry.key)) {
        if (entry.value > maxSeverity) {
          maxSeverity = entry.value;
        }
      }
    }
    
    return maxSeverity;
  }

  /// Censor text for minors
  static String censorText(String text, {required int userAge}) {
    String result = text;
    
    for (final entry in _badWords.entries) {
      // Determine which words to censor based on user age
      bool shouldCensor = false;
      
      if (userAge < 12 && entry.value >= 1) shouldCensor = true;
      if (userAge < 14 && entry.value >= 2) shouldCensor = true;
      if (userAge < 16 && entry.value >= 3) shouldCensor = true;
      if (userAge < 18 && entry.value >= 4) shouldCensor = true;
      
      if (shouldCensor) {
        result = result.replaceAll(
          RegExp(entry.key, caseSensitive: false),
          '*' * entry.key.length,
        );
      }
    }
    
    return result;
  }
}

/// Stream content analyzer - determines live stream age rating
class StreamContentAnalyzer {
  final String gameSlug;
  final List<String> _recentMessages = [];
  int _totalSeverityScore = 0;
  int _reportCount = 0;
  int _adultContentReports = 0;
  
  StreamContentAnalyzer({required this.gameSlug});

  /// Get base rating from game
  AgeRating get baseRating => GameRatings.getGameRating(gameSlug);

  /// Calculate current stream rating based on all factors
  AgeRating calculateCurrentRating() {
    AgeRating rating = baseRating;
    
    // Factor 1: Chat content severity
    final avgSeverity = _recentMessages.isEmpty 
        ? 0 
        : _totalSeverityScore / _recentMessages.length;
    
    if (avgSeverity >= 3) {
      rating = _elevateRating(rating, AgeRating.age16);
    } else if (avgSeverity >= 2) {
      rating = _elevateRating(rating, AgeRating.age14);
    } else if (avgSeverity >= 1) {
      rating = _elevateRating(rating, AgeRating.age12);
    }
    
    // Factor 2: Reports
    if (_adultContentReports >= 3) {
      rating = _elevateRating(rating, AgeRating.age18);
    } else if (_reportCount >= 5) {
      rating = _elevateRating(rating, AgeRating.age16);
    }
    
    return rating;
  }

  /// Process incoming chat message
  void processMessage(String message) {
    final severity = ProfanityFilter.analyzeText(message);
    _totalSeverityScore += severity;
    _recentMessages.add(message);
    
    // Keep only last 100 messages for rolling average
    if (_recentMessages.length > 100) {
      _recentMessages.removeAt(0);
      // Approximate removal of old score
      _totalSeverityScore = (_totalSeverityScore * 0.99).round();
    }
  }

  /// Add user report
  void addReport({bool isAdultContent = false}) {
    _reportCount++;
    if (isAdultContent) {
      _adultContentReports++;
    }
  }

  /// Elevate rating to at least the target level
  AgeRating _elevateRating(AgeRating current, AgeRating target) {
    return current.minAge >= target.minAge ? current : target;
  }

  /// Check if user can access this stream
  bool canUserAccess(int userAge) {
    return userAge >= calculateCurrentRating().minAge;
  }

  /// Get censored message for user
  String getCensoredMessage(String message, int userAge) {
    return ProfanityFilter.censorText(message, userAge: userAge);
  }
}

/// Content report types
enum ReportType {
  spam('Spam'),
  harassment('Assédio'),
  hate('Discurso de Ódio'),
  violence('Violência Extrema'),
  adultContent('Conteúdo Adulto'),
  minorInDanger('Menor em Perigo'),
  illegalContent('Conteúdo Ilegal');

  final String label;
  const ReportType(this.label);
}

/// Report a stream or user
class ContentReport {
  final String reporterId;
  final String targetId;
  final ReportType type;
  final String? description;
  final DateTime timestamp;

  ContentReport({
    required this.reporterId,
    required this.targetId,
    required this.type,
    this.description,
  }) : timestamp = DateTime.now();

  /// Check if report should escalate age rating
  bool get escalatesAgeRating => 
    type == ReportType.adultContent ||
    type == ReportType.violence ||
    type == ReportType.hate;
}

/// Username/Nickname Validator
class UsernameValidator {
  /// Inappropriate words/patterns for usernames
  static final List<String> _inappropriatePatterns = [
    // Profanity
    'fuck', 'shit', 'ass', 'bitch', 'dick', 'cock', 'pussy', 'cunt',
    'puta', 'caralho', 'foda', 'cuzao', 'viado', 'bicha', 'arrombado',
    // Sexual
    'xxx', 'porn', 'sex', 'nude', 'onlyfans', 'safado', 'gostosa',
    // Hate/Offensive
    'nazi', 'hitler', 'kkk', 'nigger', 'faggot',
    // Impersonation attempts
    'admin', 'moderator', 'staff', 'official', 'support',
    // Spam patterns
    'free', 'hack', 'cheat', 'bot',
  ];

  /// Reserved usernames
  static final Set<String> _reservedUsernames = {
    'admin', 'administrator', 'mod', 'moderator', 'staff', 'support',
    'help', 'info', 'arcade', 'lunar', 'arcadelunar', 'system',
    'official', 'verified', 'null', 'undefined', 'api', 'root',
  };

  /// Validate username - returns error message or null if valid
  static String? validate(String username) {
    final lower = username.toLowerCase();
    
    // Check length
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (username.length > 20) return 'Username must be 20 characters or less';
    
    // Check format (letters, numbers, underscore only)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscore';
    }
    
    // Check reserved
    if (_reservedUsernames.contains(lower)) {
      return 'This username is reserved';
    }
    
    // Check inappropriate content
    for (final pattern in _inappropriatePatterns) {
      if (lower.contains(pattern)) {
        return 'This username contains inappropriate content';
      }
    }
    
    // Check for excessive numbers/special chars
    final letterCount = RegExp(r'[a-zA-Z]').allMatches(username).length;
    if (letterCount < 2) {
      return 'Username must contain at least 2 letters';
    }
    
    return null; // Valid
  }

  /// Check if username is available (mock - should call API)
  static Future<bool> isAvailable(String username) async {
    // TODO: Check with backend API
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}

/// Link Moderator - Detects and blocks 18+ platform links
class LinkModerator {
  /// 18+ platforms/domains to block
  static final Set<String> _adultPlatforms = {
    // Adult content platforms
    'onlyfans.com', 'fansly.com', 'fanvue.com', 'loyalfans.com',
    'patreon.com/nsfw', 'gumroad.com/nsfw',
    'pornhub.com', 'xvideos.com', 'xnxx.com', 'xhamster.com',
    'chaturbate.com', 'myfreecams.com', 'stripchat.com',
    'manyvids.com', 'clips4sale.com',
    
    // Dating/hookup
    'tinder.com', 'grindr.com', 'adam4adam.com',
    
    // Gambling
    'bet365.com', 'betfair.com', 'pokerstars.com',
  };

  /// Keywords that indicate 18+ content in URLs
  static final List<String> _adultKeywords = [
    'onlyfans', 'fansly', 'porn', 'xxx', 'adult', 'nsfw',
    'nude', 'naked', 'sex', 'escort', 'cam', 'webcam',
    'stripper', 'hookup', 'dating',
  ];

  /// Check if a URL is 18+ content - returns blocking reason or null if allowed
  static String? checkLink(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Extract domain
    String domain = '';
    try {
      if (lowerUrl.startsWith('http')) {
        domain = Uri.parse(lowerUrl).host.toLowerCase();
      } else {
        // Handle URLs without protocol
        domain = lowerUrl.split('/')[0].toLowerCase();
      }
    } catch (e) {
      // Invalid URL format
    }
    
    // Remove www. prefix
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }
    
    // Check against blocked platforms
    for (final platform in _adultPlatforms) {
      if (domain.contains(platform.split('/')[0]) || lowerUrl.contains(platform)) {
        return 'Adult content platforms are not allowed';
      }
    }
    
    // Check for adult keywords in URL
    for (final keyword in _adultKeywords) {
      if (lowerUrl.contains(keyword)) {
        return 'Links containing adult content are not allowed';
      }
    }
    
    return null; // Link is allowed
  }

  /// Check multiple links at once
  static Map<String, String?> checkLinks(List<String> urls) {
    return {for (var url in urls) url: checkLink(url)};
  }

  /// Get user-friendly message for blocked link
  static String getBlockedMessage(String reason) {
    return '⚠️ Link blocked: $reason. '
        'Adult content links are prohibited to protect our community. '
        'Please use appropriate links only.';
  }
}


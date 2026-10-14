class AppConstants {
  AppConstants._();

  static const String appName = 'Mathra Arrow Escape';

  // ====== EDIT THESE: your own links & premium codes ======
  static const String developerName = 'Denuwan Akash';
  // Star button (home screen) -> your GitHub repo
  static const String repoUrl = 'https://www.tiktok.com/@mathra_quotes_1';
  // Heart / "Buy me a coffee" / "Get Unlock Code" -> your payment or contact page
  static const String supportUrl = 'https://wa.me/94783756055';
  // Premium unlock codes. Give one of these numbers/codes to a customer
  // after they pay. Add as many as you like (compared ignoring case/spaces).
  // Optional universal codes (work on every phone). Leave empty [] to use
  // only per-phone codes (recommended).
  static const List<String> premiumCodes = [];
  // WhatsApp number (country code, no +) that receives unlock requests.
  static const String whatsappNumber = '94783756055';
  // SECRET used to make per-phone codes. CHANGE THIS and keep the same value in
  // tools/make_code.py. Never share it.
  static const String unlockSecret = 'CHANGE_ME_mathra_2026';

  /// 6-digit code for a given device id (must match tools/make_code.py).
  static String codeForDevice(String deviceId) {
    final bytes = (unlockSecret + deviceId + unlockSecret).codeUnits;
    int h = 2166136261;
    for (final b in bytes) {
      h ^= b;
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return ((h % 900000) + 100000).toString();
  }

  static String unlockRequestUrl(String deviceId) {
    final text = Uri.encodeComponent(
        'Hi! I want the premium unlock code for Mathra Arrow Escape.\nMy ID: $deviceId');
    return 'https://wa.me/$whatsappNumber?text=$text';
  }
  // About screen buttons: (label, icon key, url). Add/remove freely.
  // icon keys: whatsapp, facebook, instagram, youtube, tiktok, telegram, github, email, web
  static const List<List<String>> aboutLinks = [
    ['WhatsApp', 'whatsapp', 'https://wa.me/94783756055'],
    ['TikTok', 'tiktok', 'https://www.tiktok.com/@mathra_quotes_1'],
  ];
  // ========================================================

  static const int maxLives = 3;

  static const int bossLevelEvery = 5;   
  static const int godLevelEvery  = 10;  

  static const Duration arrowShakeDuration = Duration(milliseconds: 400);

  static int bossCycleCount(int level) {
    int count = 0;
    for (int l = 1; l <= level; l++) {
      if (levelTypeFor(l) == LevelType.boss) count++;
    }
    return count;
  }

  static int godCycleCount(int level) {
    int count = 0;
    for (int l = 1; l <= level; l++) {
      if (levelTypeFor(l) == LevelType.god) count++;
    }
    return count;
  }

  static int gridSizeForLevel(int level) {
    final type = levelTypeFor(level);

    if (type == LevelType.god) {
      final raw = 22 + ((level / 50.0) * 1.2).round();
      return raw.clamp(22, 32);
    }

    if (type == LevelType.boss) {
      final raw = 20 + ((level / 50.0) * 1.2).round();
      return raw.clamp(20, 30);
    }

    if (level <= 10) {
      return 10 + ((level - 1) * 0.44).round();
    } else if (level <= 50) {
      return 14 + ((level - 10) * 0.15).round();
    } else if (level <= 150) {
      return 20 + ((level - 50) * 0.05).round();
    } else if (level <= 300) {
      return 25 + ((level - 150) * 0.03).round();
    } else if (level <= 500) {
      return 29 + ((level - 300) * 0.01).round();
    } else {
      return 32;
    }
  }

  static LevelType levelTypeFor(int level) {
    if (level % godLevelEvery == 0) return LevelType.god;
    if (level % bossLevelEvery == 0) return LevelType.boss;
    return LevelType.normal;
  }

  static double canvasScaleForType(LevelType type) {
    switch (type) {
      case LevelType.god:  return 0.93;
      case LevelType.boss: return 0.93;
      default:             return 0.90;
    }
  }

  static const int randomEasyMin = 11;
  static const int randomEasyMax = 50;
  static const int randomMediumMin = 51;
  static const int randomMediumMax = 150;
  static const int randomHardMin = 151;
  static const int randomHardMax = 300;
  static const int randomMasterMin = 301;
  static const int randomMasterMax = 500;
  static const int randomExpertMin = 501;
  static const int randomExpertMax = 700;
}

enum LevelType {
  normal,
  boss,
  god;
}
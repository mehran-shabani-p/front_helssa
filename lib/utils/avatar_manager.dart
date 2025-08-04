/* avatar_manager.dart
unique avatar generation and management */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

/* =============================================================================
ENUM : الگوهای پس‌زمینه
============================================================================= */

enum PatternType {
  modernDots('نقطه‌های مدرن'),
  neonLines('خطوط نئون'),
  galaxyCircles('دایره‌های کهکشانی'),
  crystalWaves('موج‌های کریستالی'),
  geometricHexagons('شش‌ضلعی هندسی'),
  sparkles('ستاره‌ها'),
  gradient3D('گرادیان سه‌بعدی');

  final String persianName;
  const PatternType(this.persianName);
}

/* =============================================================================
ENUM : نمادهای آواتار
============================================================================= */

enum AvatarSymbol {
  diamond('💎'),
  star('⭐'),
  heart('❤️'),
  lightning('⚡'),
  crown('👑'),
  fire('🔥'),
  rocket('🚀'),
  gem('💍'),
  shield('🛡️'),
  sword('⚔️'),
  magic('✨'),
  sun('☀️'),
  moon('🌙'),
  flower('🌸'),
  tree('🌳'),
  mountain('🏔️'),
  wave('🌊'),
  snowflake('❄️'),
  rainbow('🌈'),
  peace('☮️'),
  infinity('♾️'),
  music('🎵'),
  art('🎨'),
  book('📚'),
  key('🔑'),
  compass('🧭'),
  crystal('🔮'),
  butterfly('🦋'),
  eagle('🦅'),
  lion('🦁');

  final String symbol;
  const AvatarSymbol(this.symbol);
}

/* =============================================================================
AvatarManager -- ذخیره‌سازی و مدیریت تنظیمات آواتار.
============================================================================= */

class AvatarManager {
  static const String _storageKey = 'local_avatar_settings';

  /// پالت‌های گرادیان.
  static const List<List<Color>> defaultColorPalettes = [
    [Color(0xFF00BCD4), Color(0xFF0097A7)],
    [Color(0xFFFF6B6B), Color(0xFFAD1457)],
    [Color(0xFFFFBE0B), Color(0xFFF57F17)],
    [Color(0xFF4E65FF), Color(0xFF283593)],
    [Color(0xFF43E97B), Color(0xFF1B5E20)],
    [Color(0xFF9C27B0), Color(0xFF4A148C)],
    [Color(0xFFE91E63), Color(0xFF880E4F)],
    [Color(0xFF795548), Color(0xFF3E2723)],
    [Color(0xFF607D8B), Color(0xFF263238)],
    [Color(0xFFFF9800), Color(0xFFE65100)],
    [Color(0xFF8BC34A), Color(0xFF33691E)],
    [Color(0xFF00E676), Color(0xFF00C853)],
    [Color(0xFF1DE9B6), Color(0xFF00BFA5)],
    [Color(0xFF84FFFF), Color(0xFF00E5FF)],
    [Color(0xFF8C9EFF), Color(0xFF3D5AFE)],
    [Color(0xFFFF8A65), Color(0xFFBF360C)],
    [Color(0xFFBA68C8), Color(0xFF6A1B9A)],
    [Color(0xFF81C784), Color(0xFF2E7D32)],
    [Color(0xFFFFD54F), Color(0xFFF57F17)],
    [Color(0xFF90CAF9), Color(0xFF1565C0)],
  ];

  static List<List<Color>> get colorPalettes => defaultColorPalettes;

  late AvatarSettings currentSettings;
  final SharedPreferences prefs;

  AvatarManager(this.prefs) {
    _loadSettings();
  }

  void _loadSettings() {
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      currentSettings = AvatarSettings.fromJson(json.decode(jsonString));
    } else {
      currentSettings = AvatarSettings.defaults();
      _saveSettings();
    }
  }

  Future<void> _saveSettings() =>
      prefs.setString(_storageKey, json.encode(currentSettings.toJson()));

  Future<void> updateSettings(AvatarSettings newSettings) async {
    currentSettings = newSettings;
    await _saveSettings();
  }

  /// تولید آواتار یونیک بر اساس نام کاربری
  Future<void> generateAvatarFromUsername(String username) async {
    if (username.isEmpty) {
      await generateRandomAvatar();
      return;
    }

    // تولید هش از نام کاربری
    int hash = _generateHash(username);
    
    // انتخاب الگو بر اساس هش
    PatternType pattern = PatternType.values[hash % PatternType.values.length];
    
    // انتخاب پالت رنگ بر اساس هش
    int colorIndex = (hash >> 3) % defaultColorPalettes.length;
    
    // انتخاب نماد بر اساس هش
    AvatarSymbol symbol = AvatarSymbol.values[(hash >> 6) % AvatarSymbol.values.length];
    
    // انتخاب نماد ثانویه برای ترکیب (اختیاری)
    AvatarSymbol? secondarySymbol;
    if ((hash >> 9) % 3 == 0) { // 33% احتمال داشتن نماد دوم
      secondarySymbol = AvatarSymbol.values[(hash >> 12) % AvatarSymbol.values.length];
    }
    
    currentSettings = AvatarSettings(
      pattern: pattern.name,
      colorIndex: colorIndex,
      symbol: symbol.name,
      secondarySymbol: secondarySymbol?.name,
      animate: true,
    );
    
    await _saveSettings();
  }

  Future<void> generateRandomAvatar() async {
    final rnd = math.Random();
    
    // انتخاب نماد اصلی
    AvatarSymbol symbol = AvatarSymbol.values[rnd.nextInt(AvatarSymbol.values.length)];
    
    // 30% احتمال داشتن نماد ثانویه
    AvatarSymbol? secondarySymbol;
    if (rnd.nextBool() && rnd.nextBool()) {
      secondarySymbol = AvatarSymbol.values[rnd.nextInt(AvatarSymbol.values.length)];
    }
    
    currentSettings = AvatarSettings(
      pattern: PatternType.values[rnd.nextInt(PatternType.values.length)].name,
      colorIndex: rnd.nextInt(defaultColorPalettes.length),
      symbol: symbol.name,
      secondarySymbol: secondarySymbol?.name,
      animate: true,
    );
    await _saveSettings();
  }

  /// تولید هش یونیک از نام کاربری
  int _generateHash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.abs();
  }

  /// بررسی اینکه آیا آواتار فعلی متعلق به این نام کاربری است
  bool isCurrentAvatarForUsername(String username) {
    if (username.isEmpty) return false;
    
    int expectedHash = _generateHash(username);
    PatternType expectedPattern = PatternType.values[expectedHash % PatternType.values.length];
    int expectedColorIndex = (expectedHash >> 3) % defaultColorPalettes.length;
    AvatarSymbol expectedSymbol = AvatarSymbol.values[(expectedHash >> 6) % AvatarSymbol.values.length];
    
    return currentSettings.pattern == expectedPattern.name &&
           currentSettings.colorIndex == expectedColorIndex &&
           currentSettings.symbol == expectedSymbol.name;
  }
}

/* =============================================================================
AvatarSettings -- مدل دادهٔ آواتار.
============================================================================= */

class AvatarSettings {
  String pattern;
  int colorIndex;
  String symbol;
  String? secondarySymbol;
  bool animate;

  AvatarSettings({
    required this.pattern,
    required this.colorIndex,
    required this.symbol,
    this.secondarySymbol,
    required this.animate,
  });

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        'colorIndex': colorIndex,
        'symbol': symbol,
        'secondarySymbol': secondarySymbol,
        'animate': animate,
      };

  factory AvatarSettings.fromJson(Map<String, dynamic> json) => AvatarSettings(
        pattern: json['pattern'] ?? PatternType.modernDots.name,
        colorIndex: json['colorIndex'] ?? 0,
        symbol: json['symbol'] ?? AvatarSymbol.diamond.name,
        secondarySymbol: json['secondarySymbol'],
        animate: json['animate'] ?? true,
      );

  factory AvatarSettings.defaults() => AvatarSettings(
        pattern: PatternType.modernDots.name,
        colorIndex: 0,
        symbol: AvatarSymbol.diamond.name,
        animate: true,
      );

  AvatarSettings copyWith({
    String? pattern,
    int? colorIndex,
    String? symbol,
    String? secondarySymbol,
    bool? animate,
  }) =>
      AvatarSettings(
        pattern: pattern ?? this.pattern,
        colorIndex: colorIndex ?? this.colorIndex,
        symbol: symbol ?? this.symbol,
        secondarySymbol: secondarySymbol ?? this.secondarySymbol,
        animate: animate ?? this.animate,
      );
}

/* =============================================================================
LocalAvatar -- بدون قابلیت کلیک.
============================================================================= */

class LocalAvatar extends StatelessWidget {
  final AvatarSettings settings;
  final double size;

  const LocalAvatar({
    super.key,
    required this.settings,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AvatarManager.defaultColorPalettes[settings.colorIndex];
    
    // پیدا کردن نمادها
    final primarySymbol = AvatarSymbol.values
        .firstWhere((s) => s.name == settings.symbol, orElse: () => AvatarSymbol.diamond);
    
    final secondarySymbol = settings.secondarySymbol != null
        ? AvatarSymbol.values.firstWhere(
            (s) => s.name == settings.secondarySymbol,
            orElse: () => AvatarSymbol.star)
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: palette.first.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // نماد اصلی
          Text(
            primarySymbol.symbol,
            style: TextStyle(
              fontSize: size * 0.45,
            ),
          ),
          // نماد ثانویه (در گوشه)
          if (secondarySymbol != null)
            Positioned(
              top: size * 0.15,
              right: size * 0.15,
              child: Container(
                padding: EdgeInsets.all(size * 0.05),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  secondarySymbol.symbol,
                  style: TextStyle(
                    fontSize: size * 0.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* =============================================================================
AnimatedLocalAvatar -- فقط چرخش آرام؛ کلیک غیرفعال است.
============================================================================= */

class AnimatedLocalAvatar extends StatefulWidget {
  final AvatarSettings settings;
  final double size;

  const AnimatedLocalAvatar({
    super.key,
    required this.settings,
    this.size = 120,
  });

  @override
  State<AnimatedLocalAvatar> createState() => _AnimatedLocalAvatarState();
}

class _AnimatedLocalAvatarState extends State<AnimatedLocalAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    if (widget.settings.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = LocalAvatar(settings: widget.settings, size: widget.size);

    if (!widget.settings.animate) {
      return avatar;
    }

    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear),
      ),
      child: avatar,
    );
  }
}

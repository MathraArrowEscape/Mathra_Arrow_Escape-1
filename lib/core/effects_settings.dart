import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Shared on/off state for the visual effects (snow, rain, teddy ...).
/// Used by both the About screen and the in-game overlay, and saved with Hive.
class EffectsSettings extends ChangeNotifier {
  EffectsSettings._();
  static final EffectsSettings instance = EffectsSettings._();

  static const List<String> keys = [
    'snow', 'rain', 'lightning', 'arrows', 'sparks',
    'meteors', 'teddy', 'hearts', 'party', 'confetti',
  ];
  static const Set<String> _defaultsOn = {'snow', 'arrows', 'teddy'};

  final Map<String, bool> _v = {for (final k in keys) k: _defaultsOn.contains(k)};
  Box? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox('effects');
      for (final k in keys) {
        final saved = _box!.get(k);
        if (saved is bool) _v[k] = saved;
      }
    } catch (_) {}
  }

  bool get(String key) => _v[key] ?? false;
  bool get snow => get('snow');
  bool get rain => get('rain');
  bool get lightning => get('lightning');
  bool get arrows => get('arrows');
  bool get sparks => get('sparks');
  bool get meteors => get('meteors');
  bool get teddy => get('teddy');
  bool get hearts => get('hearts');
  bool get party => get('party');
  bool get confetti => get('confetti');

  bool get anyOn => _v.values.any((e) => e);
  bool get allOn => _v.values.every((e) => e);
  bool get stormy => rain || lightning;

  void toggle(String key) => set(key, !get(key));

  void set(String key, bool value) {
    _v[key] = value;
    _box?.put(key, value);
    notifyListeners();
  }

  void setAll(bool value) {
    for (final k in keys) {
      _v[k] = value;
      _box?.put(k, value);
    }
    notifyListeners();
  }
}

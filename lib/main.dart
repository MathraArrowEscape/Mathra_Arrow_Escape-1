import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_themes.dart';
import 'core/audio_haptic_helper.dart';
import 'core/effects_settings.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/level_repository.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AudioHapticHelper.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Hive.initFlutter();
  await EffectsSettings.instance.init();

  final progressRepo = await ProgressRepository.create();
  final levelRepo = await LevelRepository.create();

  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWith((ref) => progressRepo),
        levelRepositoryProvider.overrideWithValue(levelRepo),
      ],
      child: const ArrowPuzzleApp(),
    ),
  );
}

class ArrowPuzzleApp extends ConsumerWidget {
  const ArrowPuzzleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressRepo = ref.watch(progressRepositoryProvider);
    final themeColors = AppThemes.getThemeColors(progressRepo.selectedTheme);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: themeColors.isLight ? Brightness.dark : Brightness.light,
    ));

    return MaterialApp(
      title: 'Mathra Arrow Escape',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: themeColors.isLight ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: themeColors.background,
        fontFamily: 'BebasNeue',
      ),
      home: const HomeScreen(),
    );
  }
}

final progressRepositoryProvider = ChangeNotifierProvider<ProgressRepository>((ref) {
  throw UnimplementedError('Must be overridden');
});

final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  throw UnimplementedError('Must be overridden');
});
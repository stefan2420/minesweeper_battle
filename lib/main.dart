import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/battle_provider.dart';
import 'services/config_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase auto-initializes on Android via google-services.json
  // Just ensure it's ready, don't pass options to avoid duplicate
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Already initialized by native plugin, that's fine
  }

  // Initialize Crashlytics and wire up Flutter error handlers
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize app configuration from Firestore
  await ConfigService.instance.loadConfig();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => BattleProvider()),
      ],
      child: const MinesweeperApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/download_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait at the application level. The native player will
  // temporarily flip to landscape on entry and back on exit.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise flutter_downloader and register the global callback.
  // Note: in v1.12 the option is `ignoreSsl`, not `ignoreSslCertificate`.
  await FlutterDownloader.initialize(debug: true, ignoreSsl: false);
  FlutterDownloader.registerCallback(downloadCallbackDispatcher);

  // Initialise Hive for any future local storage (download history etc.).
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: CinebyApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_dependencies.dart';
import 'app/cofre_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final dependencies = await AppDependencies.create();
  runApp(CofreApp(dependencies: dependencies));
}

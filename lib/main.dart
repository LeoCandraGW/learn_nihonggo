import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/repository.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppRepository.open(); // opens + seeds SQLite on first launch
  runApp(const NihongoApp());
}

class NihongoApp extends StatelessWidget {
  const NihongoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日本語',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}

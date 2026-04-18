
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/injection_container.dart' as di;
import 'package:gomhor_alahly_clean_new/core/routes/app_router.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Clean Architecture',
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}

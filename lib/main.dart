import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/tasks/screens/task_form_screen.dart';
import 'features/tasks/screens/task_list_screen.dart';
import 'features/tasks/data/task_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());

  await Hive.openBox<TaskModel>(tasksBoxName);
  await Hive.openBox<int>(taskMetaBoxName);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'task_list',
          builder: (context, state) => const TaskListScreen(),
        ),
        GoRoute(
          path: '/form',
          name: 'task_form',
          pageBuilder: (context, state) {
            final task = state.extra as TaskModel?;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: TaskFormScreen(task: task),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                final tween = Tween<Offset>(begin: begin, end: end).chain(
                  CurveTween(curve: Curves.easeOutCubic),
                );
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Flodo Task App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}

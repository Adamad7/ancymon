import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/connection_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/pairing/presentation/pairing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AncyMonApp(),
    ),
  );
}

/// Root Application Widget for AncyMon
class AncyMonApp extends StatelessWidget {
  const AncyMonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AncyMon',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141721),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E222D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF181B26),
          elevation: 0,
          centerTitle: false,
        ),
        cardColor: const Color(0xFF1E222D),
        useMaterial3: true,
      ),
      home: const RootGate(),
    );
  }
}

/// Gateway widget determining whether to render PairingScreen or DashboardScreen
/// based on saved connection credentials in secure storage.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(connectionConfigProvider);

    return configAsync.when(
      data: (config) {
        if (config == null) {
          return const PairingScreen();
        }
        return const DashboardScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monitor_heart, size: 64, color: Colors.cyanAccent),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 54, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Failed to load connection state', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(connectionConfigProvider.notifier).loadStoredConfig(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

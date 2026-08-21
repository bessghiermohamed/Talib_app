import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'data/repository.dart';
import 'models/academic.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const TalibApp());
}

class TalibApp extends StatelessWidget {
  const TalibApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'طالب | Tâlib',
      debugShowCheckedModeBanner: false,
      theme: TalibTheme.light,
      darkTheme: TalibTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootGate(),
    );
  }
}

/// البوابة: تسجيل دخول؟ إعداد أكاديمي؟ التطبيق؟
class RootGate extends StatefulWidget {
  const RootGate({super.key});
  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final repo = TalibRepo();
  StreamSubscription<AuthState>? _sub;
  Profile? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    if (Supabase.instance.client.auth.currentUser == null) {
      setState(() {
        profile = null;
        loading = false;
      });
      return;
    }
    try {
      final p = await repo.myProfile();
      setState(() {
        profile = p;
        loading = false;
      });
    } catch (e) {
      setState(() {
        profile = null;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      return const AuthScreen();
    }
    if (profile == null || !profile!.isOnboarded) {
      return OnboardingScreen(onDone: _load);
    }
    return HomeShell(profile: profile!, onLogout: _load);
  }
}
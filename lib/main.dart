import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/reflection_history_screen.dart';
import 'screens/action_list_screen.dart';

// ★ Cloud Functions経由になったので、ここにあった geminiApiKey の行は削除しました

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutterのエラーハンドリング（開発中にあると便利なので残しています）
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ReadingHabitApp());
}

class ReadingHabitApp extends StatelessWidget {
  const ReadingHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '司書のいる書斎',
      
      // 画面上に赤いエラーが出る設定（デバッグ時は便利です）
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  details.exception.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          );
        };
        return child!;
      },

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Firebaseにログインしていればメイン画面へ、そうでなければログイン画面へ
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _idx = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ActionListScreen(),
    const ReflectionHistoryScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: '本棚'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: '実践'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '記憶'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: '記録'),
        ],
      ),
    );
  }
}
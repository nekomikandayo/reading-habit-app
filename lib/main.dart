import 'package:flutter/material.dart';

void main() {
  runApp(const ReadingHabitApp());
}

class ReadingHabitApp extends StatelessWidget {
  const ReadingHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reading Habit App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 設計の data-model.md をイメージしたダミーデータ
    final List<Map<String, String>> books = [
      {'title': '嫌われる勇気', 'author': '岸見 一郎', 'progress': '60%'},
      {'title': 'リーダブルコード', 'author': 'Dustin Boswell', 'progress': '20%'},
      {'title': 'ゼロ・トゥ・ワン', 'author': 'ピーター・ティール', 'progress': '90%'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイライブラリ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) { // ← ここを修正しました！
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.book, size: 40),
              title: Text(books[index]['title']!),
              subtitle: Text(books[index]['author']!),
              trailing: Text(books[index]['progress']!),
              onTap: () {
                print('${books[index]['title']} がタップされました');
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 次のステップでここを押した時の「本追加画面」を作ります
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('本追加画面は準備中です！')),
          );
        },
        tooltip: '本を追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
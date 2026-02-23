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
        itemView: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.book, size: 40),
              title: Text(books[index]['title']!),
              subtitle: Text(books[index]['author']!),
              trailing: Text(books[index]['progress']!),
              onTap: () {
                // ここに読書セッション画面への遷移を後ほど書きます
                print('${books[index]['title']} がタップされました');
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 本追加画面への遷移
        },
        tooltip: '本を追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
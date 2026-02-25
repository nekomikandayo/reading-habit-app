import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});
  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _t = TextEditingController(); // タイトル
  final _a = TextEditingController(); // 著者
  bool _isSearching = false;

  // 共通の Cloud Functions URL（v2 の .a.run.app に統一）
  final String _functionsUrl = 'https://generatepraise-njqdsqyfmq-an.a.run.app';

  // Google Books のサムネイル URL を少し高解像度版に寄せる
  String _normalizeThumbnail(String? url) {
    if (url == null || url.isEmpty) return '';
    final secure = url.replaceFirst('http://', 'https://');
    return secure.replaceAllMapped(RegExp(r'zoom=\d'), (m) => 'zoom=2');
  }

  @override
  void dispose() {
    _t.dispose();
    _a.dispose();
    super.dispose();
  }

  // Cloud Functions を経由してカバー画像を探す
  Future<String?> _fetchBookCover(String title, String author) async {
    try {
      final query = 'intitle:${Uri.encodeComponent(title)}+inauthor:${Uri.encodeComponent(author)}';
      
      final response = await http.post(
        Uri.parse(_functionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'actionTitle': query, // 検索クエリとして送信
          'type': 'search',     // Functions 側の Google Books API 分岐を使用
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data']['items']; // Functions の返却形式に合わせる
        if (items != null && items.length > 0) {
          String? thumb = items[0]['volumeInfo']['imageLinks']?['thumbnail'];
          return _normalizeThumbnail(thumb);
        }
      }
    } catch (e) {
      debugPrint("画像取得エラー: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("本を手動で登録", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.edit_note, size: 60, color: Colors.black26),
            const SizedBox(height: 30),
            
            TextField(
              controller: _t,
              decoration: InputDecoration(
                labelText: "タイトル",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _a,
              decoration: InputDecoration(
                labelText: "著者名",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity, 
              height: 55, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSearching ? null : () async {
                  if (_t.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("タイトルを入力してください"))
                    );
                    return;
                  }
                  
                  setState(() => _isSearching = true);
                  
                  // 画像を探しにいく
                  final cover = await _fetchBookCover(_t.text, _a.text);
                  
                  if (!mounted) return;
                  
                  // 結果を HomeScreen に戻す
                  Navigator.pop(context, {
                    'title': _t.text, 
                    'author': _a.text.isEmpty ? "著者不明" : _a.text, 
                    'progress': 0, 
                    'thumbnail': cover ?? "" // HomeScreenのキー名に合わせて thumbnail に変更
                  });
                },
                child: _isSearching 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("本棚に並べる", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Web専用のインポート
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});
  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _controller = TextEditingController();
  List _books = [];
  bool _isLoading = false;

  // Cloud Functions v2 の公式 URL（.a.run.app）を利用
  final String _functionsUrl =
      'https://generatepraise-njqdsqyfmq-an.a.run.app';

  // Google Books のサムネイル URL を少し高解像度版に寄せる
  String _normalizeThumbnail(String url) {
    if (url.isEmpty) return '';
    final secure = url.replaceAll('http://', 'https://');
    return secure.replaceAllMapped(RegExp(r'zoom=\d'), (m) => 'zoom=2');
  }

  Future<void> _searchBooks() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _books = [];
    });

    try {
      final res = await http.post(
        Uri.parse(_functionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'actionTitle': query,
          'type': 'search', 
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _books = data['data']['items'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("検索エラー: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addBook(Map book, {bool asWishlist = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final info = book['volumeInfo'];
    final String authors =
        (info['authors'] as List<dynamic>?)?.join(', ') ?? '著者不明';
    final String rawThumb = info['imageLinks']?['thumbnail'] ?? '';
    final String thumbnail = _normalizeThumbnail(rawThumb);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('books')
        .add({
      'title': info['title'] ?? '無題',
      'author': authors,
      'thumbnail': thumbnail,
      'progress': 0,
      'lastRead': FieldValue.serverTimestamp(),
      'isWishlist': asWishlist,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asWishlist
                ? "「${info['title']}」を買いたい本に追加しました"
                : "「${info['title']}」を本棚に加えました",
          ),
        ),
      );
    }
  }

  // ★ CORSエラーを回避して画像を表示、またはアイコンに切り替える関数
  Widget _buildBookCover(String url) {
    if (url.isEmpty) {
      return const Icon(Icons.book, color: Colors.brown, size: 30);
    }
    
    final String secureUrl = url.replaceAll('http://', 'https://');
    final String viewID = secureUrl;

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      return html.ImageElement()
        ..src = secureUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        // エラー時にアイコンっぽく見せるための色
        ..style.backgroundColor = '#fdf5e6'; 
    });

    return HtmlElementView(viewType: viewID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("新しい本との出会い"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "タイトル、著者名で検索...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _searchBooks(),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: Colors.black),
          Expanded(
            child: _books.isEmpty && !_isLoading
                ? const Center(child: Text("書斎に置く本を探しましょう", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final b = _books[index];
                      final info = b['volumeInfo'];
                      final thumb = info['imageLinks']?['thumbnail'] ?? '';

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          // ★ アイコン固定ではなく、画像表示関数を呼び出すように修正
                          leading: Container(
                            width: 45,
                            height: 65,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _buildBookCover(thumb),
                          ),
                          title: Text(info['title'] ?? '無題', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text((info['authors'] as List?)?.join(', ') ?? '著者不明'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite_border, color: Colors.redAccent),
                                tooltip: "買いたい本に追加",
                                onPressed: () => _addBook(b, asWishlist: true),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                tooltip: "本棚に加える",
                                onPressed: () => _addBook(b),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
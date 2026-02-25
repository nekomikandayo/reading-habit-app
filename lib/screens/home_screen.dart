import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_session_screen.dart';
import 'book_search_screen.dart';
// ★ Web専用のインポートを追加
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ★ WebのCORS制限を回避して画像を表示する関数
  Widget _buildWebImage(String url, {double? width, double? height}) {
    if (url.isEmpty) {
      final placeholder = Container(
        color: Colors.grey[200],
        child: const Icon(Icons.book, size: 40, color: Colors.grey),
      );
      if (width == null && height == null) {
        return SizedBox.expand(child: placeholder);
      }
      return SizedBox(width: width, height: height, child: placeholder);
    }

    final String secureUrl = url.replaceAll('http://', 'https://');
    final String viewID = secureUrl;

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      return html.ImageElement()
        ..src = secureUrl
        ..style.width = '100%'
        ..style.height = '100%'
        // 上から下までカバー全体が見えるように contain で表示
        ..style.objectFit = 'contain'
        ..style.backgroundColor = '#f5f5f5';
    });

    final view = HtmlElementView(viewType: viewID);
    if (width == null && height == null) {
      return SizedBox.expand(child: view);
    }
    return SizedBox(width: width, height: height, child: view);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("私の本棚"), centerTitle: true),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('books')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text("本がありません。\n右下の＋から本を追加しましょう！"),
            );
          }

          final allBooks = snap.data!.docs;

          // 本を 4 つのグループに分類
          final List<QueryDocumentSnapshot> wishlistBooks = [];
          final List<QueryDocumentSnapshot> readingBooks = [];
          final List<QueryDocumentSnapshot> unreadBooks = [];
          final List<QueryDocumentSnapshot> finishedBooks = [];

          for (final b in allBooks) {
            final data = b.data() as Map<String, dynamic>;
            final int p = data['progress'] ?? 0;
            final bool isWishlist = data['isWishlist'] ?? false;

            if (isWishlist) {
              wishlistBooks.add(b);
            } else if (p == 0) {
              unreadBooks.add(b);
            } else if (p == 100) {
              finishedBooks.add(b);
            } else {
              readingBooks.add(b);
            }
          }

          return CustomScrollView(
            slivers: [
              if (readingBooks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                        child: Text(
                          "今読んでいる本",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 440,
                        child: PageView.builder(
                          controller: PageController(viewportFraction: 0.8),
                          itemCount: readingBooks.length,
                          itemBuilder: (context, index) {
                            final bookData =
                                readingBooks[index].data() as Map<String, dynamic>;
                            final bookId = readingBooks[index].id;
                            return _buildMainBookCard(
                                context, bookData, bookId, uid!);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // 買いたい本（0 件でも見出しは常に表示）
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                  child: Text(
                    "買いたい本",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
              ),
              if (wishlistBooks.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bookData =
                          wishlistBooks[index].data() as Map<String, dynamic>;
                      final bookId = wishlistBooks[index].id;
                      return _buildOtherBookTile(
                          context, bookData, bookId, uid!);
                    },
                    childCount: wishlistBooks.length,
                  ),
                ),

              // 未読の本（0 件でも見出しは常に表示）
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                  child: Text(
                    "未読の本",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
              ),
              if (unreadBooks.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bookData =
                          unreadBooks[index].data() as Map<String, dynamic>;
                      final bookId = unreadBooks[index].id;
                      return _buildOtherBookTile(
                          context, bookData, bookId, uid!);
                    },
                    childCount: unreadBooks.length,
                  ),
                ),

              // 読み終えた本（0 件でも見出しは常に表示）
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                  child: Text(
                    "読み終えた本",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
              ),
              if (finishedBooks.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bookData =
                          finishedBooks[index].data() as Map<String, dynamic>;
                      final bookId = finishedBooks[index].id;
                      return _buildOtherBookTile(
                          context, bookData, bookId, uid!);
                    },
                    childCount: finishedBooks.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BookSearchScreen()));
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMainBookCard(BuildContext context, Map<String, dynamic> book,
      String bookId, String uid) {
    return GestureDetector(
      onTap: () => _openReadingRoom(context, book, bookId, uid),
      onLongPress: () =>
          _confirmDeletion(context, uid, bookId, book['title'] ?? "無題"),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 端末サイズに合わせて伸縮しつつ、縦長の比率を維持
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _buildWebImage(book['thumbnail'] ?? ""),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    book['title'] ?? "無題",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book['author'] ?? "著者不明",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (book['progress'] ?? 0) / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("${book['progress'] ?? 0}% 完了",
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDeletion(
                    context, uid, bookId, book['title'] ?? "無題"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherBookTile(BuildContext context, Map<String, dynamic> book,
      String bookId, String uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            // ★ Image.network を _buildWebImage に差し替え
            child: _buildWebImage(book['thumbnail'] ?? "", width: 45),
          ),
          title: Text(book['title'] ?? "無題",
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle:
              Text("${book['author'] ?? '著者不明'} | ${book['progress'] ?? 0}%"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () =>
                _confirmDeletion(context, uid, bookId, book['title'] ?? "無題"),
          ),
          onTap: () => _openReadingRoom(context, book, bookId, uid),
        ),
      ),
    );
  }

// --- 本を削除する時の確認ダイアログ ---
  void _confirmDeletion(
      BuildContext context, String uid, String bookId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("本の削除"),
        content: Text("「$title」を本棚から削除しますか？"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('books')
                  .doc(bookId)
                  .delete();
              Navigator.pop(ctx);
            },
            child: const Text("削除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- 読書ルーム（ReadingSessionScreen）を開く処理 ---
  void _openReadingRoom(BuildContext context, Map<String, dynamic> book,
      String bookId, String uid) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReadingSessionScreen(book: book)),
    );

    // 読書が終わって戻ってきた時に進捗を更新する
    if (result != null && result is Map) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('books')
          .doc(bookId)
          .update({
        'progress': result['progress'],
        'lastRead': FieldValue.serverTimestamp(),
        // 読み始めた本は「買いたい本」ではなく、通常の本として扱う
        'isWishlist': false,
      });
    }
  }
} // ← クラスの閉じカッコ

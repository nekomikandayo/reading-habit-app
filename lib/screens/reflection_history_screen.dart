import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReflectionHistoryScreen extends StatelessWidget {
  const ReflectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("記憶の棚", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('reflections')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "まだ思い出がありません。\n本を閉じるときに、言葉を残してみましょう。",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snap.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final date = d['timestamp'] != null 
                  ? (d['timestamp'] as Timestamp).toDate() 
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  shape: const Border(), // ExpansionTileのデフォルトの境界線を消す
                  leading: const Icon(Icons.book_outlined, color: Colors.black54),
                  title: Text(
                    d['bookTitle'] ?? "不明な本",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    date != null ? DateFormat('yyyy/MM/dd HH:mm').format(date) : "",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 22),
                    onPressed: () => _confirmDeletion(context, uid!, doc.id),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit_note, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text("あなたの感想", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(d['userThoughts'] ?? "", style: const TextStyle(fontSize: 14, height: 1.5)),
                            const Divider(height: 32),
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 14, color: Colors.brown),
                                SizedBox(width: 4),
                                Text("司書の言葉", style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d['aiReply'] ?? "司書はまだ考え中のようです。",
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeletion(BuildContext context, String uid, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("記憶を整理しますか？"),
        content: const Text("一度削除した思い出は元に戻すことができません。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('reflections')
                  .doc(docId)
                  .delete();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("削除する", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ActionListScreen extends StatelessWidget {
  const ActionListScreen({super.key});

  // Cloud Functions v2 の公式 URL（.a.run.app）を利用
  final String _functionsUrl = 'https://generatepraise-njqdsqyfmq-an.a.run.app';

  // --- 手動で実践を追加するダイアログ ---
  void _showAddManualDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("実践することを追加"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: controller, 
          decoration: const InputDecoration(hintText: "例：学んだことを1つ書き出す"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance.collection('users').doc(uid).collection('actions').add({
                'title': controller.text.trim(),
                'bookTitle': '手動追加',
                'isCompleted': false,
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text("追加"),
          ),
        ],
      ),
    );
  }

  // ★ Cloud Functions 経由で司書に褒めてもらう
  Future<void> _showPraiseDialog(BuildContext context, String actionTitle) async {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.black))
    );
    
    // 通信エラー時のデフォルトメッセージ
    String praiseMsg = "素晴らしい実践ですね。あなたの歩みが、確かな知識へと変わっていくのを感じます。";
    
    try {
      final res = await http.post(
        Uri.parse(_functionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'actionTitle': actionTitle,
          'type': 'praise', 
        }),
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // ★ Cloud Functions(v2) のレスポンス形式 { data: { response: "..." } } に対応
        praiseMsg = data['data']?['response'] ?? praiseMsg;
      } else {
        debugPrint("褒めエラー: status=${res.statusCode}, body=${res.body}");
      }
    } catch (e) {
      debugPrint("褒めエラー: $e");
    }
    
    if (!context.mounted) return;
    Navigator.pop(context); // 読み込み中ダイアログを閉じる

    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 10),
            Text("司書の言葉"),
          ],
        ),
        content: Text(praiseMsg, style: const TextStyle(fontSize: 16, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("大切に受け取る", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text("実践リスト", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('actions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.black));
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("まだ実践することがありません。\n読書から得た知恵を、ここへ記しましょう。", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snap.data!.docs[index];
              final bool isDone = doc['isCompleted'] ?? false;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.shade400, 
                  alignment: Alignment.centerRight, 
                  padding: const EdgeInsets.only(right: 20), 
                  child: const Icon(Icons.delete_outline, color: Colors.white)
                ),
                onDismissed: (direction) => doc.reference.delete(),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      activeColor: Colors.black,
                      shape: const CircleBorder(),
                      value: isDone,
                      onChanged: isDone ? null : (val) async {
                        // 実践完了！
                        await doc.reference.update({'isCompleted': true});
                        if (context.mounted) _showPraiseDialog(context, doc['title']);
                      },
                    ),
                    title: Text(
                      doc['title'], 
                      style: TextStyle(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey : Colors.black87,
                      )
                    ),
                    subtitle: Text(doc['bookTitle'] ?? "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    // スワイプだけでなく、赤いゴミ箱アイコンでも削除できるようにする
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => doc.reference.delete(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddManualDialog(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'dart:async' as std;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:intl/intl.dart';

class ReadingSessionScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  const ReadingSessionScreen({super.key, required this.book});
  @override
  State<ReadingSessionScreen> createState() => _ReadingSessionScreenState();
}

class _ReadingSessionScreenState extends State<ReadingSessionScreen> {
  final _sw = Stopwatch();
  late std.Timer _t;
  final _p = TextEditingController();
  final _r = TextEditingController();
  bool _loading = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isBgmPlaying = false;

  // Cloud Functions v2 の公式 URL（.a.run.app）を利用
  final String _functionsUrl = 'https://generatepraise-njqdsqyfmq-an.a.run.app';

  @override
  void initState() {
    super.initState();
    _p.text = (widget.book['progress'] ?? 0).toString();
    _t = std.Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {});
      }
    });
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _t.cancel();
    _sw.stop();
    _p.dispose();
    _r.dispose();
    _audioPlayer.dispose(); 
    super.dispose();
  }

  Future<String> _callAiFunction(String prompt, String type) async {
    try {
      final String contextPrompt = "本：『${widget.book['title']}』（${widget.book['author']}）\n内容：$prompt";

      final response = await http.post(
        Uri.parse(_functionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'actionTitle': contextPrompt, 
            'type': type,
          }
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        if (decoded.containsKey('data') && decoded['data'].containsKey('response')) {
          return decoded['data']['response'] ?? "";
        }
      } else {
        debugPrint("サーバーエラー: ${response.statusCode} / ${response.body}");
      }
    } catch (e) {
      debugPrint("AI通信エラー: $e");
    }
    return "";
  }

  Future<void> _saveSession(String reply) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final statsRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('daily_stats').doc(dateStr);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(statsRef);
      if (snap.exists) {
        tx.update(statsRef, {'seconds': (snap.get('seconds') ?? 0) + _sw.elapsed.inSeconds});
      } else {
        tx.set(statsRef, {'seconds': _sw.elapsed.inSeconds, 'timestamp': FieldValue.serverTimestamp()});
      }
    });

    // 「心に浮かんだ言葉」が空白の場合は、記憶の棚には保存しない
    if (_r.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('reflections').add({
        'bookTitle': widget.book['title'],
        'userThoughts': _r.text,
        'aiReply': reply,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _extractActions() async {
    if (_r.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("まずは心に浮かんだ言葉を書き留めてください")));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    
    final aiResponseText = await _callAiFunction(_r.text, "task");
    
    if (!mounted) {
      return;
    }
    Navigator.pop(context);

    if (aiResponseText.isNotEmpty) {
      try {
        final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
        final match = jsonPattern.stringMatch(aiResponseText);
        
        if (match != null) {
          final Map<String, dynamic> decoded = jsonDecode(match);
          final List actions = decoded['actions'] ?? [];
          _showSelectionDialog(actions);
        } else {
          throw Exception("JSON形式のデータが見つかりませんでした");
        }
      } catch (e) {
        debugPrint("JSONパースエラー: $e\n元のテキスト: $aiResponseText");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("司書が少し考え込んでしまったようです。もう一度お試しください。")));
      }
    }
  }

  Future<void> _getProphecy(String action) async {
    final prophecy = await _callAiFunction(action, "prophecy");
    
    if (!mounted) {
      return;
    }

    if (prophecy.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prophecy), 
          backgroundColor: const Color(0xFF2C2C2C), 
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        )
      );
    }
  }

  void _showSelectionDialog(List actions) {
    List<bool> sel = List.generate(actions.length, (i) => true);
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setS) => AlertDialog(
      title: const Text("本から紡ぎ出された「実践」"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(actions.length, (i) => 
        CheckboxListTile(
          activeColor: Colors.black, 
          title: Text(actions[i]), 
          subtitle: const Text("この一歩の未来を聴く", style: TextStyle(fontSize: 10)),
          value: sel[i], 
          onChanged: (v) async {
            setS(() {
              sel[i] = v!;
            });
            if (v == true) {
              await _getProphecy(actions[i]);
            }
          }
        )
      ))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("今はそっとしておく")),
        ElevatedButton(
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            for (int i=0; i<actions.length; i++) {
              if (sel[i]) {
                await FirebaseFirestore.instance.collection('users').doc(uid).collection('actions').add({
                  'title': actions[i], 
                  'isCompleted': false, 
                  'timestamp': FieldValue.serverTimestamp(), 
                  'bookTitle': widget.book['title']
                });
              }
            }
            if (mounted) {
              Navigator.pop(ctx);
            }
          }, 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), 
          child: const Text("心に留めておく")
        ),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("静かな読書の時間"), actions: [
        IconButton(icon: Icon(_isBgmPlaying ? Icons.music_off : Icons.music_note), onPressed: () async {
          if (_isBgmPlaying) {
            await _audioPlayer.pause();
          } else {
            await _audioPlayer.play(AssetSource('amenooto.mp3'));
          }
          if (mounted) {
            setState(() => _isBgmPlaying = !_isBgmPlaying);
          }
        })
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
        Text("${_sw.elapsed.inMinutes.toString().padLeft(2, '0')}:${(_sw.elapsed.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w200)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton(onPressed: () => _sw.start(), child: const Text("扉を開く")),
          const SizedBox(width: 15),
          OutlinedButton(onPressed: () => _sw.stop(), child: const Text("栞を挟む")),
        ]),
        const SizedBox(height: 40),
        TextField(controller: _p, decoration: const InputDecoration(labelText: "読み進めた割合 (%)"), keyboardType: TextInputType.number),
        const SizedBox(height: 30),
        TextField(controller: _r, decoration: const InputDecoration(labelText: "心に浮かんだ言葉をどうぞ", border: OutlineInputBorder()), maxLines: 3),
        const SizedBox(height: 15),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.auto_awesome_outlined), label: const Text("この本から『実践の種』を見つける"), onPressed: _extractActions)),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            final reply = await _callAiFunction(_r.text, "praise");
            final finalReply = reply.isNotEmpty ? reply : "物語の余韻が、あなたの心に静かに降り積もるのを、ここで見守っておりますね。";
            
            await _saveSession(finalReply);
            if (!mounted) {
              return;
            }
            setState(() => _loading = false);
            
            if (mounted) {
              showDialog(context: context, builder: (ctx) => LibrarianReplyDialog(msg: finalReply, onFinish: () { 
                Navigator.pop(ctx); 
                Navigator.pop(context, {'progress': int.tryParse(_p.text) ?? 0}); 
              }));
            }
          },
          child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("今日の読書を終える"),
        )),
      ])),
    );
  }
}

class LibrarianReplyDialog extends StatefulWidget {
  final String msg; final VoidCallback onFinish;
  const LibrarianReplyDialog({super.key, required this.msg, required this.onFinish});
  @override
  State<LibrarianReplyDialog> createState() => _LibrarianReplyDialogState();
}

class _LibrarianReplyDialogState extends State<LibrarianReplyDialog> {
  late VideoPlayerController _vc; String _txt = ""; std.Timer? _timer;
  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.asset('assets/video_project.mp4')..initialize().then((_) { 
      if (mounted) { 
        _vc.setLooping(true); 
        _vc.play(); 
        setState(() {}); 
      }
    });
    int i = 0; 
    _timer = std.Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (i < widget.msg.length) { 
        if (mounted) {
          setState(() => _txt += widget.msg[i]);
        }
        i++; 
      } else {
        t.cancel();
      }
    });
  }
  @override
  void dispose() { 
    _vc.dispose(); 
    _timer?.cancel(); 
    super.dispose(); 
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width * 0.9,
          // 長文でも下にはみ出さないよう、高さは最大まで広げて超えた分はスクロール
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: _vc.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _vc.value.aspectRatio,
                        child: VideoPlayer(_vc),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
                child: Text(
                  _txt,
                  style: const TextStyle(
                      fontSize: 18, height: 1.7, fontWeight: FontWeight.w400),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onFinish, child: const Text("そっと閉じる"))
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _err = '';
  bool _isLoading = false; // 通信中の状態を管理

  Future<void> _auth(bool isLogin) async {
    // 未入力チェック
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _err = "メールアドレスとパスワードを入力してください");
      return;
    }

    setState(() {
      _isLoading = true;
      _err = '';
    });

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _pass.text.trim());
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email.text.trim(), password: _pass.text.trim());
      }
      // 成功時は AuthCheck (main.dart) が自動で画面を切り替えてくれます
    } on FirebaseAuthException catch (e) {
      // Firebase特有のエラーメッセージを日本語で分かりやすく表示
      setState(() {
        if (e.code == 'user-not-found') _err = "ユーザーが見つかりませんでした";
        else if (e.code == 'wrong-password') _err = "パスワードが間違っています";
        else if (e.code == 'email-already-in-use') _err = "このメールアドレスは既に登録されています";
        else if (e.code == 'weak-password') _err = "パスワードが短すぎます";
        else _err = "認証に失敗しました。内容を確認してください";
      });
    } catch (e) {
      setState(() => _err = "予期せぬエラーが発生しました");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 背景色を書斎風に
      body: Center(
        child: SingleChildScrollView( // キーボード表示時のエラー防止
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 80, color: Colors.black87), // 読書のアイコン
              const SizedBox(height: 20),
              const Text(
                "読書の灯火",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: 2),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'メールアドレス',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              if (_err.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(_err, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
                
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _auth(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("書斎に入る", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading ? null : () => _auth(false),
                child: const Text("新しく灯火を灯す（新規登録）", style: TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
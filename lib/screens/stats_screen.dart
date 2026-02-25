import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("読書の記憶", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('daily_stats')
            .orderBy(FieldPath.documentId, descending: true) // 日付順に並び替え
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "まだ静かな書斎です。\n読書を終えると、ここに記録が刻まれます。",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            );
          }

          // グラフ表示用のデータ整理
          Map<String, int> statsMap = {};
          for (var doc in snap.data!.docs) {
            statsMap[doc.id] = (doc['seconds'] as int? ?? 0);
          }

          return Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "週間アクティビティ (分)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 25),
              // グラフ部分
              _buildChart(statsMap),
              const SizedBox(height: 20),
              const Divider(indent: 30, endIndent: 30),
              // 履歴リスト部分
              Expanded(
                child: _buildHistoryList(snap.data!.docs),
              ),
            ],
          );
        },
      ),
    );
  }

  // グラフウィジェットの切り出し
  Widget _buildChart(Map<String, int> statsMap) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _calculateMaxY(statsMap),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        DateFormat('M/d').format(date),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              final dayStr = DateFormat('yyyy-MM-dd').format(
                DateTime.now().subtract(Duration(days: 6 - i)),
              );
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (statsMap[dayStr] ?? 0) / 60,
                    color: Colors.black,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: _calculateMaxY(statsMap),
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // 履歴リストの切り出し
  Widget _buildHistoryList(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 5),
      itemBuilder: (context, i) {
        final d = docs[i];
        final minutes = (d['seconds'] as int? ?? 0) ~/ 60;
        return ListTile(
          dense: true,
          leading: const Icon(Icons.circle, size: 8, color: Colors.black26),
          title: Text(d.id, style: const TextStyle(fontFamily: 'Courier', fontSize: 14)),
          trailing: Text(
            "$minutes 分",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        );
      },
    );
  }

  double _calculateMaxY(Map<String, int> statsMap) {
    double maxMinutes = 30.0;
    statsMap.forEach((key, value) {
      double mins = value / 60;
      if (mins > maxMinutes) {
        maxMinutes = mins + 5;
      }
    });
    return maxMinutes;
  }
}
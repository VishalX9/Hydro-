import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<_Entry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/readings.txt');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        final items = lines.where((l) => l.trim().isNotEmpty).map((l) => _Entry.tryParse(l)).whereType<_Entry>().toList();
        setState(() => _entries = items.reversed.toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('No history yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, i) {
        final e = _entries[i];
        return ListTile(
          leading: const Icon(Icons.water_drop),
          title: Text('${e.level} m  •  ${e.time.substring(0, 19)}'),
          subtitle: Text('${e.lat}, ${e.lng}'),
          trailing: e.photoPath != null ? const Icon(Icons.image) : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryDetailScreen(entry: '${e.time},${e.lat},${e.lng},${e.level},${e.photoPath ?? ''}'),
              ),
            );
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _entries.length,
    );
  }
}

class _Entry {
  final String time;
  final String lat;
  final String lng;
  final String level;
  final String? photoPath;

  _Entry(this.time, this.lat, this.lng, this.level, this.photoPath);

  static _Entry? tryParse(String line) {
    // format: iso,lat,lng,level,photoPath
    final parts = line.split(',');
    if (parts.length < 4) return null;
    return _Entry(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
      parts.length > 4 ? parts[4] : null,
    );
  }
}
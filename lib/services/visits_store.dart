import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum VisitType { routine, inspection }
enum VisitPriority { low, medium, high }

class Visit {
  final String id;
  final DateTime date; // date only (at local midnight)
  final String time; // display-friendly time e.g., "10:00 AM"
  final String siteId;
  final String siteName;
  final VisitType type;
  final VisitPriority priority;
  final String? notes;

  const Visit({
    required this.id,
    required this.date,
    required this.time,
    required this.siteId,
    required this.siteName,
    this.type = VisitType.routine,
    this.priority = VisitPriority.medium,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'time': time,
        'siteId': siteId,
        'siteName': siteName,
        'type': type.name,
        'priority': priority.name,
        if (notes != null) 'notes': notes,
      };

  static Visit fromJson(Map<String, dynamic> j) => Visit(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        time: j['time'] as String,
        siteId: j['siteId'] as String,
        siteName: j['siteName'] as String,
        type: VisitType.values.firstWhere((e) => e.name == (j['type'] as String? ?? 'routine'), orElse: () => VisitType.routine),
        priority: VisitPriority.values.firstWhere((e) => e.name == (j['priority'] as String? ?? 'medium'), orElse: () => VisitPriority.medium),
        notes: j['notes'] as String?,
      );
}

class VisitsStore {
  VisitsStore._();
  static final VisitsStore instance = VisitsStore._();

  final ValueNotifier<List<Visit>> visits = ValueNotifier<List<Visit>>([]);

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/visits.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final arr = jsonDecode(await f.readAsString()) as List<dynamic>;
        visits.value = arr.map((e) => Visit.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        visits.value = const [];
      }
    } catch (_) {
      // ignore parse errors
    }
  }

  Future<void> save() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(visits.value.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> add(Visit v) async {
    visits.value = [...visits.value, v];
    await save();
  }

  Future<void> remove(String id) async {
    visits.value = visits.value.where((v) => v.id != id).toList();
    await save();
  }
}



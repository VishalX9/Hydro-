import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Site {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double? radiusMeters;

  const Site({required this.id, required this.name, required this.lat, required this.lng, this.radiusMeters});

  Site copyWith({String? id, String? name, double? lat, double? lng, double? radiusMeters}) => Site(
        id: id ?? this.id,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        radiusMeters: radiusMeters ?? this.radiusMeters,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        if (radiusMeters != null) 'radiusMeters': radiusMeters,
      };

  static Site fromJson(Map<String, dynamic> j) => Site(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? 'Site',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        radiusMeters: (j['radiusMeters'] as num?)?.toDouble(),
      );
}

class SitesStore {
  SitesStore._();
  static final SitesStore instance = SitesStore._();

  final ValueNotifier<List<Site>> sites = ValueNotifier<List<Site>>([]);

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sites.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final decoded = jsonDecode(await f.readAsString()) as List<dynamic>;
        sites.value = decoded.map((e) => Site.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // defaults
        sites.value = const [
          Site(id: 'DL-VAYU', name: 'Vayusenabad (110062)', lat: 28.512083, lng: 77.238389, radiusMeters: 600),
          Site(id: 'DL-NSUT', name: 'NSUT Dwarka', lat: 28.6109, lng: 77.0385, radiusMeters: 300),
        ];
        await save();
      }
    } catch (_) {
      // if parsing fails, keep current list
    }
  }

  Future<void> save() async {
    try {
      final f = await _file();
      final data = jsonEncode(sites.value.map((e) => e.toJson()).toList());
      await f.writeAsString(data);
    } catch (_) {
      // best-effort persistence
    }
  }

  Future<void> add(Site site) async {
    sites.value = [...sites.value, site];
    await save();
  }

  Future<void> removeById(String id) async {
    sites.value = sites.value.where((s) => s.id != id).toList();
    await save();
  }
}



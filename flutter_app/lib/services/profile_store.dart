import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/ssh_profile.dart';

class ProfileStore {
  static const _assetPath = 'assets/json/remote_profiles.json';
  static const _fileName = 'remote_profiles.json';

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<SshProfile>> load() async {
    final file = await _localFile();
    if (!await file.exists()) {
      final seed = await rootBundle.loadString(_assetPath);
      await file.writeAsString(seed, flush: true);
    }

    final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final list = decoded['profiles'] as List<dynamic>? ?? const [];
    return list.map((item) => SshProfile.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<SshProfile> profiles) async {
    final file = await _localFile();
    final json = const JsonEncoder.withIndent('  ').convert({
      'profiles': profiles.map((profile) => profile.toJson()).toList(),
    });
    await file.writeAsString(json, flush: true);
  }

  int nextId(List<SshProfile> profiles) {
    if (profiles.isEmpty) return 1;
    return profiles.map((profile) => profile.id).reduce((a, b) => a > b ? a : b) + 1;
  }
}

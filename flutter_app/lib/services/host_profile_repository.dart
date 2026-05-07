import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/host_profile.dart';
import '../state/remote_session_state.dart';
import 'app_logger.dart';

Future<void> loadHostProfilesFromAssets() async {
  final String response = await rootBundle.loadString('assets/json/servers.json');
  final data = jsonDecode(response);

  final loadedProfiles = <HostProfile>[];
  for (final serverJson in data['servers']) {
    final server = HostProfile.fromJson(serverJson);
    logger.i('Perfil: ${server.name}, IP: ${server.ip}');
    loadedProfiles.add(server);
  }

  hostProfiles = loadedProfiles;
}

void renameHostProfile(int serverId, String newName) {
  final index = hostProfiles.indexWhere((server) => server.id == serverId);
  if (index == -1) return;

  final current = hostProfiles[index];
  hostProfiles[index] = HostProfile(
    id: current.id,
    name: newName,
    ip: current.ip,
    port: current.port,
    username: current.username,
    key: current.key,
  );

  logger.i('Nombre del perfil actualizado: $newName');
}

Future<void> persistHostProfiles(List<HostProfile> profileList) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/servers.json');
    final jsonString = jsonEncode(profileList.map((s) => s.toJson()).toList());

    await file.writeAsString(jsonString);
    logger.i('Archivo guardado en: ${file.path}');
  } catch (e) {
    logger.e('Error guardando perfiles: $e');
  }
}

enum ProjectKind { node, java, unknown }
enum RemoteServiceState { running, stopped, restarting, error, unknown }

extension ProjectKindText on ProjectKind {
  String get label => switch (this) {
        ProjectKind.node => 'NodeJS',
        ProjectKind.java => 'Java',
        ProjectKind.unknown => 'Cap servidor detectat',
      };
}

extension RemoteServiceStateText on RemoteServiceState {
  String get label => switch (this) {
        RemoteServiceState.running => 'funcionant',
        RemoteServiceState.stopped => 'aturat',
        RemoteServiceState.restarting => 'reiniciant',
        RemoteServiceState.error => 'error',
        RemoteServiceState.unknown => 'desconegut',
      };
}

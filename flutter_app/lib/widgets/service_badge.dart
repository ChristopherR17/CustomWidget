import 'package:flutter/material.dart';

import '../models/app_enums.dart';
import 'status_dot.dart';

class ServiceBadge extends StatelessWidget {
  const ServiceBadge({super.key, required this.state, required this.kind});

  final RemoteServiceState state;
  final ProjectKind kind;

  @override
  Widget build(BuildContext context) {
    final ok = state == RemoteServiceState.running;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(.12) : Colors.orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(enabled: ok, size: 10),
          const SizedBox(width: 8),
          Text('${kind.label}: ${state.label}'),
        ],
      ),
    );
  }
}

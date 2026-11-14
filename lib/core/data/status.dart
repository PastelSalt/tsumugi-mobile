import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

/// One small status vocabulary (website `data/status.js`). Icon plus text, never colour alone.
class StatusStyle {
  const StatusStyle(this.tone, this.icon);
  final StatusTone tone;
  final IconData icon;
}

enum StatusDomain {
  project,
  work,
  derived,
  requirement,
  document,
  health,
  change,
}

const Map<StatusDomain, Map<String, StatusStyle>> statusStyles = {
  StatusDomain.project: {
    'Planning': StatusStyle(StatusTone.progress, LucideIcons.compass),
    'Active': StatusStyle(StatusTone.success, LucideIcons.play),
    'On hold': StatusStyle(StatusTone.warning, LucideIcons.pause),
    'Done': StatusStyle(StatusTone.neutral, LucideIcons.circleCheckBig),
    'Archived': StatusStyle(StatusTone.neutral, LucideIcons.archive),
  },
  StatusDomain.work: {
    'To do': StatusStyle(StatusTone.info, LucideIcons.circle),
    'Doing': StatusStyle(StatusTone.progress, LucideIcons.loader),
    'Done': StatusStyle(StatusTone.success, LucideIcons.circleCheckBig),
  },
  StatusDomain.derived: {
    'Upcoming': StatusStyle(StatusTone.info, LucideIcons.calendar),
    'Doing': StatusStyle(StatusTone.progress, LucideIcons.loader),
    'Overdue': StatusStyle(StatusTone.danger, LucideIcons.triangleAlert),
    'Done': StatusStyle(StatusTone.success, LucideIcons.check),
  },
  StatusDomain.requirement: {
    'Open': StatusStyle(StatusTone.info, LucideIcons.circle),
    'Met': StatusStyle(StatusTone.success, LucideIcons.check),
  },
  StatusDomain.document: {
    'Draft': StatusStyle(StatusTone.warning, LucideIcons.pencil),
    'Final': StatusStyle(StatusTone.success, LucideIcons.star),
  },
  StatusDomain.health: {
    'On track': StatusStyle(StatusTone.success, LucideIcons.check),
    'At risk': StatusStyle(StatusTone.warning, LucideIcons.triangleAlert),
  },
  StatusDomain.change: {
    'Recorded': StatusStyle(StatusTone.neutral, LucideIcons.clipboardCheck),
  },
};

/// Flags shown next to a status when they apply.
const Map<String, StatusStyle> flagStyles = {
  'Blocked': StatusStyle(StatusTone.danger, LucideIcons.octagonX),
  'Verified': StatusStyle(StatusTone.success, LucideIcons.shieldCheck),
  'Reviewed': StatusStyle(StatusTone.success, LucideIcons.check),
  'Final': StatusStyle(StatusTone.success, LucideIcons.star),
  'High': StatusStyle(StatusTone.warning, LucideIcons.arrowUp),
};

const workStatuses = ['To do', 'Doing', 'Done'];
const projectStatuses = ['Planning', 'Active', 'On hold', 'Done'];

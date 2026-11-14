import 'package:flutter/widgets.dart';

/// Width (in dp) from which the app uses the tablet layout: a side rail instead of the bottom bar,
/// and record details docked beside the list instead of in a bottom sheet.
const double wideBreakpoint = 840;

/// Width of the docked detail panel.
const double dockWidth = 400;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideBreakpoint;

// lib/presentation/widgets/navigation/root_tab_pop_scope.dart

import 'package:flutter/material.dart';

import '../dialogs/exit_confirmation_dialog.dart';

/// Wraps a bottom-nav-bar tab screen so back navigation behaves correctly
/// regardless of how the screen was reached:
///
/// - Reached via the bottom nav bar (which swaps tabs with
///   pushReplacementNamed): this screen sits at the root of the stack, so
///   back is intercepted — home tabs ask to exit the app, other tabs
///   return to [homeRoute].
/// - Reached by pushing on top of another screen (e.g. a quick-link card
///   inside another tab): there is a previous route to return to, so back
///   just pops normally and the AppBar shows its default back arrow.
class RootTabPopScope extends StatelessWidget {
  final Widget child;
  final String homeRoute;
  final bool isHome;

  const RootTabPopScope({
    super.key,
    required this.child,
    required this.homeRoute,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isHome) {
          await showExitConfirmationDialog(context);
        } else {
          Navigator.pushReplacementNamed(context, homeRoute);
        }
      },
      child: child,
    );
  }
}

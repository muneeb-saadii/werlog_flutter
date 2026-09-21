import 'package:flutter/material.dart';
import 'core/routes/admin_routes.dart';
import 'core/theme/app_theme.dart';

/// Embeddable entry point for the Admin module.
///
/// Push this single widget from anywhere in the host app:
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const AdminModule()),
/// );
/// ```
///
/// Internally it owns its own [Navigator], so all `pushNamed` /
/// `pushReplacementNamed` / `pop` calls made by the Dashboard, Users list,
/// and User details screens navigate within the module only — they never
/// touch the host app's navigation stack or its route table.
///
/// Android/gesture back on the module's home screen (the Dashboard) pops
/// the whole module and returns control to the host app; back while deeper
/// inside the module (e.g. on User details) just pops one step within the
/// module, as expected.
class AdminModule extends StatefulWidget {
  const AdminModule({super.key});

  @override
  State<AdminModule> createState() => _AdminModuleState();
}

class _AdminModuleState extends State<AdminModule> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nestedNav = _navigatorKey.currentState;
        if (nestedNav != null && nestedNav.canPop()) {
          nestedNav.pop();
        } else {
          // Nothing left to pop inside the module — hand back/exit
          // control to whatever pushed this module (the host app).
          Navigator.of(context).maybePop();
        }
      },
      child: Theme(
        data: AppTheme.theme,
        child: Navigator(
          key: _navigatorKey,
          initialRoute: AdminRoutes.dashboard,
          onGenerateRoute: AdminRoutes.generateRoute,
        ),
      ),
    );
  }
}

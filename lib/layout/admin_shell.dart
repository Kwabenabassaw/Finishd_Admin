import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:finishd_admin/layout/sidebar.dart';
import 'package:finishd_admin/layout/top_bar.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const AdminShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: !isDesktop
          ? Drawer(
              width: 260,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Sidebar(selectedIndex: selectedIndex),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop) Sidebar(selectedIndex: selectedIndex),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  isMobile: !isDesktop,
                  onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

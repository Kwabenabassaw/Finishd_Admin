import 'package:flutter/material.dart';
import 'package:finishd_admin/layout/sidebar.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finishd Admin')),
        drawer: Drawer(child: _SidebarContent(selectedIndex: selectedIndex)),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(selectedIndex: selectedIndex),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                // Top Bar can go here
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final int selectedIndex;
  const _SidebarContent({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    // Just reuse Sidebar logic but wrapped for Drawer if needed,
    // or actually checking `Sidebar` implementation, it is a Container.
    // So we can wrap it in a SafeArea for mobile drawer.

    return SafeArea(child: Sidebar(selectedIndex: selectedIndex));
  }
}

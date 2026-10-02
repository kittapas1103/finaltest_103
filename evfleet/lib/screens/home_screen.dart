import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import 'display_screen.dart';
import 'form_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  late final Future<AppUser> _profile =
      AuthController.loadProfile(widget.user);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: _profile,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final me = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('EVFleet'),
            actions: [
              Center(
                child: Chip(
                  avatar: Icon(
                      me.isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.engineering,
                      size: 18),
                  label: Text(me.roleLabel),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              IconButton(
                tooltip: 'ออกจากระบบ',
                icon: const Icon(Icons.logout),
                onPressed: AuthController.logout,
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(icon: Icon(Icons.ev_station), text: 'สถานีชาร์จ'),
                Tab(icon: Icon(Icons.add_circle_outline), text: 'เพิ่มสถานี'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              DisplayScreen(me: me),
              FormScreen(onSaved: () => _tab.animateTo(0)),
            ],
          ),
        );
      },
    );
  }
}

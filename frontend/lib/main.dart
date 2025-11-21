import 'package:flutter/material.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/executive/broadcast_message_screen.dart';
import 'screens/executive/executive_dashboard_screen.dart';
import 'screens/club_executive_club_management_screen.dart';
// import 'screens/admin/club_management_for_admins_screen.dart';
import 'screens/member/member_dashboard_screen.dart';
import 'screens/financial_overview_screen.dart';
import 'screens/financial_report_generation_screen.dart';
import 'screens/financial_report_viewer_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/user_profile_management_screen.dart';
import 'screens/notification_view_screen.dart';
import 'screens/membership_status_management_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'utils/auth_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Club Manager',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.deepPurpleAccent,
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 1,
        ),
      ),
      home: Startup(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/auth':
            return MaterialPageRoute(builder: (context) => AuthEntry());
          case '/home':
            return MaterialPageRoute(
              builder: (context) =>
                  const MyHomePage(title: 'Campus Club Manager'),
            );
          case '/admin-dashboard':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(
                token: args?['token'],
                user: args?['user'],
              ),
            );
          case '/executive-dashboard':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ClubExecutiveDashboardScreen(
                token: args?['token'],
                user: args?['user'],
              ),
            );
          case '/member-dashboard':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => MemberDashboardScreen(
                token: args?['token'],
                user: args?['user'],
              ),
            );
          default:
            return MaterialPageRoute(builder: (context) => AuthScreen());
        }
      },
    );
  }
}

/// Startup widget that restores saved auth (if any) and navigates to the right dashboard.
class Startup extends StatefulWidget {
  @override
  _StartupState createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('auth_user');
      if (token != null && token.isNotEmpty && userJson != null) {
        final user = jsonDecode(userJson) as Map<String, dynamic>;
        final role = (user['role'] ?? '').toString();
        // navigate to appropriate dashboard
        if (role == 'Admin') {
          Navigator.of(context).pushReplacementNamed('/admin-dashboard', arguments: {'token': token, 'user': user});
          return;
        }
        if (role == 'Executive') {
          Navigator.of(context).pushReplacementNamed('/executive-dashboard', arguments: {'token': token, 'user': user});
          return;
        }
        // default to member
        Navigator.of(context).pushReplacementNamed('/member-dashboard', arguments: {'token': token, 'user': user});
        return;
      }
    } catch (_) {}

    // No saved auth — go to AuthScreen
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// When navigating to `/auth`, clear stored credentials then show AuthScreen.
class AuthEntry extends StatefulWidget {
  @override
  _AuthEntryState createState() => _AuthEntryState();
}

class _AuthEntryState extends State<AuthEntry> {
  bool _cleared = false;

  @override
  void initState() {
    super.initState();
    _clearAndShow();
  }

  Future<void> _clearAndShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (_) {}
    setState(() => _cleared = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_cleared) return Scaffold(body: Center(child: CircularProgressIndicator()));
    return AuthScreen();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final List<ScreenItem> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      ScreenItem(
        title: 'Admin Dashboard',
        icon: Icons.dashboard,
        screen: const AdminDashboardScreen(),
      ),
      ScreenItem(
        title: 'Broadcast Message',
        icon: Icons.send,
        screen: BroadcastMessageScreen(),
      ),
      ScreenItem(
        title: 'Club Executive Dashboard',
        icon: Icons.business,
        screen: ClubExecutiveDashboardScreen(),
      ),
      ScreenItem(
        title: 'Club Management',
        icon: Icons.apartment,
        screen: ClubExecutiveClubManagementScreen(),
      ),
      // ScreenItem(
      //   title: 'Club Management (Admin)',
      //   icon: Icons.admin_panel_settings,
      //   screen: ClubManagementForAdminsScreen(),
      // ),
      ScreenItem(
        title: 'Member Dashboard',
        icon: Icons.people,
        screen: MemberDashboardScreen(),
      ),
      ScreenItem(
        title: 'Financial Overview',
        icon: Icons.account_balance_wallet,
        screen: FinancialOverviewScreen(),
      ),
      ScreenItem(
        title: 'Financial Report Generation',
        icon: Icons.assessment,
        screen: FinancialReportGenerationScreen(),
      ),
      ScreenItem(
        title: 'Financial Report Viewer',
        icon: Icons.description,
        screen: FinancialReportViewerScreen(),
      ),
      ScreenItem(
        title: 'Notification Settings',
        icon: Icons.notifications_active,
        screen: NotificationSettingsScreen(),
      ),
      ScreenItem(
        title: 'User Profile Management',
        icon: Icons.person,
        screen: UserProfileManagementScreen(),
      ),
      ScreenItem(
        title: 'Notification View',
        icon: Icons.mail,
        screen: NotificationViewScreen(),
      ),
      ScreenItem(
        title: 'Membership Status Management',
        icon: Icons.card_membership,
        screen: MembershipStatusManagementScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // Use centralized sign-out helper to clear prefs and navigate
              await signOutAndNavigate(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Screens',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 24),
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: screens.length,
                itemBuilder: (context, index) {
                  final screen = screens[index];
                  return _buildScreenCard(context, screen);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenCard(BuildContext context, ScreenItem screenItem) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screenItem.screen),
        );
      },
      child: Card(
        elevation: 4,
        color: Colors.grey[900],
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(screenItem.icon, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  screenItem.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScreenItem {
  final String title;
  final IconData icon;
  final Widget screen;

  ScreenItem({required this.title, required this.icon, required this.screen});
}

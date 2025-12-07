import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/food_list_screen.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/orders_screen.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/profile_screen.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/livreurs_screen.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';
import 'package:simple_food/services/commande_service.dart';
import 'package:simple_food/services/plat_service.dart';
import 'package:simple_food/models/plat.dart';

class CookerDashboard extends StatelessWidget {
  const CookerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _CuisinierDrawer(),
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/simple_food_bg.png', height: 35),
            const SizedBox(width: 8),
            const Text(
              'Tableau de bord',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  bool _loading = false;
  String? _error;
  int ordersToday = 0;
  int revenueToday = 0;
  int activePlats = 0;
  double avgRating = 0.0;
  List<Map<String, dynamic>> recentOrders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Commandes (on récupère une page large pour agréger côté client)
      final cmdRes = await CommandeService.getCommandes(page: 1, limit: 100);
      if (cmdRes['success'] == true) {
        final List list = (cmdRes['data'] as List);
        final now = DateTime.now();
        int cnt = 0;
        int rev = 0;
        for (final c in list) {
          final m = (c as Map);
          final createdAt = DateTime.tryParse(
            (m['createdAt'] ?? '').toString(),
          );
          if (createdAt != null && _isSameDay(createdAt.toLocal(), now)) {
            cnt += 1;
            final total = (m['totalAmount'] ?? m['total'] ?? 0);
            if (total is num) rev += total.toInt();
          }
        }
        ordersToday = cnt;
        revenueToday = rev;

        // Compute recent orders (last 5 by createdAt desc)
        final sorted =
            List<Map<String, dynamic>>.from(
              list.map((e) => (e as Map).cast<String, dynamic>()),
            )..sort((a, b) {
              final ad =
                  DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bd =
                  DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bd.compareTo(ad);
            });
        recentOrders = sorted.take(5).toList();
      } else {
        _error = cmdRes['message']?.toString();
      }

      // Plats
      final platsRes = await PlatService.getMyPlats(page: 1, limit: 100);
      if (platsRes['success'] == true) {
        final List<Plat> plats = (platsRes['data'] as List<Plat>);
        activePlats = plats.where((p) => p.available == true).length;
        if (plats.isNotEmpty) {
          final ratings = plats.map((p) => p.rating ?? 0.0).toList();
          avgRating = ratings.isEmpty
              ? 0
              : ratings.reduce((a, b) => a + b) / ratings.length;
        } else {
          avgRating = 0;
        }
      } else {
        _error ??= platsRes['message']?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            // Résumé rapide
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatCard(
                  title: 'Commandes du jour',
                  value: ordersToday.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orangeAccent,
                ),
                _StatCard(
                  title: 'Revenu du jour',
                  value: '${revenueToday.toString()} F',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatCard(
                  title: 'Plats actifs',
                  value: activePlats.toString(),
                  icon: Icons.restaurant_menu,
                  color: Colors.teal,
                ),
                _StatCard(
                  title: 'Note moyenne',
                  value: '${avgRating.toStringAsFixed(1)} ★',
                  icon: Icons.star_rate,
                  color: Colors.amber,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tendance des commandes
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 4.5),
                        FlSpot(2, 3.8),
                        FlSpot(3, 6),
                        FlSpot(4, 7.2),
                        FlSpot(5, 5),
                        FlSpot(6, 6.8),
                      ],
                      isCurved: true,
                      color: Colors.orangeAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orangeAccent.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Commandes récentes
            const Text(
              'Commandes récentes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (recentOrders.isEmpty)
              const Text('Aucune commande récente')
            else
              Column(
                children: recentOrders.map((c) {
                  final id = (c['_id'] ?? c['id'] ?? '').toString();
                  final client = (c['client'] as Map?)?.cast<String, dynamic>();
                  final name = (client?['name'] ?? 'Client').toString();
                  final status = (c['status'] ?? '').toString();
                  final createdAt = (c['createdAt'] ?? '').toString();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long),
                      ),
                      title: Text(
                        'Cmd #${id.isNotEmpty ? id.substring(0, 6) : '------'}',
                      ),
                      subtitle: Text('Client: $name • ${_fmtTime(createdAt)}'),
                      trailing: Text(
                        status,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final t = dt.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// _OrderTile removed (now using recentOrders ListTiles directly)

class _CuisinierDrawer extends StatelessWidget {
  const _CuisinierDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/simple_food_bg.png', height: 60),
                const SizedBox(height: 10),
                const Text(
                  'SimpleFood Cuisinier',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard, 'Tableau de bord', context),
          _drawerItem(Icons.restaurant_menu, 'Mes Plats', context),
          _drawerItem(Icons.receipt_long, 'Mes Commandes', context),
          _drawerItem(Icons.attach_money, 'Mes Revenus', context),
          _drawerItem(Icons.delivery_dining, 'Mes livreurs', context),
          const Divider(),
          _drawerItem(Icons.person, 'Profil', context),
          _drawerItem(Icons.logout, 'Déconnexion', context, color: Colors.red),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    BuildContext context, {
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () async {
        Navigator.pop(context); // fermer le drawer
        if (label == 'Déconnexion') {
          await ApiService.clearToken();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return;
        }
        if (label == 'Tableau de bord') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CookerDashboard()),
          );
        } else if (label == 'Mes Plats') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FoodScreen()),
          );
        } else if (label == 'Mes Commandes') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CookerOrdersScreen()),
          );
        } else if (label == 'Mes livreurs') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CookerLivreursScreen()),
          );
        } else if (label == 'Profil') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CookerProfileScreen()),
          );
        }
      },
    );
  }
}

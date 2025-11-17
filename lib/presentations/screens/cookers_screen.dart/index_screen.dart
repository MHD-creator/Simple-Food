import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/food_list_screen.dart';

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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé rapide
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StatCard(
                title: 'Commandes du jour',
                value: '12',
                icon: Icons.receipt_long,
                color: Colors.orangeAccent,
              ),
              _StatCard(
                title: 'Revenu du jour',
                value: '45.000 F',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StatCard(
                title: 'Plats actifs',
                value: '8',
                icon: Icons.restaurant_menu,
                color: Colors.teal,
              ),
              _StatCard(
                title: 'Note moyenne',
                value: '4.7 ★',
                icon: Icons.star_rate,
                color: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tendance des commandes
          const Text(
            'Tendance des commandes (7 derniers jours)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Container(
            height: 180,
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
          Column(
            children: const [
              _OrderTile(
                client: 'Awa Traoré',
                plat: 'Riz au poulet',
                heure: '10:30',
                statut: 'Livrée',
              ),
              _OrderTile(
                client: 'Issa Diallo',
                plat: 'Bissap glacé',
                heure: '11:15',
                statut: 'En cours',
              ),
              _OrderTile(
                client: 'Fatou Koné',
                plat: 'Tô sauce gombo',
                heure: '12:10',
                statut: 'Préparation',
              ),
            ],
          ),
        ],
      ),
    );
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

class _OrderTile extends StatelessWidget {
  final String client;
  final String plat;
  final String heure;
  final String statut;

  const _OrderTile({
    required this.client,
    required this.plat,
    required this.heure,
    required this.statut,
  });

  Color get statutColor {
    switch (statut) {
      case 'Livrée':
        return Colors.green;
      case 'En cours':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statutColor.withOpacity(0.1),
          child: Icon(Icons.fastfood, color: statutColor),
        ),
        title: Text(plat),
        subtitle: Text('Client: $client • $heure'),
        trailing: Text(
          statut,
          style: TextStyle(color: statutColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodScreen()),
        );
      },
    );
  }
}

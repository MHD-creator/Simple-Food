import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'widgets/plat_card.dart';
import 'package:simple_food/services/client_plat_service.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> filtered = [];
  bool _loading = false;
  String? _error;

  Future<void> rechercher(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ClientPlatService.search(query);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        filtered = (res['data'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur de recherche';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    filtered = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rechercher un plat")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              onChanged: rechercher,
              decoration: InputDecoration(
                hintText: "Ex : poulet, jus, riz...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          rechercher('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (filtered.isEmpty
                      ? Center(child: Text(_error ?? "Aucun résultat"))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final plat = filtered[index];
                            return PlatCard(
                              plat: plat,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlatDetailsScreen(plat: plat),
                                  ),
                                );
                              },
                            );
                          },
                        )),
          ),
        ],
      ),
    );
  }
}

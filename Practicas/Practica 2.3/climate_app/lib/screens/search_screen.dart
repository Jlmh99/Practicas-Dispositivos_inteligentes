import 'package:flutter/material.dart';

import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<String> _cities = ['Santiago', 'Querétaro', 'México'];
  List<String> _filtered = [];
  String _currentQuery = '';

  void _filterCities(String query) {
    setState(() {
      _currentQuery = query;
      _filtered = _cities
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si el query está vacío, mostramos toda la lista original
    final displayList = _currentQuery.isEmpty ? _cities : _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Ciudades'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterCities,
              decoration: const InputDecoration(
                hintText: 'Busca una ciudad...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final city = displayList[index];
                return ListTile(
                  title: Text(city),
                  subtitle: const Text('24°C'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(city: city),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
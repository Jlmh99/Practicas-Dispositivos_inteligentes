import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/weather_provider.dart';
import 'detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  
  List<String> cities = ['Santiago', 'Querétaro', 'México', 'Guadalajara', 'Monterrey'];
  List<String> filteredCities = [];
  String searchQuery = '';

  void filterCities(String query) {
    setState(() {
      searchQuery = query;
      filteredCities = cities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    final displayList = searchQuery.isEmpty ? cities : filteredCities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Ciudades'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: filterCities, 
              decoration: const InputDecoration(
                hintText: 'Busca una ciudad...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            
            child: (searchQuery.isNotEmpty && displayList.isEmpty)
                ? const Center(
                    child: Text('No encontradas'),
                  )
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final city = displayList[index];
                      return ListTile(
                        title: Text(city),
                        subtitle: const Text('24°C'), 
                        onTap: () async {
                              try {
                                await ref.read(weatherProvider.notifier).loadWeather(city);

                                if (!mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(city: city),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                  ),
                                );
                              }
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
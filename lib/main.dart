import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(FoodApp());
}

class FoodApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Справочник продуктов по калориям',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: FoodSearchScreen(),
    );
  }
}

class FoodSearchScreen extends StatefulWidget {
  @override
  _FoodSearchScreenState createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _favorites = [];

  Future<void> searchFood(String query) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _searchResults = (json.decode(response.body)['products'] as List<dynamic>)
            .where((product) {
              final name = product['product_name'] ?? '';
              return RegExp(r'^[A-Za-z\s]+$').hasMatch(name) || RegExp(r'[А-Яа-яЁё]').hasMatch(name);
            })
            .toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
      print('Ошибка при получении данных: ${response.body}');
    }
  }

  void addToFavorites(dynamic product) {
    setState(() {
      _favorites.add(product);
    });
  }

  void removeFromFavorites(dynamic product) {
    setState(() {
      _favorites.remove(product);
    });
  }

  Widget _buildSearchResultList() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final productName = product['product_name'] ?? 'Нет названия';
        final productCalories = product['nutriments']?['energy-kcal']?.toString() ?? 'Нет данных';

        return ListTile(
          title: Text(productName),
          subtitle: Text('Калории: $productCalories ккал'),
          trailing: IconButton(
            icon: Icon(
              _favorites.contains(product) ? Icons.favorite : Icons.favorite_border,
              color: _favorites.contains(product) ? Colors.red : null,
            ),
            onPressed: () {
              if (_favorites.contains(product)) {
                removeFromFavorites(product);
              } else {
                addToFavorites(product);
              }
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FoodDetailScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final product = _favorites[index];
        final productName = product['product_name'] ?? 'Нет названия';
        final productCalories = product['nutriments']?['energy-kcal']?.toString() ?? 'Нет данных';

        return ListTile(
          title: Text(productName),
          subtitle: Text('Калории: $productCalories ккал'),
          trailing: IconButton(
            icon: Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              removeFromFavorites(product);
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FoodDetailScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Справочник продуктов по калориям'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text('Избранное')),
                  body: _buildFavoritesList(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск продуктов',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => searchFood(_searchController.text),
                ),
              ),
            ),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: Text('Результаты поиска появятся здесь'))
                  : _buildSearchResultList(),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodDetailScreen extends StatelessWidget {
  final dynamic product;

  FoodDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    final productName = product['product_name'] ?? 'Нет названия';
    final productCalories = product['nutriments']?['energy-kcal']?.toString() ?? 'Нет данных';
    final productFat = product['nutriments']?['fat_100g']?.toString() ?? 'Нет данных';
    final productSugars = product['nutriments']?['sugars_100g']?.toString() ?? 'Нет данных';
    final productSalt = product['nutriments']?['salt_100g']?.toString() ?? 'Нет данных';
    final ingredients = product['ingredients_text'] ?? 'Нет данных';
    final allergens = product['allergens'] ?? 'Нет данных';

    return Scaffold(
      appBar: AppBar(title: Text(productName)),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Название: $productName', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Калории: $productCalories ккал', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Жиры: $productFat г', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Сахар: $productSugars г', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Соль: $productSalt г', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Text('Ингредиенты:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(ingredients, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text('Аллергены:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(allergens.isNotEmpty ? allergens : 'Нет данных', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

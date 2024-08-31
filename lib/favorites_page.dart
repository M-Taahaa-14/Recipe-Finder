import 'package:flutter/material.dart';
import 'recipe_model.dart';
import 'recipe_detail_page.dart';
import 'database_helper.dart';
import 'recipe_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _recipeService = RecipeService();
  Set<int> _favoriteRecipeIds = {};

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await DatabaseHelper.database;
  }

  Future<List<Recipe>> _loadFavorites() async {
    try {
      final favoriteMaps = await DatabaseHelper.getFavorites();
      //print("Favorites loaded: $favoriteMaps");

      return favoriteMaps
          .where((map) => map['recipeId'] != null)
          .map((map) => Recipe.fromMap(map))
          .toList();
    } catch (e) {
      //print("Error loading favorites: $e");
      return [];
    }
  }

  void _toggleFavorite(Recipe recipe) async {
    final db = await DatabaseHelper.database;
    try {
      if (_favoriteRecipeIds.contains(recipe.id)) {
        await db
            .delete('favorites', where: 'recipeId = ?', whereArgs: [recipe.id]);
        setState(() {
          _favoriteRecipeIds.remove(recipe.id);
        });
      } else {
        await DatabaseHelper.insertFavorite({
          'recipeId': recipe.id,
          'title': recipe.title,
          'imageUrl': recipe.imageUrl,
        });
        setState(() {
          _favoriteRecipeIds.add(recipe.id);
        });
      }
    } catch (e) {
      //print('Error toggling favorite: $e');
    }
  }

  void _onRecipeTap(int recipeId) async {
    try {
      final recipe = await _recipeService.fetchRecipeDetails(recipeId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
      );
    } catch (e) {
      //print("Failed to load recipe details: $e");
    }
  }

  Future<void> _removeFavorite(int recipeId) async {
    final db = await DatabaseHelper.database;
    try {
      await db
          .delete('favorites', where: 'recipeId = ?', whereArgs: [recipeId]);
      setState(() {
        _favoriteRecipeIds.remove(recipeId);
      });
    } catch (e) {
      //print('Error removing favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Recipes'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _loadFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite recipes'));
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Dismissible(
                key: Key(recipe.id.toString()),
                background: Container(
                  color: Colors.red,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ),
                onDismissed: (direction) {
                  _removeFavorite(recipe.id);
                },
                child: Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image);
                        },
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(),
                                );
                        },
                      ),
                    ),
                    title: Text(recipe.title),
                    onTap: () {
                      _onRecipeTap(recipe.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

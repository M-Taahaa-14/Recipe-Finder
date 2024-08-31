import 'package:flutter/material.dart';
import 'recipe_service.dart';
import 'recipe_model.dart';
import 'recipe_detail_page.dart';
import 'favorites_page.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recipes = []; //list to store all recipies in
  bool _loading = false;
  final String _query = '';

  bool _isBreakfastSelected = false;
  bool _isLunchSelected = false;
  bool _isDinnerSelected = false;
  Set<int> _favoriteRecipeIds = <int>{};

  @override
  void initState() {
    super.initState();
    fetchAllRecipes();
    loadFavorites();
  }

  Future<void> fetchAllRecipes() async {
    setState(() {
      _loading = true;
    });

    try {
      final recipes = await _recipeService.fetchRecipes('');
      //print('Fetched recipes: ${recipes.length}'); // to see if recipies being fetched
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } catch (e) {
      // print('Error fetching recipes: $e');
      setState(() {
        _recipes = [];
        _loading = false;
      });
    }
  }

  void _searchRecipes(String query) async {
    setState(() {
      _loading = true;
    });

    try {
      final recipes = await _recipeService.fetchRecipes(query);
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _recipes = [];
        _loading = false;
      });
    }
  }

  Future<void> loadFavorites() async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> favoriteList = await db.query('favorites');
    setState(() {
      _favoriteRecipeIds =
          favoriteList.map((fav) => fav['recipeId'] as int).toSet();
    });
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final db = await DatabaseHelper.database;

    if (_favoriteRecipeIds.contains(recipe.id)) {
      //if already in favorites than remove
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
  }

  void _openFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        bool isBreakfastSelected = _isBreakfastSelected;
        bool isLunchSelected = _isLunchSelected;
        bool isDinnerSelected = _isDinnerSelected;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Recipes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Breakfast'),
                    value: isBreakfastSelected,
                    onChanged: (value) {
                      setState(() {
                        isBreakfastSelected = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Lunch'),
                    value: isLunchSelected,
                    onChanged: (value) {
                      setState(() {
                        isLunchSelected = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Dinner'),
                    value: isDinnerSelected,
                    onChanged: (value) {
                      setState(() {
                        isDinnerSelected = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isBreakfastSelected = isBreakfastSelected;
                      _isLunchSelected = isLunchSelected;
                      _isDinnerSelected = isDinnerSelected;
                    });
                    _applyFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    String filterQuery = _query;

    if (_isBreakfastSelected) {
      filterQuery += '&type=breakfast';
    }
    if (_isLunchSelected) {
      filterQuery += '&type=lunch';
    }
    if (_isDinnerSelected) {
      filterQuery += '&type=dinner';
    }

    _searchRecipes(filterQuery);
  }

  void _onRecipeTap(BuildContext context, int recipeId) async {
    try {
      final recipe = await _recipeService.fetchRecipeDetails(recipeId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
      );
    } catch (e) {
      print("Failed to load recipe details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Masala'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _openFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Recipes...',
                suffixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.orange.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _searchRecipes,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                    ? const Center(child: Text('No recipe found'))
                    : ListView.builder(
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          bool isFavorite =
                              _favoriteRecipeIds.contains(recipe.id);

                          return Card(
                            color: Colors.orange.shade50,
                            child: InkWell(
                              onTap: () {
                                // debugging to see by print statement to check if this is called
                                print('Recipe tapped: ${recipe.title}');
                                _onRecipeTap(context, recipe.id);
                              },
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
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                    },
                                  ),
                                ),
                                title: Text(recipe.title),
                                trailing: IconButton(
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : null,
                                  ),
                                  onPressed: () async {
                                    await _toggleFavorite(recipe);
                                    setState(() {
                                      isFavorite = !isFavorite;
                                    });
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

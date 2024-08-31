import 'dart:convert';
import 'package:http/http.dart' as http;
import 'recipe_model.dart';

class RecipeService {
  final String _baseUrl = 'https://api.spoonacular.com/recipes/';
  final String _apiKey =
      '988c5a63bc02410e9276319057336f76'; // Replace with your Spoonacular API key

  Future<List<Recipe>> fetchRecipes(String query) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/complexSearch?query=$query&apiKey=$_apiKey'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['results'];
      return data.map((json) => Recipe.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<Recipe> fetchRecipeDetails(int id) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/$id/information?apiKey=$_apiKey'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Recipe(
        id: json['id'],
        title: json['title'],
        imageUrl: json['image'],
        ingredients: List<String>.from(json['extendedIngredients']
            .map((ingredient) => ingredient['original'])),
        method: json['instructions'] ?? 'No instructions provided.',
      );
    } else {
      throw Exception('Failed to load recipe details');
    }
  }
}

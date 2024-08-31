class Recipe {
  final int id;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final String method;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.method,
  });

  // Factory constructor to create a Recipe from JSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image'] ?? '', // Default to empty string if null
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      method: json['method'] ?? '',
    );
  }

  // Factory constructor to create a Recipe from a database map
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['recipeId'] ?? 0, // Use 'recipeId' as per your database schema
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ingredients: map['ingredients'] != null
          ? List<String>.from(map['ingredients'])
          : [],
      method: map['method'] ?? '',
    );
  }

  // Converts a Recipe instance to a map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'recipeId': id,
      'title': title,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'method': method,
    };
  }
}

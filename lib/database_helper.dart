import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> get database async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      join(databasePath, 'favorites.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE favorites(recipeId INTEGER PRIMARY KEY, title TEXT, imageUrl TEXT)",
        );
      },
      version: 1,
    );
  }

  // Example method to insert a favorite
  static Future<void> insertFavorite(Map<String, dynamic> favorite) async {
    final db = await database;
    await db.insert('favorites', favorite,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Example method to retrieve all favorites
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    return db.query('favorites');
  }
}

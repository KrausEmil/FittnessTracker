import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';

  // ──── Exercises ────

  static Future<List<Map<String, dynamic>>> getExercises() async {
    final res = await http.get(Uri.parse('$_baseUrl/exercises'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('Fehler beim Laden der Übungen');
  }

  static Future<Map<String, dynamic>> createExercise(
    String name,
    double weight,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/exercises'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'weight': weight}),
    );
    if (res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Fehler beim Erstellen der Übung');
  }

  static Future<void> deleteExercise(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/exercises/$id'));
    if (res.statusCode != 200) {
      throw Exception('Fehler beim Löschen der Übung');
    }
  }

  // ──── Training Plans ────

  static Future<List<Map<String, dynamic>>> getPlans() async {
    final res = await http.get(Uri.parse('$_baseUrl/training-plans'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('Fehler beim Laden der Pläne');
  }

  static Future<Map<String, dynamic>> getPlanById(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/training-plans/$id'));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Fehler beim Laden des Plans');
  }

  static Future<Map<String, dynamic>> createPlan(String name) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/training-plans'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Fehler beim Erstellen des Plans');
  }

  static Future<void> deletePlan(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/training-plans/$id'));
    if (res.statusCode != 200) {
      throw Exception('Fehler beim Löschen des Plans');
    }
  }

  static Future<Map<String, dynamic>> addExerciseToPlan(
    int planId,
    int exerciseId,
    int sets,
    int repetitions,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/training-plans/$planId/exercises'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'exercise_id': exerciseId,
        'sets': sets,
        'repetitions': repetitions,
      }),
    );
    if (res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Fehler beim Hinzufügen der Übung zum Plan');
  }

  static Future<void> removePlanExercise(int planId, int peId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/training-plans/$planId/exercises/$peId'),
    );
    if (res.statusCode != 200) {
      throw Exception('Fehler beim Entfernen der Übung');
    }
  }
}

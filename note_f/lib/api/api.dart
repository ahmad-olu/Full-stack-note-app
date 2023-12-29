import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'package:note_f/model/api_key.dart';
import 'package:note_f/model/note.dart';

class Api {
  static String baseUrl = "http://localhost:3000";
  static Map<String, String> insertHeader(String apiKey, bool addContentType) {
    if (addContentType == false) {
      return {'Api-key': apiKey};
    }
    return {'Api-key': apiKey, "Content-Type": "application/json"};
  }

  Future<List<Note>> getAllNotes(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notes'),
        headers: insertHeader(apiKey, false),
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body)['notes'];

        return body.map((note) => Note.fromMap(note)).toList();
      }
      throw NoApiKey(
          errorCode: response.statusCode,
          errorMessage: (json.decode(response.body)['error']));
    } on NoApiKey catch (e) {
      throw NoApiKey(errorCode: e.errorCode, errorMessage: e.errorMessage);
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<Note> postNote(String apiKey, Note note) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: insertHeader(apiKey, true),
        body: note.toJson(),
      );

      if (response.statusCode == 200) {
        return Note.fromJson(response.body);
      }
      log("${response.statusCode} :: ${response.body}");
      throw Exception("${response.statusCode} :: ${response.body}");
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<Note> getNote(String apiKey, String noteId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notes/$noteId'),
        headers: insertHeader(apiKey, false),
      );

      if (response.statusCode == 200) {
        return Note.fromJson(response.body);
      }
      log("${response.statusCode} :: ${response.body}");
      throw Exception("${response.statusCode} :: ${response.body}");
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<Note> updateNote(String apiKey, String noteId, Note note) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/notes/$noteId'),
        body: note.toJson(),
        headers: insertHeader(apiKey, true),
      );

      if (response.statusCode == 200) {
        return Note.fromJson(response.body);
      }
      log("${response.statusCode} :: ${response.body}");
      throw Exception("${response.statusCode} :: ${response.body}");
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<void> deleteNote(String apiKey, String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notes/$noteId'),
        headers: insertHeader(apiKey, false),
      );

      if (response.statusCode == 200) {
        log("${response.statusCode} :: Success");
        return;
      }
      log("${response.statusCode} :: ${response.body}");
      throw Exception("${response.statusCode} :: ${response.body}");
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<List<ApiKey>> getAllApiKeys(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api_key'),
        headers: insertHeader(apiKey, false),
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body)['data'];
        return body.map((data) => ApiKey.fromMap(data)).toList();
      }
      log("${response.statusCode} :: ${response.body}");
      throw Exception("${response.statusCode} :: ${response.body}");
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<ApiKey> generateApiKey(
      String name, String email, List<String> scope) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api_key/new'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'name': name, 'scope': scope, 'email': email}),
      );
      if (response.statusCode == 200) {
        log(response.body);
        return ApiKey.fromJson(response.body);
      }
      log("${response.statusCode} :: ${response.body}");
      throw Exception("${response.statusCode} :: ${response.body}");
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<void> deleteApiKey(String apiKey) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api_key'),
        headers: insertHeader(apiKey, false),
      );

      if (response.statusCode == 200) {
        log("${response.statusCode} :: ${response.body}");
        return;
      }
      log("${response.statusCode} :: ${response.body}");
      throw Exception("${response.statusCode} :: ${response.body}");
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }
}

class NoApiKey {
  final int errorCode;
  final String errorMessage;

  const NoApiKey({required this.errorCode, required this.errorMessage});

  @override
  String toString() =>
      'NoApiKey(errorCode: $errorCode, errorMessage: $errorMessage)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NoApiKey &&
        other.errorCode == errorCode &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => errorCode.hashCode ^ errorMessage.hashCode;
}

//localhost:3000
// api_key/new -> generate api key [name, scope, email] (id, name, scope, api_key, prefix,)
// /api_key/:api_key_id -> delete api key
// /api_key -> get all api key 
// /notes/:note_id -> get, delete, update, note [title, description]
// /notes -> get all notes, post note [title, description]

//header -> Api-key

//1703782883.9b7fcb47-7c69-44c3-a8d8-3c3c50682e86
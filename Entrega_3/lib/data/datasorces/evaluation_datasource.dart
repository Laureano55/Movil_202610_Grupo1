import 'dart:convert';
import 'package:http/http.dart' as http;

class EvaluationDatasource {

  final http.Client client;

  EvaluationDatasource(this.client);

  Future<void> sendEvaluation(Map<String, dynamic> data) async {

    final response = await client.post(
      Uri.parse("http://localhost:3000/api/evaluations"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Error enviando evaluación");
    }
  }
}
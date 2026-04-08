import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:tu_proyecto/data/datasources/evaluation_datasource.dart';
import 'package:tu_proyecto/data/repositories/evaluation_repository.dart';

void main() {

  test("Enviar evaluación correctamente", () async {

    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode({"message": "ok"}), 200);
    });

    final datasource = EvaluationDatasource(mockClient);
    final repository = EvaluationRepository(datasource);

    await repository.submitEvaluation({
      "evaluatorId": "1",
      "evaluatedId": "2",
      "score": 5
    });

  });
}
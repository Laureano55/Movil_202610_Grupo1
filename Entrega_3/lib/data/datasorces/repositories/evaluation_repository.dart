import '../evaluation_datasource.dart';

class EvaluationRepository {

  final EvaluationDatasource datasource;

  EvaluationRepository(this.datasource);

  Future<void> submitEvaluation(Map<String, dynamic> data) {
    return datasource.sendEvaluation(data);
  }
}
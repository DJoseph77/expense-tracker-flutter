import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/statistics_response.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StatisticsRepository(dio: dio);
});

class StatisticsRepository {
  final Dio _dio;

  StatisticsRepository({required Dio dio}) : _dio = dio;

  /// GET /api/statistics/summary
  Future<StatisticsResponse> getSummary() async {
    try {
      final response = await _dio.get(ApiEndpoints.statisticsSummary);

      if (response.statusCode == 200) {
        return StatisticsResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw const ApiException(
        message: 'Failed to load statistics summary.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

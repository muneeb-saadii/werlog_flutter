import 'package:dio/dio.dart';

class DioClient {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Dio get client => dio;
}

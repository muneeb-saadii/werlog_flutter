import 'dio_client.dart';

class ApiService {
  final DioClient dioClient;

  ApiService(this.dioClient);

  Future<dynamic> get(String url, {Map<String, dynamic>? params}) async {
    try {
      final response = await dioClient.client.get(url, queryParameters: params);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String url, Map body) async {
    try {
      final response = await dioClient.client.post(url, data: body);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

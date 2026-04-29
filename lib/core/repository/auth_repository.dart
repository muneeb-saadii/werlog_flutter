import '../../core/networking/api_service.dart';

class AuthRepository {
  final ApiService api;

  AuthRepository(this.api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await api.post(
      "https://yourapi.com/login",
      {
        "email": email,
        "password": password,
      },
    );

    return response;
  }
}

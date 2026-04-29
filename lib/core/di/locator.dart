import 'package:get_it/get_it.dart';
import '../networking/dio_client.dart';
import '../networking/api_service.dart';
import '../repository/auth_repository.dart';
import '../storage/prefs_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => DioClient());

  locator.registerLazySingleton(() => ApiService(locator<DioClient>()));

  locator.registerLazySingleton(() => PrefsService());

  locator.registerLazySingleton(() => AuthRepository(locator<ApiService>()));
}

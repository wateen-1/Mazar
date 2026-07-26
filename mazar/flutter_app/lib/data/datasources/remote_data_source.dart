import '../../core/network/api_client.dart';

/// مصدر بيانات عام للاتصال بالـ API، تُبنى عليه مصادر بيانات كل ميزة
/// من ميزات التطبيق (planner، mazarat، crowd) داخل مجلد features/.
abstract class RemoteDataSource {
  final ApiClient apiClient;

  RemoteDataSource(this.apiClient);
}

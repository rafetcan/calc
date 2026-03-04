import 'package:get_it/get_it.dart';
import '../../features/feedback/services/feedback_service.dart';
import '../../features/support/services/ad_service.dart';
import '../../features/support/services/purchase_service.dart';

final getIt = GetIt.I;

void setupLocator() {
  getIt.registerLazySingleton(() => FeedbackService());
  getIt.registerLazySingleton(() => AdService());
  getIt.registerLazySingleton(() => PurchaseService());
}

import 'package:get_it/get_it.dart';
import '../../features/feedback/services/feedback_service.dart';

void setupLocator() {
  GetIt.I.registerLazySingleton(() => FeedbackService());
}

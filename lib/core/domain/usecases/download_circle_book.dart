import 'package:injectable/injectable.dart';
import 'package:zapbook/core/services/circle_share_service.dart';

@injectable
class DownloadCircleBook {
  const DownloadCircleBook(this._circleShareService);

  final CircleShareService _circleShareService;

  Future<bool> call(String groupId, String circleDirId) async {
    return _circleShareService.fetchAndDownloadBook(groupId, circleDirId);
  }
}

import '../entities/managed_user.dart';
import '../repositories/user_management_repository.dart';

class ObserveManagedUsers {
  ObserveManagedUsers(this._repository);

  final UserManagementRepository _repository;

  Stream<List<ManagedUser>> call() {
    return _repository.observeUsers();
  }
}
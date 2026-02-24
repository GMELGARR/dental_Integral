import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/entities/module_permission.dart';

class UserManagementFirestoreDataSource {
  UserManagementFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<ManagedUser>> observeUsers() {
    return _firestore.collection('users').orderBy('displayName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final modulesRaw = (data['modules'] as List<dynamic>? ?? <dynamic>[])
            .map((entry) => entry.toString())
            .toList();

        final modules = modulesRaw
            .map(modulePermissionFromKey)
            .whereType<ModulePermission>()
            .toList(growable: false);

        return ManagedUser(
          uid: doc.id,
          email: (data['email'] as String?) ?? '',
          displayName: (data['displayName'] as String?) ?? 'Sin nombre',
          role: (data['role'] as String?) ?? 'staff',
          active: (data['active'] as bool?) ?? true,
          modules: modules,
        );
      }).toList(growable: false);
    });
  }

  Future<void> updateUserAccess({
    required String uid,
    required bool active,
    required List<ModulePermission> modules,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'active': active,
        'modules': modules.map((module) => module.key).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw AppException('No se pudo actualizar el acceso del usuario.', cause: error);
    }
  }
}
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database.dart';
import 'package:drift/drift.dart';

class CurrentUser {
  final int id;
  final String username;
  final String role;
  final bool canEdit;
  final bool canDelete;
  final bool canExport;
  final bool canViewDashboard;

  CurrentUser({
    required this.id,
    required this.username,
    required this.role,
    required this.canEdit,
    required this.canDelete,
    required this.canExport,
    required this.canViewDashboard,
  });

  bool get isAdmin => role == 'ADMIN';
}

class AuthService {
  final AppDatabase _db;
  CurrentUser? currentUser;

  AuthService(this._db);

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('currentUserId');
    if (userId != null) {
      final user = await _getUserById(userId);
      if (user != null && user.isActive) {
        currentUser = CurrentUser(
          id: user.id,
          username: user.username,
          role: user.role,
          canEdit: user.canEdit,
          canDelete: user.canDelete,
          canExport: user.canExport,
          canViewDashboard: user.canViewDashboard,
        );
      }
    }
  }

  Future<bool> get isFirstLaunch async {
    final users = await _db.getAllUsers();
    return users.isEmpty;
  }

  Future<User?> _getUserById(int id) async {
    return (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  Future<bool> login(String username, String password) async {
    final user = await _db.getUser(username);
    if (user != null && user.isActive) {
      final hashed = hashPassword(password);
      if (user.passwordHash == hashed) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currentUserId', user.id);
        currentUser = CurrentUser(
          id: user.id,
          username: user.username,
          role: user.role,
          canEdit: user.canEdit,
          canDelete: user.canDelete,
          canExport: user.canExport,
          canViewDashboard: user.canViewDashboard,
        );
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    currentUser = null;
  }

  Future<void> createAdmin(String username, String password) async {
    final hashed = hashPassword(password);
    await _db.addUser(UsersCompanion.insert(
      username: username,
      passwordHash: hashed,
      role: 'ADMIN',
      canEdit: const Value(true),
      canDelete: const Value(true),
      canExport: const Value(true),
      canViewDashboard: const Value(true),
    ));
  }

  Future<void> createUser({
    required String username,
    required String password,
    bool canEdit = false,
    bool canDelete = false,
    bool canExport = false,
    bool canViewDashboard = false,
  }) async {
    final hashed = hashPassword(password);
    await _db.addUser(UsersCompanion.insert(
      username: username,
      passwordHash: hashed,
      role: 'USER',
      canEdit: Value(canEdit),
      canDelete: Value(canDelete),
      canExport: Value(canExport),
      canViewDashboard: Value(canViewDashboard),
    ));
  }

  Future<void> updateUser(User user, {String? newPassword}) async {
    if (newPassword != null && newPassword.isNotEmpty) {
      final hashed = hashPassword(newPassword);
      await _db.updateUser(user.copyWith(passwordHash: hashed));
    } else {
      await _db.updateUser(user);
    }
  }

  Future<void> toggleUserActive(User user) async {
    await _db.updateUser(user.copyWith(isActive: !user.isActive));
  }
}

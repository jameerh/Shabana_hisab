import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/database/database.dart';
import '../../main.dart';

class UserManagementView extends StatefulWidget {
  final AuthService authService;

  const UserManagementView({super.key, required this.authService});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await database.getAllUsers();
    setState(() => _isLoading = false);
  }

  void _showUserDialog([User? user]) {
    final isNew = user == null;
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final passwordCtrl = TextEditingController();
    bool canEdit = user?.canEdit ?? false;
    bool canDelete = user?.canDelete ?? false;
    bool canExport = user?.canExport ?? false;
    bool canViewDashboard = user?.canViewDashboard ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isNew ? 'Add User' : 'Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  enabled: isNew, // Don't let them change username of existing easily
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: isNew ? 'Password' : 'New Password (leave blank to keep current)',
                  ),
                  obscureText: true,
                ),
                if (user?.role != 'ADMIN') ...[
                  const SizedBox(height: 16),
                  const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                    title: const Text('Can Add/Edit Transactions'),
                    value: canEdit,
                    onChanged: (v) => setDialogState(() => canEdit = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Can Delete Transactions'),
                    value: canDelete,
                    onChanged: (v) => setDialogState(() => canDelete = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Can Export PDF'),
                    value: canExport,
                    onChanged: (v) => setDialogState(() => canExport = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Can View Analytics Dashboard'),
                    value: canViewDashboard,
                    onChanged: (v) => setDialogState(() => canViewDashboard = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (isNew) {
                  if (usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username and Password required')));
                    return;
                  }
                  await widget.authService.createUser(
                    username: usernameCtrl.text.trim(),
                    password: passwordCtrl.text,
                    canEdit: canEdit,
                    canDelete: canDelete,
                    canExport: canExport,
                    canViewDashboard: canViewDashboard,
                  );
                } else {
                  await widget.authService.updateUser(
                    user.copyWith(
                      canEdit: user.role == 'ADMIN' ? true : canEdit,
                      canDelete: user.role == 'ADMIN' ? true : canDelete,
                      canExport: user.role == 'ADMIN' ? true : canExport,
                      canViewDashboard: user.role == 'ADMIN' ? true : canViewDashboard,
                    ),
                    newPassword: passwordCtrl.text,
                  );
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadUsers();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authService.currentUser!.isAdmin) {
      return const Scaffold(body: Center(child: Text('Access Denied')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.role == 'ADMIN' ? Colors.red : Colors.indigo,
                    child: Icon(user.role == 'ADMIN' ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
                  ),
                  title: Text(user.username),
                  subtitle: Text('Role: ${user.role} | Active: ${user.isActive}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showUserDialog(user),
                      ),
                      if (user.role != 'ADMIN')
                        Switch(
                          value: user.isActive,
                          onChanged: (val) async {
                            await widget.authService.toggleUserActive(user);
                            _loadUsers();
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

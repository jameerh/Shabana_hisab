import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../home/home_view.dart';
import '../../data/database/database.dart';
import '../../data/core/config/app_config.dart';
import '../../main.dart';
import 'package:drift/drift.dart' as drift;

class OnboardingView extends StatefulWidget {
  final AuthService authService;

  const OnboardingView({super.key, required this.authService});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _adminUserController = TextEditingController(text: 'admin');
  final _adminPassController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  void _completeOnboarding() async {
    final user = _adminUserController.text.trim();
    final pass = _adminPassController.text;
    final shopName = _shopNameController.text.trim();

    if (user.isEmpty || pass.isEmpty || shopName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin credentials and Shop Name are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Create Admin User
    await widget.authService.createAdmin(user, pass);

    // 2. Create Shop Settings
    await database.addOrUpdateSettings(
      ShopSettingsCompanion(
        shopName: drift.Value(shopName),
        ownerName: drift.Value(_ownerNameController.text.trim()),
        mobileNumber: drift.Value(_mobileController.text.trim()),
      ),
    );

    // 3. Login
    await widget.authService.login(user, pass);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Store Setup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome to ${AppConfig.appName}!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConfig.appTagline,
                  style: TextStyle(color: Colors.grey, fontSize: 18, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Admin Setup
                const Text('1. Create Admin Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _adminUserController,
                  decoration: const InputDecoration(labelText: 'Admin Username', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _adminPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Admin Password', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 32),

                // Shop Setup
                const Text('2. Shop Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(labelText: 'Store/Shop Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(labelText: 'Owner Name (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: _completeOnboarding,
                    child: const Text('Complete Setup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

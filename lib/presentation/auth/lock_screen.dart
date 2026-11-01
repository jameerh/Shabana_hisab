import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/security_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({super.key, required this.onAuthenticated});

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _tryBiometrics();
  }

  Future<void> _tryBiometrics() async {
    final success = await SecurityService.authenticateWithBiometrics();
    if (mounted && success) {
      widget.onAuthenticated();
    }
  }

  void _verifyPin() async {
    final success = await SecurityService.verifyPin(_pinController.text);
    if (!mounted) return;
    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = "चुकीचा पिन! पुन्हा प्रयत्न करा (Incorrect PIN)";
        _pinController.clear();
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade700, Colors.green.shade900],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'शबाना हिसाब',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ॲप सुरक्षित आहे. कृपया पिन टाका.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'PIN',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.length == 4) _verifyPin();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  const SizedBox(height: 48),
                  IconButton(
                    icon: const Icon(Icons.fingerprint, size: 64, color: Colors.white),
                    onPressed: _tryBiometrics,
                  ),
                  const Text(
                    'Use Biometrics / बायोमेट्रिक वापरा',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

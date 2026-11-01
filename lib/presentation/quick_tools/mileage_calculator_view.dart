import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/localization/bilingual_text.dart';
import '../../main.dart';

class MileageCalculatorView extends StatefulWidget {
  const MileageCalculatorView({Key? key}) : super(key: key);

  @override
  State<MileageCalculatorView> createState() => _MileageCalculatorViewState();
}

class _MileageCalculatorViewState extends State<MileageCalculatorView> {
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _lastKmCtrl = TextEditingController();
  final TextEditingController _presentKmCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _literCtrl = TextEditingController();

  String _result = '';

  @override
  void dispose() {
    _priceCtrl.dispose();
    _lastKmCtrl.dispose();
    _presentKmCtrl.dispose();
    _amountCtrl.dispose();
    _literCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final l10n = AppLocalizations.of(context);
    double? price = double.tryParse(_priceCtrl.text);
    double? lastKm = double.tryParse(_lastKmCtrl.text);
    double? presentKm = double.tryParse(_presentKmCtrl.text);
    double? amount = double.tryParse(_amountCtrl.text);
    double? liter = double.tryParse(_literCtrl.text);

    if (lastKm == null || presentKm == null) {
      setState(() {
        _result = l10n?.enterKmPrompt ?? 'Please enter KM';
      });
      return;
    }

    double distance = presentKm - lastKm;
    if (distance <= 0) {
      setState(() {
        _result = l10n?.presentKmGreaterPrompt ?? 'Present KM must be greater than Last KM';
      });
      return;
    }

    if (liter == null && amount != null && price != null && price > 0) {
      liter = amount / price;
      _literCtrl.text = liter.toStringAsFixed(2);
    } else if (amount == null && liter != null && price != null && price > 0) {
      amount = liter * price;
      _amountCtrl.text = amount.toStringAsFixed(2);
    } else if (liter == null && amount == null) {
      setState(() {
        _result = l10n?.enterFuelPrompt ?? 'Please enter Fuel Amount or Liters';
      });
      return;
    }

    if (liter != null && liter > 0) {
      double mileage = distance / liter;
      double costPerKm = (amount ?? 0) / distance;
      final mileageLabel = l10n?.mileageResult ?? 'Mileage';
      final costLabel = l10n?.costPerKm ?? 'Cost/KM';
      
      setState(() {
        _result = '$mileageLabel: ${mileage.toStringAsFixed(2)} KM/L\n'
                  '${costPerKm > 0 ? '$costLabel: ₹${costPerKm.toStringAsFixed(2)}' : ''}';
      });
    } else {
      setState(() {
        _result = 'Could not calculate mileage';
      });
    }
  }

  void _clear() {
    _priceCtrl.clear();
    _lastKmCtrl.clear();
    _presentKmCtrl.clear();
    _amountCtrl.clear();
    _literCtrl.clear();
    setState(() {
      _result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(
          english: 'Mileage Calculator',
          marathi: 'मायलेज कॅल्क्युलेटर',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BilingualText(
                  english: 'Fill Fuel Details',
                  marathi: 'इंधन तपशील भरा',
                  languageController: languageController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n?.currentFuelPrice ?? 'Current Fuel Price (₹/L)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  onChanged: (_) => _calculate(),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lastKmCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n?.lastKm ?? 'Last KM',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _presentKmCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n?.presentKm ?? 'Present KM',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('किंवा एक भरा (Fill one of below):', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'इंधनाची रक्कम (Amount ₹)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty) _literCtrl.clear();
                          _calculate();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _literCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'इंधन लिटर (Liters)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty) _amountCtrl.clear();
                          _calculate();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text('निकाल (Result)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      const SizedBox(height: 10),
                      Text(
                        _result.isEmpty ? '--' : _result,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _result.contains('मायलेज (Mileage)') ? Colors.green : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh),
                  label: const Text('क्लिअर करा (Clear)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

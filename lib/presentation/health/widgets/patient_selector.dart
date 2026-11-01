import 'package:flutter/material.dart';
import '../../../data/models/health_models.dart';
import '../dialogs/patient_management_dialog.dart';

class PatientSelector extends StatelessWidget {
  final List<HealthPatient> patients;
  final int? selectedPatientId; // null means 'All Patients'
  final ValueChanged<int?> onPatientSelected;
  final VoidCallback onPatientListUpdated;
  final int profileId;

  const PatientSelector({
    super.key,
    required this.patients,
    required this.selectedPatientId,
    required this.onPatientSelected,
    required this.onPatientListUpdated,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    HealthPatient? selectedPatient;
    if (selectedPatientId != null) {
      final matches = patients.where((p) => p.id == selectedPatientId);
      if (matches.isNotEmpty) selectedPatient = matches.first;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, size: 20, color: Colors.teal),
          const SizedBox(width: 8),
          const Text(
            'Patient:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 'All' Chip
                  ChoiceChip(
                    label: const Text('All Family'),
                    selected: selectedPatientId == null,
                    onSelected: (selected) {
                      if (selected) onPatientSelected(null);
                    },
                    selectedColor: Colors.teal.shade100,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedPatientId == null ? FontWeight.bold : FontWeight.normal,
                      color: selectedPatientId == null ? Colors.teal.shade900 : Colors.black87,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),

                  // Individual Patient Chips
                  ...patients.map((p) {
                    final isSelected = selectedPatientId == p.id;
                    final relationStr = p.relationship?.isNotEmpty == true ? ' (${p.relationship})' : '';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: isSelected ? Colors.teal : Colors.grey.shade300,
                          child: Text(
                            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text('${p.name}$relationStr'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) onPatientSelected(p.id);
                        },
                        selectedColor: Colors.teal.shade100,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.teal.shade900 : Colors.black87,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded, size: 20, color: Colors.teal),
            tooltip: 'Manage Family Members',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => PatientManagementDialog(profileId: profileId),
              );
              onPatientListUpdated();
            },
          ),
        ],
      ),
    );
  }
}

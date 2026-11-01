import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/health_models.dart';
import '../../../main.dart';

class PatientManagementDialog extends StatefulWidget {
  final int profileId;

  const PatientManagementDialog({super.key, required this.profileId});

  @override
  State<PatientManagementDialog> createState() => _PatientManagementDialogState();
}

class _PatientManagementDialogState extends State<PatientManagementDialog> {
  List<HealthPatient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final list = await healthRepository.getPatients(widget.profileId);
    if (mounted) {
      setState(() {
        _patients = list;
        _isLoading = false;
      });
    }
  }

  void _showAddEditPatientSheet([HealthPatient? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String relationship = existing?.relationship ?? 'Self';
    DateTime? dob = existing?.dateOfBirth;
    String gender = existing?.gender ?? 'Male';
    String bloodGroup = existing?.bloodGroup ?? 'O+';

    final relationships = ['Self', 'Father', 'Mother', 'Spouse', 'Son', 'Daughter', 'Grandfather', 'Grandmother', 'Other'];
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final genders = ['Male', 'Female', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final age = dob != null
              ? (DateTime.now().difference(dob!).inDays ~/ 365)
              : null;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'Add Family Member' : 'Edit Member Details',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Suggestion Chips if new
                  if (existing == null) ...[
                    const Text('Quick Add:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['Father', 'Mother', 'Spouse', 'Child'].map((rel) {
                        return ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: Text(rel, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setSheetState(() {
                              nameController.text = rel;
                              relationship = rel;
                              if (rel == 'Father' || rel == 'Spouse') gender = 'Male';
                              if (rel == 'Mother') gender = 'Female';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name / Relation *',
                      hintText: 'e.g. Father, Mother, Abdul',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: relationships.contains(relationship) ? relationship : 'Other',
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    items: relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => relationship = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date of Birth / Age
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dob ?? DateTime(1980, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setSheetState(() => dob = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth (Calculates Age)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        dob != null
                            ? '${DateFormat('dd MMM yyyy').format(dob!)}${age != null ? ' ($age yrs)' : ''}'
                            : 'Select Date of Birth (Optional)',
                        style: TextStyle(color: dob != null ? Colors.black87 : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Gender
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => gender = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Blood Group
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: bloodGroups.contains(bloodGroup) ? bloodGroup : 'O+',
                          decoration: const InputDecoration(
                            labelText: 'Blood Group',
                            border: OutlineInputBorder(),
                          ),
                          items: bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => bloodGroup = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(existing == null ? 'Save Family Member' : 'Update Details'),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        if (existing == null) {
                          await healthRepository.addPatient(
                            profileId: widget.profileId,
                            name: name,
                            relationship: relationship,
                            dateOfBirth: dob,
                            gender: gender,
                            bloodGroup: bloodGroup,
                          );
                        } else {
                          await healthRepository.updatePatient(
                            existing.copyWith(
                              name: name,
                              relationship: relationship,
                              dateOfBirth: dob,
                              gender: gender,
                              bloodGroup: bloodGroup,
                            ),
                          );
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadPatients();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.teal),
              SizedBox(width: 8),
              Text('Family Patients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.teal, size: 28),
            tooltip: 'Add Family Member',
            onPressed: () => _showAddEditPatientSheet(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _patients.isEmpty
                ? const Center(child: Text('No family members added.'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _patients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = _patients[index];
                      final ageStr = p.ageInYears != null ? ' • ${p.ageInYears} yrs' : '';
                      final bgStr = p.bloodGroup?.isNotEmpty == true ? ' • ${p.bloodGroup}' : '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                          ),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${p.relationship ?? "Family"}$ageStr$bgStr'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                              onPressed: () => _showAddEditPatientSheet(p),
                            ),
                            if (p.relationship != 'Self')
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: Text('Delete ${p.name}?'),
                                      content: const Text('This will also delete all health records associated with this patient.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await healthRepository.deletePatient(p.id);
                                    _loadPatients();
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

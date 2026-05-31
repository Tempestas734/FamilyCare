import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/healthsync_service.dart';
import '../../theme/app_theme.dart';

enum _AddMemberMode {
  existingPatient,
  newPatient,
}

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _existingFormKey = GlobalKey<FormState>();
  final _newPatientFormKey = GlobalKey<FormState>();
  final _healthsync = HealthsyncService(Supabase.instance.client);

  final _existingPatientCodeController = TextEditingController();
  final _existingBarcodeController = TextEditingController();
  final _existingWeightController = TextEditingController();

  final _newFullNameController = TextEditingController();
  final _newBirthDateController = TextEditingController();
  final _newPhoneController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _newWeightController = TextEditingController();
  final _newCinController = TextEditingController();

  _AddMemberMode _mode = _AddMemberMode.existingPatient;
  String _existingRelationshipRole = 'enfant';
  String _newRelationshipRole = 'enfant';
  String? _existingBloodType;
  String? _newBloodType;
  String? _newGender;
  bool _isSearching = false;
  bool _isSubmitting = false;
  HealthsyncPatientSummary? _foundPatient;

  @override
  void dispose() {
    _existingPatientCodeController.dispose();
    _existingBarcodeController.dispose();
    _existingWeightController.dispose();
    _newFullNameController.dispose();
    _newBirthDateController.dispose();
    _newPhoneController.dispose();
    _newEmailController.dispose();
    _newWeightController.dispose();
    _newCinController.dispose();
    super.dispose();
  }

  Future<void> _searchExistingPatient() async {
    FocusScope.of(context).unfocus();
    if (!_existingFormKey.currentState!.validate()) {
      return;
    }
    if (_existingPatientCodeController.text.trim().isEmpty &&
        _existingBarcodeController.text.trim().isEmpty) {
      _showMessage('Renseignez un patient code ou un barcode.');
      return;
    }

    setState(() {
      _isSearching = true;
      _foundPatient = null;
    });

    try {
      final patient = await _healthsync.findExistingPatient(
        cin: _existingPatientCodeController.text,
        barcodeValue: _existingBarcodeController.text,
      );
      if (!mounted) return;
      setState(() => _foundPatient = patient);
      if (patient == null) {
        _showMessage(
          'Aucun patient trouve. Vous pouvez creer un nouveau patient.',
        );
      }
    } on PostgrestException catch (error) {
      _showMessage('Erreur DB: ${error.message}');
    } catch (error) {
      _showMessage('Recherche impossible: $error');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _linkExistingPatient() async {
    final patient = _foundPatient;
    if (patient == null) {
      _showMessage('Recherchez d abord un patient existant.');
      return;
    }
    if (!_existingFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _healthsync.addFamilyMemberWithExistingPatient(
        familyId: widget.familyId,
        relationshipRole: _existingRelationshipRole,
        patientId: patient.id,
        birthDate: null,
        bloodType: _existingBloodType ?? patient.bloodGroup,
        weightKg: _parseWeight(_existingWeightController.text),
      );
      if (!mounted) return;
      _showSuccessDialog(
        title: 'Patient lie a la famille',
        lines: [
          'Patient global: ${patient.fullName}',
          if ((patient.dateOfBirth ?? '').isNotEmpty)
            'Naissance: ${patient.dateOfBirth}',
          if ((patient.barcodeValue ?? '').isNotEmpty)
            'Barcode: ${patient.barcodeValue}',
        ],
      );
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } on PostgrestException catch (error) {
      _showMessage('Erreur DB: ${error.message}');
    } catch (error) {
      _showMessage('Ajout impossible: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createNewPatient() async {
    FocusScope.of(context).unfocus();
    if (!_newPatientFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final patient = await _healthsync.addFamilyMemberWithNewPatient(
        familyId: widget.familyId,
        fullName: _newFullNameController.text.trim(),
        relationshipRole: _newRelationshipRole,
        birthDate: _parseDate(_newBirthDateController.text),
        gender: _newGender,
        phone: _newPhoneController.text,
        email: _newEmailController.text,
        bloodType: _newBloodType,
        weightKg: _parseWeight(_newWeightController.text),
        cin: _newCinController.text,
      );
      if (!mounted) return;
      _showSuccessDialog(
        title: 'Membre et patient crees',
        lines: [
          'Nom: ${_newFullNameController.text.trim()}',
          if ((_asText(patient['barcode_value']) ?? '').isNotEmpty)
            'Barcode genere: ${patient['barcode_value']}',
          if ((_asText(patient['patient_code']) ?? '').isNotEmpty)
            'CIN: ${patient['patient_code']}',
        ],
      );
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } on PostgrestException catch (error) {
      final details =
          '${error.message} ${error.details ?? ''} ${error.hint ?? ''}';
      if (details.toLowerCase().contains('barcode')) {
        _showMessage(
          'Creation patient impossible: verifier le trigger SQL set_patient_defaults().',
        );
      } else {
        _showMessage('Erreur DB: ${error.message}');
      }
    } catch (error) {
      _showMessage('Creation impossible: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 120, 1, 1),
      lastDate: now,
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _showSuccessDialog({
    required String title,
    required List<String> lines,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.map((line) => Text(line)).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F6F8),
    );

    return Theme(
      data: lightTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true,
              title: const Text('Ajouter un membre'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModeSwitcher(
                      mode: _mode,
                      onChanged: (mode) {
                        setState(() {
                          _mode = mode;
                          _foundPatient = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_mode == _AddMemberMode.existingPatient)
                      _buildExistingPatientForm(theme)
                    else
                      _buildNewPatientForm(theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExistingPatientForm(ThemeData theme) {
    return Form(
      key: _existingFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HintCard(
            title: 'Patient deja existant',
            body:
                'Recherchez un patient global par patient code ou barcode. Le nom et la date de naissance seront repris depuis la base.',
          ),
          const SizedBox(height: 16),
          _RoleSelector(
            value: _existingRelationshipRole,
            onChanged: (value) => setState(() => _existingRelationshipRole = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Patient code',
            child: TextFormField(
              controller: _existingPatientCodeController,
              decoration: const InputDecoration(
                hintText: 'code patient / CIN si utilise comme patient_code',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Code-barres / QR code',
            child: TextFormField(
              controller: _existingBarcodeController,
              decoration: const InputDecoration(
                hintText: 'saisie manuelle',
                suffixIcon: Icon(Icons.qr_code_scanner),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scanner camera: TODO. Saisie manuelle active pour le MVP.',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6E5B7A)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSearching ? null : _searchExistingPatient,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Rechercher patient'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_foundPatient != null)
            _PatientFoundCard(patient: _foundPatient!)
          else
            const _HintCard(
              title: 'Aucun resultat',
              body:
                  'Si aucun patient n est trouve, basculez sur "Nouveau patient".',
            ),
          const SizedBox(height: 16),
          _BloodTypeField(
            value: _existingBloodType,
            onChanged: (value) => setState(() => _existingBloodType = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Poids (optionnel)',
            child: TextFormField(
              controller: _existingWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'ex: 72', suffixText: 'kg'),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _isSubmitting || _foundPatient == null ? null : _linkExistingPatient,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link),
              label: const Text('Lier ce patient a la famille'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPatientForm(ThemeData theme) {
    return Form(
      key: _newPatientFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HintCard(
            title: 'Nouveau patient',
            body:
                'Le membre famille sera cree, puis un patient global sera ajoute dans HealthSync et lie automatiquement.',
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Nom complet',
            child: TextFormField(
              controller: _newFullNameController,
              decoration: const InputDecoration(hintText: 'ex: Sarah Benali'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nom requis';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          _RoleSelector(
            value: _newRelationshipRole,
            onChanged: (value) => setState(() => _newRelationshipRole = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Date de naissance',
            child: TextFormField(
              controller: _newBirthDateController,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icon(Icons.cake),
              ),
              onTap: () => _pickDate(_newBirthDateController),
            ),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Sexe',
            child: DropdownButtonFormField<String>(
              initialValue: _newGender,
              decoration: const InputDecoration(hintText: 'Selectionner'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Homme')),
                DropdownMenuItem(value: 'female', child: Text('Femme')),
                DropdownMenuItem(value: 'other', child: Text('Autre')),
              ],
              onChanged: (value) => setState(() => _newGender = value),
            ),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Telephone',
            child: TextFormField(
              controller: _newPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'optionnel'),
            ),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Email',
            child: TextFormField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'optionnel'),
            ),
          ),
          const SizedBox(height: 16),
          _BloodTypeField(
            value: _newBloodType,
            onChanged: (value) => setState(() => _newBloodType = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Poids (optionnel)',
            child: TextFormField(
              controller: _newWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'ex: 65', suffixText: 'kg'),
            ),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'CIN / carte nationale (optionnelle)',
            child: TextFormField(
              controller: _newCinController,
              decoration: const InputDecoration(hintText: 'laisser vide si inconnu'),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _createNewPatient,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: const Text('Creer membre + patient'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.mode,
    required this.onChanged,
  });

  final _AddMemberMode mode;
  final ValueChanged<_AddMemberMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_AddMemberMode>(
      segments: const [
        ButtonSegment(
          value: _AddMemberMode.existingPatient,
          label: Text('Patient deja existant'),
          icon: Icon(Icons.link),
        ),
        ButtonSegment(
          value: _AddMemberMode.newPatient,
          label: Text('Nouveau patient'),
          icon: Icon(Icons.person_add_alt_1),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1DCE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PatientFoundCard extends StatelessWidget {
  const _PatientFoundCard({required this.patient});

  final HealthsyncPatientSummary patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            patient.fullName,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _MetaLine(label: 'CIN', value: patient.patientCode ?? '-'),
          _MetaLine(label: 'Barcode', value: patient.barcodeValue ?? '-'),
          _MetaLine(label: 'Naissance', value: patient.dateOfBirth ?? '-'),
          _MetaLine(label: 'Telephone', value: patient.phone ?? '-'),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }
}

class _BloodTypeField extends StatelessWidget {
  const _BloodTypeField({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _InputField(
      label: 'Groupe sanguin',
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(hintText: 'Selectionner'),
        items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E5B7A),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1DCE8)),
          ),
          child: Theme(
            data: theme.copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const roles = [
      _RoleItem('pere', 'Pere', Icons.man),
      _RoleItem('mere', 'Mere', Icons.woman),
      _RoleItem('enfant', 'Enfant', Icons.child_care),
      _RoleItem('grand_parent', 'Grand-parent', Icons.elderly),
      _RoleItem('autre', 'Autre', Icons.group),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relation familiale',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E5B7A),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: roles.map((role) {
            final isActive = value == role.value;
            return ChoiceChip(
              label: Text(role.label),
              avatar: Icon(
                role.icon,
                size: 18,
                color: isActive ? Colors.white : theme.colorScheme.primary,
              ),
              selected: isActive,
              onSelected: (_) => onChanged(role.value),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isActive
                    ? theme.colorScheme.primary
                    : const Color(0xFFE1DCE8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoleItem {
  const _RoleItem(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

DateTime? _parseDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

double? _parseWeight(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return double.tryParse(value);
}

String? _asText(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

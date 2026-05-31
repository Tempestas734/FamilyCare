import 'package:supabase_flutter/supabase_flutter.dart';

class HealthsyncFamilyContext {
  const HealthsyncFamilyContext({
    required this.familyId,
    required this.familyMemberId,
    required this.familyName,
    required this.familyCode,
  });

  final String familyId;
  final String familyMemberId;
  final String familyName;
  final String? familyCode;
}

class HealthsyncFamilyMember {
  const HealthsyncFamilyMember({
    required this.id,
    required this.fullName,
    required this.relationshipRole,
    this.userId,
    this.birthDate,
    this.bloodType,
    this.weightKg,
    this.inviteEmail,
    this.isAdmin = false,
  });

  final String id;
  final String fullName;
  final String relationshipRole;
  final String? userId;
  final String? birthDate;
  final String? bloodType;
  final double? weightKg;
  final String? inviteEmail;
  final bool isAdmin;

  factory HealthsyncFamilyMember.fromMap(Map<String, dynamic> map) {
    return HealthsyncFamilyMember(
      id: _asText(map['id']) ?? '',
      fullName: _asText(map['full_name']) ?? 'Membre',
      relationshipRole: _asText(map['relationship_role']) ?? 'autre',
      userId: _asText(map['user_id']),
      birthDate: _asText(map['birth_date']),
      bloodType: _asText(map['blood_type']),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      inviteEmail: _asText(map['invite_email']),
      isAdmin: map['is_admin'] == true,
    );
  }
}

class HealthsyncPatientSummary {
  const HealthsyncPatientSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    this.bloodGroup,
    this.patientCode,
    this.barcodeValue,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? email;
  final String? bloodGroup;
  final String? patientCode;
  final String? barcodeValue;

  String get fullName {
    final parts = [firstName.trim(), lastName.trim()]
        .where((part) => part.isNotEmpty && part != '-')
        .toList();
    return parts.isEmpty ? 'Patient' : parts.join(' ');
  }

  factory HealthsyncPatientSummary.fromMap(Map<String, dynamic> map) {
    return HealthsyncPatientSummary(
      id: _asText(map['id']) ?? '',
      firstName: _asText(map['first_name']) ?? 'Patient',
      lastName: _asText(map['last_name']) ?? '-',
      dateOfBirth: _asText(map['date_of_birth']),
      gender: _asText(map['gender']),
      phone: _asText(map['phone']),
      email: _asText(map['email']),
      bloodGroup: _asText(map['blood_group']),
      patientCode: _asText(map['patient_code']),
      barcodeValue: _asText(map['barcode_value']),
    );
  }
}

class DoctorEstablishment {
  const DoctorEstablishment({
    required this.linkId,
    required this.etablissementId,
    required this.nom,
    required this.typeEtablissement,
    required this.ville,
    required this.adresse,
    this.latitude,
    this.longitude,
    this.telephone,
    this.email,
    this.role = 'medecin',
    this.actif = true,
    this.canIssuePrescriptions = true,
    this.canSignDocuments = true,
  });

  final String linkId;
  final String etablissementId;
  final String nom;
  final String typeEtablissement;
  final String ville;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final String? telephone;
  final String? email;
  final String role;
  final bool actif;
  final bool canIssuePrescriptions;
  final bool canSignDocuments;

  String get displayLabel {
    final parts = <String>[
      if (nom.trim().isNotEmpty) nom.trim(),
      if (ville.trim().isNotEmpty) ville.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(' - ');
    return 'Etablissement';
  }

  factory DoctorEstablishment.fromMap(Map<String, dynamic> map) {
    final etablissement = _extractMap(map['etablissement']) ??
        _extractMap(map['etablissements']) ??
        const <String, dynamic>{};
    return DoctorEstablishment(
      linkId: _asText(map['id']) ?? '',
      etablissementId: _asText(map['etablissement_id']) ??
          _asText(etablissement['id']) ??
          '',
      nom: _asText(etablissement['nom']) ?? 'Etablissement',
      typeEtablissement: _asText(etablissement['type_etablissement']) ?? '',
      ville: _asText(etablissement['ville']) ?? '',
      adresse: _asText(etablissement['adresse']) ?? '',
      latitude: (etablissement['latitude'] as num?)?.toDouble(),
      longitude: (etablissement['longitude'] as num?)?.toDouble(),
      telephone: _asText(etablissement['telephone']),
      email: _asText(etablissement['email']),
      role: _asText(map['role']) ?? 'medecin',
      actif: map['actif'] != false && etablissement['actif'] != false,
      canIssuePrescriptions: map['can_issue_prescriptions'] != false,
      canSignDocuments: map['can_sign_documents'] != false,
    );
  }
}

class HealthsyncDoctor {
  const HealthsyncDoctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.specialty,
    this.photoUrl,
    this.bio,
    this.langues = const [],
    this.note,
    this.numeroOrdre,
    this.signatureName,
    this.userId,
    this.establishments = const [],
    this.userIsActive = true,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? email;
  final String? phone;
  final String specialty;
  final String? photoUrl;
  final String? bio;
  final List<String> langues;
  final double? note;
  final String? numeroOrdre;
  final String? signatureName;
  final String? userId;
  final List<DoctorEstablishment> establishments;
  final bool userIsActive;

  DoctorEstablishment? get primaryEstablishment =>
      establishments.isEmpty ? null : establishments.first;

  factory HealthsyncDoctor.fromMap(Map<String, dynamic> map) {
    final user = _extractMap(map['users']);
    final fallbackName = _splitDoctorFallbackName(_asText(map['signature_name']));
    final firstName = _asText(user?['first_name']) ?? fallbackName.$1;
    final lastName = _asText(user?['last_name']) ?? fallbackName.$2;
    final fullNameParts = [firstName, lastName]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    final fullName = fullNameParts.isNotEmpty
        ? fullNameParts.join(' ')
        : (_asText(map['signature_name']) ?? 'Medecin');
    final rawLinks = map['medecin_etablissements'];
    final links = <DoctorEstablishment>[];
    if (rawLinks is List) {
      for (final item in rawLinks) {
        final row = _extractMap(item);
        if (row == null) continue;
        final establishment = DoctorEstablishment.fromMap(row);
        if (!establishment.actif || establishment.etablissementId.isEmpty) {
          continue;
        }
        links.add(establishment);
      }
    } else {
      final row = _extractMap(rawLinks);
      if (row != null) {
        final establishment = DoctorEstablishment.fromMap(row);
        if (establishment.actif && establishment.etablissementId.isNotEmpty) {
          links.add(establishment);
        }
      }
    }

    links.sort((a, b) {
      if (a.actif == b.actif) return a.nom.compareTo(b.nom);
      return a.actif ? -1 : 1;
    });

    return HealthsyncDoctor(
      id: _asText(map['id']) ?? '',
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: _asText(user?['email']),
      phone: _asText(user?['phone']),
      specialty: _asText(map['specialite']) ?? 'Medecin',
      photoUrl: _asText(map['photo_url']),
      bio: _asText(map['bio']),
      langues: map['langues'] is List
          ? (map['langues'] as List).map((item) => item.toString()).toList()
          : const [],
      note: (map['note'] as num?)?.toDouble(),
      numeroOrdre: _asText(map['numero_ordre']),
      signatureName: _asText(map['signature_name']),
      userId: _asText(map['user_id']),
      establishments: links,
      userIsActive: user == null ? true : user['is_active'] != false,
    );
  }
}

class HealthsyncDoctorLink {
  const HealthsyncDoctorLink({
    required this.id,
    required this.familyId,
    required this.medecinId,
    required this.doctor,
  });

  final String id;
  final String familyId;
  final String medecinId;
  final HealthsyncDoctor doctor;

  factory HealthsyncDoctorLink.fromMap(Map<String, dynamic> map) {
    return HealthsyncDoctorLink(
      id: _asText(map['id']) ?? '',
      familyId: _asText(map['family_id']) ?? '',
      medecinId: _asText(map['medecin_id']) ?? '',
      doctor: HealthsyncDoctor.fromMap(
        _extractMap(map['medecins']) ?? const <String, dynamic>{},
      ),
    );
  }
}

class DoctorAvailabilityInterval {
  const DoctorAvailabilityInterval({
    required this.id,
    required this.order,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final int order;
  final String startTime;
  final String endTime;

  factory DoctorAvailabilityInterval.fromMap(Map<String, dynamic> map) {
    return DoctorAvailabilityInterval(
      id: _asText(map['id']) ?? '',
      order: (map['ordre'] as num?)?.toInt() ?? 0,
      startTime: _asText(map['heure_debut']) ?? '00:00:00',
      endTime: _asText(map['heure_fin']) ?? '00:00:00',
    );
  }
}

class DoctorAvailabilityDay {
  const DoctorAvailabilityDay({
    required this.id,
    required this.weekday,
    required this.isActive,
    required this.notes,
    required this.intervals,
  });

  final String id;
  final int weekday;
  final bool isActive;
  final String? notes;
  final List<DoctorAvailabilityInterval> intervals;

  factory DoctorAvailabilityDay.fromMap(Map<String, dynamic> map) {
    final rawIntervals = map['medecin_horaire_intervalles'];
    final intervals = <DoctorAvailabilityInterval>[];
    if (rawIntervals is List) {
      for (final item in rawIntervals) {
        final row = _extractMap(item);
        if (row == null) continue;
        intervals.add(DoctorAvailabilityInterval.fromMap(row));
      }
    }
    intervals.sort((a, b) => a.order.compareTo(b.order));
    return DoctorAvailabilityDay(
      id: _asText(map['id']) ?? '',
      weekday: (map['weekday'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] == true,
      notes: _asText(map['notes']),
      intervals: intervals,
    );
  }
}

class DoctorUnavailability {
  const DoctorUnavailability({
    required this.id,
    required this.type,
    this.reason,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.allDay,
    this.notes,
  });

  final String id;
  final String type;
  final String? reason;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final bool allDay;
  final String? notes;

  factory DoctorUnavailability.fromMap(Map<String, dynamic> map) {
    final startDate = DateTime.tryParse(_asText(map['date_debut']) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final endDate = DateTime.tryParse(_asText(map['date_fin']) ?? '') ??
        startDate;
    return DoctorUnavailability(
      id: _asText(map['id']) ?? '',
      type: _asText(map['type_indisponibilite']) ?? 'indisponible',
      reason: _asText(map['motif']),
      startDate: startDate,
      endDate: endDate,
      startTime: _asText(map['heure_debut']),
      endTime: _asText(map['heure_fin']),
      allDay: map['toute_la_journee'] == true,
      notes: _asText(map['notes']),
    );
  }
}

class HealthsyncAppointment {
  const HealthsyncAppointment({
    required this.id,
    required this.patientId,
    required this.medecinId,
    required this.scheduledAt,
    required this.status,
    required this.reason,
    required this.notes,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    this.photoUrl,
  });

  final String id;
  final String patientId;
  final String medecinId;
  final DateTime scheduledAt;
  final String status;
  final String? reason;
  final String? notes;
  final String patientName;
  final String doctorName;
  final String specialty;
  final String? photoUrl;

  factory HealthsyncAppointment.fromMap(Map<String, dynamic> map) {
    final patient = _extractMap(map['patients']);
    final medecin = _extractMap(map['medecins']);
    final doctorUser = _extractMap(medecin?['users']);
    final patientName = [
      _asText(patient?['first_name']),
      _asText(patient?['last_name']),
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    final doctorName = [
      _asText(doctorUser?['first_name']),
      _asText(doctorUser?['last_name']),
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return HealthsyncAppointment(
      id: _asText(map['id']) ?? '',
      patientId: _asText(map['patient_id']) ?? '',
      medecinId: _asText(map['medecin_id']) ?? '',
      scheduledAt: _parseDateTime(map['scheduled_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _asText(map['status']) ?? 'pending',
      reason: _asText(map['reason']),
      notes: _asText(map['notes']),
      patientName: patientName.isEmpty ? 'Patient' : patientName,
      doctorName: doctorName.isEmpty ? 'Dr.' : 'Dr. $doctorName',
      specialty: _asText(medecin?['specialite']) ?? 'Medecin',
      photoUrl: _asText(medecin?['photo_url']),
    );
  }
}

class HealthsyncService {
  HealthsyncService(this.client);

  final SupabaseClient client;

  Future<HealthsyncFamilyContext?> getCurrentFamilyContext() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await client
          .from('family_members')
          .select('id, family_id, families!inner(id, family_name, family_code)')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      if (row != null) {
        final family = _extractMap(row['families']);
        final familyId = _asText(row['family_id']);
        final familyMemberId = _asText(row['id']);
        if (family != null && familyId != null && familyMemberId != null) {
          return HealthsyncFamilyContext(
            familyId: familyId,
            familyMemberId: familyMemberId,
            familyName: _asText(family['family_name']) ?? 'Famille',
            familyCode: _asText(family['family_code']),
          );
        }
      }
    } catch (_) {
      // Fallback below for creator-owned families when family_members lookup fails.
    }

    final family = await client
        .from('families')
        .select('id, family_name, family_code')
        .eq('created_by_user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (family == null) {
      return null;
    }

    final familyId = _asText(family['id']);
    if (familyId == null) {
      return null;
    }

    String familyMemberId = '';
    try {
      final creatorMember = await client
          .from('family_members')
          .select('id')
          .eq('family_id', familyId)
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();
      familyMemberId = _asText(creatorMember?['id']) ?? '';
    } catch (_) {
      familyMemberId = '';
    }

    return HealthsyncFamilyContext(
      familyId: familyId,
      familyMemberId: familyMemberId,
      familyName: _asText(family['family_name']) ?? 'Famille',
      familyCode: _asText(family['family_code']),
    );
  }

  Future<List<HealthsyncFamilyMember>> getFamilyMembers(String familyId) async {
    final data = await client
        .from('family_members')
        .select(
          'id, family_id, full_name, relationship_role, user_id, is_admin, birth_date, blood_type, weight_kg, invite_email',
        )
        .eq('family_id', familyId)
        .order('created_at');

    return (data as List<dynamic>)
        .whereType<Map>()
        .map((row) => HealthsyncFamilyMember.fromMap(Map<String, dynamic>.from(row)))
        .where((member) => member.id.isNotEmpty)
        .toList();
  }

  Future<List<String>> getPatientIdsForFamilyMember(String familyMemberId) async {
    final data = await client
        .from('family_patients')
        .select('patient_id')
        .eq('family_member_id', familyMemberId);
    return (data as List<dynamic>)
        .whereType<Map>()
        .map((row) => _asText(row['patient_id']))
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Future<HealthsyncPatientSummary?> findExistingPatient({
    String? patientId,
    String? cin,
    String? barcodeValue,
  }) async {
    final normalizedPatientId = _asText(patientId);
    final normalizedCin = _normalizePatientCode(cin);
    final normalizedBarcode = _asText(barcodeValue);
    if (normalizedPatientId == null &&
        normalizedCin == null &&
        normalizedBarcode == null) {
      return null;
    }

    final query = client.from('patients').select('''
      id,
      first_name,
      last_name,
      date_of_birth,
      gender,
      phone,
      email,
      blood_group,
      patient_code,
      barcode_value
    ''');

    final result = normalizedPatientId != null
        ? await query.eq('id', normalizedPatientId).maybeSingle()
        : normalizedCin != null
            ? await query.eq('patient_code', normalizedCin).maybeSingle()
            : await query.eq('barcode_value', normalizedBarcode!).maybeSingle();

    if (result == null) {
      return null;
    }
    return HealthsyncPatientSummary.fromMap(Map<String, dynamic>.from(result));
  }

  Future<String> createFamilyMember({
    required String familyId,
    required String fullName,
    required String relationshipRole,
    DateTime? birthDate,
    String? bloodType,
    double? weightKg,
  }) async {
    final inserted = await client
        .from('family_members')
        .insert({
          'family_id': familyId,
          'user_id': null,
          'full_name': fullName.trim(),
          'relationship_role': relationshipRole.trim(),
          'birth_date': birthDate?.toIso8601String().split('T').first,
          'blood_type': _asText(bloodType),
          'weight_kg': weightKg,
          'is_admin': false,
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<Map<String, dynamic>> createPatientFromFamilyMember({
    required String fullName,
    DateTime? birthDate,
    String? gender,
    String? phone,
    String? email,
    String? bloodGroup,
    String? cin,
  }) async {
    final nameParts = _splitFullName(fullName);
    final inserted = await client
        .from('patients')
        .insert({
          'first_name': nameParts.$1,
          'last_name': nameParts.$2,
          'date_of_birth': birthDate?.toIso8601String().split('T').first,
          'gender': _asText(gender),
          'phone': _asText(phone),
          'email': _asText(email),
          'blood_group': _asText(bloodGroup),
          'patient_code': _normalizePatientCode(cin),
        })
        .select('''
          id,
          first_name,
          last_name,
          date_of_birth,
          gender,
          phone,
          email,
          blood_group,
          patient_code,
          barcode_value
        ''')
        .single();

    return Map<String, dynamic>.from(inserted);
  }

  Future<void> linkPatientToFamilyMember({
    required String familyId,
    required String familyMemberId,
    required String patientId,
    String? relationship,
  }) async {
    final existing = await client
        .from('family_patients')
        .select('id, family_member_id, patient_id')
        .eq('family_id', familyId);

    for (final raw in existing as List<dynamic>) {
      final row = _extractMap(raw);
      if (row == null) continue;
      final linkedMemberId = _asText(row['family_member_id']);
      final linkedPatientId = _asText(row['patient_id']);
      if (linkedMemberId == familyMemberId && linkedPatientId == patientId) {
        throw StateError('Ce patient est deja lie a ce membre de famille');
      }
    }

    final existingMemberLink = existing
        .map(_extractMap)
        .whereType<Map<String, dynamic>>()
        .firstWhere(
          (row) => _asText(row['family_member_id']) == familyMemberId,
          orElse: () => const <String, dynamic>{},
        );

    final payload = {
      'family_id': familyId,
      'family_member_id': familyMemberId,
      'patient_id': patientId,
      'relationship': _asText(relationship) ?? 'family_member',
      'is_primary_caregiver': false,
      'can_view_profile': true,
      'can_view_appointments': true,
      'can_view_prescriptions': true,
      'can_view_documents': true,
      'can_receive_notifications': true,
    };

    final existingLinkId = _asText(existingMemberLink['id']);
    if (existingLinkId != null) {
      await client.from('family_patients').update(payload).eq('id', existingLinkId);
      return;
    }

    await client.from('family_patients').insert(payload);
  }

  Future<void> addFamilyMemberWithExistingPatient({
    required String familyId,
    String? fullName,
    required String relationshipRole,
    required String patientId,
    DateTime? birthDate,
    String? bloodType,
    double? weightKg,
  }) async {
    final existingPatient = await findExistingPatient(patientId: patientId);
    if (existingPatient == null) {
      throw StateError('Patient introuvable');
    }

    final resolvedFullName = _asText(fullName) ?? existingPatient.fullName;
    final resolvedBirthDate =
        birthDate ?? _parseDateOnly(existingPatient.dateOfBirth);
    final resolvedBloodType = _asText(bloodType) ?? existingPatient.bloodGroup;

    final familyMemberId = await createFamilyMember(
      familyId: familyId,
      fullName: resolvedFullName,
      relationshipRole: relationshipRole,
      birthDate: resolvedBirthDate,
      bloodType: resolvedBloodType,
      weightKg: weightKg,
    );

    await linkPatientToFamilyMember(
      familyId: familyId,
      familyMemberId: familyMemberId,
      patientId: patientId,
      relationship: relationshipRole,
    );
  }

  Future<Map<String, dynamic>> addFamilyMemberWithNewPatient({
    required String familyId,
    required String fullName,
    required String relationshipRole,
    DateTime? birthDate,
    String? gender,
    String? phone,
    String? email,
    String? bloodType,
    double? weightKg,
    String? cin,
  }) async {
    final familyMemberId = await createFamilyMember(
      familyId: familyId,
      fullName: fullName,
      relationshipRole: relationshipRole,
      birthDate: birthDate,
      bloodType: bloodType,
      weightKg: weightKg,
    );

    try {
      final patient = await createPatientFromFamilyMember(
        fullName: fullName,
        birthDate: birthDate,
        gender: gender,
        phone: phone,
        email: email,
        bloodGroup: bloodType,
        cin: cin,
      );

      final patientId = _asText(patient['id']);
      if (patientId == null) {
        throw StateError('Patient cree sans identifiant');
      }

      await linkPatientToFamilyMember(
        familyId: familyId,
        familyMemberId: familyMemberId,
        patientId: patientId,
        relationship: relationshipRole,
      );

      return patient;
    } on PostgrestException catch (error) {
      if (_looksLikePatientCodeConflict(error)) {
        throw StateError(
          'Cette CIN existe deja. Utilisez le mode "Patient deja existant".',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, String>> getFamilyPatientLinks(String familyId) async {
    final data = await client
        .from('family_patients')
        .select('patient_id, family_member_id')
        .eq('family_id', familyId);

    final links = <String, String>{};
    for (final raw in data as List<dynamic>) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      final patientId = _asText(row['patient_id']);
      final familyMemberId = _asText(row['family_member_id']);
      if (patientId == null || familyMemberId == null) continue;
      links[patientId] = familyMemberId;
    }
    return links;
  }

  Future<String> getOrCreatePatientForFamilyMember({
    required String familyId,
    required String familyMemberId,
  }) async {
    final existingLink = await client
        .from('family_patients')
        .select('patient_id')
        .eq('family_member_id', familyMemberId)
        .limit(1)
        .maybeSingle();

    final existingPatientId = _asText(existingLink?['patient_id']);
    if (existingPatientId != null && existingPatientId.isNotEmpty) {
      return existingPatientId;
    }

    final member = await client
        .from('family_members')
        .select('id, full_name, birth_date, blood_type')
        .eq('id', familyMemberId)
        .single();

    final fullName = (_asText(member['full_name']) ?? 'Patient').trim();
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final firstName = parts.isNotEmpty ? parts.first : 'Patient';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '-';

    final patient = await client
        .from('patients')
        .insert({
          'first_name': firstName,
          'last_name': lastName,
          'date_of_birth': member['birth_date'],
          'blood_group': member['blood_type'],
        })
        .select('id')
        .single();

    final patientId = patient['id'] as String;

    await client.from('family_patients').insert({
      'family_id': familyId,
      'family_member_id': familyMemberId,
      'patient_id': patientId,
      'relationship': 'family_member',
      'is_primary_caregiver': false,
      'can_view_profile': true,
      'can_view_appointments': true,
      'can_view_prescriptions': true,
      'can_view_documents': true,
      'can_receive_notifications': true,
    });

    return patientId;
  }

  Future<List<HealthsyncDoctor>> getDoctors() async {
    return _loadDoctors();
  }

  Future<HealthsyncDoctor?> getDoctorById(String doctorId) async {
    final doctors = await _loadDoctors(ids: [doctorId]);
    return doctors.isEmpty ? null : doctors.first;
  }

  Future<List<HealthsyncDoctorLink>> getFamilyDoctors(String familyId) async {
    final data = await client
        .from('family_medecins')
        .select('id, family_id, medecin_id')
        .eq('family_id', familyId)
        .order('created_at', ascending: false);
    final rows = (data as List<dynamic>)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    final doctorIds = rows
        .map((row) => _asText(row['medecin_id']))
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final doctors = await _loadDoctors(ids: doctorIds);
    final doctorsById = {for (final doctor in doctors) doctor.id: doctor};
    return rows
        .map((row) {
          final medecinId = _asText(row['medecin_id']) ?? '';
          final doctor = doctorsById[medecinId];
          if (doctor == null) return null;
          return HealthsyncDoctorLink(
            id: _asText(row['id']) ?? '',
            familyId: _asText(row['family_id']) ?? '',
            medecinId: medecinId,
            doctor: doctor,
          );
        })
        .whereType<HealthsyncDoctorLink>()
        .where((link) => link.id.isNotEmpty)
        .toList();
  }

  Future<String> ensureFamilyDoctorLink({
    required String familyId,
    required String medecinId,
  }) async {
    final existing = await client
        .from('family_medecins')
        .select('id')
        .eq('family_id', familyId)
        .eq('medecin_id', medecinId)
        .limit(1)
        .maybeSingle();

    final existingId = _asText(existing?['id']);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final inserted = await client
        .from('family_medecins')
        .insert({
          'family_id': familyId,
          'medecin_id': medecinId,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<List<DoctorAvailabilityDay>> getDoctorAvailability({
    required String medecinId,
    required String etablissementId,
  }) async {
    final rows = await client
        .from('medecin_horaires_semaine')
        .select('''
          id,
          weekday,
          is_active,
          notes,
          medecin_horaire_intervalles (
            id,
            ordre,
            heure_debut,
            heure_fin
          )
        ''')
        .eq('medecin_id', medecinId)
        .eq('etablissement_id', etablissementId)
        .eq('is_active', true)
        .order('weekday');

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((row) => DoctorAvailabilityDay.fromMap(Map<String, dynamic>.from(row)))
        .where((day) => day.isActive && day.intervals.isNotEmpty)
        .toList();
  }

  Future<List<DoctorUnavailability>> getDoctorUnavailabilities({
    required String medecinId,
    required String etablissementId,
    required DateTime from,
    required DateTime to,
  }) async {
    final fromDate = _dateOnlyString(from);
    final toDate = _dateOnlyString(to);
    final rows = await client
        .from('medecin_indisponibilites')
        .select('''
          id,
          type_indisponibilite,
          motif,
          date_debut,
          date_fin,
          heure_debut,
          heure_fin,
          toute_la_journee,
          notes
        ''')
        .eq('medecin_id', medecinId)
        .eq('etablissement_id', etablissementId)
        .lte('date_debut', toDate)
        .gte('date_fin', fromDate);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((row) => DoctorUnavailability.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<DateTime>> getTakenAppointmentSlots({
    required String medecinId,
    required String etablissementId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await client
        .from('appointments')
        .select('scheduled_at, scheduled_end_at, duration_minutes, status')
        .eq('medecin_id', medecinId)
        .eq('etablissement_id', etablissementId)
        .gte('scheduled_at', from.toIso8601String())
        .lt('scheduled_at', to.toIso8601String())
        .inFilter('status', ['pending', 'confirmed', 'follow_up_planned']);

    final slots = <DateTime>[];
    for (final raw in rows as List<dynamic>) {
      final row = _extractMap(raw);
      final scheduledAt = _parseDateTime(row?['scheduled_at']);
      if (scheduledAt != null) {
        slots.add(scheduledAt.toLocal());
      }
    }
    return slots;
  }

  Future<bool> isSlotAvailable({
    required String medecinId,
    required String etablissementId,
    required DateTime slot,
    int durationMinutes = 15,
  }) async {
    final from = DateTime(slot.year, slot.month, slot.day);
    final to = from.add(const Duration(days: 14));
    final availability = await getDoctorAvailability(
      medecinId: medecinId,
      etablissementId: etablissementId,
    );
    final unavailabilities = await getDoctorUnavailabilities(
      medecinId: medecinId,
      etablissementId: etablissementId,
      from: from,
      to: to,
    );
    final takenSlots = await getTakenAppointmentSlots(
      medecinId: medecinId,
      etablissementId: etablissementId,
      from: from,
      to: to,
    );
    return isSlotAvailableFromData(
      slot: slot,
      availability: availability,
      unavailabilities: unavailabilities,
      takenSlots: takenSlots,
      durationMinutes: durationMinutes,
    );
  }

  bool isSlotAvailableFromData({
    required DateTime slot,
    required List<DoctorAvailabilityDay> availability,
    required List<DoctorUnavailability> unavailabilities,
    required List<DateTime> takenSlots,
    int durationMinutes = 15,
  }) {
    final targetWeekday = _dbWeekday(slot);
    final dayAvailability = availability.where((day) => day.weekday == targetWeekday);
    if (dayAvailability.isEmpty) return false;

    final slotMinutes = slot.hour * 60 + slot.minute;
    final slotEndMinutes = slotMinutes + durationMinutes;
    var inAnyInterval = false;
    for (final day in dayAvailability) {
      for (final interval in day.intervals) {
        final startMinutes = _minutesFromTimeString(interval.startTime);
        final endMinutes = _minutesFromTimeString(interval.endTime);
        if (slotMinutes >= startMinutes && slotEndMinutes <= endMinutes) {
          inAnyInterval = true;
          break;
        }
      }
      if (inAnyInterval) break;
    }
    if (!inAnyInterval) return false;

    final slotDate = DateTime(slot.year, slot.month, slot.day);
    for (final unavailability in unavailabilities) {
      final startDate = DateTime(
        unavailability.startDate.year,
        unavailability.startDate.month,
        unavailability.startDate.day,
      );
      final endDate = DateTime(
        unavailability.endDate.year,
        unavailability.endDate.month,
        unavailability.endDate.day,
      );
      if (slotDate.isBefore(startDate) || slotDate.isAfter(endDate)) continue;
      if (unavailability.allDay) return false;

      final unavailabilityStart = _minutesFromTimeString(unavailability.startTime);
      final unavailabilityEnd = _minutesFromTimeString(unavailability.endTime);
      final overlapsUnavailability = slotMinutes < unavailabilityEnd &&
          slotEndMinutes > unavailabilityStart;
      if (overlapsUnavailability) return false;
    }

    final slotKey = _slotKey(slot.toLocal());
    final takenKeys = takenSlots.map((item) => _slotKey(item.toLocal())).toSet();
    return !takenKeys.contains(slotKey);
  }

  List<DateTime> buildAvailableSlots({
    required List<DoctorAvailabilityDay> availability,
    required List<DoctorUnavailability> unavailabilities,
    required List<DateTime> takenSlots,
    required DateTime from,
    int durationMinutes = 15,
    int numberOfDays = 14,
  }) {
    final slots = <DateTime>[];
    for (var dayOffset = 0; dayOffset < numberOfDays; dayOffset++) {
      final date = DateTime(from.year, from.month, from.day).add(Duration(days: dayOffset));
      final targetWeekday = _dbWeekday(date);
      final dayAvailability = availability.where((day) => day.weekday == targetWeekday);
      for (final item in dayAvailability) {
        for (final interval in item.intervals) {
          final startMinutes = _minutesFromTimeString(interval.startTime);
          final endMinutes = _minutesFromTimeString(interval.endTime);
          for (var cursor = startMinutes;
              cursor + durationMinutes <= endMinutes;
              cursor += durationMinutes) {
            final slot = DateTime(
              date.year,
              date.month,
              date.day,
              cursor ~/ 60,
              cursor % 60,
            );
            if (!slot.isAfter(DateTime.now())) continue;
            if (isSlotAvailableFromData(
              slot: slot,
              availability: availability,
              unavailabilities: unavailabilities,
              takenSlots: takenSlots,
              durationMinutes: durationMinutes,
            )) {
              slots.add(slot);
            }
          }
        }
      }
    }
    slots.sort();
    return slots;
  }

  Future<void> createFamilyAppointment({
    required String familyId,
    required String familyMemberId,
    required String medecinId,
    required String etablissementId,
    required DateTime scheduledAt,
    int durationMinutes = 15,
    String? reason,
    String? notes,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Utilisateur non connecte');
    }

    final isAvailable = await isSlotAvailable(
      medecinId: medecinId,
      etablissementId: etablissementId,
      slot: scheduledAt,
      durationMinutes: durationMinutes,
    );
    if (!isAvailable) {
      throw StateError('Ce creneau n\'est plus disponible');
    }

    final patientId = await getOrCreatePatientForFamilyMember(
      familyId: familyId,
      familyMemberId: familyMemberId,
    );

    await client.from('appointments').insert({
      'patient_id': patientId,
      'medecin_id': medecinId,
      'etablissement_id': etablissementId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'status': 'pending',
      'reason': reason,
      'notes': notes,
      'source': 'mobile_app',
      'requested_by_type': 'family',
      'requested_by_id': familyId,
      'created_by_user_id': userId,
    });
  }

  Future<List<HealthsyncAppointment>> getFamilyAppointments(String familyId) async {
    final data = await client
        .from('appointments')
        .select(
          'id, patient_id, medecin_id, scheduled_at, duration_minutes, status, reason, notes, patients(first_name, last_name), medecins(id, specialite, photo_url, users(first_name, last_name))',
        )
        .eq('requested_by_type', 'family')
        .eq('requested_by_id', familyId)
        .order('scheduled_at');

    return (data as List<dynamic>)
        .whereType<Map>()
        .map((row) => HealthsyncAppointment.fromMap(Map<String, dynamic>.from(row)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<HealthsyncAppointment>> getAppointmentsForFamilyMember({
    required String familyId,
    required String familyMemberId,
  }) async {
    final patientIds = await getPatientIdsForFamilyMember(familyMemberId);
    if (patientIds.isEmpty) return const [];

    final data = await client
        .from('appointments')
        .select(
          'id, patient_id, medecin_id, scheduled_at, duration_minutes, status, reason, notes, patients(first_name, last_name), medecins(id, specialite, photo_url, users(first_name, last_name))',
        )
        .eq('requested_by_type', 'family')
        .eq('requested_by_id', familyId)
        .inFilter('patient_id', patientIds)
        .order('scheduled_at');

    return (data as List<dynamic>)
        .whereType<Map>()
        .map((row) => HealthsyncAppointment.fromMap(Map<String, dynamic>.from(row)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<HealthsyncDoctor>> _loadDoctors({List<String>? ids}) async {
    final doctorsQuery = client.from('medecins').select('''
      id,
      specialite,
      photo_url,
      bio,
      langues,
      note,
      numero_ordre,
      signature_name,
      user_id,
      updated_at
    ''');
    final doctorsRaw = ids == null || ids.isEmpty
        ? await doctorsQuery.order('updated_at', ascending: false)
        : await doctorsQuery.inFilter('id', ids).order('updated_at', ascending: false);
    final doctorRows = (doctorsRaw as List<dynamic>)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    if (doctorRows.isEmpty) return const [];

    final userIds = doctorRows
        .map((row) => _asText(row['user_id']))
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final usersById = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      final usersRaw = await client
          .from('users')
          .select('id, first_name, last_name, email, phone, is_active')
          .inFilter('id', userIds);
      for (final raw in usersRaw as List<dynamic>) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final id = _asText(row['id']);
        if (id != null) usersById[id] = row;
      }
    }

    final doctorIds = doctorRows
        .map((row) => _asText(row['id']))
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final establishmentsByDoctorId = <String, List<Map<String, dynamic>>>{};
    if (doctorIds.isNotEmpty) {
      final linksRaw = await client.from('medecin_etablissements').select('''
        id,
        medecin_id,
        etablissement_id,
        role,
        actif,
        can_issue_prescriptions,
        can_sign_documents,
        etablissement:etablissement_id (
          id,
          nom,
          type_etablissement,
          pays,
          ville,
          adresse,
          latitude,
          longitude,
          telephone,
          email,
          actif
        )
      ''').inFilter('medecin_id', doctorIds);
      for (final raw in linksRaw as List<dynamic>) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final medecinId = _asText(row['medecin_id']);
        final etablissement = _extractMap(row['etablissement']);
        if (medecinId == null || etablissement == null) continue;
        if (row['actif'] == false || etablissement['actif'] == false) continue;
        establishmentsByDoctorId.putIfAbsent(medecinId, () => []).add(row);
      }
    }

    return doctorRows
        .map((row) {
          final merged = Map<String, dynamic>.from(row);
          final userId = _asText(row['user_id']);
          merged['users'] = userId == null ? null : usersById[userId];
          merged['medecin_etablissements'] =
              establishmentsByDoctorId[_asText(row['id']) ?? ''] ?? const [];
          return HealthsyncDoctor.fromMap(merged);
        })
        .where((doctor) => doctor.id.isNotEmpty)
        .where((doctor) => doctor.userIsActive)
        .where((doctor) => doctor.establishments.isNotEmpty)
        .toList();
  }
}

String _slotKey(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

String _dateOnlyString(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int _dbWeekday(DateTime date) {
  return date.weekday - 1;
}

int _minutesFromTimeString(String? raw) {
  final parts = (raw ?? '00:00:00').split(':');
  if (parts.length < 2) return 0;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return hour * 60 + minute;
}

Map<String, dynamic>? _extractMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is List && raw.isNotEmpty) {
    final first = raw.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  return null;
}

String? _asText(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null' || text == 'undefined') return null;
  return text;
}

DateTime? _parseDateTime(dynamic value) {
  final text = _asText(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

DateTime? _parseDateOnly(String? value) {
  final text = _asText(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

(String, String) _splitDoctorFallbackName(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return ('', '');
  final parts = text.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return ('', '');
  if (parts.length == 1) return (parts.first, '');
  return (parts.first, parts.sublist(1).join(' '));
}

(String, String) _splitFullName(String raw) {
  final parts = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return ('Patient', '-');
  }
  if (parts.length == 1) {
    return (parts.first, '-');
  }
  return (parts.first, parts.sublist(1).join(' '));
}

String? _normalizePatientCode(String? value) {
  final text = _asText(value);
  return text?.toUpperCase();
}

bool _looksLikePatientCodeConflict(PostgrestException error) {
  final details = '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
      .toLowerCase();
  return details.contains('patient_code') ||
      details.contains('patients_patient_code') ||
      details.contains('duplicate key');
}

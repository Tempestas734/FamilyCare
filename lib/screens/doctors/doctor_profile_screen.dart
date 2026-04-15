import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({
    super.key,
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.location,
    required this.imageUrl,
    this.photoUrl,
    this.bio,
    this.cliniqueNom,
    this.adresse,
    this.latitude,
    this.longitude,
    this.langues = const [],
    this.tarifMin,
    this.tarifMax,
    this.secteur,
    this.note,
    this.disponibilite,
    this.typesConsultation = const [],
  });

  final String doctorId;
  final String name;
  final String specialty;
  final String location;
  final String imageUrl;
  final String? photoUrl;
  final String? bio;
  final String? cliniqueNom;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final List<String> langues;
  final double? tarifMin;
  final double? tarifMax;
  final String? secteur;
  final double? note;
  final DateTime? disponibilite;
  final List<String> typesConsultation;

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F6F8),
      textTheme: ThemeData.light().textTheme.copyWith(
            headlineSmall: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF140D1B),
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF140D1B),
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF140D1B),
            ),
            bodySmall: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E5B7A),
            ),
          ),
    );

    return Theme(
      data: lightTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final displayImage =
              (photoUrl != null && photoUrl!.isNotEmpty) ? photoUrl! : imageUrl;
          final displayBio = bio?.trim().isNotEmpty == true
              ? bio!
              : 'Specialise(e) en ${specialty.toLowerCase()} avec une approche bienveillante et technologique.';
          final displayLocation = adresse?.trim().isNotEmpty == true
              ? adresse!
              : location;
          final displayClinic = cliniqueNom?.trim().isNotEmpty == true
              ? cliniqueNom!
              : 'Cabinet medical';
          final displayLangues = langues.isNotEmpty
              ? langues
              : const ['Francais', 'Anglais'];
          final displayTypes = typesConsultation.isNotEmpty
              ? typesConsultation
              : const ['cabinet', 'video'];
          final displayTarifs = (tarifMin != null || tarifMax != null)
              ? '${tarifMin?.toStringAsFixed(0) ?? '-'}€ - ${tarifMax?.toStringAsFixed(0) ?? '-'}€'
              : '65€ - 120€';
          final displaySecteur =
              secteur?.trim().isNotEmpty == true ? secteur! : 'Conventionne';
          final displayNote =
              note?.toStringAsFixed(1);
          final generatedSlots =
              disponibilite == null ? _generateSlots(DateTime.now()) : <DateTime>[];
          final displayDisponibilite = disponibilite == null
              ? _formatSlotSummary(generatedSlots)
              : _formatDisponibilite(disponibilite!);
          final hasCoords = latitude != null && longitude != null;
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withOpacity(0.92),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Fiche du Praticien',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.share,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.2),
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(displayImage),
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  bottom: 6,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.scaffoldBackgroundColor,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  specialty,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (displayNote != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 12, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 4),
                                       Text(
                                          displayNote,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: const Color(0xFFB45309),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: displayTypes.map((type) {
                                final normalized = type.toLowerCase();
                                if (normalized.contains('video')) {
                                  return _TagChip(
                                    icon: Icons.videocam,
                                    label: 'Video',
                                  );
                                }
                                return _TagChip(
                                  icon: Icons.home,
                                  label: 'En cabinet',
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _AvailabilityCard(text: displayDisponibilite),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            _PrimaryButton(
                              label: 'Prendre RDV',
                              icon: Icons.calendar_today,
                              onPressed: () async {
                                final slots = disponibilite == null
                                    ? generatedSlots
                                    : <DateTime>[disponibilite!];
                                final chosenMember =
                                    await _pickFamilyMember(context);
                                if (chosenMember == null) {
                                  return;
                                }
                                final medecinFamId =
                                    await _ensureMedecinFamilleId(context, doctorId);
                                if (medecinFamId == null) {
                                  return;
                                }
                                final takenSlots =
                                    await _loadTakenSlots(medecinFamId, slots);
                                if (!context.mounted) return;
                                _showRdvSheet(
                                  context,
                                  slots,
                                  familyMemberId: chosenMember.id,
                                  medecinFamilleId: medecinFamId,
                                  takenSlots: takenSlots,
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _SecondaryButton(
                              label: 'Ajouter a ma liste',
                              icon: Icons.person_add_alt,
                              onPressed: () async {
                                final user =
                                    Supabase.instance.client.auth.currentUser;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Veuillez vous reconnecter.'),
                                    ),
                                  );
                                  return;
                                }
                                final familyRow = await Supabase.instance.client
                                    .from('family_members')
                                    .select('family_id')
                                    .eq('auth_user_id', user.id)
                                    .limit(1)
                                    .maybeSingle();
                                final familyId =
                                    familyRow?['family_id']?.toString();
                                if (familyId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Famille introuvable.'),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await Supabase.instance.client
                                      .from('medecins_famille')
                                      .insert({
                                    'family_id': familyId,
                                    'medecin_id': doctorId,
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Medecin ajoute a la liste.'),
                                    ),
                                  );
                                  Navigator.of(context).pop(true);
                                } on PostgrestException catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur DB: ${e.message}'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _InfoSection(
                          title: 'A propos',
                          child: Text(
                            displayBio,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoSection(
                          title: 'Localisation',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayClinic,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          displayLocation,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 120,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: hasCoords
                                      ? FlutterMap(
                                          options: MapOptions(
                                            initialCenter: LatLng(
                                              latitude!,
                                              longitude!,
                                            ),
                                            initialZoom: 14,
                                            interactionOptions:
                                                const InteractionOptions(
                                              flags: InteractiveFlag.pinchZoom |
                                                  InteractiveFlag.drag,
                                            ),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'health_app',
                                              tileProvider:
                                                  CancellableNetworkTileProvider(),
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(
                                                    latitude!,
                                                    longitude!,
                                                  ),
                                                  width: 40,
                                                  height: 40,
                                                  child: Icon(
                                                    Icons.place,
                                                    color: theme
                                                        .colorScheme.primary,
                                                    size: 32,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Container(
                                          color: const Color(0xFFE5E7EB),
                                          child: Center(
                                            child: Icon(
                                              Icons.place,
                                              color:
                                                  theme.colorScheme.primary,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniCard(
                                title: 'Langues',
                                body: displayLangues.join(', '),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniCard(
                                title: 'Tarifs',
                                body: displayTarifs,
                                footer: displaySecteur,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event_available,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponibilite',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Row(
              children: [
                Text(
                  'Voir tout',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black38,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.title, required this.body, this.footer});

  final String title;
  final String body;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black38,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(
              footer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDisponibilite(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diffDays = dateOnly.difference(today).inDays;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final time = '$hour:$minute';
  if (diffDays == 0) {
    return 'Aujourd\'hui, $time';
  }
  if (diffDays == 1) {
    return 'Demain, $time';
  }
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year} $time';
}

List<DateTime> _generateSlots(DateTime now) {
  final slots = <DateTime>[];
  final today = DateTime(now.year, now.month, now.day);
  var cursor = today;
  var daysAdded = 0;

  while (daysAdded < 7 && slots.length < 140) {
    final weekday = cursor.weekday; // 1 = Mon, 7 = Sun
    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      var hasAny = false;
      for (var hour = 9; hour <= 17; hour++) {
        for (var minute = 0; minute <= 30; minute += 30) {
          final slot = DateTime(cursor.year, cursor.month, cursor.day, hour, minute);
          if (slot.isBefore(now)) {
            continue;
          }
          slots.add(slot);
          hasAny = true;
        }
      }
      if (hasAny) {
        daysAdded += 1;
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return slots;
}

String _formatSlotSummary(List<DateTime> slots) {
  if (slots.isEmpty) {
    return 'Sur rendez-vous';
  }
  final first = slots.first;
  final dayLabel = _dayLabel(first);
  return '$dayLabel, ${_formatTime(first)}';
}

void _showRdvSheet(
  BuildContext context,
  List<DateTime> slots, {
  required String familyMemberId,
  required String medecinFamilleId,
  required Set<String> takenSlots,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFF7F6F8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      final grouped = _groupSlotsByDay(slots);
      DateTime? selectedSlot;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choisir un rendez-vous',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (grouped.isEmpty)
                    Text(
                      'Aucune disponibilite pour le moment.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: grouped.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final entry = grouped[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTitle(entry.key),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                  children: entry.value.map((slot) {
                                    final isSelected = selectedSlot == slot;
                                    final isTaken =
                                        takenSlots.contains(_slotKey(slot));
                                    return _SlotChip(
                                      label: _formatTime(slot),
                                      selected: isSelected,
                                      disabled: isTaken,
                                      onTap: isTaken
                                          ? null
                                          : () {
                                              setState(() => selectedSlot = slot);
                                            },
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          },
                        ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: selectedSlot == null
                            ? null
                            : () async {
                                final nav = Navigator.of(context);
                                nav.pop();
                                await _createRendezVous(
                                  context,
                                  medecinFamilleId,
                                  familyMemberId,
                                  selectedSlot!,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirmer le rendez-vous',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

List<MapEntry<DateTime, List<DateTime>>> _groupSlotsByDay(
  List<DateTime> slots,
) {
  final map = <DateTime, List<DateTime>>{};
  for (final slot in slots) {
    final key = DateTime(slot.year, slot.month, slot.day);
    map.putIfAbsent(key, () => []).add(slot);
  }
  final entries = map.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

String _formatDateTitle(DateTime date) {
  final dayName = _dayName(date.weekday);
  final month = _monthName(date.month);
  return '$dayName ${date.day} $month';
}

String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final diff = dateOnly.difference(today).inDays;
  if (diff == 0) {
    return 'Aujourd\'hui';
  }
  if (diff == 1) {
    return 'Demain';
  }
  return _dayName(date.weekday);
}

String _dayName(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Lundi';
    case DateTime.tuesday:
      return 'Mardi';
    case DateTime.wednesday:
      return 'Mercredi';
    case DateTime.thursday:
      return 'Jeudi';
    case DateTime.friday:
      return 'Vendredi';
    case DateTime.saturday:
      return 'Samedi';
    case DateTime.sunday:
      return 'Dimanche';
  }
  return '';
}

String _monthName(int month) {
  switch (month) {
    case 1:
      return 'janvier';
    case 2:
      return 'fevrier';
    case 3:
      return 'mars';
    case 4:
      return 'avril';
    case 5:
      return 'mai';
    case 6:
      return 'juin';
    case 7:
      return 'juillet';
    case 8:
      return 'aout';
    case 9:
      return 'septembre';
    case 10:
      return 'octobre';
    case 11:
      return 'novembre';
    case 12:
      return 'decembre';
  }
  return '';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _slotKey(DateTime slot) {
  final dateStr =
      '${slot.year.toString().padLeft(4, '0')}-${slot.month.toString().padLeft(2, '0')}-${slot.day.toString().padLeft(2, '0')}';
  return '$dateStr ${_formatTime(slot)}';
}

Future<Set<String>> _loadTakenSlots(
  String medecinFamilleId,
  List<DateTime> slots,
) async {
  if (slots.isEmpty) {
    return {};
  }
  final start = slots.first;
  final end = slots.last;
  final startDate =
      '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
  final endDate =
      '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
  final data = await Supabase.instance.client
      .from('rendez_vous')
      .select('date, heure, status')
      .eq('medecin_famille_id', medecinFamilleId)
      .gte('date', startDate)
      .lte('date', endDate)
      .neq('status', 'annule');
  final taken = <String>{};
  for (final row in (data as List<dynamic>)) {
    final map = row as Map<String, dynamic>;
    final date = map['date']?.toString();
    final time = map['heure']?.toString();
    if (date == null || time == null) {
      continue;
    }
    final hourMinute = time.length >= 5 ? time.substring(0, 5) : time;
    taken.add('$date $hourMinute');
  }
  return taken;
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        selected ? theme.colorScheme.primary : Colors.white;
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withOpacity(0.2);
    final textColor = selected ? Colors.white : theme.colorScheme.primary;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(disabled ? 0.5 : 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withOpacity(disabled ? 0.4 : 1)),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor.withOpacity(disabled ? 0.5 : 1),
          ),
        ),
      ),
    );
  }
}

class _FamilyMember {
  const _FamilyMember({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String role;

  factory _FamilyMember.fromMap(Map<String, dynamic> map) {
    return _FamilyMember(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString().trim().isNotEmpty == true
          ? map['full_name'].toString()
          : 'Membre',
      role: map['role']?.toString() ?? '',
    );
  }
}

Future<String?> _getFamilyId() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return null;
  }
  final row = await Supabase.instance.client
      .from('family_members')
      .select('family_id')
      .eq('auth_user_id', user.id)
      .limit(1)
      .maybeSingle();
  return row?['family_id']?.toString();
}

Future<List<_FamilyMember>> _loadFamilyMembers() async {
  final familyId = await _getFamilyId();
  if (familyId == null) {
    return [];
  }
  final data = await Supabase.instance.client
      .from('family_members')
      .select('id, full_name, role')
      .eq('family_id', familyId)
      .order('created_at');
  return (data as List<dynamic>)
      .map((row) => _FamilyMember.fromMap(row as Map<String, dynamic>))
      .where((member) => member.id.isNotEmpty)
      .toList();
}

Future<_FamilyMember?> _pickFamilyMember(BuildContext context) async {
  final members = await _loadFamilyMembers();
  if (!context.mounted) return null;
  if (members.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun membre trouve.')),
    );
    return null;
  }
  return showModalBottomSheet<_FamilyMember>(
    context: context,
    backgroundColor: const Color(0xFFF7F6F8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choisir un membre',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: Colors.white,
                      title: Text(
                        member.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: member.role.isNotEmpty
                          ? Text(
                              member.role,
                              style: theme.textTheme.bodySmall,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(member),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> _ensureMedecinFamilleId(
  BuildContext context,
  String doctorId,
) async {
  final familyId = await _getFamilyId();
  if (familyId == null) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Famille introuvable.')),
    );
    return null;
  }
  final existing = await Supabase.instance.client
      .from('medecins_famille')
      .select('id')
      .eq('family_id', familyId)
      .eq('medecin_id', doctorId)
      .maybeSingle();
  final existingId = existing?['id']?.toString();
  if (existingId != null) {
    return existingId;
  }
  try {
    final inserted = await Supabase.instance.client
        .from('medecins_famille')
        .insert({
          'family_id': familyId,
          'medecin_id': doctorId,
        })
        .select('id')
        .maybeSingle();
    return inserted?['id']?.toString();
  } on PostgrestException catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur DB: ${e.message}')),
    );
    return null;
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
    return null;
  }
}

Future<void> _createRendezVous(
  BuildContext context,
  String medecinFamilleId,
  String familyMemberId,
  DateTime slot,
) async {
  final dateStr =
      '${slot.year.toString().padLeft(4, '0')}-${slot.month.toString().padLeft(2, '0')}-${slot.day.toString().padLeft(2, '0')}';
  final timeStr = '${_formatTime(slot)}:00';
  try {
    await Supabase.instance.client.from('rendez_vous').insert({
      'medecin_famille_id': medecinFamilleId,
      'family_member_id': familyMemberId,
      'date': dateStr,
      'heure': timeStr,
      'note': null,
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'RDV confirme: $dateStr a ${_formatTime(slot)}',
        ),
      ),
    );
  } on PostgrestException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur DB: ${e.message}')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}

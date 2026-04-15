import 'package:flutter/material.dart';

import 'program_customization_step2_screen.dart';

class ProgramCustomizationStep1Screen extends StatefulWidget {
  const ProgramCustomizationStep1Screen({super.key});

  @override
  State<ProgramCustomizationStep1Screen> createState() =>
      _ProgramCustomizationStep1ScreenState();
}

class _ProgramCustomizationStep1ScreenState
    extends State<ProgramCustomizationStep1Screen> {
  final TextEditingController _nameController = TextEditingController();

  String _selectedDifficulty = 'beginner';
  final Set<String> _selectedCategories = <String>{'strength'};

  static const List<_DifficultyItem> _difficulties = <_DifficultyItem>[
    _DifficultyItem(label: 'Debutant', value: 'beginner'),
    _DifficultyItem(label: 'Intermediaire', value: 'intermediate'),
    _DifficultyItem(label: 'Avance', value: 'expert'),
  ];

  static const List<_CategoryItem> _categories = <_CategoryItem>[
    _CategoryItem(
      label: 'Strength',
      value: 'strength',
      icon: Icons.fitness_center,
    ),
    _CategoryItem(
      label: 'Stretching',
      value: 'stretching',
      icon: Icons.self_improvement,
    ),
    _CategoryItem(
      label: 'Plyometrics',
      value: 'plyometrics',
      icon: Icons.bolt,
    ),
    _CategoryItem(
      label: 'Powerlifting',
      value: 'powerlifting',
      icon: Icons.monitor_weight,
    ),
    _CategoryItem(
      label: 'Olympic Weightlifting',
      value: 'olympic weightlifting',
      icon: Icons.accessibility_new,
    ),
    _CategoryItem(
      label: 'Strongman',
      value: 'strongman',
      icon: Icons.sports_gymnastics,
    ),
    _CategoryItem(
      label: 'Cardio',
      value: 'cardio',
      icon: Icons.directions_run,
    ),
  ];

  static const Map<String, String> _coverByCategory = <String, String>{
    'strength':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAspkXKvqeX6b4Ps3BM_dR3YiywRcfk4GadeAzc74fgzNc7aiDd4XiGgESMRW5JDzCOmQ-ibd5782rog8_m08GCPmIkM9KlMupKgioSKW8xVUl_J_4lMl9A_TpTGZjnPWOXnLMxpC6g6zFAPQ7VBAXjq18O_kCl-qIj6NDJSqS4DX-JErNnZFqyqLfCMmHo5-06SLDM8-4vQKbEY5BNSDpQ39wxli1TXiqy1Xfr08yIy-_Mom7kFEEGMkJsgUjthI5MzWiBgI0m9wo9',
    'stretching':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCrY6WC6G_3lg9O6W1OGAkpXZHNFPAwgpMxR0ww_jhwmmKsi9F3yiAE5c6elBGFQYh22PRjsQlUw7O2WC9GaOkA1UtK_1sTmMRpE48XFXe5MKgsTu8hXHSfDdqxNTMvOF0S1-PQ94VMyDIDB1TNyH2xf5KCBetynyEvomo3z8oco9HZLTpINJhB8esyoRrZsXgyCGOa6tdinCubXKmd2SqbjZmR2HTDXKojsZL3_ZIGOCNlkFywIIV4AyBFJFX_t2BWMc7dxnqwGg8c',
    'cardio':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA2CjN8KTpJ50Fg9-OoZRsV39nll2xZdsW5UkUYOjMr9goruui38fU03AncAF3Wnoplh9QSLyk5DMjwhLeqiHPhK9qhxaeyZvcYJCrMmw-pVIwQjSTHQm3Cu_Zz66SRHhU52znxYSOzzSgOjH9nNMUsIeJai6yHcMfDc6ockzZcaYfxjRQmoW4LJzNWUJbdC90xMLG3K7a6_bE9f4IsGH7oTX8XtwBuwrU8PWj5m-AcgFbTWGRkJlwG7nmFptC2a4AvYk7Zpx4mbkqc',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Personnaliser ma seance',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                Row(
                  children: [
                    const Text(
                      'ETAPE 1 SUR 2',
                      style: TextStyle(
                        color: Color(0xFFF48C25),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF48C25),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nom de la seance',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Full Body Express',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Niveau de difficulte',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: _difficulties.map((d) {
                      final selected = d.value == _selectedDifficulty;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDifficulty = d.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: selected
                                  ? const [
                                      BoxShadow(
                                        color: Color.fromRGBO(15, 23, 42, 0.08),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              d.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFF48C25)
                                    : const Color(0xFF475569),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CATEGORIES',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final c = _categories[index];
                    final selected = _selectedCategories.contains(c.value);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            if (_selectedCategories.length > 1) {
                              _selectedCategories.remove(c.value);
                            }
                          } else {
                            _selectedCategories.add(c.value);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color.fromRGBO(255, 247, 237, 1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFF48C25)
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(15, 23, 42, 0.06),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color.fromRGBO(255, 237, 213, 1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(c.icon, color: const Color(0xFFF48C25), size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              color: Color.fromRGBO(255, 255, 255, 0.94),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF48C25),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Suivant',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    final selectedValues = _selectedCategories.isEmpty
        ? <String>{_categories.first.value}
        : _selectedCategories;
    final selected = _categories.firstWhere(
      (c) => selectedValues.contains(c.value),
      orElse: () => _categories.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgramCustomizationStep2Screen(
          sessionName: _nameController.text.trim(),
          coverTitle: selected.label,
          coverImageUrl: _coverByCategory[selected.value] ??
              _coverByCategory['strength']!,
          initialCategories: selectedValues.toList(),
          initialDifficulty: _selectedDifficulty,
        ),
      ),
    );
  }
}

class _DifficultyItem {
  const _DifficultyItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _CategoryItem {
  const _CategoryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

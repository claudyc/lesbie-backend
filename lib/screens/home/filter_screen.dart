import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const FilterScreen({
    super.key,
    required this.currentFilters,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late double _maxDistance;
  late List<String> _selectedIdentities;
  late RangeValues _ageRange;

  final List<Map<String, String>> _identities = [
    {'key': 'stud', 'label': 'Stud 👑'},
    {'key': 'femme', 'label': 'Femme 💕'},
    {'key': 'versatile', 'label': 'Versatile ⚖️'},
    {'key': 'androgyne', 'label': 'Androgyne 🌈'},
    {'key': 'prefer_not_say', 'label': 'Pito pa di 🤷'},
  ];

  @override
  void initState() {
    super.initState();
    _maxDistance = widget.currentFilters['maxDistance'] ?? 50.0;
    _selectedIdentities = List<String>.from(
      widget.currentFilters['identities'] ?? [],
    );
    final ageMin = widget.currentFilters['ageMin'] ?? 18.0;
    final ageMax = widget.currentFilters['ageMax'] ?? 60.0;
    _ageRange = RangeValues(ageMin.toDouble(), ageMax.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filtre',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reyenisyalize',
              style: TextStyle(color: Color(0xFFED93B1)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distans
            _buildSectionTitle('Distans maksimòm'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rayon rechèch',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${_maxDistance.round()} km',
                        style: const TextStyle(
                          color: Color(0xFFD4537E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFD4537E),
                      inactiveTrackColor:
                      Colors.white.withOpacity(0.2),
                      thumbColor: const Color(0xFFD4537E),
                      overlayColor:
                      const Color(0xFFD4537E).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _maxDistance,
                      min: 5,
                      max: 500,
                      divisions: 99,
                      onChanged: (value) {
                        setState(() => _maxDistance = value);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '5 km',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '500 km',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Laj
            _buildSectionTitle('Laj'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Interval laj',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${_ageRange.start.round()} — ${_ageRange.end.round()} an',
                        style: const TextStyle(
                          color: Color(0xFFD4537E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFD4537E),
                      inactiveTrackColor:
                      Colors.white.withOpacity(0.2),
                      thumbColor: const Color(0xFFD4537E),
                      overlayColor:
                      const Color(0xFFD4537E).withOpacity(0.2),
                      rangeThumbShape:
                      const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                    ),
                    child: RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 60,
                      divisions: 42,
                      onChanged: (values) {
                        setState(() => _ageRange = values);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '18 an',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '60 an',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Idantite
            _buildSectionTitle('Idantite (opsyonèl)'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _identities.map((item) {
                final isSelected =
                _selectedIdentities.contains(item['key']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIdentities.remove(item['key']);
                      } else {
                        _selectedIdentities.add(item['key']!);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD4537E)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4537E)
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      item['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // Bouton aplike
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4537E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Aplike filtre yo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _maxDistance = 50.0;
      _selectedIdentities = [];
      _ageRange = const RangeValues(18, 60);
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'maxDistance': _maxDistance,
      'identities': _selectedIdentities,
      'ageMin': _ageRange.start,
      'ageMax': _ageRange.end,
    });
  }
}
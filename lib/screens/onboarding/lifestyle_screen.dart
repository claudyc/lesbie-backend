import 'package:flutter/material.dart';
import 'photos_screen.dart';

class LifestyleScreen extends StatefulWidget {
  final String identity;
  final String lookingFor;
  final String city;
  final String country;
  final String state;
  final double? latitude;
  final double? longitude;

  const LifestyleScreen({
    super.key,
    required this.identity,
    required this.lookingFor,
    required this.city,
    required this.country,
    required this.state,
    this.latitude,
    this.longitude,
  });

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  String? _relationshipGoal;
  final List<String> _interests = [];
  String? _smoking;
  String? _alcohol;
  String? _children;

  final List<Map<String, String>> _interestOptions = [
    {'key': 'music', 'label': 'Mizik 🎵'},
    {'key': 'travel', 'label': 'Vwayaj ✈️'},
    {'key': 'sports', 'label': 'Spò ⚽'},
    {'key': 'cooking', 'label': 'Kwizin 🍳'},
    {'key': 'reading', 'label': 'Lekti 📚'},
    {'key': 'art', 'label': 'Atizana 🎨'},
    {'key': 'movies', 'label': 'Fim 🎬'},
    {'key': 'nature', 'label': 'Nati 🌿'},
    {'key': 'fitness', 'label': 'Fitness 💪'},
    {'key': 'dancing', 'label': 'Dans 💃'},
    {'key': 'gaming', 'label': 'Gaming 🎮'},
    {'key': 'photography', 'label': 'Foto 📸'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildProgressBar(4, 5),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Estil lavi ou',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pale nou de ou pou jwenn pi bon match',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFED93B1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Kisa ou chache?'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChoiceChip('Relasyon serye 💍', 'serious',
                            _relationshipGoal,
                                (v) => setState(() => _relationshipGoal = v)),
                        _buildChoiceChip('Dating 💕', 'dating',
                            _relationshipGoal,
                                (v) => setState(() => _relationshipGoal = v)),
                        _buildChoiceChip('Zanmitay 👯', 'friendship',
                            _relationshipGoal,
                                (v) => setState(() => _relationshipGoal = v)),
                        _buildChoiceChip('Poko konnen 🤷', 'unsure',
                            _relationshipGoal,
                                (v) => setState(() => _relationshipGoal = v)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Ki enterè ou? (chwazi plizyè)'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _interestOptions.map((item) {
                        final isSelected = _interests.contains(item['key']);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _interests.remove(item['key']);
                              } else {
                                _interests.add(item['key']!);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
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
                    const SizedBox(height: 28),
                    _buildSectionTitle('Eske ou fimen?'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChoiceChip('Wi 🚬', 'yes', _smoking,
                                (v) => setState(() => _smoking = v)),
                        _buildChoiceChip('Non 🚭', 'no', _smoking,
                                (v) => setState(() => _smoking = v)),
                        _buildChoiceChip('Pafwa 🤏', 'sometimes', _smoking,
                                (v) => setState(() => _smoking = v)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Bwason alkòl?'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChoiceChip('Wi 🍷', 'yes', _alcohol,
                                (v) => setState(() => _alcohol = v)),
                        _buildChoiceChip('Non 🚫', 'no', _alcohol,
                                (v) => setState(() => _alcohol = v)),
                        _buildChoiceChip('Pafwa 🥂', 'sometimes', _alcohol,
                                (v) => setState(() => _alcohol = v)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Timoun?'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChoiceChip('Wi mwen gen 👶', 'have', _children,
                                (v) => setState(() => _children = v)),
                        _buildChoiceChip('Pa gen 🙅', 'none', _children,
                                (v) => setState(() => _children = v)),
                        _buildChoiceChip('Vle nan lavni 🌱', 'want', _children,
                                (v) => setState(() => _children = v)),
                        _buildChoiceChip('Pa vle 🚫', 'dont_want', _children,
                                (v) => setState(() => _children = v)),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isComplete() ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4537E),
                    disabledBackgroundColor:
                    const Color(0xFFD4537E).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Kontinye →',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isComplete() {
    return _relationshipGoal != null &&
        _interests.isNotEmpty &&
        _smoking != null &&
        _alcohol != null &&
        _children != null;
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

  Widget _buildChoiceChip(
      String label,
      String value,
      String? selected,
      Function(String) onTap,
      ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
          label,
          style: TextStyle(
            color:
            isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            fontWeight:
            isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 4,
            decoration: BoxDecoration(
              color: index < current
                  ? const Color(0xFFD4537E)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotosScreen(
          identity: widget.identity,
          lookingFor: widget.lookingFor,
          city: widget.city,
          country: widget.country,
          state: widget.state,
          latitude: widget.latitude,
          longitude: widget.longitude,
          relationshipGoal: _relationshipGoal!,
          interests: _interests,
          smoking: _smoking!,
          alcohol: _alcohol!,
          children: _children!,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'location_screen.dart';

class LookingForScreen extends StatefulWidget {
  final String identity;
  const LookingForScreen({super.key, required this.identity});

  @override
  State<LookingForScreen> createState() => _LookingForScreenState();
}

class _LookingForScreenState extends State<LookingForScreen> {
  String? _selectedLookingFor;

  final List<Map<String, dynamic>> _options = [
    {
      'key': 'stud',
      'emoji': '👑',
      'title': 'Stud',
      'desc': 'Mwen chache yon moun ak estil maskilèn',
    },
    {
      'key': 'femme',
      'emoji': '💕',
      'title': 'Femme / Girl',
      'desc': 'Mwen chache yon moun ak estil feminen',
    },
    {
      'key': 'versatile',
      'emoji': '⚖️',
      'title': 'Versatile',
      'desc': 'Mwen chache yon moun ki melanje de estil',
    },
    {
      'key': 'any',
      'emoji': '🌈',
      'title': 'Nenpòt',
      'desc': 'Estil pa enpòtan pou mwen',
    },
    {
      'key': 'friendship',
      'emoji': '💬',
      'title': 'Zanmitay sèlman',
      'desc': 'Mwen pa chache relasyon romantik',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildProgressBar(2, 5),
              const SizedBox(height: 32),
              // Bouton retounen
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kisa ou\nchache?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chwazi tip moun ou vle rankontre',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFED93B1),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _options[index];
                    final isSelected = _selectedLookingFor == item['key'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedLookingFor = item['key']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD4537E).withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4537E)
                                : Colors.white.withOpacity(0.15),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              item['emoji'],
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFD4537E)
                                          : Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['desc'],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFD4537E),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedLookingFor == null ? null : _continue,
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
              const SizedBox(height: 24),
            ],
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
        builder: (_) => LocationScreen(
          identity: widget.identity,
          lookingFor: _selectedLookingFor!,
        ),
      ),
    );
  }
}
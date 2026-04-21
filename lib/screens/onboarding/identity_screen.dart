import 'package:flutter/material.dart';
import 'looking_for_screen.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  String? _selectedIdentity;

  final List<Map<String, dynamic>> _identities = [
    {
      'key': 'stud',
      'emoji': '👑',
      'title': 'Stud',
      'desc': 'Mwen gen yon estil maskilèn',
    },
    {
      'key': 'femme',
      'emoji': '💕',
      'title': 'Femme / Girl',
      'desc': 'Mwen gen yon estil feminen',
    },
    {
      'key': 'versatile',
      'emoji': '⚖️',
      'title': 'Versatile',
      'desc': 'Mwen melanje de estil yo',
    },
    {
      'key': 'androgyne',
      'emoji': '🌈',
      'title': 'Androgyne',
      'desc': 'Mwen pa defini tèt mwen nan okenn estil',
    },
    {
      'key': 'prefer_not_say',
      'emoji': '🤷',
      'title': 'Pito pa di',
      'desc': 'Mwen pito kenbe sa prive',
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
              // Pwogresyon
              _buildProgressBar(1, 5),
              const SizedBox(height: 32),
              // Tit
              const Text(
                'Kijan ou defini\ntèt ou?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sa ap ede nou jwenn moun ki koresponn ak ou',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFED93B1),
                ),
              ),
              const SizedBox(height: 32),
              // Opsyon yo
              Expanded(
                child: ListView.separated(
                  itemCount: _identities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _identities[index];
                    final isSelected = _selectedIdentity == item['key'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIdentity = item['key']),
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
              // Bouton kontinye
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedIdentity == null ? null : _continue,
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
        builder: (_) => LookingForScreen(
          identity: _selectedIdentity!,
        ),
      ),
    );
  }
}
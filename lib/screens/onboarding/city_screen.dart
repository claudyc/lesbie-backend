import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'username_screen.dart';

class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String _selectedCountry = 'USA';

  final List<String> _countries = [
    'USA',
    'Canada',
    'Haiti',
    'Dominican Republic',
    'Mexico',
    'Chile',
    'France',
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              AppTheme.pink.withOpacity(0.07),
              AppTheme.bg,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.pink.withOpacity(0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Progress
                _buildProgress(2, 5),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'Where are\nyou located? 📍',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps you connect with women nearby',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray),
                ),
                const SizedBox(height: 32),

                // Country dropdown
                _buildLabel('Country'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(
                      color: AppTheme.pink.withOpacity(0.15),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountry,
                      dropdownColor: AppTheme.card,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 15,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.gray2,
                      ),
                      items: _countries.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCountry = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // City field
                _buildLabel('City'),
                _buildTextField(
                  controller: _cityController,
                  hint: 'e.g. Miami, Port-au-Prince, Paris',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 16),

                // State/Region field
                _buildLabel('State / Region (optional)'),
                _buildTextField(
                  controller: _stateController,
                  hint: 'e.g. Florida, Ouest, Île-de-France',
                  icon: Icons.map_outlined,
                ),

                const Spacer(),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _cityController.text.isNotEmpty
                          ? AppTheme.pinkGrad
                          : const LinearGradient(
                        colors: [Color(0xFF2E2C38), Color(0xFF2E2C38)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      boxShadow: _cityController.text.isNotEmpty
                          ? AppTheme.pinkShadow
                          : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _cityController.text.isEmpty
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UsernameScreen(
                              city: _cityController.text.trim(),
                              state: _stateController.text.trim(),
                              country: _selectedCountry,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: AppTheme.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.gray,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.pink.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.white, fontSize: 15),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.gray2),
          prefixIcon: Icon(icon, color: AppTheme.pink, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: index < current ? AppTheme.pink : AppTheme.gray3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
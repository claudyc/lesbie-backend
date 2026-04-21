import 'package:flutter/material.dart';
import 'lifestyle_screen.dart';

class LocationScreen extends StatefulWidget {
  final String identity;
  final String lookingFor;

  const LocationScreen({
    super.key,
    required this.identity,
    required this.lookingFor,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _selectedCountry;
  String? _selectedState;
  final _cityController = TextEditingController();

  final List<Map<String, dynamic>> _countries = [
    {'key': 'HT', 'name': 'Haiti', 'flag': '🇭🇹'},
    {'key': 'US', 'name': 'USA', 'flag': '🇺🇸'},
    {'key': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'key': 'DO', 'name': 'Dominican Republic', 'flag': '🇩🇴'},
    {'key': 'MX', 'name': 'Mexique', 'flag': '🇲🇽'},
    {'key': 'FR', 'name': 'France', 'flag': '🇫🇷'},
  ];

  final Map<String, List<String>> _states = {
    'HT': [
      'Ouest',
      'Nord',
      'Nord-Est',
      'Nord-Ouest',
      'Artibonite',
      'Centre',
      'Sud',
      'Sud-Est',
      'Grande-Anse',
      'Nippes',
    ],
    'US': [
      'Florida',
      'New York',
      'Texas',
      'California',
      'Georgia',
      'Massachusetts',
      'New Jersey',
      'Illinois',
      'Pennsylvania',
      'Ohio',
      'Michigan',
      'North Carolina',
      'Virginia',
      'Maryland',
      'Connecticut',
      'Lòt eta',
    ],
    'CA': [
      'Quebec',
      'Ontario',
      'British Columbia',
      'Alberta',
      'Manitoba',
      'Saskatchewan',
      'Nova Scotia',
      'Lòt pwovens',
    ],
    'DO': [
      'Santo Domingo',
      'Santiago',
      'La Vega',
      'San Cristóbal',
      'Puerto Plata',
      'San Pedro de Macorís',
      'La Romana',
      'Lòt pwovens',
    ],
    'MX': [
      'Ciudad de México',
      'Jalisco',
      'Nuevo León',
      'Puebla',
      'Guanajuato',
      'Chihuahua',
      'Veracruz',
      'Lòt eta',
    ],
    'FR': [
      'Île-de-France',
      'Provence-Alpes-Côte d\'Azur',
      'Auvergne-Rhône-Alpes',
      'Occitanie',
      'Hauts-de-France',
      'Nouvelle-Aquitaine',
      'Grand Est',
      'Lòt rejyon',
    ],
  };

  String _getStateLabel() {
    switch (_selectedCountry) {
      case 'HT':
        return 'Depatman';
      case 'US':
        return 'State';
      case 'CA':
        return 'Pwovens';
      case 'DO':
      case 'MX':
        return 'Pwovens / Eta';
      case 'FR':
        return 'Rejyon';
      default:
        return 'Rejyon / Eta';
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

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
              _buildProgressBar(3, 5),
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
                'Kote ou ye?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nou ap montre ou moun ki pre ou',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFED93B1),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Peyi
                      _buildLabel('Peyi'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        hint: 'Chwazi peyi ou',
                        value: _selectedCountry,
                        items: _countries.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['key'],
                            child: Text(
                              '${c['flag']} ${c['name']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            _selectedState = null;
                          });
                        },
                      ),

                      // State/Depatman — parèt sèlman si peyi chwazi
                      if (_selectedCountry != null) ...[
                        const SizedBox(height: 16),
                        _buildLabel(_getStateLabel()),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          hint: 'Chwazi ${_getStateLabel().toLowerCase()} ou',
                          value: _selectedState,
                          items: (_states[_selectedCountry] ?? [])
                              .map((s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedState = value);
                          },
                        ),
                      ],

                      // Vil
                      const SizedBox(height: 16),
                      _buildLabel('Vil / Kominote'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: TextField(
                          controller: _cityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText:
                            'Egz: Port-au-Prince, Miami, Delmas...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            prefixIcon: const Icon(
                              Icons.location_city,
                              color: Color(0xFF7F77DD),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bouton kontinye
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedCountry == null ||
                      _selectedState == null ||
                      _cityController.text.isEmpty
                      ? null
                      : _continue,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              hint,
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
          dropdownColor: const Color(0xFF3D2560),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF7F77DD),
          ),
          items: items,
          onChanged: onChanged,
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
        builder: (_) => LifestyleScreen(
          identity: widget.identity,
          lookingFor: widget.lookingFor,
          city: _cityController.text.trim(),
          country: _selectedCountry!,
          state: _selectedState!,
          latitude: null,
          longitude: null,
        ),
      ),
    );
  }
}
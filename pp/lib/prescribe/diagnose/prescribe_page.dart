import 'package:flutter/material.dart';
import 'package:pharmapulse/prescribe/diagnose/medical_history_page.dart';

class PrescribePage extends StatefulWidget {
  const PrescribePage({super.key});

  @override
  State<PrescribePage> createState() => _PrescribePageState();
}

class _PrescribePageState extends State<PrescribePage>
    with SingleTickerProviderStateMixin {
  final List<String> _allSymptoms = [
    'Headache',
    'Fever',
    'Dry Cough',
    'Sore Throat',
    'Runny Nose',
    'Body Aches',
    'Nausea',
    'Fatigue',
    'Dizziness',
    'Stomach Pain',
    'Shortness of Breath',
    'Chills',
    'Chest Pain',
    'Wheezing',
    'Skin Rash',
    'Itching',
    'Joint Pain',
    'Swelling',
    'Vomiting',
    'Diarrhea',
    'Constipation',
    'Abdominal Cramps',
    'Heartburn',
    'Loss of Appetite',
    'Blurred Vision',
    'Earache',
    'Sore Eyes',
    'Muscle Weakness',
    'Back Pain',
    'Neck Pain',
    'Confusion',
    'Anxiety',
    'Insomnia',
    'Weight Loss',
    'Congestion',
  ];

  final Set<String> _selectedSymptoms = {};

  late AnimationController _controller;
  late Animation<Offset> _animation;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation = ConstantTween<Offset>(Offset.zero).animate(_controller);
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _offset = _animation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Checker')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What are you feeling today?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select all symptoms that apply.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _offset += details.delta / 4;
                    _offset = Offset(
                      _offset.dx.clamp(-20.0, 20.0),
                      _offset.dy.clamp(-20.0, 20.0),
                    );
                  });
                },
                onPanEnd: (_) {
                  _animation = Tween<Offset>(begin: _offset, end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOut,
                        ),
                      );
                  _controller
                    ..reset()
                    ..forward();
                },
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Transform.translate(
                    offset: _offset,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _allSymptoms.map((symptom) {
                        final isSelected = _selectedSymptoms.contains(symptom);
                        return FilterChip(
                          label: Text(symptom),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSymptoms.add(symptom);
                              } else {
                                _selectedSymptoms.remove(symptom);
                              }
                            });
                          },
                          backgroundColor: Colors.grey.shade800,
                          selectedColor: Colors.redAccent,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade300,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.grey.shade700,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _selectedSymptoms.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalHistoryPage(
                              selectedSymptoms: _selectedSymptoms,
                            ),
                          ),
                        );
                      },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

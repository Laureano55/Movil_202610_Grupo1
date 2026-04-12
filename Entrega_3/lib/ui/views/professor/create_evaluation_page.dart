import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/evaluation_controller.dart';
import '../../viewmodels/auth_controller.dart';
import '../../viewmodels/professor_controller.dart';
import '../../data/kCriteria.dart';
import '../../../core/auth_utils.dart';

class CreateEvaluationPage extends StatefulWidget {
  const CreateEvaluationPage({super.key});

  @override
  State<CreateEvaluationPage> createState() => _CreateEvaluationPageState();
}

class _CreateEvaluationPageState extends State<CreateEvaluationPage> {
  static const _primary = Color(0xFF4B3CF0);

  final _formKey = GlobalKey<FormState>();
  final _activityNameCtrl = TextEditingController();

  late String _courseId;
  late String _courseName;
  late String _courseCode;

  String? _selectedCategory;
  List<String> _categories = [];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  String _visibility = 'private';
  bool _allowSelfEval = false;

  final Set<String> _selectedCriteria = {
    'Comunicación',
    'Responsabilidad',
    'Colaboración',
  };

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _courseId = args['courseId'] ?? '';
    _courseName = args['courseName'] ?? 'Curso';
    _courseCode = args['courseCode'] ?? '';
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats =
        await Get.find<EvaluationController>().getCategoriesForCourse(_courseId);
    setState(() {
      _categories = cats;
      if (cats.isNotEmpty) _selectedCategory = cats.first;
    });
  }

  @override
  void dispose() {
    _activityNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDateTimePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      Get.snackbar('Error', 'Selecciona un grupo/categoría');
      return;
    }
    if (_selectedCriteria.isEmpty) {
      Get.snackbar('Error', 'Selecciona al menos un criterio');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      Get.snackbar('Error', 'La fecha de fin debe ser posterior al inicio');
      return;
    }

    setState(() => _loading = true);
    try {
      // Usar getCurrentEmail() de auth_utils en lugar de DemoCourseStore
      final auth = Get.find<AuthController>();
      final professorEmail = (await getCurrentEmail()) ??
          auth.emailController.text.trim();

      await Get.find<EvaluationController>().createEvaluation(
        courseId: _courseId,
        courseName: _courseName,
        categoryName: _selectedCategory!,
        activityName: _activityNameCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        visibility: _visibility,
        allowSelfEval: _allowSelfEval,
        criteria: _selectedCriteria.toList(),
        professorEmail: professorEmail,
      );

      if (Get.isRegistered<ProfessorController>()) {
        Get.find<ProfessorController>().loadCourses();
      }
      Get.back();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Nueva Evaluación',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded,
                      color: _primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '$_courseName  ·  $_courseCode',
                    style: const TextStyle(
                        color: _primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SectionHeader(step: '1', title: 'Información básica'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _activityNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la actividad',
                hintText: 'Ej. Midterm Peer Review',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa un nombre'
                  : null,
            ),
            const SizedBox(height: 16),
            _categories.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'No hay grupos en este curso. Importa grupos antes de crear una evaluación.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Grupo / Categoría',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                            value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v),
                  ),
            const SizedBox(height: 24),

            _SectionHeader(step: '2', title: 'Ventana de tiempo'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Inicio',
                    value: _formatDateTime(_startDate),
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'Fin',
                    value: _formatDateTime(_endDate),
                    icon: Icons.event_rounded,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _SectionHeader(step: '3', title: 'Visibilidad de resultados'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VisibilityOption(
                    icon: Icons.visibility_off_rounded,
                    label: 'Privado',
                    subtitle: 'Solo el docente ve los resultados',
                    selected: _visibility == 'private',
                    onTap: () =>
                        setState(() => _visibility = 'private'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisibilityOption(
                    icon: Icons.visibility_rounded,
                    label: 'Público',
                    subtitle: 'Estudiantes ven sus resultados',
                    selected: _visibility == 'public',
                    onTap: () =>
                        setState(() => _visibility = 'public'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _SectionHeader(step: '4', title: 'Reglas de evaluación'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SwitchListTile(
                title: const Text('Permitir autoevaluación',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle:
                    const Text('Los estudiantes pueden evaluarse a sí mismos'),
                value: _allowSelfEval,
                onChanged: (v) => setState(() => _allowSelfEval = v),
                activeColor: _primary,
              ),
            ),
            const SizedBox(height: 24),

            _SectionHeader(step: '5', title: 'Criterios de evaluación'),
            const SizedBox(height: 12),
            ...kAllCriteria.map((criterion) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _selectedCriteria.contains(criterion)
                        ? const Color(0xFFF0EFFE)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedCriteria.contains(criterion)
                          ? _primary
                          : const Color(0xFFE5E7EB),
                      width: _selectedCriteria.contains(criterion)
                          ? 1.5
                          : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _selectedCriteria.contains(criterion),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedCriteria.add(criterion);
                        } else {
                          _selectedCriteria.remove(criterion);
                        }
                      });
                    },
                    title: Text(criterion,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        kCriteriaDescriptions[criterion] ?? '',
                        style: const TextStyle(fontSize: 12)),
                    activeColor: _primary,
                    dense: true,
                  ),
                )),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _loading || _categories.isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Activar Evaluación',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String step;
  final String title;
  const _SectionHeader({required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF4B3CF0),
          child: Text(step,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF4B3CF0)),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _VisibilityOption(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.selected,
      required this.onTap});

  static const _primary = Color(0xFF4B3CF0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0EFFE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _primary : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color:
                        selected ? _primary : const Color(0xFF6B7280),
                    size: 20),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: _primary, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? _primary : const Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}
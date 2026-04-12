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

  // ── Group selection ────────────────────────────────────────────────────────
  /// When true, the evaluation is created for ALL groups (default behaviour).
  bool _allGroups = true;
  String? _selectedCategory;
  List<String> _categories = [];

  // ── Dates ──────────────────────────────────────────────────────────────────
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  // ── Options ────────────────────────────────────────────────────────────────
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

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await _showDateTimePicker(
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

  Future<DateTime?> _showDateTimePicker({
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

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_allGroups && _selectedCategory == null) {
      Get.snackbar('Error', 'Selecciona un grupo/categoría',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_selectedCriteria.isEmpty) {
      Get.snackbar('Error', 'Selecciona al menos un criterio',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      Get.snackbar('Error', 'La fecha de fin debe ser posterior al inicio',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = Get.find<AuthController>();
      final professorEmail =
          (await getCurrentEmail()) ?? auth.emailController.text.trim();

      final categoriesToCreate =
          _allGroups ? _categories : [_selectedCategory!];

      final (created, failed) =
          await Get.find<EvaluationController>().createEvaluationsForCategories(
        courseId: _courseId,
        courseName: _courseName,
        categoryNames: categoriesToCreate,
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

      // Show result dialog before closing the page.
      if (mounted) {
        await _showResultDialog(
          created: created,
          failed: failed,
          activityName: _activityNameCtrl.text.trim(),
          totalCategories: categoriesToCreate.length,
        );
      }

      Get.back();
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red),
                SizedBox(width: 10),
                Text('Error al crear'),
              ],
            ),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showResultDialog({
    required int created,
    required int failed,
    required String activityName,
    required int totalCategories,
  }) async {
    final bool allOk = failed == 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              allOk
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: allOk ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                allOk ? '¡Evaluación activada!' : 'Creación parcial',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$activityName"',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            if (created > 0)
              _ResultRow(
                icon: Icons.check_rounded,
                color: Colors.green,
                text: '$created grupo${created > 1 ? 's' : ''} con evaluación creada.',
              ),
            if (failed > 0)
              _ResultRow(
                icon: Icons.close_rounded,
                color: Colors.red,
                text: '$failed grupo${failed > 1 ? 's' : ''} con error al crear.',
              ),
            const SizedBox(height: 8),
            Text(
              allOk
                  ? 'Los estudiantes ya pueden responder dentro del periodo indicado.'
                  : 'Revisa la consola o inténtalo de nuevo para los grupos fallidos.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = !_loading &&
        _categories.isNotEmpty &&
        (_allGroups || _selectedCategory != null);

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
            // Course banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: _primary, size: 20),
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

            // ── Section 1: Basic info ──────────────────────────────────────
            const _SectionHeader(step: '1', title: 'Información básica'),
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
            ),
            const SizedBox(height: 16),

            // ── Group selector ─────────────────────────────────────────────
            if (_categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
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
            else ...[
              // All groups toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SwitchListTile(
                  title: const Text('Todos los grupos',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _allGroups
                        ? 'Se creará una evaluación para cada grupo (${_categories.length} grupos)'
                        : 'Selecciona un grupo específico abajo',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _allGroups,
                  onChanged: (v) => setState(() => _allGroups = v),
                  activeColor: _primary,
                ),
              ),
              // Specific group dropdown (only visible when not all-groups)
              if (!_allGroups) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Grupo / Categoría',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _categories
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ],
            ],
            const SizedBox(height: 24),

            // ── Section 2: Time window ─────────────────────────────────────
            const _SectionHeader(step: '2', title: 'Ventana de tiempo'),
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

            // ── Section 3: Visibility ──────────────────────────────────────
            const _SectionHeader(
                step: '3', title: 'Visibilidad de resultados'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VisibilityOption(
                    icon: Icons.visibility_off_rounded,
                    label: 'Privado',
                    subtitle: 'Solo el docente ve los resultados',
                    selected: _visibility == 'private',
                    onTap: () => setState(() => _visibility = 'private'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisibilityOption(
                    icon: Icons.visibility_rounded,
                    label: 'Público',
                    subtitle: 'Estudiantes ven sus resultados',
                    selected: _visibility == 'public',
                    onTap: () => setState(() => _visibility = 'public'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 4: Rules ───────────────────────────────────────────
            const _SectionHeader(step: '4', title: 'Reglas de evaluación'),
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
                subtitle: const Text(
                    'Los estudiantes pueden evaluarse a sí mismos'),
                value: _allowSelfEval,
                onChanged: (v) => setState(() => _allowSelfEval = v),
                activeColor: _primary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 5: Criteria ────────────────────────────────────────
            const _SectionHeader(
                step: '5', title: 'Criterios de evaluación'),
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
                      width:
                          _selectedCriteria.contains(criterion) ? 1.5 : 1,
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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(kCriteriaDescriptions[criterion] ?? '',
                        style: const TextStyle(fontSize: 12)),
                    activeColor: _primary,
                    dense: true,
                  ),
                )),
            const SizedBox(height: 32),

            // ── Submit button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
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
                    : Text(
                        _allGroups && _categories.isNotEmpty
                            ? 'Activar evaluación para ${_categories.length} grupo${_categories.length > 1 ? 's' : ''}'
                            : 'Activar Evaluación',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _ResultRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
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
                    color: selected ? _primary : const Color(0xFF6B7280),
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
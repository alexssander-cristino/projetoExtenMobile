import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const InsulinPrescriberApp());
}

class InsulinPrescriberApp extends StatelessWidget {
  const InsulinPrescriberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insulin Prescriber (Prototype)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700),
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          labelLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const PatientFormPage(),
    );
  }
}

// =================== PATIENT FORM =====================

class PatientFormPage extends StatefulWidget {
  const PatientFormPage({super.key});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _prontuarioController = TextEditingController();
  final _weightController = TextEditingController();
  final _hbA1cController = TextEditingController();
  final _creatinineController = TextEditingController();
  final _currentBgController = TextEditingController();
  final _prevTDDController = TextEditingController();

  bool isPregnant = false;
  bool isCritical = false;
  bool isPalliative = false;
  bool isPerioperative = false;
  bool onInsulinBefore = false;
  bool onSteroids = false;
  bool onVasopressors = false;
  bool onEnteral = false;
  bool useNPH = true;

  String sensitivity = 'usual';
  PrescriptionResult? _result;

  @override
  void dispose() {
    _nameController.dispose();
    _prontuarioController.dispose();
    _weightController.dispose();
    _hbA1cController.dispose();
    _creatinineController.dispose();
    _currentBgController.dispose();
    _prevTDDController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final pront = _prontuarioController.text.trim();
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final hbA1c =
        double.tryParse(_hbA1cController.text.replaceAll(',', '.'));
    final creat =
        double.tryParse(_creatinineController.text.replaceAll(',', '.'));
    final bg =
        double.tryParse(_currentBgController.text.replaceAll(',', '.')) ?? 0.0;
    final prevTDD =
        double.tryParse(_prevTDDController.text.replaceAll(',', '.')) ?? 0.0;

    String category = 'non_critical';
    if (isPregnant) category = 'pregnancy';
    else if (isCritical) category = 'critical';
    else if (isPalliative) category = 'palliative';
    else if (isPerioperative) category = 'perioperative';

    double factorKg;
    if (sensitivity == 'sensitive') {
      factorKg = 0.25;
    } else if (sensitivity == 'resistant') {
      factorKg = 0.75;
    } else {
      factorKg = 0.4;
    }

    double recommendedTDD = 0.0;
    if (prevTDD > 0) {
      if (weight > 0 && (prevTDD / weight) > 0.6) {
        factorKg = math.max(factorKg, 0.6);
      }
      recommendedTDD = prevTDD;
    }

    if (recommendedTDD == 0.0) {
      recommendedTDD = weight * factorKg;
    }

    bool preferIV = category == 'critical';

    double basal = recommendedTDD * 0.5;
    double prandialTotal = recommendedTDD - basal;
    double prandialPerMeal = prandialTotal / 3.0;

    double nphMorning = 0.0;
    double nphNight = 0.0;
    if (useNPH) {
      nphMorning = (basal * 0.6).roundToDouble();
      nphNight = (basal * 0.4).roundToDouble();
    }

    double isf = 1700.0 / (recommendedTDD <= 0 ? 1.0 : recommendedTDD);
    List<CorrectionStep> sliding = _buildSlidingScale(isf);

    IntRange targetRange;
    if (category == 'critical') {
      targetRange = IntRange(140, 180);
    } else if (category == 'pregnancy') {
      targetRange = IntRange(80, 140);
    } else if (category == 'perioperative') {
      targetRange = IntRange(100, 180);
    } else if (category == 'palliative') {
      targetRange = IntRange(150, 250);
    } else {
      targetRange = IntRange(100, 180);
    }

    final presc = PrescriptionResult(
      patientName: name,
      prontuario: pront,
      weightKg: weight,
      category: category,
      recommendedTDD: _roundToOneDecimal(recommendedTDD),
      basalUnits: _roundToOneDecimal(basal),
      prandialUnits: _roundToOneDecimal(prandialPerMeal),
      useNPH: useNPH,
      nphMorning: nphMorning,
      nphNight: nphNight,
      preferIV: preferIV,
      isf: _roundToOneDecimal(isf),
      slidingScale: sliding,
      targetRange: targetRange,
      hypoAlert: 70,
      hypoSignificant: 54,
      notes: _buildNotes(category, sensitivity, useNPH, onSteroids, onVasopressors, onEnteral),
    );

    setState(() {
      _result = presc;
    });

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PrescriptionPage(result: presc),
    ));
  }

  List<CorrectionStep> _buildSlidingScale(double isf) {
    return [
      CorrectionStep(range: IntRange(0, 140), units: 0),
      CorrectionStep(range: IntRange(141, 180), units: 0),
      CorrectionStep(range: IntRange(181, 220), units: math.max(1, ((200 - 120) / isf).round())),
      CorrectionStep(range: IntRange(221, 300), units: math.max(2, ((250 - 120) / isf).round())),
      CorrectionStep(range: IntRange(301, 400), units: math.max(3, ((350 - 120) / isf).round())),
      CorrectionStep(range: IntRange(401, 9999), units: math.max(4, ((500 - 120) / isf).round())),
    ];
  }

  double _roundToOneDecimal(double v) => (v * 10).roundToDouble() / 10.0;

  String _buildNotes(String category, String sensitivity, bool useNPH, bool steroids, bool vasopressors, bool enteral) {
    List<String> items = [];
    items.add('Categoria: ${category.replaceAll('_', ' ')}');
    items.add('Sensibilidade: $sensitivity');
    if (useNPH) items.add('Opção: NPH disponível — basal fracionada em 2 doses');
    if (steroids) items.add('Atenção: uso de corticoide — pode aumentar necessidade de insulina');
    if (vasopressors) items.add('Atenção: vasopressores podem alterar glicemia e perfusão capilar');
    if (enteral) items.add('Nutrição enteral/parenteral: medir glicemia a cada 4-6h e ajustar insulina');
    items.add('Obs: se CAD ou SHHNC, seguir protocolos específicos');
    return items.join('\n');
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insulin Prescriber - Protótipo')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildSection(
                title: 'Identificação do paciente',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _prontuarioController,
                      decoration: const InputDecoration(labelText: 'Prontuário / CPF'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final w = double.tryParse(v ?? '');
                        if (w == null || w <= 0) return 'Informe peso válido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              _buildSection(
                title: 'Dados clínicos',
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: isPregnant,
                      onChanged: (v) => setState(() => isPregnant = v ?? false),
                      title: const Text('Gestante'),
                    ),
                    CheckboxListTile(
                      value: isCritical,
                      onChanged: (v) => setState(() => isCritical = v ?? false),
                      title: const Text('Paciente crítico (UTI, suporte vasoativo, intubado)'),
                    ),
                    CheckboxListTile(
                      value: isPalliative,
                      onChanged: (v) => setState(() => isPalliative = v ?? false),
                      title: const Text('Cuidados paliativos'),
                    ),
                    CheckboxListTile(
                      value: isPerioperative,
                      onChanged: (v) => setState(() => isPerioperative = v ?? false),
                      title: const Text('Perioperatório'),
                    ),
                  ],
                ),
              ),
              _buildSection(
                title: 'Histórico e condições associadas',
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: onInsulinBefore,
                      onChanged: (v) => setState(() => onInsulinBefore = v ?? false),
                      title: const Text('Usava insulina antes da internação'),
                    ),
                    TextFormField(
                      controller: _prevTDDController,
                      decoration: const InputDecoration(
                        labelText: 'TDD prévio (U/dia) — opcional',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    CheckboxListTile(
                      value: onSteroids,
                      onChanged: (v) => setState(() => onSteroids = v ?? false),
                      title: const Text('Uso de corticoide'),
                    ),
                    CheckboxListTile(
                      value: onVasopressors,
                      onChanged: (v) => setState(() => onVasopressors = v ?? false),
                      title: const Text('Vasopressores'),
                    ),
                    CheckboxListTile(
                      value: onEnteral,
                      onChanged: (v) => setState(() => onEnteral = v ?? false),
                      title: const Text('Nutrição enteral/parenteral'),
                    ),
                  ],
                ),
              ),
              _buildSection(
                title: 'Parâmetros laboratoriais',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _hbA1cController,
                      decoration: const InputDecoration(labelText: 'HbA1c (%) — opcional'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _creatinineController,
                      decoration: const InputDecoration(labelText: 'Creatinina (mg/dL) — opcional'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentBgController,
                      decoration: const InputDecoration(labelText: 'Glicemia atual (mg/dL)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final x = double.tryParse(v ?? '');
                        if (x == null) return 'Informe glicemia atual';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              _buildSection(
                title: 'Preferências e sensibilidade',
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Usar NPH (em vez de insulina longa)'),
                      value: useNPH,
                      onChanged: (v) => setState(() => useNPH = v),
                    ),
                    const Divider(),
                    const Text('Sensibilidade insulínica:'),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Sensível'),
                            value: 'sensitive',
                            groupValue: sensitivity,
                            onChanged: (v) =>
                                setState(() => sensitivity = v ?? 'usual'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Usual'),
                            value: 'usual',
                            groupValue: sensitivity,
                            onChanged: (v) =>
                                setState(() => sensitivity = v ?? 'usual'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Resistente'),
                            value: 'resistant',
                            groupValue: sensitivity,
                            onChanged: (v) =>
                                setState(() => sensitivity = v ?? 'usual'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '⚠️ Este é um protótipo. Revise as doses e siga protocolos locais.',
                style: TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.calculate),
          label: const Text('Calcular prescrição sugerida'),
          onPressed: _calculate,
        ),
      ),
    );
  }
}

// =================== RESULT PAGE =====================

class PrescriptionPage extends StatelessWidget {
  final PrescriptionResult result;
  const PrescriptionPage({super.key, required this.result});

  Widget _buildRow(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a),
            Text(b, style: const TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescrição sugerida')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paciente: ${result.patientName}'),
                      Text('Prontuário: ${result.prontuario}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Resumo de doses',
                  style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              _buildRow('Categoria', result.category.replaceAll('_', ' ')),
              _buildRow('Peso (kg)', result.weightKg.toString()),
              _buildRow('Dose total diária (TDD)', '${result.recommendedTDD} U'),
              _buildRow('Basal', '${result.basalUnits} U'),
              _buildRow('Prandial/refeição', '${result.prandialUnits} U'),
              _buildRow('ISF (1700/TDD)', result.isf.toString()),
              const SizedBox(height: 12),
              Text('Opções de insulina basal',
                  style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              if (result.useNPH)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NPH manhã: ${result.nphMorning} U'),
                    Text('NPH noite: ${result.nphNight} U'),
                    Text('Regular pré-refeição: ${result.prandialUnits} U'),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Longa duração 1x/dia: ${result.basalUnits} U'),
                    Text('Análogo rápido nas refeições: ${result.prandialUnits} U'),
                  ],
                ),
              const SizedBox(height: 12),
              Text('Escala de correção', style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              ...result.slidingScale
                  .map((s) => Text('${s.range.min}-${s.range.max} mg/dL → ${s.units} U')),
              const SizedBox(height: 12),
              Text('Alvos glicêmicos', style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              Text('Geral: ${result.targetRange.min}-${result.targetRange.max} mg/dL'),
              if (result.category == 'pregnancy')
                const Text('Gestação: jejum <95; 1h <140; 2h <120 mg/dL'),
              const SizedBox(height: 12),
              Text('Hipoglicemia', style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              Text('Alerta ≤ ${result.hypoAlert} mg/dL — tratar com 15g CHO'),
              Text('Grave < ${result.hypoSignificant} mg/dL — D50 IV ou glucagon IM/SC'),
              const SizedBox(height: 12),
              Text('Observações', style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              Text(result.notes),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Aceitar e gerar ordem (simulação)'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Ordem gerada (simulação)'),
                      content: const Text(
                          'A ordem foi gerada no formato de protótipo. Integre ao prontuário eletrônico.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== DATA CLASSES =====================

class PrescriptionResult {
  final String patientName;
  final String prontuario;
  final double weightKg;
  final String category;
  final double recommendedTDD;
  final double basalUnits;
  final double prandialUnits;
  final bool useNPH;
  final double nphMorning;
  final double nphNight;
  final bool preferIV;
  final double isf;
  final List<CorrectionStep> slidingScale;
  final IntRange targetRange;
  final int hypoAlert;
  final int hypoSignificant;
  final String notes;

  PrescriptionResult({
    required this.patientName,
    required this.prontuario,
    required this.weightKg,
    required this.category,
    required this.recommendedTDD,
    required this.basalUnits,
    required this.prandialUnits,
    required this.useNPH,
    required this.nphMorning,
    required this.nphNight,
    required this.preferIV,
    required this.isf,
    required this.slidingScale,
    required this.targetRange,
    required this.hypoAlert,
    required this.hypoSignificant,
    required this.notes,
  });
}

class CorrectionStep {
  final IntRange range;
  final int units;
  CorrectionStep({required this.range, required this.units});
}

class IntRange {
  final int min;
  final int max;
  IntRange(this.min, this.max);
}

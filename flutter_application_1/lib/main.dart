import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(InsulinPrescriberApp());
}

class InsulinPrescriberApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insulin Prescriber (Prototype)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: PatientFormPage(),
    );
  }
}

class PatientFormPage extends StatefulWidget {
  @override
  _PatientFormPageState createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _prontuarioController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _hbA1cController = TextEditingController();
  final TextEditingController _creatinineController = TextEditingController();
  final TextEditingController _currentBgController = TextEditingController();
  final TextEditingController _prevTDDController = TextEditingController();

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
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final hbA1c = double.tryParse(_hbA1cController.text.replaceAll(',', '.'));
    final creat = double.tryParse(_creatinineController.text.replaceAll(',', '.'));
    final bg = double.tryParse(_currentBgController.text.replaceAll(',', '.')) ?? 0.0;
    final prevTDD = double.tryParse(_prevTDDController.text.replaceAll(',', '.')) ?? 0.0;

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

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PrescriptionPage(result: presc)));
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
    items.add('Categoria: ' + category.replaceAll('_', ' '));
    items.add('Sensibilidade: ' + sensitivity);
    if (useNPH) items.add('Opção: NPH disponível — basal fracionada em 2 doses');
    if (steroids) items.add('Atenção: paciente em uso de corticoide — pode aumentar necessidade de insulina');
    if (vasopressors) items.add('Atenção: vasopressores podem alterar glicemia e perfusão capilar');
    if (enteral) items.add('Nutrição enteral/parenteral: medir glicemia a cada 4-6h e ajustar insulina de correção');
    items.add('Obs: se CAD ou SHHNC, seguir protocolos específicos (não usar esquema basal-bolus convencional)');
    return items.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insulin Prescriber - Prototype (Flutter)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paciente', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: _prontuarioController,
                decoration: const InputDecoration(labelText: 'Prontuário / CPF'),
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final w = double.tryParse(v ?? '');
                  if (w == null || w <= 0) return 'Informe peso válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Dados clínicos (marque os que se aplicam)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                title: const Text('Perioperatório (pré/intra/pós)'),
              ),
              CheckboxListTile(
                value: onInsulinBefore,
                onChanged: (v) => setState(() => onInsulinBefore = v ?? false),
                title: const Text('Usava insulina antes da internação (informe TDD abaixo se sim)'),
              ),
              TextFormField(
                controller: _prevTDDController,
                decoration: const InputDecoration(labelText: 'TDD prévio (U/dia) — opcional'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                title: const Text('Nutrição enteral ou parenteral'),
              ),
              const SizedBox(height: 12),
              const Text('Parâmetros laboratoriais / glicemias', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _hbA1cController,
                decoration: const InputDecoration(labelText: 'HbA1c (%) — opcional'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: _creatinineController,
                decoration: const InputDecoration(labelText: 'Creatinina (mg/dL) — opcional'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: _currentBgController,
                decoration: const InputDecoration(labelText: 'Glicemia capilar atual (mg/dL)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final x = double.tryParse(v ?? '');
                  if (x == null) return 'Informe glicemia atual';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Preferências de insumos', style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Usar NPH (em vez de insulina longa) quando necessário'),
                value: useNPH,
                onChanged: (v) => setState(() => useNPH = v),
              ),
              const SizedBox(height: 12),
              const Text('Sensibilidade insulínica (selecione a estimativa)'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Sensível'),
                      value: 'sensitive',
                      groupValue: sensitivity,
                      onChanged: (v) => setState(() => sensitivity = v ?? 'usual'),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Usual'),
                      value: 'usual',
                      groupValue: sensitivity,
                      onChanged: (v) => setState(() => sensitivity = v ?? 'usual'),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Resistente'),
                      value: 'resistant',
                      groupValue: sensitivity,
                      onChanged: (v) => setState(() => sensitivity = v ?? 'usual'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular prescrição sugerida'),
                onPressed: _calculate,
              ),
              const SizedBox(height: 20),
              const Text('Observação: este é um protótipo. Sempre revise as doses e siga as diretrizes locais.'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class PrescriptionPage extends StatelessWidget {
  final PrescriptionResult result;
  const PrescriptionPage({Key? key, required this.result}) : super(key: key);

  Widget _buildRow(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(a), Text(b, style: const TextStyle(fontWeight: FontWeight.bold))],
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
              Text('Paciente: ${result.patientName}  |  Prontuário: ${result.prontuario}'),
              const SizedBox(height: 12),
              Text('Resumo de doses', style: Theme.of(context).textTheme.titleLarge),
              _buildRow('Categoria', result.category.replaceAll('_', ' ')),
              _buildRow('Peso (kg)', result.weightKg.toString()),
              _buildRow('Dose total diária sugerida (U/dia)', result.recommendedTDD.toString()),
              _buildRow('Basal (U/dia)', result.basalUnits.toString()),
              _buildRow('Prandial por refeição (U)', result.prandialUnits.toString()),
              _buildRow('ISF (1700/TDD)', result.isf.toString()),
              const SizedBox(height: 12),
              const Text('Opções para insulina basal', style: TextStyle(fontWeight: FontWeight.bold)),
              result.useNPH
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Usar NPH (fracionada em 2 doses):'),
                        Text(' - NPH manhã: ${result.nphMorning.toString()} U'),
                        Text(' - NPH noite: ${result.nphNight.toString()} U'),
                        const SizedBox(height: 8),
                        Text('Usar Regular antes das refeições: ${result.prandialUnits} U (30 min antes)'),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Usar insulina longa (glargina/detemir) 1x/dia: ${result.basalUnits} U'),
                        Text('Prandial: análogo rápido antes das refeições: ${result.prandialUnits} U'),
                      ],
                    ),
              const SizedBox(height: 12),
              const Text('Escala de correção (sliding-scale orientativa):', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.slidingScale.map((s) => Text('${s.range.min}-${s.range.max} mg/dL -> ${s.units} U')),
              const SizedBox(height: 12),
              const Text('Alvos glicêmicos', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(' - Alvo geral: ${result.targetRange.min} - ${result.targetRange.max} mg/dL'),
              if (result.category == 'pregnancy')
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  SizedBox(height: 6),
                  Text('Metas na gestação (exemplos): jejum <95 mg/dL; 1h pós-prandial <140 mg/dL; 2h <120 mg/dL'),
                ]),
              const SizedBox(height: 12),
              const Text('Hipoglicemia - protocolo resumido', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(' - Alerta: ≤ ${result.hypoAlert} mg/dL -> tratar com 15 g CHO oral se consciente; reavaliar 15 min'),
              Text(' - Significativo: < ${result.hypoSignificant} mg/dL -> tratamento imediato, considerar D50 IV ou glucagon IM/SC'),
              const SizedBox(height: 12),
              const Text('Observações e avisos', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      content: const Text('A ordem médica foi gerada no formato do protótipo. Integrar com o prontuário eletrônico para produção real.'),
                      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Calculos detalhado (transparência):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('ISF = 1700 / TDD = ${result.isf} (1U reduz ~${result.isf} mg/dL)'),
              Text('Basal = 50% * TDD = ${result.basalUnits} U/dia'),
              Text('Prandial total = TDD - basal = ${(result.recommendedTDD - result.basalUnits).toStringAsFixed(1)} U (dividido em 3 refeições = ${result.prandialUnits} U/refeição)'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Data classes
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

import 'package:flutter/material.dart';
import '../models/prescription_result.dart';
import '../widgets/navbar.dart';

class PrescricaoPage extends StatelessWidget {
  final PrescriptionResult? result;
  const PrescricaoPage({super.key, this.result});

  Widget _buildRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final res = result ??
        PrescriptionResult(
          patientName: 'Paciente Exemplo',
          prontuario: '0001',
          weightKg: 70,
          category: 'não crítico',
          recommendedTDD: 28,
          basalUnits: 14,
          prandialUnits: 4.5,
          useNPH: true,
          nphMorning: 8,
          nphNight: 6,
          preferIV: false,
          isf: 60,
          slidingScale: [
            CorrectionStep(range: IntRange(0, 140), units: 0),
            CorrectionStep(range: IntRange(141, 200), units: 1),
            CorrectionStep(range: IntRange(201, 300), units: 2),
          ],
          targetRange: IntRange(100, 180),
          hypoAlert: 70,
          hypoSignificant: 54,
          notes: 'Ajustar conforme evolução.',
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Prescrição Sugerida')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Paciente: ${res.patientName}  |  Prontuário: ${res.prontuario}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              'Resumo de Doses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildRow('Peso (kg)', '${res.weightKg}'),
            _buildRow('TDD sugerida (U/dia)', '${res.recommendedTDD}'),
            _buildRow('Basal (U/dia)', '${res.basalUnits}'),
            _buildRow('Prandial/refeição (U)', '${res.prandialUnits}'),
            _buildRow('ISF', '${res.isf}'),
            const SizedBox(height: 20),
            const Text('Escala de Correção:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            ...res.slidingScale.map(
              (s) => Text('${s.range.min}-${s.range.max} mg/dL → ${s.units} U'),
            ),
            const SizedBox(height: 20),
            const Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(res.notes),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.timeline),
              label: const Text('Ir para Acompanhamento'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pushNamed(context, '/acompanhamento'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 4),
    );
  }
}

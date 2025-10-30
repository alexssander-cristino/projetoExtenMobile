import 'package:flutter/material.dart';

class ProtocoloPage extends StatelessWidget {
  const ProtocoloPage({super.key});

  Widget _buildCard(String title, String body, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protocolos de Insulina')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            'Gestante',
            'Alvo glicêmico: jejum <95 mg/dL, 1h pós-prandial <140 mg/dL.\nUsar insulina NPH e regular, com acompanhamento diário.',
            Icons.pregnant_woman,
            Colors.pink,
          ),
          _buildCard(
            'Crítico (UTI)',
            'Manter glicemia entre 140–180 mg/dL.\nPreferir insulina IV contínua.\nReavaliar glicemias a cada 1–2h.',
            Icons.local_hospital,
            Colors.redAccent,
          ),
          _buildCard(
            'Paliativo',
            'Evitar hipoglicemia.\nAjustar alvos para 150–250 mg/dL.\nEvitar esquema intensivo.',
            Icons.self_improvement,
            Colors.orange,
          ),
          _buildCard(
            'Perioperatório',
            'Manter glicemia entre 100–180 mg/dL.\nSuspender análogos de ação prolongada no dia da cirurgia.',
            Icons.healing,
            Colors.green,
          ),
          _buildCard(
            'Não crítico',
            'Alvo glicêmico: 100–180 mg/dL.\nUsar esquema basal-bolus com correções conforme escala deslizante.',
            Icons.people,
            Colors.blueAccent,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.medication),
            label: const Text('Gerar Prescrição'),
            onPressed: () => Navigator.pushNamed(context, '/prescricao'),
          ),
        ],
      ),
    );
  }
}

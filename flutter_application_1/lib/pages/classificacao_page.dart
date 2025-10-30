import 'package:flutter/material.dart';

class ClassificacaoPage extends StatefulWidget {
  const ClassificacaoPage({super.key});

  @override
  State<ClassificacaoPage> createState() => _ClassificacaoPageState();
}

class _ClassificacaoPageState extends State<ClassificacaoPage> {
  bool isPregnant = false;
  bool isCritical = false;
  bool isPalliative = false;
  bool isPerioperative = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classificação do Paciente')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CheckboxListTile(
            value: isPregnant,
            onChanged: (v) => setState(() => isPregnant = v ?? false),
            title: const Text('Gestante'),
          ),
          CheckboxListTile(
            value: isCritical,
            onChanged: (v) => setState(() => isCritical = v ?? false),
            title: const Text('Crítico (UTI, suporte vasoativo)'),
          ),
          CheckboxListTile(
            value: isPalliative,
            onChanged: (v) => setState(() => isPalliative = v ?? false),
            title: const Text('Paliativo'),
          ),
          CheckboxListTile(
            value: isPerioperative,
            onChanged: (v) => setState(() => isPerioperative = v ?? false),
            title: const Text('Perioperatório'),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.assignment),
            label: const Text('Ver protocolo'),
            onPressed: () => Navigator.pushNamed(context, '/protocolo'),
          ),
        ],
      ),
    );
  }
}

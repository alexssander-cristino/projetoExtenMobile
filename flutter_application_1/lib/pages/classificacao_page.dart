import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

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
          const SizedBox(height: 10),
          const Text(
            'Selecione o tipo de paciente:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                CheckboxListTile(
                  value: isPregnant,
                  onChanged: (v) => setState(() => isPregnant = v ?? false),
                  title: const Text('Gestante'),
                  secondary: const Icon(Icons.pregnant_woman),
                ),
                const Divider(height: 0),
                CheckboxListTile(
                  value: isCritical,
                  onChanged: (v) => setState(() => isCritical = v ?? false),
                  title: const Text('Crítico (UTI, suporte vasoativo)'),
                  secondary: const Icon(Icons.monitor_heart),
                ),
                const Divider(height: 0),
                CheckboxListTile(
                  value: isPalliative,
                  onChanged: (v) => setState(() => isPalliative = v ?? false),
                  title: const Text('Paliativo'),
                  secondary: const Icon(Icons.spa),
                ),
                const Divider(height: 0),
                CheckboxListTile(
                  value: isPerioperative,
                  onChanged: (v) => setState(() => isPerioperative = v ?? false),
                  title: const Text('Perioperatório'),
                  secondary: const Icon(Icons.local_hospital),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.assignment),
            label: const Text('Ver Protocolo'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => Navigator.pushNamed(context, '/protocolo'),
          ),
        ],
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 2),
    );
  }
}

import 'package:flutter/material.dart';

class AcompanhamentoPage extends StatefulWidget {
  const AcompanhamentoPage({super.key});

  @override
  State<AcompanhamentoPage> createState() => _AcompanhamentoPageState();
}

class _AcompanhamentoPageState extends State<AcompanhamentoPage> {
  final _bgController = TextEditingController();
  final List<double> _readings = [];

  void _addReading() {
    final val = double.tryParse(_bgController.text.replaceAll(',', '.'));
    if (val != null) {
      setState(() => _readings.add(val));
      _bgController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acompanhamento Glicêmico')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _bgController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Glicemia atual (mg/dL)',
                suffixIcon: Icon(Icons.bloodtype),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Registrar leitura'),
              onPressed: _addReading,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _readings.isEmpty
                  ? const Center(child: Text('Nenhuma leitura registrada'))
                  : ListView.builder(
                      itemCount: _readings.length,
                      itemBuilder: (_, i) {
                        final bg = _readings[i];
                        Color color = bg < 70
                            ? Colors.orange
                            : bg > 180
                                ? Colors.red
                                : Colors.green;
                        return ListTile(
                          leading: Icon(Icons.analytics, color: color),
                          title: Text('Leitura ${i + 1}: $bg mg/dL'),
                          subtitle: Text(bg < 70
                              ? 'Hipoglicemia'
                              : bg > 180
                                  ? 'Hiperglicemia'
                                  : 'Dentro da meta'),
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Finalizar e ir para Alta'),
              onPressed: () => Navigator.pushNamed(context, '/alta'),
            ),
          ],
        ),
      ),
    );
  }
}

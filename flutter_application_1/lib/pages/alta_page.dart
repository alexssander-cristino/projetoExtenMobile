import 'package:flutter/material.dart';

class AltaPage extends StatelessWidget {
  const AltaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alta do Paciente')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Atendimento Finalizado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'O caso foi encerrado com sucesso.\nCertifique-se de registrar as informações no prontuário eletrônico.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Voltar ao Início'),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/inicio', (_) => false),
            ),
          ],
        ),
      ),
    );
  }
}

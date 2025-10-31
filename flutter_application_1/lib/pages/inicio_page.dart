import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insulin Prescriber')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo ao Insulin Prescriber',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Novo Cadastro de Paciente'),
              onPressed: () => Navigator.pushNamed(context, '/cadastro'),
            ),
          ],
        ),
      ),
      // 👇 adiciona a NavBar no final
      bottomNavigationBar: const NavBar(selectedIndex: 0),
    );
  }
}

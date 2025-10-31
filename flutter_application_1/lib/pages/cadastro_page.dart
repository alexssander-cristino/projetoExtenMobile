import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/navbar.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prontuarioController = TextEditingController();
  final _weightController = TextEditingController();
  final _creatininaController = TextEditingController();
  final _idadeController = TextEditingController();

  bool _isCorticoide = false;
  bool _isMulher = false;
  String? _escalaDispositivo;

  double calcularTFG(double scr, int idade, bool mulher) {
    const double kappa = 0.7;
    const double alfaMulher = -0.241;
    const double alfaHomem = -0.302;

    double minScr = scr / kappa;
    double maxScr = scr / kappa;

    double tfg = 142 *
        (minScr < 1 ? pow(minScr, mulher ? alfaMulher : alfaHomem) : 1) *
        (maxScr > 1 ? pow(maxScr, -1.200) : 1) *
        pow(0.9938, idade) *
        (mulher ? 1.012 : 1.0);

    return tfg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro do Paciente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: _prontuarioController,
                decoration:
                    const InputDecoration(labelText: 'Prontuário / CPF'),
              ),
              TextFormField(
                controller: _idadeController,
                decoration: const InputDecoration(labelText: 'Idade'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('Sexo feminino?'),
                value: _isMulher,
                onChanged: (v) => setState(() => _isMulher = v),
              ),
              SwitchListTile(
                title: const Text(
                    'Paciente em uso de corticoide? (Insulino-resistente)'),
                value: _isCorticoide,
                onChanged: (v) => setState(() => _isCorticoide = v),
              ),
              TextFormField(
                controller: _creatininaController,
                decoration: const InputDecoration(
                    labelText: 'Creatinina sérica (mg/dL)'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Escala do dispositivo de insulina',
                ),
                items: const [
                  DropdownMenuItem(
                    value: '1',
                    child: Text('1 unidade (caneta ou seringa 1/1)'),
                  ),
                  DropdownMenuItem(
                    value: '2',
                    child: Text('2 unidades (seringa 2/2)'),
                  ),
                ],
                onChanged: (v) => setState(() => _escalaDispositivo = v),
                validator: (v) =>
                    v == null ? 'Selecione a escala do dispositivo' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Avançar para Classificação'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_creatininaController.text.isNotEmpty &&
                        _idadeController.text.isNotEmpty) {
                      double scr =
                          double.tryParse(_creatininaController.text) ?? 0;
                      int idade = int.tryParse(_idadeController.text) ?? 0;
                      double tfg = calcularTFG(scr, idade, _isMulher);
                      debugPrint('TFG estimada: ${tfg.toStringAsFixed(2)}');
                    }

                    Navigator.pushNamed(
                      context,
                      '/classificacao',
                      arguments: {
                        'nome': _nameController.text,
                        'peso': _weightController.text,
                        'corticoide': _isCorticoide,
                        'escala': _escalaDispositivo,
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 1), // 👈 Adiciona a NavBar
    );
  }
}

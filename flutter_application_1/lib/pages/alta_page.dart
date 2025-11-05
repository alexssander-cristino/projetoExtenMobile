import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../services/api_service.dart';

class AltaPage extends StatefulWidget {
  const AltaPage({super.key});

  @override
  State<AltaPage> createState() => _AltaPageState();
}

class _AltaPageState extends State<AltaPage> {
  Map<String, dynamic>? _paciente;
  final _resumoController = TextEditingController();
  bool _isLoading = false;
  bool _altaRegistrada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paciente == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _paciente = args;
        });
      }
    }
  }

  @override
  void dispose() {
    _resumoController.dispose();
    super.dispose();
  }

  Future<void> _registrarAlta() async {
    if (_paciente == null || _resumoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Preencha o resumo da alta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dadosAlta = {
        'paciente_id': _paciente!['id'],
        'resumo': _resumoController.text.trim(),
      };

      await ApiService.registrarAlta(dadosAlta);

      setState(() {
        _altaRegistrada = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alta registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao registrar alta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getNomeCenario(int cenario) {
    switch (cenario) {
      case 1: return 'Não crítico';
      case 2: return 'Gestante';
      case 3: return 'Crítico';
      case 4: return 'Paliativo';
      case 5: return 'Perioperatório';
      default: return 'Não definido';
    }
  }

  Widget _buildResumoItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_paciente == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alta do Paciente')),
        body: const Center(
          child: Text('Erro: Dados do paciente não encontrados'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alta do Paciente'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status da alta
            Icon(
              _altaRegistrada ? Icons.check_circle : Icons.assignment_turned_in,
              color: _altaRegistrada ? Colors.green : Colors.orange,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              _altaRegistrada ? 'Alta Registrada' : 'Registrar Alta',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Dados do paciente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do Atendimento',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildResumoItem('Paciente', _paciente!['nome'] ?? 'Não informado'),
                    _buildResumoItem('Idade/Sexo', '${_paciente!['idade']} anos • ${_paciente!['sexo'] == 'F' ? 'Feminino' : 'Masculino'}'),
                    _buildResumoItem('Peso', '${_paciente!['peso']} kg'),
                    if (_paciente!['imc'] != null)
                      _buildResumoItem('IMC', '${_paciente!['imc']?.toStringAsFixed(1)} kg/m²'),
                    if (_paciente!['egfr'] != null)
                      _buildResumoItem('TFG', '${_paciente!['egfr']?.toStringAsFixed(0)} mL/min/1,73m²'),
                    _buildResumoItem('Local', _paciente!['local_internacao'] ?? 'Não informado'),
                    _buildResumoItem('Cenário', _getNomeCenario(_paciente!['cenario'])),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (!_altaRegistrada) ...[
              // Formulário de alta
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo da Alta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _resumoController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Descreva:\n• Condições de alta\n• Medicações prescritas\n• Orientações ao paciente\n• Follow-up necessário',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _registrarAlta,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? 'Salvando...' : 'Registrar Alta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Alta já registrada
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Atendimento Finalizado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'O caso foi encerrado com sucesso. As informações foram registradas no sistema.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumo da Alta:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(_resumoController.text),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Botões de navegação
            Row(
              children: [
                if (!_altaRegistrada) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/acompanhamento',
                        arguments: _paciente,
                      ),
                      icon: const Icon(Icons.timeline),
                      label: const Text('Acompanhamento'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text('Voltar ao Início'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/inicio',
                      (_) => false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
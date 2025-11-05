import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../widgets/navbar.dart';
import '../services/api_service.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers básicos
  final _nameController = TextEditingController();
  final _idadeController = TextEditingController(text: '28');
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '165');
  final _creatController = TextEditingController(text: '0.8');

  // Estados
  String _sexo = 'M';
  String _local = 'Enfermaria';
  double _imc = 0;
  double _eGFR = 0;
  int _cenarioSelecionado = 1;
  bool _isLoading = false;
  
  // Status de conectividade
  bool _apiConectada = false;
  bool _testandoConexao = false;
  String _statusConexao = 'Verificando...';

  @override
  void initState() {
    super.initState();
    _calcularBasicos();
    _testarConexaoInicial();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idadeController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _creatController.dispose();
    super.dispose();
  }

  Future<void> _testarConexaoInicial() async {
    setState(() {
      _testandoConexao = true;
      _statusConexao = 'Verificando conexão...';
    });

    try {
      bool conectada = await ApiService.testarConexao();
      setState(() {
        _apiConectada = conectada;
        _statusConexao = conectada ? 'Conectado ao banco' : 'Sem conexão com API';
        _testandoConexao = false;
      });
    } catch (e) {
      setState(() {
        _apiConectada = false;
        _statusConexao = 'Erro de conexão';
        _testandoConexao = false;
      });
    }
  }

  Future<void> _testarConexaoManual() async {
    setState(() => _testandoConexao = true);

    try {
      bool conectada = await ApiService.testarConexao();
      setState(() {
        _apiConectada = conectada;
        _statusConexao = conectada ? 'Conectado ao banco' : 'Sem conexão com API';
        _testandoConexao = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(conectada ? '✅ API Conectada!' : '❌ API Desconectada'),
            backgroundColor: conectada ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _apiConectada = false;
        _statusConexao = 'Erro: $e';
        _testandoConexao = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  double _ckdEpi2021(double scr, int age, String sex) {
    if (scr <= 0) return 0;
    
    final k = (sex == 'F') ? 0.7 : 0.9;
    final a = (sex == 'F') ? -0.241 : -0.302;
    
    final minPart = min(scr / k, 1.0);
    final maxPart = max(scr / k, 1.0);
    
    final eGFR = 142 * 
        pow(minPart, a) * 
        pow(maxPart, -1.200) * 
        pow(0.9938, age) * 
        ((sex == 'F') ? 1.012 : 1.0);
    
    return eGFR.toDouble();
  }

  void _calcularBasicos() {
    final idade = int.tryParse(_idadeController.text) ?? 0;
    final peso = double.tryParse(_weightController.text) ?? 0;
    final altura = double.tryParse(_heightController.text) ?? 0;
    final creat = double.tryParse(_creatController.text) ?? 0;

    setState(() {
      _imc = (peso > 0 && altura > 0) ? peso / pow(altura / 100, 2) : 0;
      _eGFR = _ckdEpi2021(creat, idade, _sexo);
    });
  }

  // 🆕 NOVO: Método apenas para salvar (sem navegar)
  Future<void> _salvarPaciente() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_apiConectada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Sem conexão com a API. Teste a conexão primeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final dadosPaciente = {
        'nome': _nameController.text.trim(),
        'sexo': _sexo,
        'idade': int.tryParse(_idadeController.text) ?? 0,
        'peso': double.tryParse(_weightController.text) ?? 0,
        'altura': double.tryParse(_heightController.text) ?? 0,
        'creatinina': double.tryParse(_creatController.text) ?? 0,
        'local_internacao': _local,
        'imc': _imc,
        'egfr': _eGFR,
        'cenario': _cenarioSelecionado,
        'data_cadastro': DateTime.now().toIso8601String(),
      };

      final resultado = await ApiService.criarPaciente(dadosPaciente);
      
      if (mounted) {
        // 🎉 Sucesso: Mostrar dialog com opções
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('Paciente Cadastrado!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_nameController.text} foi cadastrado com sucesso.'),
                const SizedBox(height: 8),
                Text('ID: ${resultado['id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _limparFormulario();
                },
                child: const Text('Cadastrar Outro'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/classificacao'); // Ir para lista de pacientes
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Ver Pacientes'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao cadastrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🆕 NOVO: Limpar formulário para novo cadastro
  void _limparFormulario() {
    _nameController.clear();
    _idadeController.text = '28';
    _weightController.text = '70';
    _heightController.text = '165';
    _creatController.text = '0.8';
    setState(() {
      _sexo = 'M';
      _local = 'Enfermaria';
      _cenarioSelecionado = 1;
      _imc = 0;
      _eGFR = 0;
    });
    _calcularBasicos();
  }

  void _escolherCenario(int cenario) {
    setState(() => _cenarioSelecionado = cenario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro do Paciente'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _testandoConexao ? null : _testarConexaoManual,
            icon: _testandoConexao
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Testar Conexão API',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status de conectividade
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _apiConectada ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: _apiConectada ? Colors.green : Colors.red,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testandoConexao
                          ? Icons.sync
                          : _apiConectada
                              ? Icons.check_circle
                              : Icons.error,
                      color: _testandoConexao
                          ? Colors.blue
                          : _apiConectada
                              ? Colors.green
                              : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusConexao,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _testandoConexao
                              ? Colors.blue[700]
                              : _apiConectada
                                  ? Colors.green[700]
                                  : Colors.red[700],
                        ),
                      ),
                    ),
                    if (!_testandoConexao)
                      TextButton(
                        onPressed: _testarConexaoManual,
                        child: const Text(
                          'Testar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Card principal
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastro do Paciente',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Primeira linha - Nome
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nome',
                        placeholder: 'Nome completo',
                        validator: (v) => v?.trim().isEmpty == true ? 'Nome é obrigatório' : null,
                        onChanged: (_) => _calcularBasicos(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Segunda linha - Sexo e Idade
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Sexo'),
                                DropdownButtonFormField<String>(
                                  value: _sexo,
                                  decoration: _buildInputDecoration(),
                                  items: const [
                                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                                    DropdownMenuItem(value: 'F', child: Text('Feminino')),
                                  ],
                                  onChanged: (v) {
                                    setState(() => _sexo = v!);
                                    _calcularBasicos();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _idadeController,
                              label: 'Idade (anos)',
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null ? 'Idade inválida' : null,
                              onChanged: (_) => _calcularBasicos(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Terceira linha - Peso e Altura
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _weightController,
                              label: 'Peso (kg)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => double.tryParse(v ?? '') == null ? 'Peso inválido' : null,
                              onChanged: (_) => _calcularBasicos(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _heightController,
                              label: 'Altura (cm)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => double.tryParse(v ?? '') == null ? 'Altura inválida' : null,
                              onChanged: (_) => _calcularBasicos(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Quarta linha - Creatinina e Local
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _creatController,
                              label: 'Creatinina (mg/dL)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => _calcularBasicos(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Local de internação'),
                                DropdownButtonFormField<String>(
                                  value: _local,
                                  decoration: _buildInputDecoration(),
                                  items: const [
                                    DropdownMenuItem(value: 'Enfermaria', child: Text('Enfermaria')),
                                    DropdownMenuItem(value: 'UTI', child: Text('UTI')),
                                    DropdownMenuItem(value: 'Centro cirúrgico', child: Text('Centro cirúrgico')),
                                    DropdownMenuItem(value: 'Obstetrícia', child: Text('Obstetrícia')),
                                  ],
                                  onChanged: (v) => setState(() => _local = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Resultados dos cálculos
                      if (_imc > 0 || _eGFR > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  if (_imc > 0) ...[
                                    Expanded(
                                      child: Text(
                                        'IMC: ${_imc.toStringAsFixed(1)} kg/m²',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  if (_eGFR > 0) ...[
                                    Expanded(
                                      child: Text(
                                        'TFG (CKD-EPI 2021): ${_eGFR.toStringAsFixed(0)} mL/min/1,73m²',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Dados calculados automaticamente.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Classificação Clínica
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Classificação Clínica',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Botões de cenário
                      _buildCenarioButton(
                        cenario: 1,
                        titulo: '1) Não crítico (Diabetes mellitus prévio/Hiperglicemia hospitalar)',
                        isSelected: _cenarioSelecionado == 1,
                      ),
                      const SizedBox(height: 8),
                      _buildCenarioButton(
                        cenario: 2,
                        titulo: '2) Gestante (Diabetes mellitus prévio/Diabetes mellitus gestacional)',
                        isSelected: _cenarioSelecionado == 2,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 8),
                      _buildCenarioButton(
                        cenario: 3,
                        titulo: '3) Paciente crítico',
                        isSelected: _cenarioSelecionado == 3,
                      ),
                      const SizedBox(height: 8),
                      _buildCenarioButton(
                        cenario: 4,
                        titulo: '4) Cuidados paliativos',
                        isSelected: _cenarioSelecionado == 4,
                      ),
                      const SizedBox(height: 8),
                      _buildCenarioButton(
                        cenario: 5,
                        titulo: '5) Perioperatório',
                        isSelected: _cenarioSelecionado == 5,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botões de ação
              Row(
                children: [
                  // 🆕 NOVO: Botão para limpar
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _limparFormulario,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Botão principal para salvar
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (_isLoading || !_apiConectada) ? null : _salvarPaciente,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading
                            ? 'Salvando...'
                            : _apiConectada
                                ? 'Cadastrar Paciente'
                                : 'Conecte-se à API primeiro',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 1),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _buildInputDecoration(placeholder: placeholder),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF616161),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? placeholder}) {
    return InputDecoration(
      hintText: placeholder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1976D2)),
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }

  Widget _buildCenarioButton({
    required int cenario,
    required String titulo,
    required bool isSelected,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _escolherCenario(cenario),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (isPrimary ? const Color(0xFF1976D2) : const Color(0xFFBBDEFB))
              : const Color(0xFFBBDEFB),
          foregroundColor: isSelected
              ? (isPrimary ? Colors.white : const Color(0xFF0d2a4d))
              : const Color(0xFF0d2a4d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: isSelected ? 4 : 2,
        ),
        child: Text(
          titulo,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
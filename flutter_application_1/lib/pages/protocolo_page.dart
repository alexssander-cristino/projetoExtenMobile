import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

class ProtocoloPage extends StatefulWidget {
  const ProtocoloPage({super.key});

  @override
  State<ProtocoloPage> createState() => _ProtocoloPageState();
}

class _ProtocoloPageState extends State<ProtocoloPage> with TickerProviderStateMixin {
  Map<String, dynamic> _dadosPaciente = {};
  
  // Controllers
  final _glicemiaAtualController = TextEditingController(text: '220');
  final _igSemanasController = TextEditingController(text: '28');
  
  // Estados do protocolo
  String _dieta = 'oral_ba';
  String _corticoide = 'nao';
  String _hepato = 'nao';
  String _sensib = 'usual';
  String _stepProto = '1';
  String _basalTipo = 'nph';
  String _nphPosologia = '3x';
  String _rapidaTipo = 'regular';
  String _bolusThreshold = '100';
  
  // Específicos por cenário
  String _tipoGest = 'dmprevio';
  String _estadoCritico = 'uti';
  String _nivelPaliativo = 'limitado';
  String _tipoCircurgia = 'eletiva';
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _dadosPaciente = args;
      _autoSugerirSensibilidade();
      _ajustarParametrosPorCenario();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glicemiaAtualController.dispose();
    _igSemanasController.dispose();
    super.dispose();
  }

  void _autoSugerirSensibilidade() {
    final imc = _dadosPaciente['imc'] ?? 0.0;
    final cenario = _dadosPaciente['cenario'] ?? 1;
    String sug = 'usual';
    
    if (imc < 22) sug = 'sensivel';
    if (imc > 30) sug = 'resistente';
    
    // Ajustes por cenário
    if (cenario == 2) sug = 'resistente'; // Gestantes tendem a ser mais resistentes
    if (cenario == 3) sug = 'resistente'; // Críticos são mais resistentes
    if (cenario == 4) sug = 'sensivel';   // Paliativos são mais sensíveis
    
    setState(() => _sensib = sug);
  }

  void _ajustarParametrosPorCenario() {
    final cenario = _dadosPaciente['cenario'] ?? 1;
    
    switch (cenario) {
      case 2: // Gestante
        _dieta = 'oral_ba';
        _bolusThreshold = '70'; // Meta mais rigorosa
        _glicemiaAtualController.text = '180';
        break;
      case 3: // Crítico
        _basalTipo = 'glargina';
        _bolusThreshold = '140'; // Meta menos rigorosa
        _glicemiaAtualController.text = '250';
        break;
      case 4: // Paliativo
        _bolusThreshold = '140';
        _glicemiaAtualController.text = '200';
        break;
      case 5: // Perioperatório
        _dieta = 'npo';
        _bolusThreshold = '100';
        _glicemiaAtualController.text = '160';
        break;
    }
  }

  void _ajustaSugestaoSens() {
    _autoSugerirSensibilidade();
    String sug = _sensib;
    
    if (['pred_baixa', 'pred_media', 'pred_alta'].contains(_corticoide)) {
      if (sug == 'sensivel') {
        sug = 'usual';
      } else if (sug == 'usual') {
        sug = 'resistente';
      }
    }
    
    setState(() => _sensib = sug);
  }

  void _calcularPrescricao() {
    Navigator.pushNamed(
      context,
      '/prescricao',
      arguments: {
        ..._dadosPaciente,
        'dieta': _dieta,
        'corticoide': _corticoide,
        'hepato': _hepato,
        'sensib': _sensib,
        'stepProto': _stepProto,
        'basalTipo': _basalTipo,
        'nphPosologia': _nphPosologia,
        'rapidaTipo': _rapidaTipo,
        'bolusThreshold': _bolusThreshold,
        'glicemiaAtual': _glicemiaAtualController.text,
        // Específicos
        'tipoGest': _tipoGest,
        'igSemanas': _igSemanasController.text,
        'estadoCritico': _estadoCritico,
        'nivelPaliativo': _nivelPaliativo,
        'tipoCircurgia': _tipoCircurgia,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cenario = _dadosPaciente['cenario'] ?? 1;
    final nomesCenario = [
      '',
      'Não crítico',
      'Gestante',
      'Crítico',
      'Paliativo',
      'Perioperatório'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Protocolo — ${nomesCenario[cenario]}'),
        backgroundColor: _getCorCenario(cenario),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getCorCenario(cenario).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: FadeTransition(
              opacity: _slideAnimation,
              child: Column(
                children: [
                  _buildDadosPaciente(),
                  const SizedBox(height: 16),
                  _buildProtocoloEspecifico(cenario),
                  const SizedBox(height: 16),
                  _buildInsulinas(cenario),
                  const SizedBox(height: 20),
                  _buildBotoes(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCorCenario(int cenario) {
    switch (cenario) {
      case 1: return const Color(0xFF1976D2);
      case 2: return const Color(0xFFE91E63);
      case 3: return const Color(0xFFD32F2F);
      case 4: return const Color(0xFF7B1FA2);
      case 5: return const Color(0xFFFF9800);
      default: return const Color(0xFF1976D2);
    }
  }

  Widget _buildDadosPaciente() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _getCorCenario(_dadosPaciente['cenario'] ?? 1).withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getCorCenario(_dadosPaciente['cenario'] ?? 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _dadosPaciente['sexo'] == 'F' ? Icons.female : Icons.male,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dadosPaciente['nome'] ?? 'Paciente',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_dadosPaciente['idade']} anos • ${_dadosPaciente['peso']} kg • IMC: ${(_dadosPaciente['imc'] ?? 0).toStringAsFixed(1)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocoloEspecifico(int cenario) {
    switch (cenario) {
      case 2: return _buildProtocoloGestante();
      case 3: return _buildProtocoloCritico();
      case 4: return _buildProtocoloPaliativo();
      case 5: return _buildProtocoloPerioperatorio();
      default: return _buildProtocoloNaoCritico();
    }
  }

  Widget _buildProtocoloGestante() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pregnant_woman, color: _getCorCenario(2)),
                const SizedBox(width: 8),
                const Text(
                  'Protocolo Gestante',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'METAS RIGOROSAS:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('• Jejum: < 95 mg/dL'),
                  const Text('• 1h pós-prandial: < 140 mg/dL'),
                  const Text('• 2h pós-prandial: < 120 mg/dL'),
                  const Text('• Evitar hipoglicemia < 60 mg/dL'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _igSemanasController,
                    label: 'Idade gestacional (semanas)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown('Tipo', _tipoGest, [
                    {'value': 'dmprevio', 'label': 'DM prévio'},
                    {'value': 'dmg', 'label': 'DM gestacional'},
                  ], (v) => setState(() => _tipoGest = v!)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocoloCritico() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: _getCorCenario(3)),
                const SizedBox(width: 8),
                const Text(
                  'Protocolo Crítico',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROTOCOLO UTI:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('• Meta: 140-180 mg/dL'),
                  const Text('• Glicemia a cada 1-4h'),
                  const Text('• Preferir insulina IV se instável'),
                  const Text('• Evitar hipoglicemia < 70 mg/dL'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown('Estado do paciente', _estadoCritico, [
              {'value': 'uti', 'label': 'UTI Geral'},
              {'value': 'coronario', 'label': 'UTI Coronariana'},
              {'value': 'pos_op', 'label': 'Pós-operatório complexo'},
              {'value': 'sepse', 'label': 'Sepse/Choque'},
              {'value': 'trauma', 'label': 'Trauma grave'},
            ], (v) => setState(() => _estadoCritico = v!)),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocoloPaliativo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa, color: _getCorCenario(4)),
                const SizedBox(width: 8),
                const Text(
                  'Protocolo Paliativo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FOCO NO CONFORTO:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('• Meta: 100-250 mg/dL (flexível)'),
                  const Text('• EVITAR hipoglicemia'),
                  const Text('• Esquema simplificado'),
                  const Text('• Priorizar qualidade de vida'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown('Nível de cuidados', _nivelPaliativo, [
              {'value': 'limitado', 'label': 'Suporte limitado'},
              {'value': 'exclusivo', 'label': 'Cuidados exclusivos'},
              {'value': 'transicao', 'label': 'Transição de cuidados'},
            ], (v) => setState(() => _nivelPaliativo = v!)),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocoloPerioperatorio() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.healing, color: _getCorCenario(5)),
                const SizedBox(width: 8),
                const Text(
                  'Protocolo Perioperatório',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MANEJO CIRÚRGICO:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('• Meta: 100-180 mg/dL'),
                  const Text('• Suspender análogos longos no dia da cirurgia'),
                  const Text('• Preferir insulina regular no intraoperatório'),
                  const Text('• Monitorização intensiva'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown('Tipo de cirurgia', _tipoCircurgia, [
              {'value': 'eletiva', 'label': 'Eletiva de baixo risco'},
              {'value': 'medio', 'label': 'Médio risco'},
              {'value': 'alto', 'label': 'Alto risco/emergência'},
              {'value': 'cardiaca', 'label': 'Cirurgia cardíaca'},
              {'value': 'neuro', 'label': 'Neurocirurgia'},
            ], (v) => setState(() => _tipoCircurgia = v!)),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocoloNaoCritico() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: _getCorCenario(1)),
                const SizedBox(width: 8),
                const Text(
                  'Protocolo Não Crítico',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MANEJO PADRÃO:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('• Meta: 100-180 mg/dL'),
                  const Text('• Esquema basal-bolus'),
                  const Text('• Monitorização 4x/dia'),
                  const Text('• Ajustes conforme evolução'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsulinas(int cenario) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: _getCorCenario(cenario)),
                const SizedBox(width: 8),
                const Text(
                  'Configuração de Insulinas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDadosClinicos(),
            const SizedBox(height: 16),
            _buildConfiguracaoInsulina(cenario),
          ],
        ),
      ),
    );
  }

  Widget _buildDadosClinicos() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados Clínicos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDropdown('Dieta', _dieta, [
                {'value': 'oral_ba', 'label': 'Oral — boa aceitação'},
                {'value': 'oral_ma', 'label': 'Oral — má aceitação'},
                {'value': 'enteral', 'label': 'Enteral'},
                {'value': 'parenteral', 'label': 'Parenteral'},
                {'value': 'npo', 'label': 'NPO'},
              ], (v) => setState(() => _dieta = v!))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('Corticosteroide', _corticoide, [
                {'value': 'nao', 'label': 'Não'},
                {'value': 'pred_baixa', 'label': 'Prednisona baixa'},
                {'value': 'pred_media', 'label': 'Prednisona média'},
                {'value': 'pred_alta', 'label': 'Prednisona alta'},
              ], (v) {
                setState(() => _corticoide = v!);
                _ajustaSugestaoSens();
              })),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDropdown('Hepatopatia', _hepato, [
                {'value': 'nao', 'label': 'Não'},
                {'value': 'sim', 'label': 'Sim'},
              ], (v) => setState(() => _hepato = v!))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('Sensibilidade', _sensib, [
                {'value': 'sensivel', 'label': 'Sensível'},
                {'value': 'usual', 'label': 'Usual'},
                {'value': 'resistente', 'label': 'Resistente'},
              ], (v) => setState(() => _sensib = v!))),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _glicemiaAtualController,
            label: 'Glicemia atual (mg/dL)',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracaoInsulina(int cenario) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuração de Insulina',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDropdown('Escala do dispositivo', _stepProto, [
            {'value': '0.5', 'label': '0,5 UI'},
            {'value': '1', 'label': '1 UI'},
            {'value': '2', 'label': '2 UI'},
          ], (v) => setState(() => _stepProto = v!)),
          if (_stepProto == '2') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Doses arredondadas em números pares',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDropdown('Insulina basal', _basalTipo, [
                {'value': 'nph', 'label': 'NPH'},
                {'value': 'glargina', 'label': 'Glargina'},
                {'value': 'degludeca', 'label': 'Degludeca'},
                if (cenario == 3) {'value': 'iv', 'label': 'IV contínua'},
              ], (v) => setState(() => _basalTipo = v!))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('Insulina rápida', _rapidaTipo, [
                {'value': 'regular', 'label': 'Regular'},
                {'value': 'lispro', 'label': 'Lispro'},
                {'value': 'aspart', 'label': 'Aspart'},
                {'value': 'glulisina', 'label': 'Glulisina'},
              ], (v) => setState(() => _rapidaTipo = v!))),
            ],
          ),
          if (_basalTipo == 'nph') ...[
            const SizedBox(height: 12),
            _buildDropdown('Posologia NPH', _nphPosologia, [
              {'value': '1m', 'label': '1x manhã (06h)'},
              {'value': '1n', 'label': '1x noite (22h)'},
              {'value': '2x', 'label': '2x dia (06h + 22h)'},
              {'value': '3x', 'label': '3x dia (06h + 11h + 22h)'},
            ], (v) => setState(() => _nphPosologia = v!)),
          ],
        ],
      ),
    );
  }

  Widget _buildBotoes() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _calcularPrescricao,
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular Prescrição'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCorCenario(_dadosPaciente['cenario'] ?? 1),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: _getCorCenario(_dadosPaciente['cenario'] ?? 1),
            side: BorderSide(color: _getCorCenario(_dadosPaciente['cenario'] ?? 1)),
            minimumSize: const Size(80, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Voltar'),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<Map<String, String>> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _buildInputDecoration(),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item['value'],
                    child: Text(item['label']!),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _buildInputDecoration(),
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
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
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
        borderSide: BorderSide(color: _getCorCenario(_dadosPaciente['cenario'] ?? 1)),
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }
}
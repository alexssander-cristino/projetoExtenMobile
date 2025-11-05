import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/navbar.dart';
import '../services/api_service.dart';

class PrescricaoPage extends StatefulWidget {
  const PrescricaoPage({super.key});

  @override
  State<PrescricaoPage> createState() => _PrescricaoPageState();
}

class _PrescricaoPageState extends State<PrescricaoPage> with TickerProviderStateMixin {
  Map<String, dynamic>? _paciente;
  List<Map<String, dynamic>> _prescricoesExistentes = [];
  Map<String, dynamic> _novaPrescricao = {};
  bool _isLoading = false;
  bool _calculado = false;
  bool _mostrandoNova = false;
  
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paciente == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _paciente = args;
        _carregarPrescricoesExistentes();
      }
    }
  }

  Future<void> _carregarPrescricoesExistentes() async {
    if (_paciente == null) return;

    setState(() => _isLoading = true);

    try {
      final prescricoes = await ApiService.listarPrescricoes(_paciente!['id']);
      setState(() {
        _prescricoesExistentes = prescricoes;
        _isLoading = false;
      });

      _animationController.forward();
      if (prescricoes.isNotEmpty) {
        _fabAnimationController.forward();
      }

      if (prescricoes.isEmpty) {
        _calcularNovaPrescricao();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErro('Erro ao carregar prescrições: $e');
    }
  }

  void _calcularNovaPrescricao() {
    if (_paciente == null) return;

    setState(() {
      _isLoading = true;
      _mostrandoNova = true;
    });

    try {
      final peso = (_paciente!['peso'] ?? 70.0).toDouble();
      final idade = _paciente!['idade'] ?? 30;
      final cenario = _paciente!['cenario'] ?? 1;
      final sexo = _paciente!['sexo'] ?? 'M';
      final egfr = (_paciente!['egfr'] ?? 90.0).toDouble();

      // 🧮 CÁLCULO AVANÇADO DA DOSE TOTAL DIÁRIA (TDD)
      double tddBase = peso * 0.4;
      
      switch (cenario) {
        case 1: tddBase = peso * 0.4; break;
        case 2: tddBase = peso * 0.6; break;
        case 3: tddBase = peso * 0.5; break;
        case 4: tddBase = peso * 0.3; break;
        case 5: tddBase = peso * 0.3; break;
      }

      // Ajustes inteligentes
      if (idade > 65) tddBase *= 0.8;
      if (egfr < 60) tddBase *= 0.9;
      if (egfr < 30) tddBase *= 0.8;

      final tdd = tddBase.round();
      final basalPercentual = cenario == 3 ? 0.6 : 0.5;
      final basal = (tdd * basalPercentual).round();
      final bolus = tdd - basal;
      final bolusRefeicao = (bolus / 3).round();
      final isf = (1700 / tdd).round();
      final escalaCorrecao = _criarEscalaCorrecao(isf, cenario);
      final nphManha = (basal * 0.6).round();
      final nphNoite = basal - nphManha;
      final metas = _definirMetas(cenario);

      setState(() {
        _novaPrescricao = {
          'tdd': tdd,
          'basal': basal,
          'bolus_total': bolus,
          'bolus_refeicao': bolusRefeicao,
          'isf': isf,
          'nph_manha': nphManha,
          'nph_noite': nphNoite,
          'escala_correcao': escalaCorrecao,
          'meta_min': metas['min'],
          'meta_max': metas['max'],
          'hipo_alerta': metas['hipo_alerta'],
          'tipo_basal': _definirTipoBasal(cenario),
          'tipo_rapida': 'Insulina regular ou análogo rápido',
          'observacoes': _gerarObservacoes(cenario, egfr, idade),
          'risco_hipo': _calcularRiscoHipoglicemia(idade, egfr),
          'eficacia_estimada': _calcularEficaciaEstimada(cenario, idade),
        };
        _calculado = true;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErro('Erro ao calcular prescrição: $e');
    }
  }

  String _calcularRiscoHipoglicemia(int idade, double egfr) {
    int pontos = 0;
    if (idade > 65) pontos += 2;
    if (egfr < 60) pontos += 1;
    if (egfr < 30) pontos += 2;
    
    if (pontos >= 3) return 'Alto';
    if (pontos >= 1) return 'Moderado';
    return 'Baixo';
  }

  String _calcularEficaciaEstimada(int cenario, int idade) {
    int pontos = 5; // Base
    if (cenario == 2) pontos += 2; // Gestante
    if (cenario == 3) pontos += 1; // Crítico
    if (idade < 65) pontos += 1;
    
    if (pontos >= 7) return 'Excelente';
    if (pontos >= 5) return 'Boa';
    return 'Moderada';
  }

  List<Map<String, dynamic>> _criarEscalaCorrecao(int isf, int cenario) {
    final escala = <Map<String, dynamic>>[];
    
    if (cenario == 4) {
      escala.addAll([
        {'min': 150, 'max': 200, 'unidades': 2},
        {'min': 201, 'max': 250, 'unidades': 4},
        {'min': 251, 'max': 300, 'unidades': 6},
        {'min': 301, 'max': 400, 'unidades': 8},
      ]);
    } else {
      escala.addAll([
        {'min': 141, 'max': 180, 'unidades': 2},
        {'min': 181, 'max': 220, 'unidades': 4},
        {'min': 221, 'max': 260, 'unidades': 6},
        {'min': 261, 'max': 300, 'unidades': 8},
        {'min': 301, 'max': 350, 'unidades': 10},
        {'min': 351, 'max': 400, 'unidades': 12},
      ]);
    }
    
    return escala;
  }

  Map<String, int> _definirMetas(int cenario) {
    switch (cenario) {
      case 2: return {'min': 70, 'max': 140, 'hipo_alerta': 60};
      case 3: return {'min': 140, 'max': 180, 'hipo_alerta': 70};
      case 4: return {'min': 100, 'max': 250, 'hipo_alerta': 70};
      default: return {'min': 100, 'max': 180, 'hipo_alerta': 70};
    }
  }

  String _definirTipoBasal(int cenario) {
    switch (cenario) {
      case 2: return 'NPH (2x/dia) ou Glargina';
      case 3: return 'Insulina IV contínua ou Glargina';
      default: return 'NPH (2x/dia) ou Glargina/Detemir';
    }
  }

  String _gerarObservacoes(int cenario, double egfr, int idade) {
    final obs = <String>[];
    
    switch (cenario) {
      case 2:
        obs.add('Gestante: monitorar glicemia 4x/dia');
        obs.add('Meta pré-prandial: 70-95 mg/dL');
        break;
      case 3:
        obs.add('Paciente crítico: glicemia a cada 2-4h');
        obs.add('Considerar insulina IV se instável');
        break;
      case 4:
        obs.add('Cuidados paliativos: evitar hipoglicemia');
        obs.add('Priorizar qualidade de vida');
        break;
    }
    
    if (egfr < 60) obs.add('⚠️ Função renal reduzida: monitorar hipoglicemia');
    if (idade > 65) obs.add('⚠️ Idoso: risco aumentado de hipoglicemia');
    
    obs.add('Ajustar doses conforme monitorização');
    obs.add('Reavaliar em 24-48h');
    
    return obs.join('. ');
  }

  Future<void> _salvarNovaPrescricao() async {
    if (_paciente == null || !_calculado) return;

    setState(() => _isLoading = true);

    try {
      final dadosPrescricao = {
        'paciente_id': _paciente!['id'],
        'dose_total': _novaPrescricao['tdd'],
        'basal': _novaPrescricao['basal'],
        'prandial': _novaPrescricao['bolus_refeicao'],
        'observacoes': _novaPrescricao['observacoes'],
      };

      await ApiService.criarPrescricao(dadosPrescricao);

      if (mounted) {
        _mostrarSucesso('✅ Prescrição salva com sucesso!');
        _carregarPrescricoesExistentes();
        setState(() {
          _mostrandoNova = false;
          _calculado = false;
        });
        _fabAnimationController.forward();
      }
    } catch (e) {
      if (mounted) _mostrarErro('❌ Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copiarPrescricao() async {
    final texto = _gerarTextoPrescricao();
    await Clipboard.setData(ClipboardData(text: texto));
    _mostrarSucesso('📋 Prescrição copiada para área de transferência!');
  }

  String _gerarTextoPrescricao() {
    return '''
PRESCRIÇÃO DE INSULINA - ${_paciente!['nome']}

Paciente: ${_paciente!['nome']}
Idade: ${_paciente!['idade']} anos
Peso: ${_paciente!['peso']} kg
Cenário: ${_getNomeCenario(_paciente!['cenario'])}

DOSES CALCULADAS:
- TDD: ${_novaPrescricao['tdd']} U/dia
- Basal: ${_novaPrescricao['basal']} U/dia
- Prandial: ${_novaPrescricao['bolus_refeicao']} U/refeição
- ISF: ${_novaPrescricao['isf']} mg/dL/U

POSOLOGIA NPH:
- Manhã (06h): ${_novaPrescricao['nph_manha']} U
- Noite (22h): ${_novaPrescricao['nph_noite']} U

ESCALA DE CORREÇÃO:
${(_novaPrescricao['escala_correcao'] as List).map((e) => '• ${e['min']}-${e['max']} mg/dL → ${e['unidades']} U').join('\n')}

META GLICÊMICA: ${_novaPrescricao['meta_min']}-${_novaPrescricao['meta_max']} mg/dL

OBSERVAÇÕES:
${_novaPrescricao['observacoes']}

Gerado pelo InsulinCare - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
    ''';
  }

  void _mostrarModalPrescricaoCompleta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Color(0xFF1976D2), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Prescrição Completa',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _copiarPrescricao,
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copiar',
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _gerarTextoPrescricao(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  Color _getCorCenario(int cenario) {
    switch (cenario) {
      case 1: return const Color(0xFF1976D2);
      case 2: return const Color(0xFFE91E63);
      case 3: return const Color(0xFFD32F2F);
      case 4: return const Color(0xFF7B1FA2);
      case 5: return const Color(0xFFFF9800);
      default: return Colors.grey;
    }
  }

  String _formatarData(String dataISO) {
    try {
      final DateTime data = DateTime.parse(dataISO);
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dataISO;
    }
  }

  Widget _buildIndicadorSeguranca() {
    if (!_calculado) return const SizedBox();

    final risco = _novaPrescricao['risco_hipo'];
    final eficacia = _novaPrescricao['eficacia_estimada'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Análise de Segurança',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIndicador(
                    'Risco de Hipoglicemia',
                    risco,
                    risco == 'Baixo' ? Colors.green : 
                    risco == 'Moderado' ? Colors.orange : Colors.red,
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIndicador(
                    'Eficácia Estimada',
                    eficacia,
                    eficacia == 'Excelente' ? Colors.green :
                    eficacia == 'Boa' ? Colors.blue : Colors.orange,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicador(String label, String valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cor,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoVisual() {
    if (!_calculado) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1976D2).withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.medication, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${_novaPrescricao['tdd']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'U/dia',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    'Basal',
                    '${_novaPrescricao['basal']} U',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    'Prandial',
                    '${_novaPrescricao['bolus_refeicao']} U',
                    Icons.restaurant,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    'ISF',
                    '${_novaPrescricao['isf']}',
                    Icons.calculate,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescricaoExistenteCard(Map<String, dynamic> prescricao, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        )),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medication, color: Colors.blue[600], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prescrição #${prescricao['id']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatarData(prescricao['data']),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'visualizar',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('Visualizar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copiar',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 20),
                              SizedBox(width: 8),
                              Text('Copiar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPrescricaoInfo('TDD', '${prescricao['dose_total']} U/dia'),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      Expanded(
                        child: _buildPrescricaoInfo('Basal', '${prescricao['basal']} U/dia'),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      Expanded(
                        child: _buildPrescricaoInfo('Prandial', '${prescricao['prandial']} U'),
                      ),
                    ],
                  ),
                ),
                if (prescricao['observacoes'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note, size: 16, color: Colors.amber[700]),
                            const SizedBox(width: 6),
                            Text(
                              'Observações:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescricao['observacoes'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescricaoInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_paciente == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescrição')),
        body: const Center(child: Text('Erro: Dados do paciente não encontrados')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_mostrandoNova ? 'Nova Prescrição' : 'Prescrições de Insulina'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_mostrandoNova && !_isLoading)
            IconButton(
              onPressed: _calcularNovaPrescricao,
              icon: const Icon(Icons.add),
              tooltip: 'Nova Prescrição',
            ),
          if (_mostrandoNova)
            IconButton(
              onPressed: () {
                setState(() {
                  _mostrandoNova = false;
                  _calculado = false;
                });
                _animationController.reset();
              },
              icon: const Icon(Icons.close),
              tooltip: 'Fechar',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1976D2).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dados do paciente com design melhorado
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              _getCorCenario(_paciente!['cenario']).withOpacity(0.1),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getCorCenario(_paciente!['cenario']),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getCorCenario(_paciente!['cenario']).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _paciente!['sexo'] == 'F' ? Icons.female : Icons.male,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _paciente!['nome'] ?? 'Nome não informado',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${_paciente!['idade']} anos • ${_paciente!['sexo'] == 'F' ? 'Feminino' : 'Masculino'}'),
                                      const SizedBox(width: 12),
                                      Icon(Icons.monitor_weight, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${_paciente!['peso']} kg'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.local_hospital, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${_paciente!['local_internacao']}'),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCorCenario(_paciente!['cenario']),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getNomeCenario(_paciente!['cenario']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_mostrandoNova && _calculado) ...[
                      // Resumo visual da nova prescrição
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildResumoVisual(),
                      ),

                      // Indicadores de segurança
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildIndicadorSeguranca(),
                      ),

                      // Escala de correção com design melhorado
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.adjust, color: Colors.purple[600]),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Escala de Correção',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: (_novaPrescricao['escala_correcao'] as List)
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final escala = entry.value;
                                      final isLast = entry.key == (_novaPrescricao['escala_correcao'] as List).length - 1;
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: escala['unidades'] <= 4 ? Colors.green : 
                                                       escala['unidades'] <= 8 ? Colors.orange : Colors.red,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '${escala['min']}-${escala['max']} mg/dL',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${escala['unidades']} U',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botões de ação melhorados
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _salvarNovaPrescricao,
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
                                label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _mostrarModalPrescricaoCompleta,
                                icon: const Icon(Icons.visibility),
                                label: const Text('Visualizar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Lista de prescrições existentes melhorada
                      Row(
                        children: [
                          const Text(
                            'Histórico de Prescrições',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (_prescricoesExistentes.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.2)),
                              ),
                              child: Text(
                                '${_prescricoesExistentes.length} encontrada${_prescricoesExistentes.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_prescricoesExistentes.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma prescrição encontrada',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Clique no botão + para criar a primeira prescrição',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _prescricoesExistentes
                              .asMap()
                              .entries
                              .map((entry) => _buildPrescricaoExistenteCard(entry.value, entry.key))
                              .toList(),
                        ),
                    ],

                    const SizedBox(height: 80), // Espaço para FAB
                  ],
                ),
              ),
      ),
      floatingActionButton: !_mostrandoNova && _prescricoesExistentes.isNotEmpty
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/acompanhamento',
                  arguments: _paciente,
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.timeline),
                label: const Text('Acompanhamento'),
              ),
            )
          : null,
    );
  }
}
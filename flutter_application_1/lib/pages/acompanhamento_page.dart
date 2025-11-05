import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../services/api_service.dart';

class AcompanhamentoPage extends StatefulWidget {
  const AcompanhamentoPage({super.key});

  @override
  State<AcompanhamentoPage> createState() => _AcompanhamentoPageState();
}

class _AcompanhamentoPageState extends State<AcompanhamentoPage> with TickerProviderStateMixin {
  Map<String, dynamic>? _paciente;
  final _glicemiaController = TextEditingController();
  List<Map<String, dynamic>> _leituras = [];
  bool _isLoading = false;
  String _selectedPeriodo = 'jejum';
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final Map<String, String> _periodos = {
    'jejum': 'Jejum',
    'pre_cafe': 'Pré-Café',
    'pos_cafe': 'Pós-Café',
    'pre_almoco': 'Pré-Almoço',
    'pos_almoco': 'Pós-Almoço',
    'pre_jantar': 'Pré-Jantar',
    'pos_jantar': 'Pós-Jantar',
    '22h': '22h',
    'madrugada': 'Madrugada',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _carregarDados();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glicemiaController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paciente == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _paciente = args;
        _carregarAcompanhamentos();
      }
    }
  }

  Future<void> _carregarDados() async {
    await _carregarAcompanhamentos();
    _animationController.forward();
  }

  Future<void> _carregarAcompanhamentos() async {
    if (_paciente == null) return;

    setState(() => _isLoading = true);

    try {
      // Simular carregamento dos acompanhamentos da API
      // final acompanhamentos = await ApiService.listarAcompanhamentos(_paciente!['id']);
      
      // Dados simulados para demonstração
      final agora = DateTime.now();
      setState(() {
        _leituras = [
          {
            'id': 1,
            'glicemia': 95.0,
            'periodo': 'jejum',
            'data': agora.subtract(const Duration(hours: 2)),
            'observacao': 'Paciente em jejum há 8h',
          },
          {
            'id': 2,
            'glicemia': 180.0,
            'periodo': 'pos_almoco',
            'data': agora.subtract(const Duration(hours: 6)),
            'observacao': '',
          },
          {
            'id': 3,
            'glicemia': 210.0,
            'periodo': 'pre_jantar',
            'data': agora.subtract(const Duration(hours: 1)),
            'observacao': 'Paciente relatou stress',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar acompanhamentos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _adicionarLeitura() async {
    final glicemia = double.tryParse(_glicemiaController.text.replaceAll(',', '.'));
    if (glicemia == null || glicemia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um valor válido de glicemia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final novaLeitura = {
        'id': _leituras.length + 1,
        'glicemia': glicemia,
        'periodo': _selectedPeriodo,
        'data': DateTime.now(),
        'observacao': '',
      };

      // TODO: Salvar na API
      // await ApiService.registrarAcompanhamento({
      //   'paciente_id': _paciente!['id'],
      //   'glicemia': glicemia,
      //   'periodo': _selectedPeriodo,
      // });

      setState(() {
        _leituras.insert(0, novaLeitura);
        _isLoading = false;
      });

      _glicemiaController.clear();

      // Mostrar alertas se necessário
      _verificarAlertas(glicemia);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Glicemia registrada: ${glicemia.toStringAsFixed(0)} mg/dL'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _verificarAlertas(double glicemia) {
    if (glicemia < 70) {
      _mostrarAlertaHipoglicemia(glicemia);
    } else if (glicemia > 300) {
      _mostrarAlertaHiperglicemia(glicemia);
    }
  }

  void _mostrarAlertaHipoglicemia(double glicemia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('HIPOGLICEMIA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glicemia muito baixa: ${glicemia.toStringAsFixed(0)} mg/dL',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONDUTA IMEDIATA:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text('• Paciente consciente: 30mL glicose 50% VO'),
                  Text('• Paciente inconsciente: 30mL glicose 50% IV'),
                  Text('• Repetir glicemia em 15 minutos'),
                  Text('• Manter até glicemia > 100 mg/dL'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarAlertaHiperglicemia(double glicemia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('HIPERGLICEMIA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glicemia muito alta: ${glicemia.toStringAsFixed(0)} mg/dL',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVALIAR:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text('• Pesquisar cetonemia'),
                  Text('• Aplicar correção conforme protocolo'),
                  Text('• Reavaliar em 2-4 horas'),
                  Text('• Considerar ajuste da prescrição'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Color _getCorGlicemia(double glicemia) {
    if (glicemia < 70) return Colors.red;
    if (glicemia < 100) return Colors.orange;
    if (glicemia <= 180) return Colors.green;
    if (glicemia <= 250) return Colors.orange;
    return Colors.red;
  }

  String _getClassificacao(double glicemia) {
    if (glicemia < 54) return 'Hipoglicemia Grave';
    if (glicemia < 70) return 'Hipoglicemia';
    if (glicemia < 100) return 'Baixa';
    if (glicemia <= 140) return 'Normal';
    if (glicemia <= 180) return 'Adequada';
    if (glicemia <= 250) return 'Hiperglicemia';
    return 'Hiperglicemia Grave';
  }

  Widget _buildEstatisticas() {
    if (_leituras.isEmpty) return const SizedBox();

    final glicemias = _leituras.map((l) => l['glicemia'] as double).toList();
    final media = glicemias.reduce((a, b) => a + b) / glicemias.length;
    final min = glicemias.reduce((a, b) => a < b ? a : b);
    final max = glicemias.reduce((a, b) => a > b ? a : b);
    
    final dentroMeta = glicemias.where((g) => g >= 100 && g <= 180).length;
    final percentualMeta = (dentroMeta / glicemias.length * 100);

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
                Icon(Icons.analytics, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Estatísticas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Média', '${media.toStringAsFixed(0)} mg/dL', Icons.trending_up, Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Mín/Máx', '${min.toStringAsFixed(0)}/${max.toStringAsFixed(0)}', Icons.unfold_more, Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Na Meta', '${percentualMeta.toStringAsFixed(0)}%', Icons.gps_fixed,
                    percentualMeta >= 70 ? Colors.green : Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Leituras', '${glicemias.length}', Icons.format_list_numbered, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeituraCard(Map<String, dynamic> leitura, int index) {
    final glicemia = leitura['glicemia'] as double;
    final data = leitura['data'] as DateTime;
    final periodo = leitura['periodo'] as String;
    final cor = _getCorGlicemia(glicemia);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
      )),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  glicemia.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'mg/dL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Text(
                _periodos[periodo] ?? periodo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cor.withOpacity(0.3)),
                ),
                child: Text(
                  _getClassificacao(glicemia),
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}'),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${data.day}/${data.month}'),
                ],
              ),
              if (leitura['observacao']?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  leitura['observacao'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSugestoes() {
    if (_leituras.length < 3) return const SizedBox();

    final ultimasLeituras = _leituras.take(5).toList();
    final glicemias = ultimasLeituras.map((l) => l['glicemia'] as double).toList();
    final media = glicemias.reduce((a, b) => a + b) / glicemias.length;

    List<String> sugestoes = [];

    if (media > 200) {
      sugestoes.add('• Considerar aumento da dose basal em 10-20%');
      sugestoes.add('• Reavaliar prescrição de insulina');
    } else if (media < 90) {
      sugestoes.add('• Considerar redução da dose basal em 10%');
      sugestoes.add('• Investigar causas de hipoglicemia');
    }

    final hiperCount = glicemias.where((g) => g > 180).length;
    if (hiperCount >= 3) {
      sugestoes.add('• Ajustar insulina prandial das refeições elevadas');
    }

    final ultimaLeitura = _leituras.first['glicemia'] as double;
    if (ultimaLeitura > 250) {
      sugestoes.add('• Aplicar correção conforme escala da prescrição');
      sugestoes.add('• Pesquisar cetonemia');
    }

    if (sugestoes.isEmpty) {
      sugestoes.add('• Manter esquema atual');
      sugestoes.add('• Continuar monitorização');
    }

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
                Icon(Icons.lightbulb, color: Colors.amber[600]),
                const SizedBox(width: 8),
                const Text(
                  'Sugestões Clínicas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sugestoes.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(s),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhamento Glicêmico'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
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
        child: Column(
          children: [
            // Formulário de nova leitura
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Leitura',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _glicemiaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Glicemia (mg/dL)',
                              suffixIcon: const Icon(Icons.bloodtype),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedPeriodo,
                            decoration: InputDecoration(
                              labelText: 'Período',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _periodos.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedPeriodo = value!);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _adicionarLeitura,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: _isLoading && _leituras.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (_paciente != null) ...[
                            // Info do paciente
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: const Color(0xFF1976D2),
                                      child: Icon(
                                        _paciente!['sexo'] == 'F' ? Icons.female : Icons.male,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _paciente!['nome'] ?? 'Paciente',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '${_paciente!['idade']} anos • ${_paciente!['peso']} kg',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Estatísticas
                          FadeTransition(
                            opacity: _slideAnimation,
                            child: _buildEstatisticas(),
                          ),

                          // Sugestões
                          FadeTransition(
                            opacity: _slideAnimation,
                            child: _buildSugestoes(),
                          ),

                          // Lista de leituras
                          if (_leituras.isEmpty)
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhuma leitura registrada',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Registre a primeira glicemia para começar o acompanhamento',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Histórico de Leituras',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: Text(
                                          '${_leituras.length} registro${_leituras.length != 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._leituras
                                    .asMap()
                                    .entries
                                    .map((entry) => _buildLeituraCard(entry.value, entry.key)),
                              ],
                            ),

                          const SizedBox(height: 80), // Espaço para o FAB
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/alta', arguments: _paciente),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Finalizar & Alta'),
      ),
    );
  }
}
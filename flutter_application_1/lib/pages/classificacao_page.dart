import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../services/api_service.dart';

class ClassificacaoPage extends StatefulWidget {
  const ClassificacaoPage({super.key});

  @override
  State<ClassificacaoPage> createState() => _ClassificacaoPageState();
}

class _ClassificacaoPageState extends State<ClassificacaoPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _pacientesFiltrados = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _carregarPacientes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarPacientes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final pacientes = await ApiService.listarPacientes();
      setState(() {
        _pacientes = pacientes;
        _pacientesFiltrados = pacientes;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filtrarPacientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _pacientesFiltrados = _pacientes;
      } else {
        _pacientesFiltrados = _pacientes.where((paciente) {
          final nome = paciente['nome']?.toLowerCase() ?? '';
          final cenario = _getNomeCenario(paciente['cenario']).toLowerCase();
          final local = paciente['local_internacao']?.toLowerCase() ?? '';
          return nome.contains(query.toLowerCase()) ||
                 cenario.contains(query.toLowerCase()) ||
                 local.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _excluirPaciente(Map<String, dynamic> paciente) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja excluir o paciente:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getCorCenario(paciente['cenario']),
                    child: Icon(
                      paciente['sexo'] == 'F' ? Icons.female : Icons.male,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paciente['nome'] ?? 'Nome não informado',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${paciente['idade']} anos • ${_getNomeCenario(paciente['cenario'])}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta ação não pode ser desfeita!',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      try {
        // TODO: Implementar exclusão na API
        // await ApiService.excluirPaciente(paciente['id']);
        
        setState(() {
          _pacientes.removeWhere((p) => p['id'] == paciente['id']);
          _pacientesFiltrados.removeWhere((p) => p['id'] == paciente['id']);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${paciente['nome']} foi excluído com sucesso'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir paciente: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _mostrarModalPaciente(Map<String, dynamic> paciente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCorCenario(paciente['cenario']).withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar_${paciente['id']}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getCorCenario(paciente['cenario']),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getCorCenario(paciente['cenario']).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        paciente['sexo'] == 'F' ? Icons.female : Icons.male,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paciente['nome'] ?? 'Nome não informado',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getCorCenario(paciente['cenario']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getNomeCenario(paciente['cenario']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red[600], size: 20),
                            const SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red[600])),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 200), () {
                            _excluirPaciente(paciente);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Informações detalhadas
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection('Dados Pessoais', [
                      _buildInfoItem(Icons.person, 'Sexo', paciente['sexo'] == 'F' ? 'Feminino' : 'Masculino'),
                      _buildInfoItem(Icons.cake, 'Idade', '${paciente['idade']} anos'),
                      _buildInfoItem(Icons.monitor_weight, 'Peso', '${paciente['peso']} kg'),
                      _buildInfoItem(Icons.height, 'Altura', '${paciente['altura']} cm'),
                      if (paciente['imc'] != null)
                        _buildInfoItem(Icons.analytics, 'IMC', '${paciente['imc']?.toStringAsFixed(1)} kg/m²'),
                    ]),

                    const SizedBox(height: 24),

                    _buildInfoSection('Dados Clínicos', [
                      _buildInfoItem(Icons.local_hospital, 'Local', paciente['local_internacao'] ?? 'Não informado'),
                      if (paciente['egfr'] != null)
                        _buildInfoItem(Icons.water_drop, 'TFG', '${paciente['egfr']?.toStringAsFixed(0)} mL/min/1,73m²'),
                      if (paciente['creatinina'] != null)
                        _buildInfoItem(Icons.science, 'Creatinina', '${paciente['creatinina']} mg/dL'),
                    ]),

                    const SizedBox(height: 32),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.description,
                            label: 'Protocolo',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/protocolo', arguments: paciente);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.medication,
                            label: 'Prescrição',
                            color: Colors.green,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/prescricao', arguments: paciente);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.analytics,
                            label: 'Acompanhamento',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/acompanhamento', arguments: paciente);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.exit_to_app,
                            label: 'Alta',
                            color: Colors.purple,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/alta', arguments: paciente);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNomeCenario(int? cenario) {
    switch (cenario) {
      case 1: return 'Não crítico';
      case 2: return 'Gestante';
      case 3: return 'Crítico';
      case 4: return 'Paliativo';
      case 5: return 'Perioperatório';
      default: return 'Não definido';
    }
  }

  Color _getCorCenario(int? cenario) {
    switch (cenario) {
      case 1: return const Color(0xFF1976D2);
      case 2: return const Color(0xFFE91E63);
      case 3: return const Color(0xFFD32F2F);
      case 4: return const Color(0xFF7B1FA2);
      case 5: return const Color(0xFFFF9800);
      default: return Colors.grey;
    }
  }

  Widget _buildPacienteCard(Map<String, dynamic> paciente, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.3),
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
          child: InkWell(
            onTap: () => _mostrarModalPaciente(paciente),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    _getCorCenario(paciente['cenario']).withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar_${paciente['id']}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getCorCenario(paciente['cenario']),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: _getCorCenario(paciente['cenario']).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        paciente['sexo'] == 'F' ? Icons.female : Icons.male,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paciente['nome'] ?? 'Nome não informado',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${paciente['idade']} anos'),
                            const SizedBox(width: 16),
                            Icon(Icons.monitor_weight, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${paciente['peso']} kg'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.local_hospital, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                paciente['local_internacao'] ?? 'Local não informado',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCorCenario(paciente['cenario']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getNomeCenario(paciente['cenario']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPacientes,
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
            // Barra de busca
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filtrarPacientes,
                decoration: InputDecoration(
                  hintText: 'Buscar pacientes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filtrarPacientes('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Contador e filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pacientes Cadastrados',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.2)),
                      ),
                      child: Text(
                        '${_pacientesFiltrados.length} encontrado${_pacientesFiltrados.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista de pacientes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text('Erro ao carregar', style: TextStyle(fontSize: 18, color: Colors.red[700])),
                              const SizedBox(height: 8),
                              Text(_errorMessage, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _carregarPacientes,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar Novamente'),
                              ),
                            ],
                          ),
                        )
                      : _pacientesFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'Nenhum paciente encontrado'
                                        : 'Nenhum paciente cadastrado',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/cadastro'),
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Cadastrar Paciente'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _pacientesFiltrados.length,
                              itemBuilder: (context, index) {
                                return _buildPacienteCard(_pacientesFiltrados[index], index);
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/cadastro'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Paciente'),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 2),
    );
  }
}
import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InsulinCare'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1976D2).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 80),
                
                // 🎯 ÍCONE PRINCIPAL
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medication_liquid,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 🏥 TÍTULO PRINCIPAL
                const Text(
                  'InsulinCare',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 📋 SUBTÍTULO
                Text(
                  'Assistente inteligente para prescrição de insulina hospitalar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                
                const Spacer(),
                
                // 🚀 BOTÃO PRINCIPAL
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/cadastro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: const Text(
                      'Iniciar Novo Atendimento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 📋 BOTÃO SECUNDÁRIO
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/classificacao'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                      side: const BorderSide(color: Color(0xFF1976D2), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.people_rounded),
                    label: const Text(
                      'Ver Pacientes Cadastrados',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 🏥 RODAPÉ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Desenvolvido para profissionais de saúde',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 0),
    );
  }
}
import 'package:flutter/material.dart';
import '../pages/inicio_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/classificacao_page.dart';
import '../pages/historico_alta_page.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  const NavBar({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const InicioPage();
        break;
      case 1:
        page = const CadastroPage();
        break;
      case 2:
        page = const ClassificacaoPage();
        break;
      case 3:
        page = const HistoricoAltaPage();
        break;
      default:
        page = const InicioPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: Colors.grey[500],
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.home_outlined,
                Icons.home_rounded,
                0,
              ),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.person_add_outlined,
                Icons.person_add_rounded,
                1,
              ),
              label: 'Cadastro',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.people_outline,
                Icons.people_rounded,
                2,
              ),
              label: 'Pacientes',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.history_outlined,
                Icons.history_rounded,
                3,
              ),
              label: 'Histórico',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData inactiveIcon, IconData activeIcon, int index) {
    final isSelected = selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1976D2).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF1976D2).withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          key: ValueKey(isSelected),
          size: isSelected ? 26 : 24,
          color: isSelected
              ? const Color(0xFF1976D2)
              : Colors.grey[500],
        ),
      ),
    );
  }
}

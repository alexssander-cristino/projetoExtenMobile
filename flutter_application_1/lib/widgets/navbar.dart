import 'package:flutter/material.dart';
import '../pages/inicio_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/classificacao_page.dart';
import '../pages/protocolo_page.dart';
import '../pages/prescricao_page.dart';
import '../pages/acompanhamento_page.dart';

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
        page = const ProtocoloPage();
        break;
      case 4:
        page = const PrescricaoPage();
        break;
      case 5:
        page = const AcompanhamentoPage();
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
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_add),
          label: 'Cadastro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Classificação',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Protocolo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services),
          label: 'Prescrição',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Acompanhamento',
        ),
      ],
    );
  }
}

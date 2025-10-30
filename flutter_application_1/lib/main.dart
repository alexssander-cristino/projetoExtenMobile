import 'package:flutter/material.dart';
import 'pages/inicio_page.dart';
import 'pages/cadastro_page.dart';
import 'pages/classificacao_page.dart';
import 'pages/protocolo_page.dart';
import 'pages/prescricao_page.dart';
import 'pages/acompanhamento_page.dart';
import 'pages/alta_page.dart';

void main() {
  runApp(InsulinPrescriberApp());
}

class InsulinPrescriberApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insulin Prescriber',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/inicio',
      routes: {
        '/inicio': (_) => const InicioPage(),
        '/cadastro': (_) => const CadastroPage(),
        '/classificacao': (_) => const ClassificacaoPage(),
        '/protocolo': (_) => const ProtocoloPage(),
        '/prescricao': (_) => const PrescricaoPage(),
        '/acompanhamento': (_) => const AcompanhamentoPage(),
        '/alta': (_) => const AltaPage(),
      },
    );
  }
}

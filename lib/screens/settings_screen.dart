import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Conta'),
            _settingsCard([
              _settingsOption(
                  Icons.person, 'Editar perfil', 'Atualize seus dados'),
              _settingsOption(
                  Icons.lock, 'Privacidade', 'Controle de visibilidade'),
            ]),
            const SizedBox(height: 16),
            _sectionTitle('Notificações'),
            _settingsCard([
              _settingsOption(
                  Icons.notifications, 'Alertas', 'Pet perdido e adoções'),
              _settingsOption(Icons.mail, 'E-mails', 'Resumo semanal'),
            ]),
            const SizedBox(height: 16),
            _sectionTitle('Aplicativo'),
            _settingsCard([
              _settingsOption(Icons.dark_mode, 'Tema', 'Claro'),
              _settingsOption(Icons.language, 'Idioma', 'Português (Brasil)'),
              _settingsOption(Icons.info, 'Sobre o app', 'Versão 1.0.0'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _settingsOption(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.orange.shade700),
          title: Text(title),
          subtitle:
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(height: 1),
      ],
    );
  }
}

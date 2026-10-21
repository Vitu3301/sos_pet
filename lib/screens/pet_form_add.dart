import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PetFormScreen extends StatefulWidget {
  final Map<String, dynamic>? petParaEditar;

  const PetFormScreen({super.key, this.petParaEditar});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _localController = TextEditingController();

  String? _caminhoImagemNova;
  String _statusSelecionado = 'Perdido';
  String? _imagemAntiga;

  @override
  void initState() {
    super.initState();
    if (widget.petParaEditar != null) {
      _nomeController.text = widget.petParaEditar!['nome'];
      _racaController.text = widget.petParaEditar!['raca'];
      _localController.text = widget.petParaEditar!['local'];
      _statusSelecionado = widget.petParaEditar!['status'];
      _imagemAntiga = widget.petParaEditar!['foto'];
    }
  }

  Future<void> _escolherImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _caminhoImagemNova = pickedFile.path;
      });
    }
  }

  void _salvarFormulario() {
    if (_formKey.currentState!.validate()) {
      if (_caminhoImagemNova == null && _imagemAntiga == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione uma foto!')),
        );
        return;
      }

      final petAtualizado = {
        'nome': _nomeController.text,
        'raca': _racaController.text,
        'local': _localController.text,
        'status': _statusSelecionado,
        'foto':
            _caminhoImagemNova != null ? _caminhoImagemNova! : _imagemAntiga,
      };

      Navigator.pop(context, petAtualizado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdicao = widget.petParaEditar != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Animal' : 'Cadastrar Animal'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _escolherImagem,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: _construirImagem(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                    labelText: 'Nome do Animal', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _racaController,
                decoration: const InputDecoration(
                    labelText: 'Raça (ou SRD)', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite a raça' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _localController,
                decoration: const InputDecoration(
                    labelText: 'Local (Ex: Centro, Recife)',
                    border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite o local' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _statusSelecionado,
                decoration: const InputDecoration(
                    labelText: 'Status', border: OutlineInputBorder()),
                items: ['Perdido', 'Para Adoção'].map((String status) {
                  return DropdownMenuItem<String>(
                      value: status, child: Text(status));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _statusSelecionado = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _salvarFormulario,
                child: Text(
                  isEdicao ? 'Salvar Alterações' : 'Salvar Animal',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirImagem() {
    if (_caminhoImagemNova != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: kIsWeb
            ? Image.network(_caminhoImagemNova!, fit: BoxFit.cover)
            : Image.file(File(_caminhoImagemNova!), fit: BoxFit.cover),
      );
    } else if (_imagemAntiga != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: kIsWeb || _imagemAntiga!.startsWith('http')
            ? Image.network(_imagemAntiga!, fit: BoxFit.cover)
            : Image.file(File(_imagemAntiga!), fit: BoxFit.cover),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('Toque para escolher uma foto',
              style: TextStyle(color: Colors.grey[600])),
        ],
      );
    }
  }
}

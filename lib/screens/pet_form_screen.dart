import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class PetFormScreen extends StatefulWidget {
  final PetModel? petParaEditar;

  const PetFormScreen({super.key, this.petParaEditar});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _localController = TextEditingController();
  final _resumoController = TextEditingController();

  String _statusSelecionado = 'Perdido';

  XFile? _arquivoImagemNova;
  String? _imagemAntiga;

  @override
  void initState() {
    super.initState();
    if (widget.petParaEditar != null) {
      _nomeController.text = widget.petParaEditar!.nome;
      _racaController.text = widget.petParaEditar!.raca;
      _localController.text = widget.petParaEditar!.local;
      _resumoController.text = widget.petParaEditar!.resumo;
      _statusSelecionado = widget.petParaEditar!.status;
      _imagemAntiga = widget.petParaEditar!.foto;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _localController.dispose();
    _resumoController.dispose();
    super.dispose();
  }

  Future<void> _escolherImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _arquivoImagemNova = pickedFile;
      });
    }
  }

  Future<void> _salvarFormulario() async {
    if (_formKey.currentState!.validate()) {
      if (_arquivoImagemNova == null && _imagemAntiga == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione uma foto!')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => const Center(
            child: CircularProgressIndicator(color: Colors.orange)),
      );

      try {
        String caminhoImagemParaSalvar = _imagemAntiga ?? '';

        if (_arquivoImagemNova != null) {
          final fileName = _arquivoImagemNova!.name.isNotEmpty
              ? _arquivoImagemNova!.name
              : 'pet_${DateTime.now().millisecondsSinceEpoch}.jpg';

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('pets/${DateTime.now().millisecondsSinceEpoch}_$fileName');

          if (kIsWeb) {
            final bytes = await _arquivoImagemNova!.readAsBytes();
            await storageRef.putData(bytes);
          } else {
            await storageRef.putFile(File(_arquivoImagemNova!.path));
          }

          caminhoImagemParaSalvar = await storageRef.getDownloadURL();
        }

        final petModel = PetModel(
          id: widget.petParaEditar?.id,
          nome: _nomeController.text,
          raca: _racaController.text,
          local: _localController.text,
          status: _statusSelecionado,
          foto: caminhoImagemParaSalvar,
          resumo: _resumoController.text.trim(),
          dataAtualizacao: DateTime.now(),
        );

        final firestore = FirebaseFirestore.instance;

        if (widget.petParaEditar != null && widget.petParaEditar!.id != null) {
          final String docId = widget.petParaEditar!.id!;
          await firestore
              .collection('pets')
              .doc(docId)
              .update(petModel.toMap());
        } else {
          await firestore.collection('pets').add(petModel.toMap());
        }

        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (mounted) Navigator.pop(context, petModel);
      } catch (e) {
        debugPrint('Erro ao guardar animal: $e');

        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao guardar animal: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdicao = widget.petParaEditar != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Animal' : 'Cadastrar Animal'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdicao ? 'Atualize os dados' : 'Vamos conhecer esse pet',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preencha as informações para ajudar a encontrar o caminho certo.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _escolherImagem,
                child: Stack(
                  children: [
                    Container(
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _construirImagem(),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Informações do pet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoracaoCampo(
                  'Nome do animal',
                  Icons.pets_outlined,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _racaController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoracaoCampo(
                  'Raça (ou SRD)',
                  Icons.category_outlined,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite a raça' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _localController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoracaoCampo(
                  'Local (ex.: Centro, Recife)',
                  Icons.location_on_outlined,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite o local' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _resumoController,
                maxLines: 4,
                minLines: 3,
                decoration: _decoracaoCampo(
                  'Resumo sobre o pet',
                  Icons.notes_rounded,
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Descreva o pet'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Situação',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'Perdido',
                    icon: Icon(Icons.search_rounded),
                    label: Text('Perdido'),
                  ),
                  ButtonSegment(
                    value: 'Para Adoção',
                    icon: Icon(Icons.favorite_border_rounded),
                    label: Text('Adoção'),
                  ),
                ],
                selected: {_statusSelecionado},
                onSelectionChanged: (selection) {
                  setState(() => _statusSelecionado = selection.first);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    )),
                onPressed: _salvarFormulario,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded),
                    const SizedBox(width: 8),
                    Text(
                      isEdicao ? 'Salvar alterações' : 'Cadastrar pet',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirImagem() {
    if (_arquivoImagemNova != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: kIsWeb
            ? Image.network(_arquivoImagemNova!.path, fit: BoxFit.cover)
            : Image.file(File(_arquivoImagemNova!.path), fit: BoxFit.cover),
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
          const Icon(Icons.add_a_photo_outlined,
              size: 38, color: Colors.orange),
          const SizedBox(height: 10),
          const Text(
            'Adicionar foto do pet',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque aqui para escolher uma imagem',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      );
    }
  }

  InputDecoration _decoracaoCampo(
    String label,
    IconData icon, {
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange.shade700),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
      ),
    );
  }
}

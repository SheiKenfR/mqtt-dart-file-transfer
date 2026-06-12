import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../application/signature_controller.dart';
import 'signature_pad.dart';

class SignaturePage extends StatefulWidget {
  const SignaturePage({super.key});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  final SignatureFeatureController _featureController =
      SignatureFeatureController();

  bool _hasDrawn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _signatureController.onDrawEnd = _onDrawChanged;
  }

  void _onDrawChanged() {
    final drawn = _signatureController.isNotEmpty;
    if (drawn != _hasDrawn) {
      setState(() => _hasDrawn = drawn);
    }
  }

  Future<void> _onClear() async {
    _signatureController.clear();
    setState(() => _hasDrawn = false);
  }

  Future<void> _onValidate() async {
    if (!_hasDrawn || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final path = await _featureController.exportAndSave(_signatureController);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signature saved: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signature')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Signez avec votre doigt',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SignaturePad(controller: _signatureController),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _onClear,
                      child: const Text('Effacer'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _hasDrawn && !_isProcessing
                          ? _onValidate
                          : null,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

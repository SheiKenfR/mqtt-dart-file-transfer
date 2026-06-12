import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatelessWidget {
  final SignatureController controller;

  const SignaturePad({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Signature(
          controller: controller,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

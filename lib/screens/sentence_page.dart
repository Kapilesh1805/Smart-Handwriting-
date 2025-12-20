import 'package:flutter/material.dart';
import '../sections/sentence_section.dart';

class SentencePage extends StatelessWidget {
  const SentencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Writing Practice'),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
      ),
      body: const SentenceSection(),
    );
  }
}

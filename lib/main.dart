import 'package:flutter/material.dart';

void main() => runApp(const VibraApp());

class VibraApp extends StatelessWidget {
  const VibraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibra',
      theme: ThemeData.dark(),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        scrollDirection: Axis.vertical,
        children: const [
          VideoCard(texto: 'Vibra — Video 1', icono: '🎵'),
          VideoCard(texto: 'Vibra — Video 2', icono: '🔥'),
          VideoCard(texto: 'Vibra — Video 3', icono: '💃'),
        ],
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final String texto, icono;
  const VideoCard({super.key, required this.texto, required this.icono});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icono, style: const TextStyle(fontSize: 90)),
          const SizedBox(height: 24),
          Text(texto, style: const TextStyle(fontSize: 28, color: Colors.white)),
        ],
      ),
    );
  }
}

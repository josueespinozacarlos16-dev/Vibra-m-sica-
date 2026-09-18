import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicProvider(),
      child: MaterialApp(
        title: 'Vibra',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    await Permission.audio.request();
    await Permission.storage.request();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.music_note, size: 80, color: Colors.purpleAccent),
      SizedBox(height: 20),
      Text('Vibra', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
      SizedBox(height: 10),
      Text('Tu música, siempre contigo', style: TextStyle(color: Colors.grey)),
      SizedBox(height: 30),
      CircularProgressIndicator(color: Colors.purpleAccent)
    ])));
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void initState() {
    super.initState();
    Provider.of<MusicProvider>(context, listen: false).loadSongs(_audioQuery);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Vibra 🎵'), backgroundColor: Colors.purpleAccent),
      body: provider.isLoading ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
        : provider.songs.isEmpty ? const Center(child: Text('No se encontraron canciones en el dispositivo', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
          itemCount: provider.songs.length,
          itemBuilder: (context, index) {
            final song = provider.songs[index];
            return ListTile(
              leading: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO,
                nullArtworkWidget: const Icon(Icons.music_note, color: Colors.purpleAccent, size: 40)),
              title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(song.artist ?? 'Desconocido', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              onTap: () => provider.playSong(index),
            );
          }),
        ),
      bottomNavigationBar: provider.currentSong != null ? const PlayerBar() : null,
    );
  }
}

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    return Container(
      color: const Color(0xFF2C2C44),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Slider(value: provider.position, max: provider.duration, onChanged: provider.seek, activeColor: Colors.purpleAccent, inactiveColor: Colors.grey),
        Row(children: [
          Expanded(child: Text(provider.currentSong?.title ?? '', style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: provider.previous),
          IconButton(icon: Icon(provider.isPlaying ? Icons.pause_circle : Icons.play_circle_fill, color: Colors.purpleAccent, size: 45),
            onPressed: provider.togglePlay),
          IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: provider.next),
        ])
      ]),
    );
  }
}

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = true;
  double _position = 0;
  double _duration = 1;

  List<SongModel> get songs => _songs;
  SongModel? get currentSong => _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get position => _position;
  double get duration => _duration;

  Future<void> loadSongs(OnAudioQuery audioQuery) async {
    _songs = await audioQuery.querySongs();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> playSong(int index) async {
    _currentIndex = index;
    await _audioPlayer.setFilePath(_songs[index].data);
    _audioPlayer.play();
    _isPlaying = true;
    _audioPlayer.positionStream.listen((p) {
      _position = p.inSeconds.toDouble();
      notifyListeners();
    });
    _audioPlayer.durationStream.listen((d) {
      _duration = d?.inSeconds.toDouble() ?? 1;
      notifyListeners();
    });
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) _audioPlayer.pause();
    else _audioPlayer.play();
  }

  void seek(double sec) => _audioPlayer.seek(Duration(seconds: sec.toInt()));

  void previous() {
    if (_currentIndex > 0) playSong(_currentIndex - 1);
  }

  void next() {
    if (_currentIndex < _songs.length - 1) playSong(_currentIndex + 1);
  }
}

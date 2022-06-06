import 'dart:io';

import 'package:flame/flame.dart';
import 'package:flame_splash_screen/flame_splash_screen.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_puzzle_cell/layout/other/credits.dart';
import 'package:the_puzzle_cell/layout/tools/tools.dart';
import 'package:the_puzzle_cell/utils/ScaleAssist.dart';
import 'package:the_puzzle_cell/layout/layout.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:window_manager/window_manager.dart';

import 'logic/logic.dart';

late ThemeData td;

final deflate = ZLibCodec(level: ZLibOption.maxLevel);

void main() async {
  //await Flame.device.setLandscape();

  DartVLC.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();

  await loadAllPuzzles();
  await loadBlueprints();
  addBlueprints();

  //fixDefault();

  td = ThemeData(
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  storage = await SharedPreferences.getInstance();

  if (storage.getString("lang") != null) {
    loadLangByName(storage.getString("lang")!);
  }

  worldManager.loadWorldsFromSettings();

  if (storage.getDouble('ui_scale') == null) {
    await storage.setDouble('ui_scale', 1);
  }

  if (storage.getDouble('music_volume') == null) {
    await storage.setDouble('music_volume', 0.5);
  }

  if (storage.getStringList('servers') == null) {
    await storage.setStringList('servers', []);
  }

  if (storage.getInt('coins') == null) {
    await storage.setInt('coins', 0);
  }

  if (storage.getStringList('skins') == null) {
    await storage.setStringList('skins', <String>[]);
  }

  if (storage.getStringList('usedSkins') == null) {
    await storage.setStringList('usedSkins', <String>[]);
  }

  if (storage.getBool("invert_zoom_scroll") == null) {
    await storage.setBool("invert_zoom_scroll", true);
  }

  if (storage.getBool("fullscreen") != null) {
    await windowManager.setFullScreen(storage.getBool("fullscreen")!);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _splashController = FlameSplashController(
    fadeInDuration: Duration(milliseconds: 500),
    fadeOutDuration: Duration(milliseconds: 500),
  );

  @override
  void initState() {
    initSound();
    setSoundDevice(getAudioDevice());
    texturePacks.forEach(
      (tp) {
        tp.load(false);
      },
    ); // How to make people with 50,000 random texture packs they never use but keep installed mad
    super.initState();
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  var splashScreenOver = false;

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'The Puzzle Cell',
      theme: td,
      debugShowCheckedModeBanner: false,
      home: FlameSplashScreen(
        controller: _splashController,
        theme: FlameSplashTheme(
            backgroundDecoration: BoxDecoration(
              color: Colors.black,
            ),
            logoBuilder: (ctx) {
              return ScaleAssist(builder: (context, size) {
                return FluentTheme(
                  data: td,
                  child: ScaffoldPage(
                    content: Center(
                      child: Column(
                        children: [
                          Spacer(),
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                          Text(
                            'The Puzzle Cell',
                            style: TextStyle(
                              fontSize: 12.sp,
                            ),
                          ),
                          Text(
                            'by A Monitor#1595',
                            style: TextStyle(
                              fontSize: 5.sp,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              });
            }),
        onFinish: (ctx) {
          if (!splashScreenOver) {
            splashScreenOver = true;
            setLoopSoundVolume(
              flightMusic,
              storage.getDouble('music_volume')!,
            );
            //playOnLoop(floatMusic, storage.getDouble('music_volume')!);
            Navigator.of(ctx).pushNamed('/main');
          }
        },
      ),
      routes: {
        '/main': (ctx) => MainScreen(),
        '/editor': (ctx) => Editor(),
        '/game': (ctx) {
          game = PuzzleGame();
          return Container(child: GameUI());
        },
        '/game-loaded': (ctx) {
          game = PuzzleGame();
          return Container(child: GameUI(editorType: EditorType.loaded));
        },
        '/puzzles': (ctx) => Puzzles(),
        '/settings': (ctx) => SettingsPage(),
        '/version': (ctx) => VersionPage(),
        '/credits': (ctx) => CreditsPage(),
        '/multiplayer': (ctx) => MultiplayerPage(),
        '/worlds': (ctx) => WorldUI(),
      },
    );
  }
}

class ConstantButtonValue<T> extends ButtonState<T> {
  final T value;

  ConstantButtonValue(this.value);

  @override
  T resolve(Set<ButtonStates> states) {
    return value;
  }
}

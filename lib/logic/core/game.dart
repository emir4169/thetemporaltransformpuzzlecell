part of logic;

class PuzzleGame extends FlameGame with TapDetector, KeyboardEvents {
  late Canvas canvas;

  double sfxVolume = 1;

  bool firstRender = true;

  late BuildContext context;

  bool mouseDown = false;

  EditorType edType = EditorType.making;

  String? ip;

  bool get isMultiplayer => ip != null;

  var isLan = false;

  late WebSocketChannel channel;

  // ignore: cancel_subscriptions
  late StreamSubscription<dynamic> multiplayerListener;

  String currentSelection = "empty";

  int currentRotation = 0;

  Map<String, dynamic> currentData = {};

  double mouseX = 0;
  double mouseY = 0;
  var mouseButton = -1;

  double get offX => (smoothOffX - canvasSize.x / 2) * (cellSize / wantedCellSize) + canvasSize.x / 2;
  double get offY => (smoothOffY - canvasSize.y / 2) * (cellSize / wantedCellSize) + canvasSize.y / 2;

  var storedOffX = 0.0;
  var storedOffY = 0.0;

  var smoothOffX = 0.0;
  var smoothOffY = 0.0;

  int updates = 0;

  bool running = false;
  bool isinitial = true;

  double itime = 0;
  double delay = 0.15;

  late Grid initial;

  var cellsToPlace = <String>["empty"];
  var cellsCount = <int>[1];

  var bgX = 0.0;
  var bgY = 0.0;

  late bool realisticRendering;

  bool get validPlacePos => ((mouseY > 5.h) && (mouseY < 92.h));

  var selecting = false;
  var pasting = false;
  var gridClip = GridClip();

  var selX = 0;
  var selY = 0;
  var selW = 0;
  var selH = 0;
  var setPos = false;
  var dragPos = false;

  // Particles
  final redparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.red);
  final blueparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.blue);
  final greenparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.green);
  final yellowparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.yellow);
  final purpleparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.purple);
  final tealparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.teal);
  final blackparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.black);
  final magentaparticles = ParticleSystem(5, 2, 0.25, 0.125, 1, Colors.magenta);

  Rect? viewbox;

  // Brush stuff
  var brushSize = 0;
  var brushTemp = 0;

  final gridTab = <int, Grid>{0: grid};
  final cachedGridEmpties = <int, Sprite?>{};
  var gridTabIndex = 0;

  var gridHistory = <String>[];

  double scrollDelta = 0;

  bool hideUI = false;

  void saveHistory() {
    if (!isMultiplayer && worldIndex == null) {
      storage.setStringList("grid_history", gridHistory);
    }
  }

  void loadHistory() {
    if (!isMultiplayer && worldIndex == null) {
      gridHistory = storage.getStringList("grid_history") ?? [];
    }
  }

  void saveGridToHistory(Grid grid) {
    final date = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    final str = SavingFormat.encodeGrid(grid, title: (grid.title == "" ? dateFormat : grid.title), description: grid.desc);

    gridHistory.add(str);
    saveHistory();
  }

  void changeTab(int newTabIndex) {
    if (edType != EditorType.making || isMultiplayer) {
      return;
    }
    if (worldIndex != null) {
      worldManager.saveWorld(worldIndex!);
      worldIndex = newTabIndex % worldManager.worldLength;
      gridTabIndex = worldIndex!;
      grid = loadStr(worldManager.worldAt(worldIndex!));
      buildEmpty();
      return;
    }
    if (!isinitial) {
      return;
    }
    gridTab[gridTabIndex] = grid;
    cachedGridEmpties[gridTabIndex] = emptyImage;
    if (gridTab[newTabIndex] == null) {
      gridTab[newTabIndex] = Grid(grid.width, grid.height);
    }
    if (cachedGridEmpties[newTabIndex] == null) {
      buildEmpty();
    } else {
      emptyImage = cachedGridEmpties[newTabIndex];
    }
    grid = gridTab[newTabIndex]!;
    gridTabIndex = newTabIndex;
  }

  void increaseTab() {
    changeTab(gridTabIndex + 1);
  }

  void decreaseTab() {
    changeTab(gridTabIndex - 1);
  }

  void increaseBrush() => brushSize++;
  void decreaseBrush() => brushSize = max(brushSize - 1, 0);

  void increaseTemp() => brushTemp++;
  void decreaseTemp() => brushTemp--;

  void whenSelected(String newSelection) {
    if (newSelection.startsWith("blueprint ")) {
      // Blueprint code
      loadBlueprint(int.parse(newSelection.split(' ')[1]));
    } else if (newSelection == "inc_brush") {
      increaseBrush();
    } else if (newSelection == "dec_brush") {
      decreaseBrush();
    } else if (newSelection == "zoomin") {
      zoomin();
    } else if (newSelection == "zoomout") {
      zoomout();
    } else if (newSelection == "inctab") {
      increaseTab();
    } else if (newSelection == "dectab") {
      decreaseTab();
    } else if (newSelection.startsWith("trick_tool")) {
      if (currentSelection.startsWith("totrick_")) {
        return;
      } else if (cells.contains(currentSelection) && currentSelection != "empty") {
        currentSelection = "totrick_$currentSelection";
        currentData = {};
        animatePropertyEditor();
      }
    } else {
      currentSelection = newSelection;
      currentData = {};
      final p = props[currentSelection];
      if (p != null) {
        for (var prop in p) {
          if (prop.def != null) {
            currentData[prop.key] = prop.def;
          }
        }
      }
      animatePropertyEditor();
    }
  }

  void animatePropertyEditor() {
    final btn = buttonManager.buttons['prop-edit-btn'];
    if (btn == null) {
      return;
    }
    if (btn.isRendering != btn.shouldRender()) {
      btn.time = 0;
      btn.duration = 0.25;
    }
  }

  void loadFromText(String str) {
    QueueManager.empty("cell-updates");
    QueueManager.empty("subticks");
    grid = loadStr(str);
    QueueManager.runQueue("post-game-init");
    timeGrid = null;
    initial = grid.copy;
    buttonManager.buttons['play-btn']?.texture = 'mover.png';
    buttonManager.buttons['play-btn']?.rotation = 0;
    buttonManager.buttons['wrap-btn']?.title = grid.wrap ? lang('wrapModeOn', "Wrap Mode (ON)") : lang("wrapModeOff", "Wrap Mode (OFF)");
    buildEmpty();
  }

  void exit() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return ContentDialog(
          title: Text(
            lang(
              "confirm_exit",
              "Confirm exit?",
            ),
          ),
          content: Text(
            lang(
              "confirm_exit_desc",
              "You have pressed the Exit Editor button, which exits the game.\nAny unsaved progress will be gone forever.\nAre you sure you want to exit?",
            ),
          ),
          actions: [
            Button(
              child: Text(lang("yes", "Yes")),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                if (worldIndex != null) {
                  worldManager.saveWorld(
                    worldIndex!,
                  );
                }
                if ((storage.getBool("save_on_exit") == true) && worldIndex == null && !isMultiplayer) {
                  saveGridToHistory(grid);
                }
                worldIndex = null;
                puzzleIndex = null;
              },
            ),
            Button(
              child: Text(lang("no", "No")),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void back() {
    if (edType == EditorType.making) {
      if (overlays.isActive('EditorMenu')) {
        overlays.remove('EditorMenu');
      } else {
        overlays.add('EditorMenu');
      }
    } else {
      exit();
    }
  }

  void paste() {
    if (gridClip.active) {
      gridClip.place(cellMouseX, cellMouseY);
      buttonManager.buttons['select-btn']!.texture = "interface/select.png";
      buttonManager.buttons['paste-btn']!.texture = "interface/paste.png";
      selecting = false;
      setPos = false;
    }
  }

  void copy() {
    if (selW < 0) {
      selW *= -1;
      selX -= selW;
    }
    if (selH < 0) {
      selH *= -1;
      selY -= selH;
    }

    final g = <List<Cell>>[];

    selW--;
    selH--;

    for (var x = 0; x <= selW; x++) {
      g.add(<Cell>[]);
      for (var y = 0; y <= selH; y++) {
        final cx = selX + x;
        final cy = selY + y;
        if (grid.inside(cx, cy)) {
          g.last.add(grid.at(cx, cy).copy);
        }
      }
    }

    gridClip.activate(selW + 1, selH + 1, g);
    gridClip.optimize();

    selecting = false;
    setPos = false;
    dragPos = false;
    pasting = true;
    buttonManager.buttons['paste-btn']?.texture = 'interface/paste_on.png';

    selW++;
    selH++;
  }

  bool mouseInside = true;

  void properlyChangeZoom(double oldzoom, double newzoom) {
    final scale = newzoom / oldzoom;

    storedOffX = (storedOffX - canvasSize.x / 2) * scale + canvasSize.x / 2;
    storedOffY = (storedOffY - canvasSize.y / 2) * scale + canvasSize.y / 2;

    smoothOffX = (smoothOffX - canvasSize.x / 2) * scale + canvasSize.x / 2;
    smoothOffY = (smoothOffY - canvasSize.y / 2) * scale + canvasSize.y / 2;
  }

  void onPointerMove(PointerMoveEvent event) {
    final dx = event.position.dx - mouseX;
    final dy = event.position.dy - mouseY;

    mouseX = event.position.dx;
    mouseY = event.position.dy;

    if (middleMove && mouseDown && mouseButton == kMiddleMouseButton) {
      storedOffX += dx;
      storedOffY += dy;
    }
  }

  void onMouseExit() {
    mouseDown = false;
    mouseInside = false;
  }

  late ButtonManager buttonManager;

  Map<String, dynamic> parseCellDataStr(String str) {
    if (num.tryParse(str) != null) {
      return {"heat": num.parse(str)};
    }
    final pairs = fancySplit(str, ':');
    final m = <String, dynamic>{};

    for (var pair in pairs) {
      final segs = fancySplit(pair, '=');
      m[segs[0]] = TPCML.decodeValue(segs[1]);
    }

    return m;
  }

  void multiplayerCallback(dynamic data) {
    if (data is String) {
      if (!data.startsWith('{') || !data.endsWith('}')) {
        return legacyMultiplayerCallback(data);
      }

      final packet = jsonDecode(data) as Map<String, dynamic>;

      final packetType = packet["pt"].toString();

      final g = isinitial ? grid : initial;

      if (packetType == "place") {
        final x = (packet["x"] as num).toInt();
        final y = (packet["y"] as num).toInt();
        final id = packet["id"] as String;
        final rot = (packet["rot"] as num).toInt();
        final data = packet["data"] as Map<String, dynamic>;
        final size = (packet["size"] as num).toInt();

        for (var cx = x - size; cx <= x + size; cx++) {
          for (var cy = y - size; cy <= y + size; cy++) {
            final wcx = grid.wrap ? cx % grid.width : cx;
            final wcy = grid.wrap ? cy % grid.height : cy;
            if (!g.inside(wcx, wcy)) {
              continue;
            }
            final cell = Cell(wcx, wcy);
            cell.id = id;
            cell.rot = rot;
            cell.data = data;
            cell.invisible = false;
            cell.tags.clear();
            cell.lifespan = 0;
            g.set(wcx, wcy, cell);
          }
        }
      }
      if (packetType == "bg") {
        final x = (packet["x"] as num).toInt();
        final y = (packet["y"] as num).toInt();
        final bg = packet["bg"] as String;
        final size = (packet["size"] as num).toInt();

        for (var cx = x - size; cx <= x + size; cx++) {
          for (var cy = y - size; cy <= y + size; cy++) {
            final wcx = grid.wrap ? cx % grid.width : cx;
            final wcy = grid.wrap ? cy % grid.height : cy;
            if (!g.inside(wcx, wcy)) {
              continue;
            }
            g.setPlace(wcx, wcy, bg);
          }
        }
      }
      if (packetType == "wrap") {
        g.wrap = packet["v"];
      }
      if (packetType == "setinit") {
        final levelCode = packet["code"] as String;
        if (isinitial) {
          grid = loadStr(levelCode);
        } else {
          initial = loadStr(levelCode);
        }
      }
      if (packetType == "new-hover") {
        final String uuid = packet["uuid"];
        final x = (packet["x"] as num).toDouble();
        final y = (packet["y"] as num).toDouble();
        final String id = packet["id"];
        final rot = (packet["rot"] as num).toInt();
        final Map<String, dynamic> data = packet["data"];

        hovers[uuid] = CellHover(x, y, id, rot, data);
      }
      if (packetType == "set-hover") {
        final String uuid = packet["uuid"];
        final x = (packet["x"] as num).toDouble();
        final y = (packet["y"] as num).toDouble();

        hovers[uuid]?.x = x;
        hovers[uuid]?.y = y;
      }
      if (packetType == "drop-hover") {
        final String uuid = packet["uuid"];
        hovers.remove(uuid);
      }
      if (packetType == "set-cursor") {
        final String id = packet["id"];
        final x = (packet["x"] as num).toDouble();
        final y = (packet["y"] as num).toDouble();
        final String selection = packet["selection"];
        final String texture = packet["texture"];
        final rot = (packet["rot"] as num).toInt();
        final data = packet["data"] as Map<String, dynamic>;

        if (cursors[id] == null) {
          cursors[id] = CellCursor(x, y, selection, rot, texture, data);
        } else {
          cursors[id]?.x = x;
          cursors[id]?.y = y;
          cursors[id]?.selection = selection;
          cursors[id]?.texture = texture;
          cursors[id]?.rotation = rot;
          cursors[id]?.data = data;
        }
      }
      if (packetType == "invis") {
        final x = (packet["x"] as int).toInt();
        final y = (packet["y"] as int).toInt();
        final bool v = packet["v"];

        final cx = g.cx(x);
        final cy = g.cy(y);

        if (g.inside(cx, cy)) {
          g.at(cx, cy).invisible = v;
        }
      }
      if (packetType == "chat") {
        final String signed = packet["author"];
        final String content = packet["content"];

        if (content.contains("@[$clientID]")) {
          playSound(pingSound);
        }

        final msgStr = "[$signed] > $content";

        msgs.add(msgStr);

        msgsListener.sink.add(msgStr);
      }
      if (packetType == "set-role") {
        final String id = packet["id"];
        final role = getRoleStr(packet["role"]);

        if (role == null) {
          return;
        }

        roles[id] = role;
      }
      if (packetType == "del-role") {
        final String id = packet["id"];
        roles.remove(id);
      }
      if (packetType == "remove-cursor") {
        final String id = packet["id"];
        cursors.remove(id);
      }
      if (packetType == "grid") {
        final String code = packet["code"];
        if (overlays.isActive("loading")) {
          overlays.remove("loading");
          AchievementManager.complete("friends");
        }
        if (isinitial) {
          grid = loadStr(code);
          initial = grid.copy;
          isinitial = true;
          running = false;
          buttonManager.buttons['play-btn']?.texture = 'mover.png';
          buttonManager.buttons['play-btn']?.rotation = 0;
          buttonManager.buttons['wrap-btn']?.title = grid.wrap ? lang('wrapModeOn', "Wrap Mode (ON)") : lang("wrapModeOff", "Wrap Mode (OFF)");

          buildEmpty();
        } else {
          initial = loadStr(code);
        }
      }
      if (packetType == "edtype") {
        final String et = packet["et"];
        edType = et == "puzzle" ? EditorType.loaded : EditorType.making;

        loadAllButtons();
      }
    }
  }

  void legacyMultiplayerCallback(dynamic data) {
    if (data is String) {
      final cmd = data.split(' ').first;
      final args = data.split(' ').sublist(1);

      if (cmd == "place") {
        if (isinitial) {
          final size = int.parse(args[5]);
          for (var ox = -size; ox <= size; ox++) {
            for (var oy = -size; oy <= size; oy++) {
              if (grid.inside(int.parse(args[0]) + ox, int.parse(args[1]) + oy)) {
                grid.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).id = args[2];
                grid.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).rot = int.parse(args[3]);
                if (args.length > 4) {
                  grid.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).data = parseCellDataStr(args[4]);
                }
                grid.setChunk(int.parse(args[0]) + ox, int.parse(args[1]) + oy, args[2]);
                grid.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).invisible = false;
              }
            }
          }
        } else {
          final size = int.parse(args[5]);
          for (var ox = -size; ox <= size; ox++) {
            for (var oy = -size; oy <= size; oy++) {
              if (initial.inside(int.parse(args[0]) + ox, int.parse(args[1]) + oy)) {
                initial.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).id = args[2];
                initial.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).rot = int.parse(args[3]);
                if (args.length > 4) {
                  initial.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).data = parseCellDataStr(args[4]);
                }
                initial.setChunk(int.parse(args[0]) + ox, int.parse(args[1]) + oy, args[2]);
                initial.at(int.parse(args[0]) + ox, int.parse(args[1]) + oy).invisible = false;
              }
            }
          }
        }
      } else if (cmd == "bg") {
        final size = int.parse(args[3]);
        for (var ox = -size; ox <= size; ox++) {
          for (var oy = -size; oy <= size; oy++) {
            if (isinitial) {
              if (grid.inside(int.parse(args[0]) + ox, int.parse(args[1]) + oy)) {
                grid.setPlace(int.parse(args[0]) + ox, int.parse(args[1]) + oy, args[2]);
              }
            } else {
              if (initial.inside(int.parse(args[0]) + ox, int.parse(args[1]) + oy)) {
                initial.setPlace(int.parse(args[0]) + ox, int.parse(args[1]) + oy, args[2]);
              }
            }
          }
        }
      } else if (cmd == "wrap") {
        if (isinitial) {
          grid.wrap = !grid.wrap;
          buttonManager.buttons['wrap-btn']?.title = grid.wrap ? lang('wrapModeOn', "Wrap Mode (ON)") : lang("wrapModeOff", "Wrap Mode (OFF)");
        } else {
          initial.wrap = !initial.wrap;
        }
      } else if (cmd == "setinit") {
        saveGridToHistory(grid);
        if (isinitial) {
          loadFromText(args.first);
          running = false;
          buildEmpty();
        } else {
          initial = loadStr(args.first);
        }
      } else if (cmd == "grid") {
        if (overlays.isActive("loading")) {
          overlays.remove("loading");
          AchievementManager.complete("friends");
        }
        if (isinitial) {
          grid = loadStr(args.first);
          initial = grid.copy;
          isinitial = true;
          running = false;
          buttonManager.buttons['play-btn']?.texture = 'mover.png';
          buttonManager.buttons['play-btn']?.rotation = 0;
          buttonManager.buttons['wrap-btn']?.title = grid.wrap ? lang('wrapModeOn', "Wrap Mode (ON)") : lang("wrapModeOff", "Wrap Mode (OFF)");

          buildEmpty();
        } else {
          initial = loadStr(args.first);
        }
      } else if (cmd == "edtype") {
        edType = args.first == "puzzle" ? EditorType.loaded : EditorType.making;

        loadAllButtons();
      } else if (cmd == "new-hover") {
        hovers[args.first] = CellHover(
          double.parse(args[1]),
          double.parse(args[2]),
          args[3],
          int.parse(
            args[4],
          ),
          TPCML.decodeValue(args.sublist(5).join(" ")),
        );
      } else if (cmd == "set-hover") {
        hovers[args.first]!.x = double.parse(args[1]);
        hovers[args.first]!.y = double.parse(args[2]);
      } else if (cmd == "drop-hover") {
        hovers.remove(args.first);
        if (args.first == clientID) {
          currentSelection = "empty";
          currentRotation = 0;
          currentData = {};
        }
      } else if (cmd == "set-cursor") {
        if (cursors[args.first] == null) {
          cursors[args.first] = CellCursor(
            double.parse(args[1]),
            double.parse(args[2]),
            args[3],
            int.parse(args[4]),
            args[5],
            parseCellDataStr(args[6]),
          );
        } else {
          cursors[args.first]!.x = double.parse(args[1]);
          cursors[args.first]!.y = double.parse(args[2]);
          cursors[args.first]!.selection = args[3];
          cursors[args.first]!.rotation = int.parse(args[4]);
          //cursors[args.first]!.texture = args[5];
        } // I will try to avoid reinstantiation of classes
      } else if (cmd == "remove-cursor") {
        cursors.remove(args.first);
      } else if (cmd == "toggle-invis") {
        final x = int.parse(args[0]);
        final y = int.parse(args[1]);

        grid.at(x, y).invisible = !grid.at(x, y).invisible;
      } else if (cmd == "chat") {
        final payloadStr = args.join(" ");
        try {
          final payload = jsonDecode(payloadStr);

          final author = payload["author"].toString();
          final content = payload["content"].toString();

          if (content.contains("@[$clientID]")) {
            playSound(pingSound);
          }

          final msgStr = "[$author] > $content";

          msgs.add(msgStr);

          msgsListener.sink.add(msgStr);
        } catch (e) {
          print("Invalid message format received!");
          print(e);
        }
      } else if (cmd == "set-role") {
        final id = args[0];
        final role = args[1];

        UserRole? userRole;

        for (var urole in UserRole.values) {
          if (urole.toString().replaceAll('UserRole.', '') == role) {
            userRole = urole;
          }
        }

        if (userRole != null) {
          roles[id] = userRole;
        }
      } else if (cmd == "del-role") {
        roles.remove(args[0]);
      }
    }
  }

  String clientID = "";

  void toggleWrap() {
    grid.wrap = !grid.wrap;
    buttonManager.buttons['wrap-btn']?.title = grid.wrap ? lang('wrapModeOn', "Wrap Mode (ON)") : lang("wrapModeOff", "Wrap Mode (OFF)");
  }

  Map<String, CellHover> hovers = {};
  Map<String, UserRole> roles = {};

  List<String> msgs = [];
  // ignore: close_sinks
  var msgsListener = StreamController<String>();

  void sendMessageToServer(String msg) {
    final payload = <String, dynamic>{
      "content": msg,
      "author": clientID,
    };

    sendToServer("chat", payload);
  }

  List<String> packetQueue = [];
  double packetQueueTimer = 0;

  int get packetQueueLimit => storage.getInt("packet_queue_limit")!;

  void sendToServer(String pt, Map<String, dynamic> packet) {
    if (isMultiplayer && isinitial) {
      packetQueue.add(jsonEncode({"pt": pt, ...packet}));
    }
  }

  void loadAllButtons() {
    buttonManager = ButtonManager(this);

    buttonManager.setButton(
      "back-btn",
      VirtualButton(
        Vector2.zero(),
        Vector2.all(80),
        edType == EditorType.making ? "interface/menu.png" : "interface/back.png",
        ButtonAlignment.topLeft,
        back,
        () => true,
        title: edType == EditorType.making ? lang('editor_menu', 'Editor Menu') : lang('exit', 'Exit Editor'),
        description: edType == EditorType.making ? lang('editor_menu_desc', 'Opens the Editor Menu') : lang('exit_desc', 'Exits the editor'),
      ),
    );

    if (isMultiplayer) {
      buttonManager.setButton(
        "chat-btn",
        VirtualButton(
          Vector2(90, 0),
          Vector2.all(80),
          "interface/chat.png",
          ButtonAlignment.topLeft,
          () {
            showDialog<void>(context: context, builder: (ctx) => ChatDialog());
          },
          () => true,
          title: 'Send Chat Message',
          description: "Send some messages to your friends! You can also ping them with @[<id>] (by replacing <id> with their id)",
        ),
      );
      buttonManager.setButton(
        "see-online-btn",
        VirtualButton(
          Vector2(180, 0),
          Vector2.all(80),
          "interface/see_online.png",
          ButtonAlignment.topLeft,
          () {
            showDialog<void>(context: context, builder: (ctx) => SeeOnlineDialog());
          },
          () => true,
          title: 'See Online',
          description: "Shows you a list of every known user connected to this server",
        ),
      );
    }

    if (edType == EditorType.making) {
      buttonManager.setButton(
        "prop-edit-btn",
        VirtualButton(
          Vector2(0, 90),
          Vector2.all(80),
          "interface/property_editor.png",
          ButtonAlignment.topLeft,
          () {
            showDialog<void>(context: context, builder: (ctx) => PropertyEditorDialog());
          },
          () => props[currentSelection] != null,
          title: 'Property Editor',
          description: 'It looks like you have selected a cell with adjustable properties.\nClick on this button to edit them',
        )..startPos = Vector2(-90, 90),
      );

      buttonManager.setButton(
        "search-cell-btn",
        VirtualButton(
          Vector2(15, 15),
          Vector2.all(70),
          "interface/search_cell.png",
          ButtonAlignment.bottomRight,
          () {
            showDialog<void>(context: context, builder: (ctx) => SearchCellDialog());
          },
          () => true,
          title: 'Search Cell',
          description: 'Search for a cell',
        ),
      );

      buttonManager.setButton(
        "terminal-btn",
        VirtualButton(
          Vector2(95, 15),
          Vector2.all(70),
          "interface/terminal.png",
          ButtonAlignment.bottomRight,
          () {
            showDialog<void>(context: context, builder: (ctx) => TerminalDialog());
          },
          () => true,
          title: 'Terminal',
          description: 'Open a very simple Terminal with a LISP-based shell language.',
        ),
      );
    }

    buttonManager.setButton(
      "play-btn",
      VirtualButton(
        Vector2(
          20,
          30,
        ),
        Vector2.all(40),
        "mover.png",
        ButtonAlignment.topRight,
        playPause,
        () => true,
        title: lang('playPause.title', 'Play / Pause'),
        description: lang('playPause.desc', 'Play or Pause the simulation\n(Space key)'),
      ),
    );

    if (isMultiplayer && edType == EditorType.loaded) {
      buttonManager.setButton(
        "m-load-btn",
        VirtualButton(
          Vector2(
            20,
            80,
          ),
          Vector2.all(40),
          "interface/load.png",
          ButtonAlignment.topRight,
          () {
            try {
              FlutterClipboard.controlV().then(
                (str) {
                  if (str is ClipboardData) {
                    saveGridToHistory(grid);

                    loadFromText(str.text ?? "");
                    timeGrid = null;
                    running = false;
                    isinitial = true;

                    sendToServer('setinit', {"code": SavingFormat.encodeGrid(grid)});

                    hovers.forEach(
                      (key, value) {
                        sendToServer('drop-hover', {"uuid": key});
                      },
                    );

                    buildEmpty();
                  }
                },
              );
            } catch (e) {
              print(e);
              showDialog<void>(
                context: context,
                builder: (ctx) {
                  return LoadSaveErrorDialog(e.toString());
                },
              );
            }
          },
          () => isinitial,
          title: lang('loadNewPuzzle.title', 'Load New Puzzle'),
          description: lang(
            'loadNewPuzzle.desc',
            'Load a new puzzle to play, please do not abuse this mechanic!',
          ),
        ),
      );
    }

    buttonManager.setButton(
      "save-btn",
      VirtualButton(
        Vector2(
          edType == EditorType.making ? 120 : 70,
          30,
        ),
        Vector2.all(40),
        "interface/save.png",
        ButtonAlignment.topRight,
        () {
          final c = grid.encode();
          FlutterClipboard.copy(c);
          if (worldIndex != null) {
            worldManager.saveWorld(worldIndex!);
          } else {
            showDialog<void>(context: context, builder: (ctx) => SaveLevelDialog(c));
          }
        },
        () => true,
        title: lang("save.title", 'Save to clipboard'),
        description: lang(
          'save.desc',
          'Save the simulation as an encoded string into your clipboard',
        ),
      ),
    );

    if (edType == EditorType.making) {
      buttonManager.setButton(
        "rot-cw-btn",
        VirtualButton(
          Vector2(
            70,
            30,
          ),
          Vector2.all(40),
          "rotator_cw.png",
          ButtonAlignment.topRight,
          e,
          () => true,
          title: lang('rotate_cw.title', 'Rotate CW'),
          description: lang(
            'rotate_cw.desc',
            'Rotates the cells in the UI or what you are about to paste clockwise\n(E key)',
          ),
        ),
      );

      buttonManager.setButton(
        "rot-ccw-btn",
        VirtualButton(
          Vector2(
            70,
            80,
          ),
          Vector2.all(40),
          "rotator_ccw.png",
          ButtonAlignment.topRight,
          q,
          () => true,
          title: lang('rotate_ccw.title', 'Rotate CCW'),
          description: lang(
            'rotate_ccw.desc',
            'Rotates the cells in the UI or what you are about to paste counter-clockwise\n(Q key)',
          ),
        ),
      );

      buttonManager.setButton(
        "select-btn",
        VirtualButton(
          Vector2(
            170,
            30,
          ),
          Vector2.all(40),
          "interface/select.png",
          ButtonAlignment.topRight,
          () {
            game.selecting = !game.selecting;
            if (game.selecting) {
              buttonManager.buttons['select-btn']?.texture = "interface/select_on.png";
            }
            if (!game.selecting) {
              buttonManager.buttons['select-btn']?.texture = "interface/select.png";
              game.setPos = false;
              game.dragPos = false;
            }
            game.pasting = false;
            buttonManager.buttons['paste-btn']?.texture = 'interface/paste.png';
          },
          () => true,
          title: 'Toggle Select Mode',
          description:
              'In Select Mode you drag an area and can copy, cut, or paste it\nArrow keys move the selected area\nCtrl+arrow keys resize the selection area\nShift + arrow keys move the selection area',
        ),
      );

      buttonManager.setButton(
        "copy-btn",
        VirtualButton(
          Vector2(
            170,
            80,
          ),
          Vector2.all(40),
          "interface/copy.png",
          ButtonAlignment.topRight,
          copy,
          () => selecting && !dragPos,
          title: 'Copy',
          description: 'Copy selected area\n(Ctrl + C)',
        ),
      );

      buttonManager.setButton(
        "cut-btn",
        VirtualButton(
          Vector2(
            170,
            130,
          ),
          Vector2.all(40),
          "interface/cut.png",
          ButtonAlignment.topRight,
          () {
            copy();
            for (var x = 0; x < selW; x++) {
              for (var y = 0; y < selH; y++) {
                final cx = selX + x;
                final cy = selY + y;
                if (grid.inside(cx, cy)) {
                  if (!isMultiplayer) {
                    grid.set(cx, cy, Cell(cx, cy));
                  }
                  sendToServer('place', {"x": cx, "y": cy, "id": "empty", "rot": 0, "data": <String, dynamic>{}, "size": 1});
                }
              }
            }
          },
          () => selecting && !dragPos,
          title: 'Cut',
          description: 'Copy and delete selected area\n(Ctrl + X)',
        ),
      );

      buttonManager.setButton(
        "del-btn",
        VirtualButton(
          Vector2(
            170,
            180,
          ),
          Vector2.all(40),
          "interface/del.png",
          ButtonAlignment.topRight,
          () {
            if (selW < 0) {
              selW *= -1;
              selX -= selW;
            }
            if (selH < 0) {
              selH *= -1;
              selY -= selH;
            }

            selW--;
            selH--;

            for (var x = 0; x <= selW; x++) {
              for (var y = 0; y <= selH; y++) {
                final cx = selX + x;
                final cy = selY + y;
                if (grid.inside(cx, cy)) {
                  if (!isMultiplayer) {
                    grid.set(cx, cy, Cell(cx, cy));
                  }
                  sendToServer('place', {"x": cx, "y": cy, "id": "empty", "rot": 0, "data": <String, dynamic>{}, "size": 1});
                }
              }
            }

            selecting = false;
            buttonManager.buttons['select-btn']!.texture = "interface/select.png";
          },
          () => selecting && !dragPos,
          title: 'Delete',
          description: 'Delete selected area',
        ),
      );

      buttonManager.setButton(
        "save-blueprint-btn",
        VirtualButton(
          Vector2(
            170,
            230,
          ),
          Vector2.all(40),
          "interface/save_bp.png",
          ButtonAlignment.topRight,
          () {
            if (selW < 0) {
              selW *= -1;
              selX -= selW;
            }
            if (selH < 0) {
              selH *= -1;
              selY -= selH;
            }

            final g = <List<Cell>>[];

            selW--;
            selH--;

            for (var x = 0; x <= selW; x++) {
              g.add(<Cell>[]);
              for (var y = 0; y <= selH; y++) {
                final cx = selX + x;
                final cy = selY + y;
                if (grid.inside(cx, cy)) {
                  g.last.add(grid.at(cx, cy).copy);
                }
              }
            }

            final bp = Grid(g.length, g.isEmpty ? 0 : g.first.length);
            bp.tiles = g.map((row) => row.map((cell) => CellGridTile(cell, "empty", [false, false, false, false])).toList()).toList();
            final bpSave = SavingFormat.encodeGrid(bp, title: "Unnamed Blueprint", description: "This blueprint currently has no name");

            FlutterClipboard.controlC(bpSave).then((v) {
              if (v) {
                showDialog<void>(
                  context: context,
                  builder: (ctx) {
                    return SaveBlueprintDialog(bpSave);
                  },
                );
              }
            });

            selecting = false;
            setPos = false;
            dragPos = false;

            selW++;
            selH++;

            buttonManager.buttons['select-btn']!.texture = "interface/select.png";
          },
          () => selecting && !dragPos,
          title: 'Save as Blueprint',
          description: 'Saves selected area to clipboard as a blueprint',
        ),
      );

      buttonManager.setButton(
        "replace-btn",
        VirtualButton(
          Vector2(
            170,
            280,
          ),
          Vector2.all(40),
          "interface/copy.png",
          ButtonAlignment.topRight,
          () {
            showDialog<void>(
              context: context,
              builder: (ctx) => ReplaceCellDialog(),
            );
          },
          () => selecting && !dragPos,
          title: 'Replace Cell',
          description: 'Replaces a cell with another',
        ),
      );

      buttonManager.setButton(
        "load-blueprint-btn",
        VirtualButton(
          Vector2(120, 180),
          Vector2.all(40),
          "interface/load_bp.png",
          ButtonAlignment.topRight,
          () {
            try {
              FlutterClipboard.paste().then((txt) {
                try {
                  final blueprint = loadStr(txt, false);
                  gridClip.activate(blueprint.width, blueprint.height, blueprint.tiles.map((row) => row.map((tile) => tile.cell).toList()).toList());
                  selecting = false;
                  setPos = false;
                  dragPos = false;
                  pasting = true;
                  buttonManager.buttons['paste-btn']?.texture = 'interface/paste_on.png';
                } catch (e) {
                  print(e);
                  showDialog<void>(
                    context: context,
                    builder: (context) => LoadBlueprintErrorDialog(e.toString()),
                  );
                }
              });
            } catch (e) {
              print(e);
              showDialog<void>(
                context: context,
                builder: (context) => LoadBlueprintErrorDialog(e.toString()),
              );
            }
          },
          () => true,
          title: 'Load as Blueprint',
          description: 'Loads a blueprint from your clipboard (using a level code)',
        ),
      );

      buttonManager.setButton(
        "del-blueprint-btn",
        VirtualButton(
          Vector2(120, 230),
          Vector2.all(40),
          "interface/del_bp.png",
          ButtonAlignment.topRight,
          () async {
            await showDialog<void>(
              context: context,
              builder: (ctx) {
                return DeleteBlueprintDialog();
              },
            );
          },
          () => true,
          title: 'Delete Blueprints',
          description: 'Will reveal a popup where you can select which blueprints you want to delete',
        ),
      );

      buttonManager.setButton(
        "paste-btn",
        VirtualButton(
          Vector2(
            220,
            30,
          ),
          Vector2.all(40),
          "interface/select.png",
          ButtonAlignment.topRight,
          () {
            game.pasting = !game.pasting;

            buttonManager.buttons['paste-btn']?.texture = game.pasting ? 'interface/paste_on.png' : 'interface/paste.png';

            buttonManager.buttons['select-btn']?.texture = "interface/select.png";
          },
          () => gridClip.active,
          title: 'Paste',
          description: 'Paste what you have copied\n(Ctrl + V)',
        ),
      );

      buttonManager.setButton(
        "onetick-btn",
        VirtualButton(
          Vector2(
            20,
            80,
          ),
          Vector2.all(40),
          "redirector.png",
          ButtonAlignment.topRight,
          oneTick,
          () => true,
          title: 'Advance one tick',
          description: 'Steps the simulation forward by 1 tick\n(F key)',
        ),
      );

      buttonManager.setButton(
        "restore-btn",
        VirtualButton(
          Vector2(
            20,
            130,
          ),
          Vector2.all(40),
          "rotator_180.png",
          ButtonAlignment.topRight,
          restoreInitial,
          () => !isinitial,
          title: 'Restore to initial state',
          description: 'Restores the simulation to the initial state\n(Ctrl + R)',
        ),
      );
      buttonManager.setButton(
        "setinitial-btn",
        VirtualButton(
          Vector2(
            20,
            180,
          ),
          Vector2.all(40),
          "generator.png",
          ButtonAlignment.topRight,
          setInitial,
          () => !isinitial,
          title: 'Set Initial',
          description: 'Sets the simulation\'s current state as the initial state\n(Ctrl + I)',
        ),
      );
      buttonManager.setButton(
        "load-btn",
        VirtualButton(
          Vector2(
            120,
            80,
          ),
          Vector2.all(40),
          "interface/load.png",
          ButtonAlignment.topRight,
          () {
            try {
              FlutterClipboard.controlV().then(
                (str) {
                  if (str is ClipboardData) {
                    isinitial = true;
                    running = false;

                    if (isMultiplayer) {
                      final g = loadStr(str.text!, false);
                      sendToServer('setinit', {"code": SavingFormat.encodeGrid(g, title: g.title, description: g.desc)});
                    } else {
                      saveGridToHistory(grid);
                      try {
                        loadFromText(str.text ?? "");
                      } catch (e) {
                        gridHistory.removeLast();
                        showDialog<void>(context: context, builder: (ctx) => LoadSaveErrorDialog(e.toString()));
                      }
                      saveHistory();
                    }

                    buildEmpty();
                  }
                },
              );
            } catch (e) {
              print(e);
              showDialog<void>(
                context: context,
                builder: (ctx) {
                  return LoadSaveErrorDialog(e.toString());
                },
              );
            }
          },
          () => true,
          title: 'Load from clipboard',
          description: 'Sets the grid to the level stored in the string in your clipboard',
        ),
      );
      buttonManager.setButton(
        "wrap-btn",
        VirtualButton(
          Vector2(
            120,
            130,
          ),
          Vector2.all(40),
          "interface/wrap.png",
          ButtonAlignment.topRight,
          () {
            if (isMultiplayer && isinitial) {
              sendToServer('wrap', {"v": !grid.wrap});
            } else {
              grid.wrap = !grid.wrap;
              buttonManager.buttons['wrap-btn']?.title = grid.wrap ? lang('wrapModeOn', "Wrap Mode (ON)") : lang("wrapModeOff", "Wrap Mode (OFF)");
            }
          },
          () => true,
          title: lang("wrapModeOff", 'Wrap Mode (OFF)'),
          description: 'When Wrap mode is on, cells will wrap around the grid',
        ),
      );

      loadCellButtons();

      buttonManager.buttons.forEach((id, btn) {
        btn.time = 500;
      });
    }
  }

  void loadCellButtons() {
    var catOff = 80.0;
    var leftCatOff = 80.0;
    var catSize = 60.0;

    var cellSize = 40.0;

    for (var i = 0; i < categories.length; i++) {
      buttonManager.setButton(
        'cat$i',
        VirtualButton(
          Vector2((leftCatOff - catSize) / 2 + i * catOff, catOff),
          Vector2(catSize, catSize),
          '${categories[i].look}.png',
          ButtonAlignment.bottomLeft,
          () {
            final cat = categories[i]; // Kitty
            resetAllCategories(cat);

            cat.opened = !cat.opened;

            AchievementManager.complete("overload");

            for (var j = 0; j < cat.items.length; j++) {
              buttonManager.buttons['cat${i}cell$j']?.time = 0;
              buttonManager.buttons['cat${i}cell$j']?.startPos = (Vector2((leftCatOff - catSize) / 2 + i * catOff, catOff) + Vector2.all((catSize - cellSize) / 2)) * uiScale;
            }
          },
          () => true,
          title: lang("${categories[i]}.title", categories[i].title),
          description: lang(
                "${categories[i]}.desc",
                categories[i].description,
              ) +
              (isDebugMode ? "\nID: ${categories[i]}" : ""),
          isCellButton: true,
        ),
      );
      for (var j = 0; j < categories[i].items.length; j++) {
        final isCategory = (categories[i].items[j] is CellCategory);
        buttonManager.setButton(
          'cat${i}cell$j',
          VirtualButton(
            Vector2((leftCatOff - catSize) / 2 + i * catOff + (catSize - cellSize) / 2, catOff + cellSize * (j + 1)),
            Vector2(cellSize, cellSize),
            isCategory ? '${categories[i].items[j].look}.png' : '${categories[i].items[j]}.png',
            ButtonAlignment.bottomLeft,
            () {
              if (isCategory) {
                categories[i].items[j].opened = !(categories[i].items[j].opened);

                final isOpen = categories[i].items[j].opened;

                AchievementManager.complete("subcells");

                resetAllCategories(categories[i]);

                categories[i].items[j].opened = isOpen;

                for (var k = 0; k < categories[i].items[j].items.length; k++) {
                  buttonManager.buttons['cat${i}cell${j}sub$k']?.time = 0;
                  buttonManager.buttons['cat${i}cell${j}sub$k']?.startPos = Vector2((leftCatOff - catSize) / 2 + i * catOff + (catSize - cellSize) / 2, catOff + cellSize * (j + 1)) * uiScale;
                }
              } else {
                whenSelected(categories[i].items[j]);
              }
            },
            () {
              return categories[i].opened;
            },
            title: isCategory
                ? lang("${categories[i]}.${categories[i].items[j]}.title", categories[i].items[j].title)
                : lang("${categories[i].items[j]}.title", (cellInfo[categories[i].items[j]] ?? defaultProfile).title),
            description: isCategory
                ? lang('${categories[i]}.${categories[i].items[j]}.desc', categories[i].items[j].description) +
                    (isDebugMode ? "\nID: ${categories[i].toString()}.${categories[i].items[j].toString()}" : "")
                : lang("${categories[i].items[j].toString()}.desc", (cellInfo[categories[i].items[j]] ?? defaultProfile).description) + (isDebugMode ? "\nID: ${categories[i].items[j]}" : ""),
            isCellButton: true,
          )..time = 50,
        );

        buttonManager.buttons['cat${i}cell$j']?.duration += 0.005 * j;

        if (isCategory) {
          final cat = categories[i].items[j] as CellCategory;
          final catPos = Vector2((leftCatOff - catSize) / 2 + i * catOff + (catSize - cellSize) / 2, catOff + cellSize * (j + 1));
          for (var k = 0; k < cat.items.length; k++) {
            final cell = cat.items[k] as String;

            final xOff = cellSize + (k % cat.max) * cellSize;
            final yOff = (k ~/ cat.max) * cellSize;

            final off = Vector2(xOff, yOff);

            buttonManager.setButton(
              'cat${i}cell${j}sub$k',
              VirtualButton(
                catPos + off,
                Vector2.all(cellSize),
                "$cell.png",
                ButtonAlignment.bottomLeft,
                () => whenSelected(cell),
                () => cat.opened,
                title: lang(
                  "$cell.title",
                  (cellInfo[cell] ?? defaultProfile).title,
                ),
                description: lang(
                  "$cell.desc",
                  (cellInfo[cell] ?? defaultProfile).description + (isDebugMode ? "\nID: $cell" : ""),
                ),
                isCellButton: true,
              )
                ..time = 50
                ..duration += k * 0.005,
            );
          }
        }
      }
    }
  }

  Sprite? emptyImage;

  List<Sprite> empties = [];

  // By how much the resolution decreases
  static const emptyLinearScale = 2;

  // When to change it
  static const emptyLinearEffect = 3;

  Future<Sprite?> buildEmpty() async {
    final e = Flame.images.fromCache('empty.png');
    final rowCompose = ImageComposition();
    for (var x = 0; x < grid.width; x++) {
      rowCompose.add(e, Vector2(x * e.width.toDouble(), 0));
    }
    final rowImage = await rowCompose.compose();
    final emptyCompose = ImageComposition(
      defaultBlendMode: BlendMode.color,
    );
    for (var y = 0; y < grid.height; y++) {
      emptyCompose.add(
        rowImage,
        Vector2(0, y.toDouble()) * rowImage.height.toDouble(),
      );
    }
    final composed = await emptyCompose.compose();
    emptyImage = Sprite(composed);
    empties.clear();
    empties.add(emptyImage!);
    for (var i = 0; i < 2; i++) {
      final scale = (i + 1) * emptyLinearScale;
      emptyCompose.clear();
      final jpeg = emptyImage!.image;
      final w = jpeg.width ~/ scale;
      final h = jpeg.height ~/ scale;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      emptyImage?.render(canvas, size: Vector2(w.toDouble(), h.toDouble()));
      empties.add(Sprite(await recorder.endRecording().toImageSafe(w, h)));
    }
    return emptyImage;
  }

  var isDebugMode = false;
  var interpolation = true;
  var cellbar = false;
  var altRender = false;
  var middleMove = false;
  var cursorTexture = "cursor";
  var proxyMirror = false;
  var replaceBgWithRect = false;

  @override
  Future<void>? onLoad() async {
    isDebugMode = storage.getBool("debug") ?? false;
    interpolation = storage.getBool("interpolation") ?? true;
    cellbar = storage.getBool("cellbar") ?? false;
    altRender = storage.getBool("alt_render") ?? false;
    middleMove = storage.getBool("middle_move") ?? false;
    cursorTexture = storage.getString("cursor_texture") ?? "cursor";
    proxyMirror = storage.getBool("local_packet_mirror") ?? false;
    replaceBgWithRect = storage.getBool("background_rect") ?? false;

    initial = grid.copy;

    if (worldIndex != null) {
      gridTabIndex = worldIndex!;
    }
  
    lastTickKeys.clear();

    await loadAllButtonTextures();

    await Flame.images.load('base.png');
    await Flame.images.load(textureMap['missing.png'] ?? 'missing.png');
    await Flame.images.load('empty.png');

    // Load effects
    await Flame.images.loadAll([
      "effects/stopped.png",
      "effects/started.png",
      "effects/heat.png",
      "effects/cold.png",
      "effects/consistent.png",
      "effects/shield.png",
    ]);

    await loadSkinTextures();

    if (edType == EditorType.making) {
      // In sandbox
      AchievementManager.complete("editor");
    } else if (edType == EditorType.loaded) {
      // In puzzle
      AchievementManager.complete("solving");
    }

    await buildEmpty();

    // Handle multiplayer
    if (isMultiplayer) {
      channel = WebSocketChannel.connect(Uri.parse(ip!));

      loadAllButtons();

      multiplayerListener = channel.stream.listen(
        multiplayerCallback,
        onDone: () {
          Navigator.of(context).popUntil((route) {
            return route.settings.name == "/main";
          });
          showDialog<void>(
            context: context,
            builder: (ctx) {
              return DisconnectionDialog();
            },
          );
        },
        onError: (dynamic e) {
          Navigator.of(context).popUntil((route) {
            return route.settings.name == "/main";
          });
          showDialog<void>(
            context: context,
            builder: (ctx) {
              return BasicErrorDialog(e.toString());
            },
          );
        },
      );

      clientID = storage.getString('clientID') ?? '@uuid';

      while (clientID.contains('@uuid')) {
        clientID = clientID.replaceFirst('@uuid', Uuid().v4());
      }
      //sendToServer('version ${currentVersion.split(' ').first}');
      sendToServer('token', {"version": currentVersion.split(' ').first, "clientID": clientID});

      Flame.images.load('interface/cursor.png');

      overlays.add('loading');
    }

    loadHistory();

    defaultCellSize = baseCellSize * storage.getDouble('cell_scale')!;
    cellSize = defaultCellSize.toDouble();
    if (edType == EditorType.loaded) {
      wantedCellSize /= (max(grid.width, grid.height) / 2);
      storedOffX = canvasSize.x / 2 - (grid.width / 2) * cellSize;
      storedOffY = canvasSize.y / 2 - (grid.height / 2) * cellSize;
      smoothOffX = storedOffX;
      smoothOffY = storedOffY;
    }
    await Flame.images.loadAll(
      cells.map((name) => textureMap["$name.png"] ?? "$name.png").toList(),
    );

    await Flame.images.load('mechanical/pixel_on.png');
    await Flame.images.load('electrical/electric_wire_on.png');

    loadAllButtons();

    wantedCellSize = defaultCellSize;
    cellSize = defaultCellSize.toDouble();
    keys = {};
    puzzleWin = false;
    puzzleLost = false;
    delay = storage.getDouble("delay") ?? 0.15;
    realisticRendering = storage.getBool("realistic_render") ?? true;

    QueueManager.runQueue("post-game-init");

    return super.onLoad();
  }

  int get cellMouseX => (mouseX - offX) ~/ cellSize;
  int get cellMouseY => (mouseY - offY) ~/ cellSize;

  int pixelToCellX(int px) => (px - offX) ~/ cellSize;
  int pixelToCellY(int py) => (py - offY) ~/ cellSize;

  double cellToPixelX(int cx) => (cx * cellSize) + offX;
  double cellToPixelY(int cy) => (cy * cellSize) + offY;

  Map<String, CellCursor> cursors = {};

  void fancyRender(Canvas canvas) {
    if (realisticRendering && (running || onetick)) {
      for (var b in grid.brokenCells) {
        b.render(canvas, interpolation ? (itime % delay) / delay : 1);
      }
    }
  }

  double alltime = 0;

  @override
  // Main game rendering
  void render(Canvas canvas) {
    try {
      this.canvas = canvas;

      if (overlays.isActive("loading")) {
        canvas.drawRect(
          Offset.zero & Size(canvasSize.x, canvasSize.y),
          Paint()..color = Colors.black,
        );
        return;
      }

      if (emptyImage == null) {
        canvas.drawRect(
          Offset.zero & Size(canvasSize.x, canvasSize.y),
          Paint()..color = Colors.black,
        );
        final tp = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: 'Building Empty Image composition',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
            ),
          ),
        );
        tp.layout();

        final pos = (canvasSize - tp.size.toVector2()) / 2;

        tp.paint(
          canvas,
          pos.toOffset(),
        );
        return;
      }

      canvas.drawRect(
        Offset.zero & Size(canvasSize.x, canvasSize.y),
        Paint()..color = settingsColor('game_bg', Color.fromARGB(255, 27, 27, 27)),
      );

      //canvas.save();

      canvas.translate(offX, offY);

      if (!firstRender) {
        final opacity = storage.getDouble("grid_opacity")!;
        if (replaceBgWithRect) {
          canvas.drawRect(Offset.zero & Size(grid.width / 1, grid.height / 1) * cellSize, Paint()..color = Color.fromARGB((opacity * 255).toInt(), 49, 47, 47));
        } else {
          var downscaleTarget = defaultCellSize / cellSize;
          var i = 0;

          while (downscaleTarget > emptyLinearEffect) {
            downscaleTarget /= emptyLinearEffect;
            i++;
          }

          if (empties.isNotEmpty && i >= empties.length) {
            i = empties.length - 1;
          }

          var jpeg = empties.elementAtOrNull(i);
          jpeg?.render(
            canvas,
            position: Vector2.zero(),
            size: Vector2(
              grid.width * cellSize,
              grid.height * cellSize,
            ),
            overridePaint: Paint()..color = Colors.white.withOpacity(opacity),
          );
        }
      }

      firstRender = false;

      var sx = floor((-offX - cellSize) / cellSize);
      var sy = floor((-offY - cellSize) / cellSize);
      var ex = ceil((canvasSize.x - offX) / cellSize);
      var ey = ceil((canvasSize.y - offY) / cellSize);

      sx = max(sx, 0);
      sy = max(sy, 0);
      ex = min(ex, grid.width);
      ey = min(ey, grid.height);

      if (viewbox != null) {
        sx = viewbox!.topLeft.dx.toInt();
        sy = viewbox!.topLeft.dy.toInt();
        ex = viewbox!.bottomRight.dx.toInt();
        ey = viewbox!.bottomRight.dy.toInt();
      }

      if (realisticRendering) {
        const extra = 5;
        sx = max(sx - extra, 0);
        sy = max(sy - extra, 0);
        ex = min(ex + extra, grid.width);
        ey = min(ey + extra, grid.height);
      }

      final cellsPos = grid.quadChunk.fetch("all", sx, sy, ex, ey);

      for (var p in cellsPos) {
        final x = p[0];
        final y = p[1];

        if (grid.placeable(x, y) != "empty") {
          renderEmpty(grid.at(x, y), x, y);
        }
      }

      fancyRender(canvas);

      for (var p in cellsPos) {
        final x = p[0];
        final y = p[1];

        if (grid.at(x, y).id != "empty") {
          renderCell(grid.at(x, y), x, y);
        }
      }

      for (var fc in grid.fakeCells) {
        fc.render(canvas);
      }

      grid.fakeCells.removeWhere((fc) => fc.dead);

      if (hideUI) {
        return;
      }

      if (edType == EditorType.making && realisticRendering && mouseInside && !(pasting || selecting)) {
        var mx = cellMouseX; // shorter names
        var my = cellMouseY; // shorter names

        for (var cx = mx - brushSize; cx <= mx + brushSize; cx++) {
          for (var cy = my - brushSize; cy <= my + brushSize; cy++) {
            if (grid.inside(cx, cy)) {
              final ocx = cx;
              final ocy = cy;
              if (grid.wrap) {
                cx += grid.width;
                cx %= grid.width;
                cy += grid.height;
                cy %= grid.height;
              }
              renderCell(
                Cell(cx, cy)
                  ..id = currentSelection
                  ..rot = currentRotation
                  ..lastvars.lastRot = currentRotation
                  ..data = currentData,
                cx,
                cy,
                Paint()..color = Colors.white.withOpacity(0.5),
              );
              cx = ocx;
              cy = ocy;
            }
          }
        }
      }

      if (edType == EditorType.making && interpolation && mouseInside && !selecting) {
        final mx = cellMouseX;
        final my = cellMouseY;

        final coolOverlayThickness = cellSize / 8;
        final coolOverlayWidth = (pasting ? gridClip.width : (brushSize + 1) * 2 - 1) * cellSize + coolOverlayThickness * 2;
        final coolOverlayHeight = (pasting ? gridClip.height : (brushSize + 1) * 2 - 1) * cellSize + coolOverlayThickness * 2;
        const coolOverlayAnimTime = 1;
        final delta = lerp(0, 1, (sin(alltime / coolOverlayAnimTime).abs()));

        final coolOverlaySpacingW = coolOverlayWidth + cellSize * delta;
        final coolOverlaySpacingH = coolOverlayHeight + cellSize * delta;

        final sx = mx * cellSize;
        final sy = my * cellSize;

        final rect = Offset(
              sx - (coolOverlaySpacingW - cellSize) / 2 + (pasting ? (gridClip.width ~/ 2 + (gridClip.width % 2 - 1) / 2) * cellSize : 0),
              sy - (coolOverlaySpacingH - cellSize) / 2 + (pasting ? (gridClip.height ~/ 2 + (gridClip.height % 2 - 1) / 2) * cellSize : 0),
            ) &
            Size(coolOverlaySpacingW, coolOverlaySpacingH);

        var coolOverlayColor = settingsColor('cellbar_border', Colors.grey[60]);

        if (pasting) {
          if (grid.inside(mx, my) || grid.inside(mx + gridClip.width, my) || grid.inside(mx, my + gridClip.height) || grid.inside(mx + gridClip.width, my + gridClip.height)) {
            for (var x = 0; x < gridClip.width; x++) {
              for (var y = 0; y < gridClip.height; y++) {
                if (grid.inside(mx + x, my + y)) {
                  if (gridClip.cells[x][y].id != "empty" && grid.at(mx + x, my + y).id != "empty") {
                    final c = (grid.at(mx + x, my + y).copy)..lifespan = 0;
                    if (c != gridClip.cells[x][y]) {
                      coolOverlayColor = Colors.red;
                    }
                  }
                } else {
                  coolOverlayColor = Colors.red;
                }
              }
            }
            canvas.drawRect(
              rect,
              Paint()
                ..color = coolOverlayColor
                ..strokeWidth = coolOverlayThickness
                ..style = PaintingStyle.stroke,
            );
          }
        } else if (grid.inside(mx, my)) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = coolOverlayColor
              ..strokeWidth = coolOverlayThickness
              ..style = PaintingStyle.stroke,
          );
        }
      }

      if (edType == EditorType.loaded && currentSelection != "empty" && mouseInside && !running) {
        final c = Cell(0, 0);
        c.lastvars = LastVars(currentRotation, 0, 0, currentSelection);
        c.lastvars.lastPos = Offset(
          (mouseX - offX) / cellSize,
          (mouseY - offY) / cellSize,
        );
        c.id = currentSelection;
        c.rot = currentRotation;
        c.data = currentData;
        renderCell(
          c,
          (mouseX - offX) / cellSize - 0.5,
          (mouseY - offY) / cellSize - 0.5,
        );
      }
      if (isMultiplayer && !running) {
        hovers.forEach(
          (id, hover) {
            if (id != clientID) {
              renderCell(
                Cell(0, 0)
                  ..id = hover.id
                  ..rot = hover.rot
                  ..data = hover.data,
                hover.x,
                hover.y,
              );
            }
          },
        );
      }

      if (pasting) {
        final mx = grid.wrap ? (cellMouseX + grid.width) % grid.width : cellMouseX;

        final my = grid.wrap ? (cellMouseY + grid.height) % grid.height : cellMouseY;
        gridClip.render(canvas, mx, my);
      } else if (selecting && setPos) {
        final selScreenX = (selX * cellSize);
        final selScreenY = (selY * cellSize);
        canvas.drawRect(
          Offset(selScreenX, selScreenY) & Size(selW * cellSize, selH * cellSize),
          Paint()..color = (Colors.grey[100].withOpacity(0.4)),
        );

        if (isDebugMode) {
          final tp = TextPainter(
            text: TextSpan(
              text: 'X: $selX\nY: $selY\nA: ${selW.abs()} x ${selH.abs()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * uiScale,
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          tp.layout();

          tp.paint(canvas, Offset(selScreenX, selScreenY + selH * cellSize));
        }
      }

      redparticles.render(canvas);
      blueparticles.render(canvas);
      greenparticles.render(canvas);
      yellowparticles.render(canvas);
      purpleparticles.render(canvas);
      tealparticles.render(canvas);
      blackparticles.render(canvas);
      magentaparticles.render(canvas);

      //grid.forEach(renderCell);

      canvas.restore();

      if (!running) {
        cursors.forEach(
          (id, cursor) {
            if (id != clientID) {
              if (cursor.selection != "empty" && edType == EditorType.making) {
                renderCell(
                  Cell(0, 0)
                    ..id = cursor.selection
                    ..rot = cursor.rotation,
                  cursor.x + offX / cellSize,
                  cursor.y + offY / cellSize,
                );
              }

              final p = (cursor.pos + Vector2.all(0.5)) * cellSize + Vector2(offX, offY);

              var c = 'interface/cursor.png';
              // Haha cool
              if (cursor.texture != "cursor") {
                c = textureMap["${cursor.texture}.png"] ?? "${cursor.texture}.png";
              }
              if (!Flame.images.containsKey(c) || !cursorTextures.contains(cursor.texture)) {
                c = 'base.png'; // No crashing rendering or setting stuff to other things :trell:
              }
              // Haha cooln't
              Sprite(Flame.images.fromCache(c)).render(
                canvas,
                position: p,
                size: Vector2.all(cellSize / 2),
              );

              if (isDebugMode) {
                final tp = TextPainter(
                  textDirection: TextDirection.ltr,
                  text: TextSpan(
                    text: id,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: cellSize / 3,
                    ),
                  ),
                );
                tp.layout();
                tp.paint(canvas, p.toOffset());
              }
            }
          },
        );
      }

      if (cellbar && edType == EditorType.making) {
        final cellbarBackground = settingsColor('cellbar_background', Colors.grey[180]);
        final cellbarBorder = settingsColor('cellbar_border', Colors.grey[60]);

        canvas.drawRect(
          Offset(0, canvasSize.y - 110 * uiScale) & Size(canvasSize.x, 110 * uiScale),
          Paint()..color = cellbarBackground,
        );

        final w = 5.0 * uiScale;

        canvas.drawRect(
          Offset(w, canvasSize.y - 110 * uiScale + w) & Size(canvasSize.x - w, 110 * uiScale - w),
          Paint()
            ..color = cellbarBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = w,
        );
      }

      AchievementRenderer.draw(canvas, canvasSize);

      buttonManager.forEach(
        (key, button) {
          button.canvasSize = canvasSize;
          button.render(canvas, canvasSize);
        },
      );

      if (isDebugMode && !isinitial) {
        final tp = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: 'Tick Count: ${grid.tickCount}',
            style: TextStyle(
              fontSize: 10.sp,
            ),
          ),
        );

        tp.layout();

        tp.paint(canvas, Offset(10 * uiScale, 70 * uiScale));
      }
      if (storage.getBool('show_titles') ?? true) {
        var hasShown = false;
        buttonManager.forEach(
          (key, button) {
            if (button.isHovered(mouseX.toInt(), mouseY.toInt()) && button.shouldRender() && mouseInside && !key.startsWith('hidden-') && !hasShown) {
              hasShown = true;
              renderInfoBox(canvas, button.title, button.description);
            }
          },
        );
      }

      if (keys[LogicalKeyboardKey.shiftLeft.keyLabel] == true && !selecting) {
        final mx = cellMouseX;
        final my = cellMouseY;

        final c = safeAt(mx, my);

        if (c != null) {
          var id = c.id;

          if (id == "empty") {
            id = grid.placeable(mx, my);
          }

          if (c.data["trick_as"] != null && edType == EditorType.loaded) {
            id = c.data["trick_as"];
          }

          var d = lang("$id.desc", (cellInfo[id] ?? defaultProfile).description);
          if (isDebugMode) {
            d += "\nID: $id";
            d += "\nX: $mx";
            d += "\nY: $my";
            final prop = props[id];
            if (prop != null) {
              var strings = <String>[];

              for (var property in prop) {
                strings.add("${lang("property.$id.${property.key}", property.name)}: ${c.data[property.key] ?? property.def}");
              }

              var str = strings.join("\n");
              d += "\n\n$str";
            }
          }

          renderInfoBox(canvas, "${lang("$id.title", (cellInfo[id] ?? defaultProfile).title)} (${rotToString(c.rot)})", d);
        }
      }

      if (grid.title != "") {
        // Render title and description

        final titletp = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: grid.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40 * uiScale,
            ),
          ),
        );

        titletp.layout();

        titletp.paint(
          canvas,
          Offset(
            (canvasSize.x - titletp.width) / 2,
            50 * uiScale,
          ),
        );

        if (grid.desc != "") {
          final descriptiontp = TextPainter(
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            text: TextSpan(
              text: grid.desc,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30 * uiScale,
              ),
            ),
          );

          descriptiontp.layout(maxWidth: 50.w);

          descriptiontp.paint(
            canvas,
            Offset((canvasSize.x - descriptiontp.width) / 2, 70 * uiScale + titletp.height),
          );
        }
      }

      canvas.translate(offX, offY);

      super.render(canvas);
    } catch (e) {
      print(e);
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (ctx) => ErrorWidget(e),
      ));
    }
  }

  void renderEmpty(Cell cell, int x, int y) {
    if (grid.placeable(x, y) != "empty" && backgrounds.contains(grid.placeable(x, y))) {
      final off = Vector2(x * cellSize.toDouble(), y * cellSize.toDouble());
      Sprite(Flame.images.fromCache(textureMap['${grid.placeable(x, y)}.png'] ?? 'backgrounds/${grid.placeable(x, y)}.png')).render(
        canvas,
        position: off,
        size: Vector2(
          cellSize.toDouble(),
          cellSize.toDouble(),
        ),
      );
    }
  }

  void drawSkin(String skin, Offset off, Paint? paint) {
    if (SkinManager.skinEnabled(skin)) {
      Sprite(Flame.images.fromCache('skins/$skin.png'))
        ..paint = paint ?? Paint()
        ..render(
          canvas,
          position: Vector2(off.dx, off.dy),
          size: Vector2.all(cellSize.toDouble()),
        );
    }
  }

  void renderCell(Cell cell, num x, num y, [Paint? paint, num scaleX = 1, num scaleY = 1, num? rrot]) {
    if ((paint?.color.opacity ?? 0) < 1 && cell.id == "empty") {
      final p = Offset(x.toDouble(), y.toDouble()) * cellSize;
      final r = p & Size(cellSize, cellSize);

      canvas.drawRect(
        r,
        Paint()
          ..color = (Colors.black.withOpacity(
            paint?.color.opacity ?? 0.5,
          )),
      );

      return;
    } // Help

    if (cell.id == "empty") return;
    if (cell.invisible) {
      if (edType == EditorType.making) {
        paint ??= Paint()..color = Colors.white.withOpacity(0.1);
      } else {
        return;
      }
    }
    var file = cell.id;

    var ignoreSafety = false;

    if ((cell.id == "pixel" && MechanicalManager.on(cell))) {
      file = 'pixel_on';
      ignoreSafety = true;
    }

    if (cell.id == "electric_wire" && electricManager.directlyReadPower(cell) > 0) {
      file = 'electric_wire_on';
      ignoreSafety = true;
    }

    if (cell.id == "invis_tool") {
      file = "interface/tools/invis_tool";
      ignoreSafety = true;
    }

    if (file.startsWith('totrick_')) {
      file = "interface/tools/trick_tool";
      ignoreSafety = true;
    }

    if (cell.data["trick_as"] != null) {
      if (edType == EditorType.loaded) {
        file = cell.data["trick_as"]!;
      }
    }

    if (cell.id == "trick_tool") {
      file = "interface/tools/trick_tool";
      ignoreSafety = true;
    }

    if (backgrounds.contains(cell.id)) {
      ignoreSafety = true;
    }

    if (!ignoreSafety && !cells.contains(file)) {
      file = "missing";
    }

    var sprite = Sprite(
      Flame.images.fromCache(textureMap['$file.png'] ?? '$file.png'),
    );
    final rot = (((running || onetick) && interpolation ? lerpRotation(cell.lastvars.lastRot, rrot ?? cell.rot, itime / delay) : cell.rot) +
            (edType == EditorType.loaded ? cell.data["trick_rot"] ?? 0 : 0) % 4) *
        halfPi;
    final center = Offset(cellSize.toDouble() * scaleX, cellSize.toDouble() * scaleY) / 2;

    canvas.save();

    final lp = cell.lastvars.lastPos;
    final past = Offset(
              (lp.dx + grid.width) % grid.width,
              (lp.dy + grid.height) % grid.height,
            ) *
            cellSize.toDouble() +
        center;
    final current = Offset(x.toDouble(), y.toDouble()) * cellSize.toDouble() + center;

    var off = ((running || onetick) && interpolation) ? interpolate(past, current, itime / delay) : current;

    canvas.rotate(rot);

    off = rotateOff(off, -rot) - center;

    final last = cell.lastvars.id;
    var opacity = 1.0;

    if (last != cell.id && cells.contains(last) && running) {
      opacity = itime / delay;

      Sprite(Flame.images.fromCache(textureMap['$last.png'] ?? '$last.png')).render(
        canvas,
        position: Vector2(off.dx, off.dy),
        size: Vector2.all(cellSize.toDouble()),
        overridePaint: Paint()..color = Colors.white.withOpacity(1 - opacity),
      );
    }

    sprite
      ..paint = paint ?? (Paint()..color = Colors.white.withOpacity(opacity))
      ..render(
        canvas,
        position: Vector2(off.dx, off.dy),
        size: Vector2(
          cellSize.toDouble() * scaleX,
          cellSize.toDouble() * scaleY,
        ),
      );

    if (edType == EditorType.making && cell.data["trick_as"] != null) {
      final texture = textureMap[cell.data["trick_as"] + '.png'] ?? "${cell.data["trick_as"]}.png";
      final rotoff = (cell.data["trick_rot"] ?? 0) * halfPi;
      var trickOff = rotateOff(Offset(off.dx + cellSize / 2, off.dy + cellSize / 2), -rotoff);

      canvas.rotate(rotoff);

      Sprite(Flame.images.fromCache(texture))
        ..paint = paint ?? Paint()
        ..render(
          canvas,
          position: Vector2(trickOff.dx * scaleX, trickOff.dy * scaleY),
          size: Vector2(
            cellSize.toDouble() * scaleX / 2,
            cellSize.toDouble() * scaleY / 2,
          ),
          anchor: Anchor.center,
        );

      canvas.rotate(-rotoff);
    }

    if (edType == EditorType.making && cell.id.startsWith('totrick_')) {
      final trickAs = cell.id.substring(8);
      final texture = textureMap['$trickAs.png'] ?? "$trickAs.png";

      Sprite(Flame.images.fromCache(texture))
        ..paint = paint ?? Paint()
        ..render(
          canvas,
          position: Vector2(off.dx * scaleX + cellSize / 2, off.dy * scaleY + cellSize / 2),
          size: Vector2(
            cellSize.toDouble() * scaleX / 2,
            cellSize.toDouble() * scaleY / 2,
          ),
          anchor: Anchor.center,
        );
    }

    // Skins
    if (cell.id == "puzzle") {
      drawSkin('computer', off, paint);
      drawSkin('hands', off, paint);
      drawSkin('christmas', off, paint);
    }

    // Effects
    if ((paint != null && brushTemp != 0) || ((cell.data['heat'] ?? 0) != 0 && !(cell.id == "magma" || cell.id == "snow"))) {
      final heat = paint == null ? (cell.data['heat'] ?? 0) : brushTemp;

      Sprite(Flame.images.fromCache(heat > 0 ? 'effects/heat.png' : 'effects/cold.png'))
        ..paint = paint ?? Paint()
        ..render(
          canvas,
          position: Vector2(off.dx * scaleX, off.dy * scaleY),
          size: Vector2(
            cellSize.toDouble() * scaleX,
            cellSize.toDouble() * scaleY,
          ),
        );

      final tp = TextPainter(
        text: TextSpan(
          text: "${abs(heat)}",
          style: TextStyle(
            fontSize: cellSize * 0.25,
            color: heat > 0 ? Colors.orange["light"] : Color.fromARGB(255, 33, 162, 194),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          off.dx * scaleX + cellSize * 0.3,
          off.dy * scaleY - cellSize * 0.07,
        ),
      );
    }

    final effects = <String>{};

    if (cell.tags.contains("consistent")) {
      effects.add("consistent");
    }
    if (cell.tags.contains("stopped")) {
      effects.add("stopped");
    }
    if (cell.tags.contains("shielded")) {
      effects.add("shield");
    }

    for (var effect in effects) {
      Sprite(Flame.images.fromCache("effects/$effect.png"))
        ..paint = paint ?? Paint()
        ..render(
          canvas,
          position: Vector2(off.dx * scaleX, off.dy * scaleY),
          size: Vector2(
            cellSize.toDouble() * scaleX,
            cellSize.toDouble() * scaleY,
          ),
        );
    }

    // Custom cell stuff

    var text = textToRenderOnCell(cell, x, y);

    if (text != "") {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: cellSize * 0.25,
            color: paint?.color,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(cellSize, cellSize) * 0.025,
                blurRadius: cellSize / 200,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          off.dx * scaleX + cellSize / 2 - tp.width / 2,
          off.dy * scaleY + cellSize / 2 - tp.height / 2,
        ),
      );
    }

    canvas.restore();
  }

  int currentPacketBytes = 0;

  // Main game update
  @override
  void update(double dt) {
    alltime += dt;
    try {
      if (overlays.isActive("loading")) {
        return;
      }
      while ((currentPacketBytes < packetQueueLimit) && packetQueue.isNotEmpty) {
        final packet = packetQueue.first;
        // packet.codeUnits is the UTF-16 bytes of the thing. Yes, Dart uses UTF-16, not UTF-8.
        currentPacketBytes += packet.codeUnits.length;
        channel.sink.add(packet);
        if (proxyMirror) {
          if (packet.startsWith('toggle-invis') || packet.startsWith('wrap')) {
            return;
          }
          multiplayerCallback(packet);
        }
        packetQueue.removeAt(0);
        if (packetQueue.isEmpty) {
          break;
        }
      }
      packetQueueTimer += dt;
      if (packetQueueTimer > 1) {
        packetQueueTimer = 0;
        currentPacketBytes = 0;
      }
      if (rerenderOverlays) {
        rerenderOverlays = false;
        final openOverlays = Set<String>.from(overlays.activeOverlays);
        for (var open in openOverlays) {
          // Force a rerender
          overlays.remove(open);
          overlays.add(open);
        }
      }
      updates++;
      if (edType == EditorType.making) {
        puzzleWin = false;
        puzzleLost = false;
      }
      redparticles.update(dt);
      blueparticles.update(dt);
      greenparticles.update(dt);
      yellowparticles.update(dt);
      purpleparticles.update(dt);
      tealparticles.update(dt);
      blackparticles.update(dt);
      magentaparticles.update(dt);

      AchievementRenderer.update(dt);
      if (!overlays.isActive("EditorMenu")) {
        if ((running || onetick)) {
          var speedMultiplyer = 1;

          if (keys[LogicalKeyboardKey.comma.keyLabel] == true) speedMultiplyer *= 2;
          if (keys[LogicalKeyboardKey.period.keyLabel] == true) speedMultiplyer *= 4;
          if (keys[LogicalKeyboardKey.slash.keyLabel] == true) speedMultiplyer *= 8;
          if (keys[LogicalKeyboardKey.semicolon.keyLabel] == true) speedMultiplyer *= 16;

          itime += dt * speedMultiplyer;

          while (itime > delay) {
            itime -= delay;
            if (onetick) {
              onetick = false;
              itime = 0;
            } else {
              grid.update(); // Update the cells boizz
              lastTickKeys = {...keys}; // not good for GC
            }
          }
        }

        const speed = 600;
        if (keys[LogicalKeyboardKey.keyW.keyLabel] == true) {
          storedOffY += speed * dt;
        }
        if (keys[LogicalKeyboardKey.keyS.keyLabel] == true) {
          storedOffY -= speed * dt;
        }
        if (keys[LogicalKeyboardKey.keyA.keyLabel] == true) {
          storedOffX += speed * dt;
        }
        if (keys[LogicalKeyboardKey.keyD.keyLabel] == true) {
          storedOffX -= speed * dt;
        }
      }
      if (isMultiplayer && mouseInside) {
        var n = pow(10, storage.getInt("cursor_precision")!);
        num mx = (mouseX - offX) / cellSize - 0.5;
        num my = (mouseY - offY) / cellSize - 0.5;
        mx *= n;
        mx ~/= 1;
        mx /= n;
        my *= n;
        my ~/= 1;
        my /= n;
        if (hovers[clientID] != null) {
          if (hovers[clientID]!.x != mx || hovers[clientID]!.y != my) {
            sendToServer('set-hover', {"uuid": clientID, "x": mx, "y": my});
          }
        }
        var shouldCursor = false;
        if (cursors[clientID] == null) {
          shouldCursor = true;
        } else {
          final c = cursors[clientID]!;
          shouldCursor = (c.x != mx || c.y != my || c.selection != currentSelection || c.rotation != currentRotation || c.texture != cursorTexture || (c.data.toString() != currentData.toString()));
        }
        if (shouldCursor) {
          sendToServer('set-cursor', {"id": clientID, "x": mx, "y": my, "selection": currentSelection, "rot": currentRotation, "texture": cursorTexture, "data": currentData});
        }
      }
      if (realisticRendering) {
        final speed = storage.getDouble("lerp_speed") ?? 10.0;
        final t = dt * speed;
        cellSize = lerp(cellSize, wantedCellSize.toDouble(), t);
        smoothOffX = lerp(smoothOffX, storedOffX, t);
        smoothOffY = lerp(smoothOffY, storedOffY, t);
      } else {
        cellSize = wantedCellSize.toDouble();
        smoothOffX = storedOffX;
        smoothOffY = storedOffY;
      }
      if (hideUI) return;
      buttonManager.forEach(
        (key, button) {
          button.time += dt;
          button.timeRot += dt;
        },
      );

      if (puzzleLost && edType == EditorType.loaded) {
        if (!overlays.isActive("Lose")) {
          overlays.add("Lose");
          AchievementManager.complete("loser");
        }
        return;
      }
      if (puzzleWin && edType == EditorType.loaded) {
        if ((!overlays.isActive("Win"))) {
          overlays.add("Win");
          CoinManager.give(Random().nextInt(7) + 3);
          AchievementManager.complete("winner");
        }
        return;
      }
      if (!overlays.isActive("EditorMenu")) {
        if (selecting && dragPos && setPos) {
          final ex = max(min(cellMouseX, grid.width - 1), -1);
          final ey = max(min(cellMouseY, grid.height - 1), -1);

          selW = ex - selX + 1;
          selH = ey - selY + 1;
        }

        if (!(pasting || selecting || edType == EditorType.loaded)) {
          if (mouseDown) {
            final mx = (mouseX - offX) ~/ cellSize;
            final my = (mouseY - offY) ~/ cellSize;
            if (isMultiplayer) {
              if (mouseButton == kPrimaryMouseButton) {
                if (backgrounds.contains(currentSelection)) {
                  sendToServer('bg', {"x": mx, "y": my, "bg": currentSelection, "size": brushSize});
                } else {
                  sendToServer('place', {"x": mx, "y": my, "id": currentSelection, "rot": currentRotation, "data": currentData, "size": brushSize});
                }
              }
              if (mouseButton == kSecondaryMouseButton) {
                if (backgrounds.contains(currentSelection)) {
                  sendToServer('bg', {"x": mx, "y": my, "bg": "empty", "size": brushSize});
                } else {
                  sendToServer('place', {"x": mx, "y": my, "id": "empty", "rot": currentRotation, "data": currentData, "size": brushSize});
                }
              }
            } else {
              for (var cx = mx - brushSize; cx <= mx + brushSize; cx++) {
                for (var cy = my - brushSize; cy <= my + brushSize; cy++) {
                  if (grid.inside(cx, cy)) {
                    if (mouseButton == kPrimaryMouseButton) {
                      placeCell(currentSelection, currentRotation, cx, cy);
                    } else if (mouseButton == kSecondaryMouseButton) {
                      placeCell("empty", 0, cx, cy);
                    }
                  }
                }
              }
            }
            if (mouseButton == kMiddleMouseButton && !middleMove) {
              if (grid.inside(mx, my)) {
                final id = grid.at(mx, my).id;
                final p = grid.placeable(mx, my);

                if (edType == EditorType.making) {
                  if (cells.contains(id)) {
                    currentSelection = id;
                    animatePropertyEditor();
                    if (id == "empty" && cells.contains(p)) {
                      currentSelection = p;
                    } else {
                      for (var i = 0; i < categories.length; i++) {
                        buttonManager.buttons['cat$i']!.lastRot = currentRotation;
                        buttonManager.buttons['cat$i']!.timeRot = 0;
                        for (var j = 0; j < categories[i].items.length; j++) {
                          buttonManager.buttons['cat${i}cell$j']!.lastRot = currentRotation;
                          buttonManager.buttons['cat${i}cell$j']!.timeRot = 0;

                          if (categories[i].items[j] is CellCategory) {
                            for (var k = 0; k < categories[i].items[j].items.length; k++) {
                              buttonManager.buttons['cat${i}cell${j}sub$k']!.lastRot = currentRotation;
                              buttonManager.buttons['cat${i}cell${j}sub$k']!.timeRot = 0;
                            }
                          }
                        }
                      }
                      currentRotation = grid.at(mx, my).rot;
                      currentData = {...grid.at(mx, my).data};
                      for (var i = 0; i < categories.length; i++) {
                        buttonManager.buttons['cat$i']!.rotation = currentRotation;
                        for (var j = 0; j < categories[i].items.length; j++) {
                          buttonManager.buttons['cat${i}cell$j']!.rotation = currentRotation;

                          if (categories[i].items[j] is CellCategory) {
                            for (var k = 0; k < categories[i].items[j].items.length; k++) {
                              buttonManager.buttons['cat${i}cell${j}sub$k']!.rotation = currentRotation;
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      super.update(dt);
    } catch (e, st) {
      print(e);
      print(st);
      Navigator.pop(context);
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (ctx) => ErrorWidget(e),
      ));
    }
  }

  bool get inMenu => overlays.isActive('EditorMenu');

  void onMouseEnter(PointerEvent e) {
    mouseX = e.localPosition.dx;
    mouseY = e.localPosition.dy;
    mouseInside = true;
  }

  String originalPlace = "empty";

  String cellDataStr(Map<String, dynamic> cellData) {
    if (cellData.isEmpty) {
      return "0";
    }

    final l = <String>[];

    cellData.forEach((key, value) {
      l.add("$key=${TPCML.encodeValue(value)}");
    });

    return l.join(':');
  }

  void placeCell(String id, int rot, int cx, int cy) {
    if (id == "invis_tool") {
      mouseDown = false;
      if (grid.inside(cx, cy) && grid.at(cx, cy).id != "empty") {
        if (isinitial && isMultiplayer) {
          sendToServer("invis", {"x": cx, "y": cy, "v": !grid.at(cx, cy).invisible});
        } else {
          grid.at(cx, cy).invisible = !grid.at(cx, cy).invisible;
        }
      }
      return;
    }
    if (id.startsWith('totrick_')) {
      mouseDown = false;
      if (grid.inside(cx, cy)) {
        final trickAs = id.substring(8);
        final trickRotOff = (rot - grid.at(cx, cy).rot) % 4;
        if (isinitial && isMultiplayer) {
          final d = Map<String, dynamic>.from(grid.at(cx, cy).data);
          d["trick_as"] = trickAs;
          d["trick_rot"] = trickRotOff;
          sendToServer('place', {"x": cx, "y": cy, "id": grid.at(cx, cy).id, "rot": grid.at(cx, cy).rot, "data": d, "size": 1});
        } else {
          grid.at(cx, cy).data["trick_as"] = trickAs;
          grid.at(cx, cy).data["trick_rot"] = trickRotOff;
        }
      }
      return;
    }
    if (!grid.inside(cx, cy)) return;
    if (edType == EditorType.making) {
      //if (grid.at(cx, cy).id == id && grid.at(cx, cy).rot == rot) return;
      if (!isMultiplayer || !isinitial) {
        grid.set(
          cx,
          cy,
          Cell(cx, cy)
            ..id = id
            ..rot = rot
            ..lastvars.lastRot = rot
            ..data = {...currentData},
        );
      }
      if (brushTemp != 0) {
        if (!isMultiplayer) grid.at(cx, cy).data['heat'] = brushTemp;
      }
      if (id == "empty" && backgrounds.contains(currentSelection)) {
        if (!isMultiplayer) grid.setPlace(cx, cy, "empty");
        sendToServer("bg", {"x": cx, "y": cy, "bg": "empty"});
      } else {
        if (backgrounds.contains(id)) {
          sendToServer("bg", {"x": cx, "y": cy, "bg": id});
        } else {
          sendToServer('place', {
            "x": cx,
            "y": cy,
            "id": id,
            "rot": rot,
            "data": {...currentData, "heat": brushTemp},
            "size": 1
          });
        }
      }
    } else if (edType == EditorType.loaded) {
      if (grid.placeable(cx, cy) == "rotatable") {
        if (!isMultiplayer) {
          grid.at(cx, cy).rot++;
          grid.at(cx, cy).rot %= 4;
        }
        sendToServer('place', {"x": cx, "y": cy, "id": grid.at(cx, cy).id, "rot": grid.at(cx, cy).rot, "data": grid.at(cx, cy).data, "size": 1});
        return;
      }
      if (biomes.contains(grid.placeable(cx, cy))) {
        return;
      }
      if (id == "empty" && grid.at(cx, cy).id != "empty") {
        currentSelection = grid.at(cx, cy).id;
        animatePropertyEditor();
        currentRotation = grid.at(cx, cy).rot;
        originalPlace = grid.placeable(cx, cy);
        currentData = grid.at(cx, cy).data;
        if (!isMultiplayer) {
          grid.set(cx, cy, Cell(cx, cy));
        }
        sendToServer('place', {"x": cx, "y": cy, "id": "empty", "rot": 0, "data": <String, dynamic>{}, "size": 1});
        sendToServer(
          'new-hover',
          {
            "uuid": clientID,
            "x": cx,
            "y": cy,
            "id": currentSelection,
            "rot": currentRotation,
            "data": currentData,
          },
        );
      } else if (grid.at(cx, cy).id == "empty" && grid.placeable(cx, cy) == originalPlace) {
        if (!isMultiplayer) {
          grid.set(
            cx,
            cy,
            Cell(cx, cy)
              ..id = id
              ..rot = rot
              ..lastvars.lastRot = rot
              ..data = {...currentData},
          );
        }
        currentSelection = "empty";
        animatePropertyEditor();
        currentRotation = 0;
        sendToServer(
          'place',
          {
            "x": cx,
            "y": cy,
            "id": id,
            "rot": rot,
            "data": currentData,
            "size": 1,
          },
        );
        currentData = {};
        sendToServer('drop-hover', {"uuid": clientID});
      }
    }
  }

  // void onTapDown(TapDownInfo info) {
  //   final cx = (info.eventPosition.global.x - offX) ~/ cellSize;
  //   final cy = (info.eventPosition.global.y - offY) ~/ cellSize;
  //   final cell = cells[currentSeletion];

  //   if (grid.inside(cx, cy) && cell == "place") {
  //     placeCell(currentSeletion, 0, cx, cy);
  //   }
  // }

  Future<void> onPointerUp(PointerUpEvent event) async {
    mouseDown = false;
    if (selecting && setPos) {
      dragPos = false;
    }
  }

  void resetAllCategories([CellCategory? except]) {
    for (var category in categories) {
      var wasOpened = category.opened;
      if (category != except) {
        category.opened = false;
        for (var item in category.items) {
          if (wasOpened) {
            buttonManager.buttons['cat${categories.indexOf(category)}cell${category.items.indexOf(item)}']?.time = 0;
          }
        }
      }
      for (var item in category.items) {
        if (item is CellCategory) {
          final wasopen = item.opened;
          item.opened = false;
          if (wasopen) {
            for (var subitem in item.items) {
              final btn = buttonManager.buttons['cat${categories.indexOf(category)}cell${category.items.indexOf(item)}sub${item.items.indexOf(subitem)}'];
              if (btn != null) {
                if (btn.hasRendered) {
                  btn.time = 0;
                }
              }
            }
          }
        }
      }
    }
  }

  double get globalMouseX => (mouseX - offX) / cellSize - 0.5;
  double get globalMouseY => (mouseY - offY) / cellSize - 0.5;

  Future<void> onPointerDown(PointerDownEvent event) async {
    if (overlays.isActive("loading")) {
      return;
    }
    if (event.down && event.kind == PointerDeviceKind.mouse) {
      mouseX = event.position.dx;
      mouseY = event.position.dy;
      if (true) {
        mouseButton = event.buttons;
        mouseDown = true;
        buttonManager.forEach((key, button) {
          if (button.shouldRender() && button.isHovered(mouseX.toInt(), mouseY.toInt())) {
            button.callback();
            mouseDown = false;
          }
        });
        if (mouseY > (canvasSize.y - 110 * uiScale) && cellbar && edType == EditorType.making) {
          mouseDown = false;
        }
        if (edType == EditorType.loaded && mouseDown && !running) {
          mouseDown = false;
          bool hijacked = false;
          final gmx = globalMouseX;
          final gmy = globalMouseY;
          String hijackedHover = "";
          if (currentSelection == "empty") {
            hovers.forEach(
              (id, hover) {
                if (gmx >= hover.x - 0.5 && gmx <= hover.x + 0.5 && gmy >= hover.y - 0.5 && gmy < hover.y + 0.5) {
                  hijacked = true;
                  sendToServer(
                    'new-hover',
                    {
                      "uuid": clientID,
                      "x": cellMouseX,
                      "y": cellMouseY,
                      "id": hover.id,
                      "rot": hover.rot,
                      "data": hover.data,
                    },
                  );
                  currentSelection = hover.id;
                  currentRotation = hover.rot;
                  originalPlace = backgrounds.first;
                  currentData = Map.from(hover.data);
                  hijackedHover = id;
                }
              },
            );
          }
          if (hijackedHover != "") {
            sendToServer('drop-hover', {"uuid": hijackedHover});
          }
          if (hijacked) return;
          if (grid.inside(cellMouseX, cellMouseY) && grid.placeable(cellMouseX, cellMouseY) != "empty") {
            placeCell(
              currentSelection,
              currentRotation,
              cellMouseX,
              cellMouseY,
            );
          }
          return;
        }
        if (puzzleWin || puzzleLost) mouseDown = false;
        if (!mouseDown) return;
        if (selecting) {
          setPos = true;
          dragPos = true;
          selX = max((mouseX - offX) ~/ cellSize, 0);
          selY = max((mouseY - offY) ~/ cellSize, 0);
        } else if (pasting) {
          paste();
          pasting = false;
          selecting = false;
          setPos = false;
          dragPos = false;
          mouseDown = false;
          buttonManager.buttons['select-btn']!.texture = "interface/select.png";
          buttonManager.buttons['paste-btn']!.texture = "interface/paste.png";
          selecting = false;
          setPos = false;
        }
      }
    }
  }

  var rerenderOverlays = false;

  @override
  void onGameResize(Vector2 screenSize) {
    super.onGameResize(screenSize);
    ScaleAssist.setNewSize(screenSize.toOffset());
    rerenderOverlays = true;
  }

  void zoomout() {
    if (inMenu) return;
    if (wantedCellSize > (defaultCellSize) / 16) {
      final lastZoom = wantedCellSize;
      wantedCellSize /= 2;
      wantedCellSize = max(
        wantedCellSize,
        (defaultCellSize / 16),
      );
      properlyChangeZoom(lastZoom, wantedCellSize);
    }
  }

  void zoomin() {
    if (inMenu) return;
    if (wantedCellSize < (defaultCellSize) * 512) {
      final lastZoom = wantedCellSize;
      wantedCellSize *= 2;
      wantedCellSize = min(wantedCellSize, defaultCellSize * 512);
      properlyChangeZoom(lastZoom, wantedCellSize);
    }
  }

  void setInitial() {
    if (inMenu) return;
    QueueManager.empty("cell-updates");
    QueueManager.empty("subticks");
    initial = grid.copy;
    isinitial = true;
    running = false;
    buttonManager.buttons["play-btn"]!.texture = "mover.png";
    buttonManager.buttons["play-btn"]!.rotation = 0;
    timeGrid = null;
    if (isMultiplayer) sendToServer('setinit', {"code": SavingFormat.encodeGrid(grid)});
    grid.tickCount = 0;
  }

  void restoreInitial() {
    if (inMenu) return;
    QueueManager.empty("cell-updates");
    QueueManager.empty("subticks");
    bool differentSize = (grid.width != initial.width || grid.height != initial.height);
    grid = initial.copy;
    isinitial = true;
    puzzleWin = false;
    puzzleLost = false;
    overlays.remove('Win');
    running = false;
    buttonManager.buttons['wrap-btn']?.title = grid.wrap ? lang('wrapModeOn', "Wrap Mode (ON)") : lang("wrapModeOff", "Wrap Mode (OFF)");
    buttonManager.buttons["play-btn"]!.texture = "mover.png";
    buttonManager.buttons["play-btn"]!.rotation = 0;
    if (differentSize) buildEmpty();
    timeGrid = null;
    grid.tickCount = 0;
  }

  bool onetick = false;

  void oneTick() {
    if (inMenu) return;
    if (!running) {
      if (isinitial) {
        initial = grid.copy;
      }
      grid.update();
      itime = 0;
      isinitial = false;
      onetick = true;
    }
  }

  void playPause() {
    if (inMenu) return;
    running = !running;
    if (edType == EditorType.loaded) {
      isinitial = true;
      //if (currentSelection != "empty") return;
    }
    if (running) {
      if (isinitial) {
        initial = grid.copy;
      }
      isinitial = false;
      playerKeys = 0;
      buttonManager.buttons["play-btn"]!.texture = "slide.png";
      buttonManager.buttons["play-btn"]!.rotation = 1;
      itime = delay;
      AchievementManager.complete("start");
    } else {
      if (edType == EditorType.loaded) {
        restoreInitial();
      }
      puzzleWin = false;
      puzzleLost = false;
      overlays.remove("Win");
      overlays.remove("Lose");
      buttonManager.buttons["play-btn"]!.texture = "mover.png";
      buttonManager.buttons["play-btn"]!.rotation = 0;
    }
  }

  void q() {
    if (inMenu) return;
    if (edType == EditorType.making) {
      if (pasting) {
        gridClip.rotate(RotationalType.counter_clockwise);
      } else {
        for (var i = 0; i < categories.length; i++) {
          buttonManager.buttons['cat$i']!.lastRot = game.currentRotation;
          buttonManager.buttons['cat$i']!.timeRot = 0;
          for (var j = 0; j < categories[i].items.length; j++) {
            buttonManager.buttons['cat${i}cell$j']!.lastRot = game.currentRotation;
            buttonManager.buttons['cat${i}cell$j']!.timeRot = 0;

            if (categories[i].items[j] is CellCategory) {
              for (var k = 0; k < categories[i].items[j].items.length; k++) {
                buttonManager.buttons['cat${i}cell${j}sub$k']!.lastRot = game.currentRotation;
                buttonManager.buttons['cat${i}cell${j}sub$k']!.timeRot = 0;
              }
            }
          }
        }
        game.currentRotation += 3;
        game.currentRotation %= 4;
        for (var i = 0; i < categories.length; i++) {
          buttonManager.buttons['cat$i']!.rotation = game.currentRotation;
          for (var j = 0; j < categories[i].items.length; j++) {
            buttonManager.buttons['cat${i}cell$j']!.rotation = game.currentRotation;

            if (categories[i].items[j] is CellCategory) {
              for (var k = 0; k < categories[i].items[j].items.length; k++) {
                buttonManager.buttons['cat${i}cell${j}sub$k']!.rotation = game.currentRotation;
              }
            }
          }
        }
      }
    }
  }

  void e() {
    if (inMenu) return;
    if (edType == EditorType.making) {
      if (pasting) {
        gridClip.rotate(RotationalType.clockwise);
      } else {
        for (var i = 0; i < categories.length; i++) {
          buttonManager.buttons['cat$i']!.lastRot = game.currentRotation;
          buttonManager.buttons['cat$i']!.timeRot = 0;
          for (var j = 0; j < categories[i].items.length; j++) {
            buttonManager.buttons['cat${i}cell$j']!.lastRot = game.currentRotation;
            buttonManager.buttons['cat${i}cell$j']!.timeRot = 0;

            if (categories[i].items[j] is CellCategory) {
              for (var k = 0; k < categories[i].items[j].items.length; k++) {
                buttonManager.buttons['cat${i}cell${j}sub$k']!.lastRot = game.currentRotation;
                buttonManager.buttons['cat${i}cell${j}sub$k']!.timeRot = 0;
              }
            }
          }
        }
        game.currentRotation += 1;
        game.currentRotation %= 4;
        for (var i = 0; i < categories.length; i++) {
          buttonManager.buttons['cat$i']!.rotation = game.currentRotation;
          for (var j = 0; j < categories[i].items.length; j++) {
            buttonManager.buttons['cat${i}cell$j']!.rotation = game.currentRotation;

            if (categories[i].items[j] is CellCategory) {
              for (var k = 0; k < categories[i].items[j].items.length; k++) {
                buttonManager.buttons['cat${i}cell${j}sub$k']!.rotation = game.currentRotation;
              }
            }
          }
        }
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is RawKeyDownEvent) {
      final keysDown = keysPressed.map<String>((e) => e.keyLabel).toSet();
      if (keysPressed.contains(LogicalKeyboardKey.altLeft)) {
        // Alternative stuffz
      } else {
        if (keysDown.contains(LogicalKeyboardKey.keyQ.keyLabel)) {
          q();
        } else if (keysDown.contains(LogicalKeyboardKey.keyE.keyLabel)) {
          e();
        } else if (keysDown.contains(LogicalKeyboardKey.space.keyLabel) && !(keys[LogicalKeyboardKey.space.keyLabel] == true)) {
          playPause();
        } else if (keysDown.contains(LogicalKeyboardKey.escape.keyLabel) || keysDown.contains(LogicalKeyboardKey.backspace.keyLabel)) {
          if (pasting) {
            pasting = false;
            buttonManager.buttons['select-btn']!.texture = "interface/select.png";
            buttonManager.buttons['paste-btn']!.texture = "interface/paste.png";
          } else {
            if (edType == EditorType.making) {
              if (!overlays.isActive("EditorMenu")) {
                overlays.add("EditorMenu");
              } else {
                overlays.remove("EditorMenu");
              }
            }
          }
        } else if (keysDown.contains(LogicalKeyboardKey.keyF.keyLabel) && edType == EditorType.making) {
          oneTick();
        } else if (keysDown.contains(LogicalKeyboardKey.escape.keyLabel) && edType == EditorType.making) {
          if (!overlays.isActive("EditorMenu")) {
            overlays.add("EditorMenu");
          } else {
            overlays.remove("EditorMenu");
          }
        } else if (keysDown.contains(LogicalKeyboardKey.f1.keyLabel)) {
          hideUI = !hideUI;
        } else if (keysDown.contains(LogicalKeyboardKey.keyZ.keyLabel)) {
          delay /= 2;
          delay = max(delay, 0.01);
        } else if (keysDown.contains(LogicalKeyboardKey.keyX.keyLabel) && !keysDown.contains(LogicalKeyboardKey.controlLeft.keyLabel)) {
          delay *= 2;
          delay = min(delay, 1);
        } else if (keysDown.contains(LogicalKeyboardKey.keyI.keyLabel) && keysDown.contains(LogicalKeyboardKey.controlLeft.keyLabel)) {
          if (edType == EditorType.making) setInitial();
        } else if (keysDown.contains(LogicalKeyboardKey.keyR.keyLabel) && keysDown.contains(LogicalKeyboardKey.controlLeft.keyLabel)) {
          if (edType == EditorType.making) restoreInitial();
        } else if (keysDown.contains(LogicalKeyboardKey.keyV.keyLabel) && keysDown.contains(LogicalKeyboardKey.controlLeft.keyLabel) && gridClip.active) {
          game.pasting = !game.pasting;

          buttonManager.buttons['paste-btn']?.texture = game.pasting ? 'interface/paste_on.png' : 'interface/paste.png';

          buttonManager.buttons['select-btn']?.texture = "interface/select.png";
        } else if (keysDown.contains(LogicalKeyboardKey.keyC.keyLabel) && keysDown.contains(LogicalKeyboardKey.controlLeft.keyLabel)) {
          if (selecting) copy();
        } else if (keysDown.contains(LogicalKeyboardKey.keyX.keyLabel) && keysDown.contains(LogicalKeyboardKey.controlLeft.keyLabel)) {
          if (selecting) {
            copy();
            for (var x = 0; x < selW; x++) {
              for (var y = 0; y < selH; y++) {
                final cx = selX + x;
                final cy = selY + y;
                if (grid.inside(cx, cy)) {
                  if (!isMultiplayer) grid.set(cx, cy, Cell(cx, cy));
                  sendToServer('place', {"x": cx, "y": cy, "id": "empty", "rot": 0, "data": <String, dynamic>{}, "size": 1});
                }
              }
            }
          }
        }

        final arrowKeys = [
          LogicalKeyboardKey.arrowUp.keyLabel,
          LogicalKeyboardKey.arrowDown.keyLabel,
          LogicalKeyboardKey.arrowLeft.keyLabel,
          LogicalKeyboardKey.arrowRight.keyLabel,
        ];

        if (keysDown.containsAny(arrowKeys) && selecting) {
          if (keysDown.contains(LogicalKeyboardKey.shiftLeft.keyLabel)) {
            if (keysDown.contains(arrowKeys[0])) {
              selY--;
            }
            if (keysDown.contains(arrowKeys[1])) {
              selY++;
            }
            if (keysDown.contains(arrowKeys[2])) {
              selX--;
            }
            if (keysDown.contains(arrowKeys[3])) {
              selX++;
            }
          } else if (keysDown.contains(LogicalKeyboardKey.controlLeft.keyLabel)) {
            if (keysDown.contains(arrowKeys[0])) {
              selH--;
            }
            if (keysDown.contains(arrowKeys[1])) {
              selH++;
            }
            if (keysDown.contains(arrowKeys[2])) {
              selW--;
            }
            if (keysDown.contains(arrowKeys[3])) {
              selW++;
            }
          } else {
            if (selW < 0) {
              selW *= -1;
              selX -= selW;
            }
            if (selH < 0) {
              selH *= -1;
              selY -= selH;
            }

            var nsx = selX;
            var nsy = selY;

            if (keysDown.contains(arrowKeys[0])) {
              nsy--;
            }
            if (keysDown.contains(arrowKeys[1])) {
              nsy++;
            }
            if (keysDown.contains(arrowKeys[2])) {
              nsx--;
            }
            if (keysDown.contains(arrowKeys[3])) {
              nsx++;
            }
            var shouldMove = true;

            if (nsx < 0) {
              shouldMove = false;
            }
            if (nsy < 0) {
              shouldMove = false;
            }
            if (nsx > grid.width - selW) {
              shouldMove = false;
            }
            if (nsy > grid.height - selH) {
              shouldMove = false;
            }

            if (shouldMove) {
              final s = <Cell>[];

              for (var x = 0; x < selW; x++) {
                for (var y = 0; y < selH; y++) {
                  final cx = selX + x;
                  final cy = selY + y;
                  if (grid.inside(cx, cy)) {
                    s.add(grid.at(cx, cy).copy);
                    if (!isMultiplayer) {
                      grid.set(cx, cy, Cell(cx, cy));
                    }
                    sendToServer('place', {"x": cx, "y": cy, "id": "empty", "rot": 0, "data": <String, dynamic>{}, "size": 0});
                  }
                }
              }

              var i = 0;
              for (var x = 0; x < selW; x++) {
                for (var y = 0; y < selH; y++) {
                  final cx = nsx + x;
                  final cy = nsy + y;
                  if (grid.inside(cx, cy)) {
                    final c = s[i];
                    i++;
                    if (!isMultiplayer) grid.set(cx, cy, c);
                    sendToServer('place', {"x": cx, "y": cy, "id": c.id, "rot": c.rot, "data": c.data, "size": 0});
                    if (c.invisible) sendToServer('invis', {"x": cx, "y": cy, "v": true});
                  }
                }
              }

              selX = nsx;
              selY = nsy;
            }
          }
        }
      }
      for (var key in keysPressed) {
        //print(key);
        keys[key.keyLabel] = true;
      }
      return KeyEventResult.handled;
    } else if (event is RawKeyUpEvent) {
      for (var key in LogicalKeyboardKey.knownLogicalKeys) {
        keys[key.keyLabel] = event.isKeyPressed(key);
      }
      //keysPressed.forEach((e) => keys[e] = true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
part of logic;

final mathManager = MathManager();

void math() {
  for (var r in rotOrder) {
    grid.updateCell((cell, x, y) {
      cell.data['count'] = mathManager.input(x, y, cell.rot + 2);
      mathManager.output(x, y, cell.rot, cell.data['count']!);
    }, r, "math_sync");
  }
  mathManager.core();
  mathManager.functions();
  mathManager.trigonometry();
  mathManager.logic();

  final safeNums = grid.quadChunk.fetch("math_safe_number");

  for (var pos in safeNums) {
    final x = pos[0];
    final y = pos[1];

    final c = grid.at(x, y);

    if (c.id == "math_safe_number") {
      c.data['count'] = ((c.data['next_count'] ?? c.data['count']) ?? 0);
      c.data.remove("next_count");
    }
  }
}

class MathManager {
  void logic() {
    // Equals
    grid.updateCell((cell, x, y) {
      final a = input(x, y, cell.rot - 1);
      final b = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, a == b ? 1 : 0);
    }, null, "math_equal");
    // Not Equals
    grid.updateCell((cell, x, y) {
      final a = input(x, y, cell.rot - 1);
      final b = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, a != b ? 1 : 0);
    }, null, "math_notequal");
    // Greater
    grid.updateCell((cell, x, y) {
      final a = input(x, y, cell.rot - 1);
      final b = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, a > b ? 1 : 0);
    }, null, "math_greater");
    // Greater or Equal
    grid.updateCell((cell, x, y) {
      final a = input(x, y, cell.rot - 1);
      final b = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, a >= b ? 1 : 0);
    }, null, "math_greater_equal");
    // Less
    grid.updateCell((cell, x, y) {
      final a = input(x, y, cell.rot - 1);
      final b = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, a < b ? 1 : 0);
    }, null, "math_less");
    // Less or Equal
    grid.updateCell((cell, x, y) {
      final a = input(x, y, cell.rot - 1);
      final b = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, a <= b ? 1 : 0);
    }, null, "math_less_equal");
    // Switch
    grid.updateCell((cell, x, y) {
      final a = input(x, y, cell.rot - 1);
      final b = input(x, y, cell.rot + 1);
      final c = input(x, y, cell.rot + 2);

      output(x, y, cell.rot, c > 0 ? a : b);
    }, null, "math_switch");
  }

  void trigonometry() {
    // Sine wave
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);
      output(x, y, cell.rot, sin(i));
    }, null, "math_sin");
    // Cosine wave
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);
      output(x, y, cell.rot, cos(i));
    }, null, "math_cos");
    // Tangent
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);
      output(x, y, cell.rot, tan(i));
    }, null, "math_tan");
  }

  void functions() {
    // Aboslute
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);
      if (i == double.infinity) return output(x, y, cell.rot, double.infinity);
      if (i == double.negativeInfinity) {
        return output(x, y, cell.rot, double.infinity);
      }
      if (i is double && i.isNaN) return output(x, y, cell.rot, double.nan);
      output(x, y, cell.rot, abs(i));
    }, null, "math_abs");
    // Ceil
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);
      if (i == double.infinity) return output(x, y, cell.rot, double.infinity);
      if (i == double.negativeInfinity) {
        return output(x, y, cell.rot, double.negativeInfinity);
      }
      if (i is double && i.isNaN) return output(x, y, cell.rot, double.nan);
      output(x, y, cell.rot, ceil(i));
    }, null, "math_ceil");
    // Floor
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);
      if (i == double.infinity) return output(x, y, cell.rot, double.infinity);
      if (i == double.negativeInfinity) {
        return output(x, y, cell.rot, double.negativeInfinity);
      }
      if (i is double && i.isNaN) return output(x, y, cell.rot, double.nan);
      output(x, y, cell.rot, floor(i));
    }, null, "math_floor");
    // Natural Log
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);
      if (i == double.infinity) return output(x, y, cell.rot, double.infinity);
      if (i == double.negativeInfinity) {
        return output(x, y, cell.rot, double.negativeInfinity);
      }
      if (i is double && i.isNaN) return output(x, y, cell.rot, double.nan);
      output(x, y, cell.rot, log(i));
    }, null, "math_log");
    // LogN
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot - 1);
      if (i == double.infinity) return output(x, y, cell.rot, double.infinity);
      if (i == double.negativeInfinity) {
        return output(x, y, cell.rot, double.negativeInfinity);
      }
      if (i is double && i.isNaN) return output(x, y, cell.rot, double.nan);
      final base = input(x, y, cell.rot + 1);
      if (base == double.infinity) return output(x, y, cell.rot, 0);
      if (base == double.negativeInfinity) return output(x, y, cell.rot, 0);
      if (base is double && base.isNaN) {
        return output(x, y, cell.rot, double.nan);
      }
      output(x, y, cell.rot, logn(i, base));
    }, null, "math_logn");
    // Max
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);
      output(x, y, cell.rot, max(i1, i2));
    }, null, "math_max");
    // Min
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);
      output(x, y, cell.rot, min(i1, i2));
    }, null, "math_min");
    // Pseudo-Randomizer
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);

      final seed = (x + y * grid.width) * grid.tickCount * x / (cell.rot + 1);

      output(
        x,
        y,
        cell.rot,
        Random(seed.toInt()).nextDouble() * (i2 - i1) + i1,
      );
    }, null, "math_prng");
    // Randomizer
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, rng.nextDouble() * (i2 - i1) + i1);
    }, null, "math_rng");
  }

  void core() {
    // Addition
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);
      output(x, y, cell.rot, i1 + i2);
    }, null, "math_plus");

    // Subtraction
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);
      output(x, y, cell.rot, i1 - i2);
    }, null, "math_minus");

    // Multiplication
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);
      output(x, y, cell.rot, i1 * i2);
    }, null, "math_mult");

    // Division
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);

      if (i1 > 0 && i2 == 0) return output(x, y, cell.rot, double.infinity);
      if (i1 < 0 && i2 == 0) {
        return output(x, y, cell.rot, double.negativeInfinity);
      }
      if (i1 == 0 && i2 == 0) return output(x, y, cell.rot, double.nan);

      output(x, y, cell.rot, i1 / i2);
    }, null, "math_div");

    // Modulo
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);

      if (i1 > 0 && i2 == 0) return output(x, y, cell.rot, double.infinity);
      if (i1 < 0 && i2 == 0) {
        return output(x, y, cell.rot, double.negativeInfinity);
      }
      if (i1 == 0 && i2 == 0) return output(x, y, cell.rot, double.nan);

      output(x, y, cell.rot, i1 % i2);
    }, null, "math_mod");

    // Power
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);

      output(x, y, cell.rot, pow(i1, i2));
    }, null, "math_exp");

    // Square Root
    grid.updateCell((cell, x, y) {
      final i = input(x, y, cell.rot + 2);

      output(x, y, cell.rot, sqrt(i));
    }, null, "math_sqrt");

    // NRoot
    grid.updateCell((cell, x, y) {
      final i1 = input(x, y, cell.rot - 1);
      final i2 = input(x, y, cell.rot + 1);

      if (i2 == 0) {
        return output(x, y, cell.rot, double.infinity);
      }

      output(x, y, cell.rot, pow(i1, 1 / i2));
    }, null, "math_nroot");
  }

  void setGlobal(num channel, num index, num value) {
    // Doing nothing if indexies are invalid
    if (channel == double.infinity) return;
    if (channel == double.negativeInfinity) return;
    if (channel is double && channel.isNaN) return;
    if (index is double && channel.isNaN) return;
    if (index == double.negativeInfinity) return;
    if (index is double && channel.isNaN) return;

    if (grid.memory[channel.toInt()] == null) {
      grid.memory[channel.toInt()] = HashMap();
    }

    grid.memory[channel.toInt()]![index.toInt()] = value;
  }

  num getGlobal(num channel, num index) {
    // Doing nothing if indexies are invalid
    if (channel == double.infinity) return 0;
    if (channel == double.negativeInfinity) return 0;
    if (channel is double && channel.isNaN) return 0;
    if (index == double.infinity) return 0;
    if (index == double.negativeInfinity) return 0;
    if (index is double && channel.isNaN) return 0;

    if (grid.memory[channel.toInt()] == null) return 0;
    if (grid.memory[channel.toInt()]![index.toInt()] == null) return 0;

    return grid.memory[channel.toInt()]![index.toInt()]!;
  }

  // This technically does a little rounding. Eh, whatever, we also do a little trolling
  double logn(num x, num n) {
    return log(x) / log(n);
  }

  List<int> tunneled(int x, int y, int dir) {
    var depth = 0;
    while (true) {
      depth++;
      if (depth == grid.width * grid.height) return [x, y];
      var lx = x;
      var ly = y;
      x = frontX(x, dir);
      y = frontY(y, dir);
      if (!grid.inside(x, y)) return [lx, ly];
      final c = grid.at(x, y);
      final side = toSide(dir, c.rot);

      switch (c.id) {
        case "math_tunnel":
          if (side % 2 == 1) return [x, y];
          break;
        case "math_tunnel_cw":
          if (side == 0) {
            dir++;
            dir %= 4;
          } else if (side == 3) {
            dir--;
            dir %= 4;
          } else {
            return [x, y];
          }
          break;
        case "math_wireless_tunnel":
          if (side != 0) return [x, y];
          final targetID = (grid.at(x, y).data['target'] ?? 0);
          Cell? target;
          double? best;

          final cells = grid.quadChunk.fetch("math_wireless_tunnel");

          for (var pos in cells) {
            final cx = pos[0];
            final cy = pos[1];
            final c = grid.at(cx, cy);

            if (c.id == "math_wireless_tunnel" && (c.data['id'] == targetID)) {
              final dx = cx - x;
              final dy = cy - y;
              // Distance squared
              final dsqr = (dx * dx + dy * dy).toDouble();

              // Check if its the best one we've got, but not us
              if (((best == null) || dsqr < best) && dsqr > 0) {
                best = dsqr;
                target = c;
              }
            }
          }

          if (target == null) return [x, y];
          x = target.cx!;
          y = target.cy!;
          dir = (target.rot + 2) % 4;
          break;
        case "math_cross_tunnel":
          break;
        default:
          return [x, y];
      }
    }
  }

  void whenWritten(Cell cell, int x, int y, int dir, num amount) {
    if (cell.id == "math_memwriter") {
      setGlobal(cell.data['channel'], cell.data['index'], amount);
    }
    if (cell.id == "math_safe_number") {
      cell.data['next_count'] = amount;
    }
    if (cell.id == "code_number") {
      final prog = cell.data["progID"].toString();
      final buff = cell.data["buffID"].toString();

      grid.codeManager.setBuffer(prog, buff, amount.toDouble());
    }
    if (cell.id == "math_memset") {
      final channel = input(x, y, dir - 1);
      final index = input(x, y, dir + 1);
      setGlobal(channel, index, amount);
    }

    if(modded.contains(cell.id)) {
      return scriptingManager.mathWhenWritten(cell, x, y, dir, amount);
    }
  }

  final num phi = (1 + sqrt(5)) / 2;

  num? customCount(Cell cell, int x, int y, int dir) {
    if (cell.id == "math_e") return e;
    if (cell.id == "math_infinity") return double.infinity;
    if (cell.id == "math_phi") return phi;
    if (cell.id == "math_pi") return pi;
    if (cell.id == "math_tick") return grid.tickCount;
    if (cell.id == "math_time") return grid.tickCount * game.delay;

    if (cell.id == "math_memreader") {
      return getGlobal(cell.data['channel'], cell.data['index']);
    }
    if (cell.id == "math_memget") {
      final channel = input(x, y, dir - 1);
      final index = input(x, y, dir + 1);
      return getGlobal(channel, index);
    }

    if (cell.id == "mech_to_math") {
      return MechanicalManager.on(cell) ? (cell.data['scale'] ?? 1) : 0;
    }

    if (cell.id == "code_number") {
      final prog = cell.data["progID"].toString();
      final buff = cell.data["buffID"].toString();

      final v = grid.codeManager.getBuffer(prog, buff);

      return v is num ? v.toDouble() : null;
    }

    if(modded.contains(cell.id)) {
      return scriptingManager.mathCustomCount(cell, x, y, dir);
    }

    return customMasterNum(cell, x, y, dir);
  }

  // Returns if we should override count
  bool isWritable(int x, int y, int dir) {
    final cell = grid.at(x, y);

    if (cell.id == "counter" ||
        cell.id == "math_number" ||
        cell.id == "math_safe_number") return true;
    if (["math_memset", "math_memwriter"].contains(cell.id) && dir == cell.rot) {
      return true;
    }

    if(modded.contains(cell.id)) {
      return scriptingManager.mathIsWritable(cell, x, y, dir);
    }

    return false;
  }

  // Returns if we should read count
  bool isOutput(int x, int y, int dir) {
    final cell = grid.at(x, y);

    if (cell.id.startsWith("master_get_")) return true;

    if ([
      "counter",
      "math_number",
      "math_e",
      "math_infinity",
      "math_phi",
      "math_pi",
      "math_tick",
      "math_time",
      "math_safe_number"
    ].contains(cell.id)) return true;
    // Memory outputs
    if (["math_memget", "math_memreader", "math_memset", "math_memwriter"]
            .contains(cell.id) &&
        dir == cell.rot) return true;
    // Core outputs
    if ([
          "math_div",
          "math_exp",
          "math_minus",
          "math_mod",
          "math_mult",
          "math_plus",
          "math_sqrt",
          "math_nroot"
        ].contains(cell.id) &&
        dir == cell.rot) return true;
    // Function outputs
    if ([
          "math_abs",
          "math_ceil",
          "math_floor",
          "math_log",
          "math_logn",
          "math_max",
          "math_min",
          "math_prng",
          "math_rng",
          "math_sin",
          "math_cos",
          "math_tan"
        ].contains(cell.id) &&
        dir == cell.rot) return true;
    // Logic outputs
    if (["math_equal", "math_notequal", "math_greater", "math_less"]
            .contains(cell.id) &&
        dir == cell.rot) return true;

    // sync
    if (cell.id == "math_sync" && dir == cell.rot) return true;

    if(modded.contains(cell.id)) {
      return scriptingManager.mathIsOutput(cell, x, y, dir);
    }

    return false;
  }

  bool autoApplyCount(
      Cell cell, int cx, int cy, int dir, num count, int ox, int oy) {
    if (cell.id == "math_safe_number") return false;

    if(modded.contains(cell.id)) {
      return scriptingManager.mathAutoApplyCount(cell, cx, cy, dir, count, ox, oy);
    }

    return true;
  }

  void output(int x, int y, int dir, num count) {
    grid.at(x, y).data['count'] = count;
    dir %= 4;
    final t = tunneled(x, y, dir);
    final tx = t[0];
    final ty = t[1];

    if (isWritable(tx, ty, dir)) {
      if (autoApplyCount(grid.at(tx, ty), tx, ty, dir, count, x, y)) {
        grid.at(tx, ty).data['count'] = count;
      }
      whenWritten(grid.at(tx, ty), tx, ty, dir, count);
    }
  }

  num input(int x, int y, int dir) {
    dir %= 4;
    final t = tunneled(x, y, dir);
    final tx = t[0];
    final ty = t[1];

    if (isOutput(tx, ty, (dir + 2) % 4)) {
      final c = grid.at(tx, ty);
      return customCount(c, tx, ty, dir) ?? ((c.data['count'] as num?) ?? 0);
    }

    return 0;
  }
}

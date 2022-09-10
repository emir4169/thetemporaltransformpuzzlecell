part of logic;

void doFan(Cell cell, int x, int y) {
  final fx = frontX(x, cell.rot);
  final fy = frontY(y, cell.rot);

  if (grid.inside(fx, fy)) {
    push(fx, fy, cell.rot, 1);
  }
}

void doVacuum(Cell cell, int x, int y) {
  final front = inFront(x, y, cell.rot);

  if (front != null) {
    if (front.id == "empty") {
      pull(frontX(frontX(x, cell.rot), cell.rot), frontY(frontY(y, cell.rot), cell.rot), (cell.rot + 2) % 4, 1);
    }
  }
}

void doSuperFan(Cell cell, int x, int y) {
  var cx = x;
  var cy = y;
  var d = 0;

  while (true) {
    d++;
    if (d >= grid.width * grid.height) return;
    cx = frontX(cx, cell.rot);
    cy = frontY(cy, cell.rot);

    if (!grid.inside(cx, cy)) return;
    if (grid.at(cx, cy).id != "empty") {
      push(cx, cy, cell.rot, 1);
      return;
    }
  }
}

bool isFlowThrough(Cell cell, int x, int y, int dir) {
  if (["airflow", "inverse_airflow"].contains(cell.id) && (cell.rot % 2 == dir % 2)) {
    return true;
  }

  return false;
}

void doAirflow(Cell cell, int x, int y) {
  var cx = x;
  var cy = y;
  var d = 0;

  while (true) {
    d++;
    if (d >= grid.width * grid.height) return;
    cx = frontX(cx, cell.rot);
    cy = frontY(cy, cell.rot);

    if (!grid.inside(cx, cy)) return;
    final c = grid.at(cx, cy);
    if (isFlowThrough(c, x, y, cell.rot)) continue;
    if (c.id != "empty") {
      push(cx, cy, cell.rot, 1);
      return;
    }
  }
}

void doSuperVacuum(Cell cell, int x, int y) {
  var cx = x;
  var cy = y;
  var d = 0;

  while (true) {
    d++;
    if (d >= grid.width * grid.height) return;
    cx = frontX(cx, cell.rot);
    cy = frontY(cy, cell.rot);

    if (!grid.inside(cx, cy)) return;
    if (grid.at(cx, cy).id != "empty") {
      pull(cx, cy, (cell.rot + 2) % 4, 1);
      return;
    }
  }
}

void doInverseAirflow(Cell cell, int x, int y) {
  var cx = x;
  var cy = y;
  var d = 0;

  while (true) {
    d++;
    if (d >= grid.width * grid.height) return;
    cx = frontX(cx, cell.rot);
    cy = frontY(cy, cell.rot);

    if (!grid.inside(cx, cy)) return;
    final c = grid.at(cx, cy);
    if (isFlowThrough(c, x, y, cell.rot)) continue;
    if (c.id != "empty") {
      pull(cx, cy, (cell.rot + 2) % 4, 1);
      return;
    }
  }
}

void fans() {
  for (var rot in rotOrder) {
    grid.updateCell(
      doFan,
      rot,
      "fan",
    );
    grid.updateCell(
      doSuperFan,
      rot,
      "superfan",
    );
    grid.updateCell(
      doAirflow,
      rot,
      "airflow",
    );
  }
  for (var rot in rotOrder) {
    grid.updateCell(
      doVacuum,
      rot,
      "vacuum",
    );
    grid.updateCell(
      doSuperVacuum,
      rot,
      "supervacuum",
    );
    grid.updateCell(
      doInverseAirflow,
      rot,
      "inverse_airflow",
    );
  }
  for (var rot in rotOrder) {
    grid.updateCell(
      (c, x, y) {
        grabSide(x, y, c.rot - 1, c.rot);
        grabSide(x, y, c.rot + 1, c.rot);
      },
      rot,
      "conveyor",
    );
  }
  for (var rot in rotOrder) {
    grid.updateCell(
      (c, x, y) {
        doDriller(frontX(x, c.rot), frontY(y, c.rot), c.rot);
      },
      rot,
      "swapper",
    );
  }
  for (var rot in rotOrder) {
    grid.updateCell(
      (c, x, y) {
        nudge(frontX(x, c.rot), frontY(y, c.rot), c.rot);
      },
      rot,
      "nudger",
    );
  }
}

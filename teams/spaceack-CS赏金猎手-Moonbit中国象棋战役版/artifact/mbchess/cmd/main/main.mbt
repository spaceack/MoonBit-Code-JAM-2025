///| 游戏状态
struct GameStat {
  mut x : UInt // 红车的 x 坐标， 范围 0~8
  mut y : UInt // 红车的 y 坐标， 范围 0~9
  mut win : Bool // 是否胜利，满足一定回合数则为胜利
  mut is_move : Bool // 红车是否可以移动
  // col : UInt      // 棋盘列数
  // row : UInt      // 棋盘行数
  gamemap : FixedArray[FixedArray[Char]] // 棋盘
  bpos : Map[(UInt, UInt), Char] // 棋子位置，类型
  rng : @random.Rand // 随机数
  mut step : Int // 回合数计数器
  ctype : Map[String, UInt] // 棋子类型
}

///|
let gs : GameStat = GameStat::new()

///|
pub fn GameStat::new() -> GameStat {
  {
    x: 4, // 红车初始坐标
    y: 5, // 红车初始坐标
    win: false,
    is_move: false,
    // col: 9,
    // row: 10,
    gamemap: [
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', 'b', '0', 'b', '0', 'b', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
      ['0', '0', '0', '0', '0', '0', '0', '0', '0'],
    ],
    rng: @random.Rand::new(),
    step: 0,
    ctype: {
      "B": 0, //兵
      "S": 1, //士
      "M": 2, //马
      "X": 3, //象
      "W": 4, //王
      "C": 5, //车
    },
    bpos: {},
  }
}

///|生成敌方棋子
fn gchess(ct : UInt, ge : Bool) -> UInt {
  let mut result : UInt = 0
  let pos_bits : Int = 7
  let type_bits : Int = 3
  let piece_bits : Int = pos_bits + type_bits
  let se : Array[(UInt, UInt)] = []
  if ge {
    while se.length() < 3 {
      let limit : UInt = 8
      let x : UInt = gs.rng.uint(limit~)
      let limit : UInt = 9
      let y : UInt = gs.rng.uint(limit~)
      let pos : UInt = x + 9 * y
      if gs.gamemap[x.reinterpret_as_int()][y.reinterpret_as_int()] == '0' {
        gs.gamemap[x.reinterpret_as_int()][y.reinterpret_as_int()] = 'b'
        se.push((pos, ct))
        gs.bpos[(x, y)] = 'b'
      }
    }
    for i = 0; i < 3; i = i + 1 {
      for j = 0; j < 2 - i; j = j + 1 {
        if se[j].0 > se[j + 1].0 {
          let temp : (UInt, UInt) = se[j]
          se[j] = se[j + 1]
          se[j + 1] = temp
        }
      }
    }
  } else {
    while se.length() < 3 {
      let pos : UInt = 90 + se.length().reinterpret_as_uint()
      let piece_type : UInt = ct 
      se.push((pos, piece_type))
    }
  }
  for a in se {
    let piece_code : UInt = (a.0 << 3) | a.1
    result = (result << 10) | piece_code
  }
  merge_win_move() | result
}

///|
fn decodePos(pos : UInt) -> (UInt, UInt) {
  let x : UInt = pos % 9
  let y : UInt = pos / 9
  return (x, y)
}

///|
fn encodePosIndex(x : UInt, y : UInt) -> UInt {
  if x < 0 || x > 8 || y < 0 || y > 9 {
    return 90
  }
  return x + y * 9
}

///|
fn check_move_chess(x : UInt, y : UInt) -> Bool {
  let mut col : Bool = false
  let mut row : Bool = false
  if gs.x == x {
    row = true
  } else {
    row = false
  }
  if gs.y == y {
    col = true
  } else {
    col = false
  }
  (row && !col) || (!row && col)
}

///|
fn is_path_clear(x1 : UInt, y1 : UInt, x2 : UInt, y2 : UInt) -> Bool {
  if x1 == x2 {
    let start = if y1 < y2 { y1 } else { y2 }
    let end = if y1 < y2 { y2 } else { y1 }
    for y = start + 1; y < end; y = y + 1 {
      if gs.gamemap[x1.reinterpret_as_int()][y.reinterpret_as_int()] != '0' {
        return false
      }
    }
  } else if y1 == y2 {
    let start = if x1 < x2 { x1 } else { x2 }
    let end = if x1 < x2 { x2 } else { x1 }
    for x = start + 1; x < end; x = x + 1 {
      if gs.gamemap[x.reinterpret_as_int()][y1.reinterpret_as_int()] != '0' {
        return false
      }
    }
  }
  return true
}

///|
pub fn echoname(name : UInt) -> UInt {
  if gs.step == 0 {
    gs.bpos[(2, 2)] = 'b'
    gs.bpos[(4, 2)] = 'b'
    gs.bpos[(6, 2)] = 'b'
  }
  let mut r : UInt = 0
  let p : (UInt, UInt) = decodePos(name)
  if check_move_chess(p.0, p.1) {
    gs.is_move = true
    gs.gamemap[gs.x.reinterpret_as_int()][gs.y.reinterpret_as_int()] = '0'
    gs.x = p.0
    gs.y = p.1
    gs.gamemap[p.0.reinterpret_as_int()][p.1.reinterpret_as_int()] = 'x'
  } else {
    gs.is_move = false
    let result : UInt = 0
    return merge_win_move() | result
  }
  if gs.bpos.get_or_default((p.0, p.1), 'n') != 'x' || gs.bpos.get_or_default((p.0, p.1), 'n') != '0' {
    gs.bpos.remove((p.0, p.1))
  }
  let checkLoseResult : (UInt, Bool) = checkLose()
  if checkLoseResult.1 {
    return checkLoseResult.0
  }
  
  gs.step = gs.step + 1

  // if gs.step > 7 {
  if gs.step >=8 {
    gs.win = true
    return (1 << 31) | (1 << 30)
  }
  let mut isge : Bool = true
  if gs.step % 3 == 0 {
    isge = true

    r = gchess(gs.ctype.get_or_default("B", 0), isge)
    return r
  } else {
    isge = false
    let mut best_move : (UInt, UInt, UInt, UInt) = (100, 100, 100, 100) 
    let mut found_move = false
    if !found_move {
      for bpos in gs.bpos {
        if !found_move && (bpos.0.0 == gs.x) {
          if bpos.0.0 > 0 &&
            gs.gamemap[(bpos.0.0 - 1).reinterpret_as_int()][bpos.0.1.reinterpret_as_int()] ==
            '0' {
            best_move = (bpos.0.0, bpos.0.1, bpos.0.0 - 1, bpos.0.1)
            found_move = true
          } else if bpos.0.0 < 8 &&
            gs.gamemap[(bpos.0.0 + 1).reinterpret_as_int()][bpos.0.1.reinterpret_as_int()] ==
            '0' {
            best_move = (bpos.0.0, bpos.0.1, bpos.0.0 + 1, bpos.0.1)
            found_move = true
          }
        }
        if !found_move && {bpos.0.1 == gs.y}{
          if bpos.0.1 > 0 &&
            gs.gamemap[bpos.0.0.reinterpret_as_int()][bpos.0.1.reinterpret_as_int() - 1] ==
            '0' {
            best_move = (bpos.0.0, bpos.0.1, bpos.0.0, bpos.0.1 - 1)
            found_move = true
            } else if bpos.0.0 < gs.x - 1 &&
            gs.gamemap[bpos.0.0.reinterpret_as_int() + 1][bpos.0.1.reinterpret_as_int()] ==
            '0' {
            best_move = (bpos.0.0, bpos.0.1, bpos.0.0 + 1, bpos.0.1)
            }
        }
      }
    }

    if !found_move {
      for bpos in gs.bpos {
        if !found_move &&
          bpos.0.1 < 9 &&
          gs.gamemap[bpos.0.0.reinterpret_as_int()][(bpos.0.1 + 1).reinterpret_as_int()] ==
          '0' {
          best_move = (bpos.0.0, bpos.0.1, bpos.0.0, bpos.0.1 + 1)
          found_move = true
        }
      }
    }
    if found_move {
      let (src_x, src_y, dst_x, dst_y) = best_move
      gs.gamemap[src_x.reinterpret_as_int()][src_y.reinterpret_as_int()] = '0'
      gs.gamemap[dst_x.reinterpret_as_int()][dst_y.reinterpret_as_int()] = 'b'
      gs.bpos.remove((src_x, src_y))
      gs.bpos[(dst_x, dst_y)] = 'b'
      let srcIndex = encodePosIndex(src_x, src_y)
      let dstIndex = encodePosIndex(dst_x, dst_y)
      let moveCode = moveChessEncode(srcIndex, dstIndex)

      return merge_win_move() | moveCode
    } else {
      return 0
    }
  }
}

///|
fn moveChessEncode(srcIndex : UInt, dstIndex : UInt) -> UInt {
  let maskedSrc = srcIndex & 0x3F
  let maskedDst = dstIndex & 0x3F
  return maskedSrc | (maskedDst << 6)
}

///|
fn moveChessDecode(code : UInt) -> (UInt, UInt) {
  let src : UInt = code & 0xffff
  let dst : UInt = (code >> 16) & 0xffff
  return (src, dst)
}

///|
fn checkLose() -> (UInt, Bool) {
  let mut lose : Bool = false
  let mut moveCode : UInt = 0
  for i, x in gs.bpos {
    if i.0 + 1 < 9 &&
      gs.gamemap[i.0.reinterpret_as_int() + 1][i.1.reinterpret_as_int()] == 'x' {
      let srcIndex : UInt = encodePosIndex(i.0, i.1)
      let dstIndex : UInt = encodePosIndex(i.0 + 1, i.1)
      moveCode = moveChessEncode(srcIndex, dstIndex)
      lose = true
      return (merge_win_move() | moveCode, lose)
    }
    if i.0 > 0 &&
      gs.gamemap[i.0.reinterpret_as_int() - 1][i.1.reinterpret_as_int()] == 'x' {
      let srcIndex : UInt = encodePosIndex(i.0, i.1)
      let dstIndex : UInt = encodePosIndex(i.0 - 1, i.1)
      moveCode = moveChessEncode(srcIndex, dstIndex)
      lose = true
      return (merge_win_move() | moveCode, lose)
    }
    if i.1 + 1 < 10 &&
      gs.gamemap[i.0.reinterpret_as_int()][i.1.reinterpret_as_int() + 1] == 'x' {
      let srcIndex : UInt = encodePosIndex(i.0, i.1)
      let dstIndex : UInt = encodePosIndex(i.0, i.1 + 1)
      moveCode = moveChessEncode(srcIndex, dstIndex)
      lose = true
      return (merge_win_move() | moveCode, lose)
    }
    if i.1 > 0 &&
      gs.gamemap[i.0.reinterpret_as_int()][i.1.reinterpret_as_int() - 1] == 'x' {
      let srcIndex : UInt = encodePosIndex(i.0, i.1)
      let dstIndex : UInt = encodePosIndex(i.0, i.1 - 1)
      moveCode = moveChessEncode(srcIndex, dstIndex)
      lose = true
      return (merge_win_move() | moveCode, lose)
    }
  }
  return (merge_win_move() | moveCode, lose)
}

fn merge_win_move() -> UInt {
  let mut gs_win : UInt = 0
  let mut gs_move : UInt = 0
  if gs.is_move {
    gs_move = 1
  } else {
    gs_move = 0
  }
  if gs.win {
    gs_win = 1
  } else {
    gs_win = 0
  }
  return (gs_win << 31) | (gs_move << 30)
}

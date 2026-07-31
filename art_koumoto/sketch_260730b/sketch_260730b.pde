//==================================================
// ダイエットカードゲーム
// Processing 4 用
// 2人プレイ・1画面完結型カードゲーム
//==================================================

//------------------------------
// 変更しやすい初期設定
//------------------------------
final int GAME_WIDTH = 1200;
final int GAME_HEIGHT = 700;

final int MAX_TURN = 5;
final int NORMAL_TURN_TIME = 10;
final int SHORT_TURN_TIME = 5;
final int CUT_IN_TIME = 1800;

final int START_WEIGHT = 120;
final int START_HEALTH = 50;
final int START_STRESS = 20;

final int MIN_TARGET_WEIGHT = 30;
final int MAX_TARGET_WEIGHT = 80;

final int HAND_SIZE = 4;

final int SCENE_TITLE = 0;
final int SCENE_GAME = 1;
final int SCENE_CUT_IN = 2;
final int SCENE_RESULT = 3;

int scene = SCENE_TITLE;

int targetWeight;
int currentPlayer = 0;
int turn = 1;

int turnStartTime;
int cutInStartTime;

String eventText = "";
String lastActionText = "";

Player p1;
Player p2;

PFont font;


//==================================================
// 初期化
//==================================================
void setup() {
  size(1200, 700);

  font = createFont("Meiryo", 20);
  textFont(font);

  initGame();
}


void initGame() {
  targetWeight =
    (int)random(MIN_TARGET_WEIGHT, MAX_TARGET_WEIGHT + 1);

  p1 = new Player("PLAYER 1");
  p2 = new Player("PLAYER 2");

  p1.drawFirstCards();
  p2.drawFirstCards();

  currentPlayer = 0;
  turn = 1;

  eventText = "";
  lastActionText = "";

  scene = SCENE_TITLE;
  turnStartTime = millis();
}


//==================================================
// メイン描画
//==================================================
void draw() {
  if (scene == SCENE_TITLE) {
    drawTitle();
  } else if (scene == SCENE_GAME) {
    drawGame();
  } else if (scene == SCENE_CUT_IN) {
    drawCutIn();
  } else if (scene == SCENE_RESULT) {
    drawResult();
  }
}


//==================================================
// タイトル画面
//==================================================
void drawTitle() {
  background(220, 245, 255);

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(44);
  text("ダイエットカードゲーム", width / 2, 120);

  textSize(28);
  text("目標体重：" + targetWeight + " kg",
       width / 2, 210);

  textSize(20);
  text("2人で交互にカードを使い、目標体重に近づこう",
       width / 2, 290);

  textSize(22);
  text("ENTERキーでスタート",
       width / 2, 390);

  textSize(16);
  text("カードはクリック、または数字キー1～4で使用",
       width / 2, 445);
}


//==================================================
// ゲーム画面
//==================================================
void drawGame() {
  background(245);

  Player now = getCurrentPlayer();

  int timeLimit = getCurrentTimeLimit();
  int elapsed = (millis() - turnStartTime) / 1000;
  int remain = timeLimit - elapsed;

  if (remain < 0) {
    remain = 0;
  }

  drawHeader(now, remain);
  drawPlayerStatus();
  now.showCards();
  drawActionMessage();

  if (remain <= 0) {
    startTurnEnd();
  }

  if (isImmediateLose()) {
    scene = SCENE_RESULT;
  }
}


//==================================================
// ヘッダー表示
//==================================================
void drawHeader(Player now, int remain) {
  fill(0);
  textAlign(LEFT, TOP);

  textSize(22);
  text("ターン：" + turn + " / " + MAX_TURN,
       35, 25);

  text("現在：" + now.name,
       35, 60);

  text("目標体重：" + targetWeight + " kg",
       35, 95);

  if (remain <= 3) {
    fill(200, 0, 0);
  } else {
    fill(0);
  }

  text("残り時間：" + remain + " 秒",
       35, 130);
}
//==================================================
// プレイヤーステータス表示
//==================================================
void drawPlayerStatus() {
  drawOnePlayerStatus(p1, 35, 205, currentPlayer == 0);
  drawOnePlayerStatus(p2, 930, 205, currentPlayer == 1);
}


void drawOnePlayerStatus(Player p, int x, int y, boolean active) {
  if (active) {
    fill(255, 245, 170);
  } else {
    fill(230);
  }

  stroke(80);
  rect(x, y, 235, 185, 15);

  fill(0);
  textAlign(LEFT, TOP);

  textSize(23);
  text(p.name, x + 15, y + 15);

  textSize(19);
  text("体重：" + p.taiju + " kg", x + 15, y + 60);
  text("健康：" + p.health, x + 15, y + 92);
  text("ストレス：" + p.stress, x + 15, y + 124);

  if (p.shortTurnNext) {
    fill(180, 0, 0);
    textSize(14);
    text("次のターンは5秒", x + 15, y + 157);
  }

  if (p.onlyMounjaroNext) {
    fill(180, 0, 0);
    textSize(14);
    text("次の手札はマンジャロのみ", x + 15, y + 157);
  }
}


//==================================================
// 行動メッセージ
//==================================================
void drawActionMessage() {
  fill(20);
  textAlign(CENTER, CENTER);
  textSize(18);

  text(lastActionText, width / 2, 420);
}


//==================================================
// ターン終了開始
//==================================================
void startTurnEnd() {
  if (scene != SCENE_GAME) {
    return;
  }

  Player now = getCurrentPlayer();

  String randomEventText = now.randomEvent();

  if (randomEventText.equals("")) {
    eventText = now.name + " のターン終了";
  } else {
    eventText =
      now.name + " のターン終了\n\n" + randomEventText;
  }

  cutInStartTime = millis();
  scene = SCENE_CUT_IN;
}


//==================================================
// カットイン画面
//==================================================
void drawCutIn() {
  background(30);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);

  text(eventText, width / 2, height / 2);

  if (millis() - cutInStartTime >= CUT_IN_TIME) {
    changeTurn();
  }
}


//==================================================
// ターン交代
//==================================================
void changeTurn() {
  Player finishedPlayer = getCurrentPlayer();

  //今回使った短縮効果を解除
  finishedPlayer.shortTurnNow = false;

  if (currentPlayer == 0) {
    currentPlayer = 1;
  } else {
    currentPlayer = 0;
    turn++;
  }

  if (turn > MAX_TURN || isImmediateLose()) {
    scene = SCENE_RESULT;
    return;
  }

  Player nextPlayer = getCurrentPlayer();
  nextPlayer.prepareTurn();

  lastActionText = "";
  turnStartTime = millis();
  scene = SCENE_GAME;
}


//==================================================
// 現在プレイヤー
//==================================================
Player getCurrentPlayer() {
  if (currentPlayer == 0) {
    return p1;
  } else {
    return p2;
  }
}


//==================================================
// ターン時間
//==================================================
int getCurrentTimeLimit() {
  Player now = getCurrentPlayer();

  if (now.shortTurnNow) {
    return SHORT_TURN_TIME;
  }

  return NORMAL_TURN_TIME;
}


//==================================================
// 即敗北判定
//==================================================
boolean isImmediateLose() {
  if (p1.taiju <= 0 || p1.stress >= 100) {
    return true;
  }

  if (p2.taiju <= 0 || p2.stress >= 100) {
    return true;
  }

  return false;
}
//==================================================
// 結果画面
//==================================================
void drawResult() {
  background(255);

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(44);
  text("ゲーム終了", width / 2, 95);

  String result = getResultText();

  textSize(34);
  text(result, width / 2, 200);

  textSize(22);
  text("目標体重：" + targetWeight + " kg",
       width / 2, 300);

  text("PLAYER 1：" + p1.taiju + " kg",
       width / 2, 350);

  text("PLAYER 2：" + p2.taiju + " kg",
       width / 2, 390);

  float d1 = abs(targetWeight - p1.taiju);
  float d2 = abs(targetWeight - p2.taiju);

  textSize(18);
  text("PLAYER 1との差：" + d1 + " kg",
       width / 2, 440);

  text("PLAYER 2との差：" + d2 + " kg",
       width / 2, 475);

  textSize(20);
  text("Rキーでリスタート",
       width / 2, 580);
}


//==================================================
// 勝敗結果
//==================================================
String getResultText() {
  boolean p1Lose =
    p1.taiju <= 0 || p1.stress >= 100;

  boolean p2Lose =
    p2.taiju <= 0 || p2.stress >= 100;

  if (p1Lose && p2Lose) {
    return "両者敗北";
  }

  if (p1Lose) {
    return "PLAYER 2 の勝ち！";
  }

  if (p2Lose) {
    return "PLAYER 1 の勝ち！";
  }

  float d1 = abs(targetWeight - p1.taiju);
  float d2 = abs(targetWeight - p2.taiju);

  if (d1 < d2) {
    return "PLAYER 1 の勝ち！";
  }

  if (d2 < d1) {
    return "PLAYER 2 の勝ち！";
  }

  return "引き分け";
}


//==================================================
// キー操作
//==================================================
void keyPressed() {
  if (scene == SCENE_TITLE && keyCode == ENTER) {
    p1.prepareTurn();
    turnStartTime = millis();
    scene = SCENE_GAME;
    return;
  }

  if (scene == SCENE_RESULT &&
      (key == 'r' || key == 'R')) {

    initGame();
    return;
  }

  if (scene != SCENE_GAME) {
    return;
  }

  Player now = getCurrentPlayer();

  if (key == '1') {
    now.useCard(0);
  } else if (key == '2') {
    now.useCard(1);
  } else if (key == '3') {
    now.useCard(2);
  } else if (key == '4') {
    now.useCard(3);
  }
}


//==================================================
// マウス操作
//==================================================
void mousePressed() {
  if (scene != SCENE_GAME) {
    return;
  }

  Player now = getCurrentPlayer();

  for (int i = 0; i < HAND_SIZE; i++) {
    int x = 180 + i * 210;
    int y = 485;
    int w = 170;
    int h = 175;

    if (mouseX >= x &&
        mouseX <= x + w &&
        mouseY >= y &&
        mouseY <= y + h) {

      now.useCard(i);
      return;
    }
  }
}
//==================================================
// Playerクラス
//==================================================
class Player {
  String name;

  int taiju = START_WEIGHT;
  int health = START_HEALTH;
  int stress = START_STRESS;

  Card[] hand = new Card[HAND_SIZE];

  boolean shortTurnNext = false;
  boolean shortTurnNow = false;
  boolean onlyMounjaroNext = false;


  Player(String playerName) {
    name = playerName;
  }


  //最初の手札4枚
  void drawFirstCards() {
    for (int i = 0; i < HAND_SIZE; i++) {
      hand[i] = new Card();
    }
  }


  //ターン開始時
  void prepareTurn() {
    shortTurnNow = shortTurnNext;
    shortTurnNext = false;

    //マンジャロ注文を受けた場合
    if (onlyMounjaroNext) {
      for (int i = 0; i < HAND_SIZE; i++) {
        hand[i] = new Card(9);
      }

      onlyMounjaroNext = false;
    }
  }


  //手札表示
  void showCards() {
    for (int i = 0; i < HAND_SIZE; i++) {
      int x = 180 + i * 210;
      int y = 485;

      hand[i].display(x, y, i + 1);
    }
  }


  //カード使用
  void useCard(int index) {
    if (index < 0 || index >= HAND_SIZE) {
      return;
    }

    if (scene != SCENE_GAME) {
      return;
    }

    Card usedCard = hand[index];

    lastActionText = usedCard.use(this);

    //カードを使用したら新しいカードを補充
    hand[index] = new Card();

    //健康とストレスを0～100に収める
    health = constrain(health, 0, 100);
    stress = constrain(stress, 0, 100);

    p1.health = constrain(p1.health, 0, 100);
    p1.stress = constrain(p1.stress, 0, 100);

    p2.health = constrain(p2.health, 0, 100);
    p2.stress = constrain(p2.stress, 0, 100);

    if (isImmediateLose()) {
      scene = SCENE_RESULT;
    }
  }


  //ターン終了時のランダムイベント
  String randomEvent() {
    String result = "";

    //健康値を確率として体重減少イベント
    if (random(100) < health) {
      int down = (int)random(1, 6);

      taiju -= down;

      result =
        "健康イベント：体重 -" + down + " kg";
    }

    //ストレス値を確率として体重増加イベント
    if (random(100) < stress) {
      int up = (int)random(1, 6);

      if (!result.equals("")) {
        result += "\n";
      }

      taiju += up;

      result +=
        "ストレスイベント：体重 +" + up + " kg";
    }

    return result;
  }
}
//==================================================
// Cardクラス
//==================================================
class Card {
  String name;
  String category;
  String description;
  int type;


  //ランダムカード
  Card() {
    makeRandomCard();
  }


  //種類を指定したカード
  Card(int fixedType) {
    type = fixedType;
    setCardData();
  }


  //カードをランダム生成
  void makeRandomCard() {
    float r = random(100);

    //マンジャロ 10%
    if (r < 10) {
      type = 9;
    }

    //妨害カード3種類 各10%
    else if (r < 20) {
      type = 12;
    }

    else if (r < 30) {
      type = 13;
    }

    else if (r < 40) {
      type = 14;
    }

    //その他11種類を均等に出す
    else {
      int[] normalTypes = {
        0, 1, 2, 3, 4, 5,
        6, 7, 8, 10, 11
      };

      int randomIndex =
        (int)random(normalTypes.length);

      type = normalTypes[randomIndex];
    }

    setCardData();
  }


  //カード名・カテゴリー・説明
  void setCardData() {
    switch(type) {

    case 0:
      name = "サラダ";
      category = "食事";
      description = "体重-2\n健康+10";
      break;

    case 1:
      name = "プロテイン";
      category = "食事";
      description = "健康+15\nストレス-5";
      break;

    case 2:
      name = "ケーキ";
      category = "食事";
      description = "体重+5\nストレス-10";
      break;

    case 3:
      name = "ウォーキング";
      category = "運動";
      description = "体重-3\n健康+5";
      break;

    case 4:
      name = "ジム";
      category = "運動";
      description = "体重-7\n健康+8\nストレス+5";
      break;

    case 5:
      name = "ランニング";
      category = "運動";
      description = "体重-10\n健康+10\nストレス+10";
      break;

    case 6:
      name = "睡眠";
      category = "生活";
      description = "健康+20\nストレス-20";
      break;

    case 7:
      name = "水を飲む";
      category = "生活";
      description = "体重-1\n健康+5";
      break;

    case 8:
      name = "夜更かし";
      category = "生活";
      description = "健康-15\nストレス+20";
      break;

    case 9:
      name = "マンジャロ";
      category = "特殊";
      description = "体重-30\n健康-30\nストレス+40";
      break;

    case 10:
      name = "リフレッシュ";
      category = "特殊";
      description = "健康+10\nストレス-30";
      break;

    case 11:
      name = "チートデイ";
      category = "特殊";
      description = "体重+8\nストレス-15";
      break;

    case 12:
      name = "ご飯を奢る";
      category = "妨害";
      description = "相手の体重+8";
      break;

    case 13:
      name = "睡眠薬";
      category = "妨害";
      description = "相手の次ターンを\n5秒にする";
      break;

    case 14:
      name = "マンジャロ注文";
      category = "妨害";
      description = "相手の次の手札を\nマンジャロだけにする";
      break;
    }
  }


  //カード表示
  void display(int x, int y, int number) {
    setCategoryColor();

    stroke(60);
    rect(x, y, 170, 175, 12);

    fill(0);
    textAlign(CENTER, CENTER);

    textSize(15);
    text(category, x + 85, y + 20);

    textSize(19);
    text(name, x + 85, y + 60);

    textSize(14);
    text(description, x + 85, y + 112);

    textSize(16);
    text("[" + number + "]",
         x + 85, y + 157);
  }


  //カテゴリーごとの色
  void setCategoryColor() {
    if (category.equals("食事")) {
      fill(255, 235, 190);
    }

    else if (category.equals("運動")) {
      fill(205, 240, 205);
    }

    else if (category.equals("生活")) {
      fill(205, 225, 255);
    }

    else if (category.equals("特殊")) {
      fill(230, 205, 255);
    }

    else {
      fill(255, 200, 200);
    }
  }


  //カード使用
  String use(Player user) {
    Player enemy;

    if (user == p1) {
      enemy = p2;
    } else {
      enemy = p1;
    }

    switch(type) {

    case 0:
      user.taiju -= 2;
      user.health += 10;
      break;

    case 1:
      user.health += 15;
      user.stress -= 5;
      break;

    case 2:
      user.taiju += 5;
      user.stress -= 10;
      break;

    case 3:
      user.taiju -= 3;
      user.health += 5;
      break;

    case 4:
      user.taiju -= 7;
      user.health += 8;
      user.stress += 5;
      break;

    case 5:
      user.taiju -= 10;
      user.health += 10;
      user.stress += 10;
      break;

    case 6:
      user.health += 20;
      user.stress -= 20;
      break;

    case 7:
      user.taiju -= 1;
      user.health += 5;
      break;

    case 8:
      user.health -= 15;
      user.stress += 20;
      break;

    case 9:
      user.taiju -= 30;
      user.health -= 30;
      user.stress += 40;
      break;

    case 10:
      user.health += 10;
      user.stress -= 30;
      break;

    case 11:
      user.taiju += 8;
      user.stress -= 15;
      break;

    case 12:
      enemy.taiju += 8;
      break;

    case 13:
      enemy.shortTurnNext = true;
      break;

    case 14:
      enemy.onlyMounjaroNext = true;
      break;
    }

    return user.name + " が「" + name + "」を使用";
  }
}

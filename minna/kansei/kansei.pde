// ==========================================
// 各種初期パラメータ（設定・バランス調整用）
// ==========================================
// ステータス初期値・限界値
int INIT_TAIJU = 120;
int INIT_HEALTH = 50;
int INIT_STRESS = 20;
int MAX_HEALTH = 100;
int MIN_HEALTH = 0;
int MAX_STRESS = 100;
int MIN_STRESS = 0;

// ゲーム進行に関する設定
int MAX_TURNS = 5;                  // 最大ターン数
float NORMAL_TURN_TIME = 10.0;     // 通常ターンの制限時間(秒)
float CUTIN_DURATION = 1.2;        // カットイン表示時間(秒)
float EVENT_DURATION = 3.5;        // ランダムイベント演出表示時間(秒)
float JAM_NOTICE_DURATION = 2.0;   // 妨害ポップアップ表示時間(秒)
int TARGET_TAIJU_MIN = 30;         // 目標体重の最小値
int TARGET_TAIJU_MAX = 80;         // 目標体重の最大値

// --- カード排出率の設定（%） ---
float MANJARO_RATE = 10.0;          // マンジャロの出現確率 (%)
float JAM_MEAL_RATE = 10.0;         // 「ご飯を奢る」の出現確率 (%)
float JAM_SLEEP_RATE = 10.0;        // 「睡眠薬」の出現確率 (%)
float JAM_MANJARO_RATE = 10.0;      // 「マンジャロ注文」の出現確率 (%)

// --- カード使用演出の設定 ---
float CARD_EFFECT_DURATION = 0.5;   // カードが消えるまでの秒数
float CARD_EFFECT_RISE = 120.0;     // 消えるまでに上へ移動する距離(px)

// ==========================================
// システム用変数定義
// ==========================================
// gameState: 0:タイトル, 1:メインゲーム, 2:ターンカットイン, 3:ランダムイベント演出, 4:結果発表
int gameState = 0; 
int activePlayer = 0; // 0: P1, 1: P2
int currentTurn = 1;
int targetTaiju;

// プレイヤーデータ [0]: P1, [1]: P2
int[] taiju = new int[2];
int[] health = new int[2];
int[] stress = new int[2];
float[] turnTimeLimit = new float[2]; // 次ターンの制限時間
boolean[] isManjaroOnly = new boolean[2]; // 次ターンマンジャロ限定か

// 制限時間タイマー用
int turnStartTime;
int cutinStartTime;
int eventStartTime;
String cutinMessage = "";

// フィールド内妨害演出（通知ポップアップ）用
String[] jamNoticeMessage = new String[2];
int[] jamNoticeStartTime = new int[2];

// ランダムイベントの演出用ログデータ
ArrayList<String> eventLogs = new ArrayList<String>();

// カード関連
ArrayList<Card>[] hands = new ArrayList[2];
Card manjaroCard; // テンプレート用

// カード使用時の演出
ArrayList<CardEffect> cardEffects = new ArrayList<CardEffect>();

// カード画像
// スケッチフォルダ内に「data」フォルダを作り、画像を保存してください。
HashMap<String, PImage> cardImages = new HashMap<String, PImage>();
// PLAYER 1の体重別画像
HashMap<Integer, PImage> player1Images = new HashMap<Integer, PImage>();
// PLAYER 2の体重別画像
HashMap<Integer, PImage> player2Images = new HashMap<Integer, PImage>();
// ==========================================
// 構造体・クラス定義
// ==========================================
enum CardType {
  MEAL, EXERCISE, LIFE, SPECIAL, JAM
}

class Card {
  String name;
  CardType type;
  int dTaiju, dHealth, dStress;
  int jamType; // 0:なし, 1:ご飯を奢る, 2:睡眠薬, 3:マンジャロ注文

  Card(String n, CardType t, int dt, int dh, int ds) {
    name = n; type = t; dTaiju = dt; dHealth = dh; dStress = ds; jamType = 0;
  }
  
  Card(String n, CardType t, int jam) {
    name = n; type = t; dTaiju = 0; dHealth = 0; dStress = 0; jamType = jam;
  }
}

// カード使用時の上昇・フェードアウト演出
class CardEffect {
  Card card;
  float x, y, startY, w, h;
  int startTime;

  CardEffect(Card c, float startX, float startY, float cardW, float cardH) {
    card = c;
    x = startX;
    y = startY;
    this.startY = startY;
    w = cardW;
    h = cardH;
    startTime = millis();
  }

  // 指定秒数に合わせて上昇位置を更新
  void update() {
    float elapsed = (millis() - startTime) / 1000.0;
    float rate = constrain(elapsed / CARD_EFFECT_DURATION, 0, 1);
    y = startY - CARD_EFFECT_RISE * rate;
  }

  // 指定秒数に合わせて徐々に透明にする
  void display() {
    float elapsed = (millis() - startTime) / 1000.0;
    float rate = constrain(elapsed / CARD_EFFECT_DURATION, 0, 1);
    float alphaValue = 255 * (1.0 - rate);
    drawCardEffect(card, x, y, w, h, alphaValue);
  }

  boolean isFinished() {
    float elapsed = (millis() - startTime) / 1000.0;
    return elapsed >= CARD_EFFECT_DURATION;
  }
}

// カードのデータベース
ArrayList<Card> cardPool = new ArrayList<Card>();

void setup() {
  size(1280, 720); // 画面サイズ 1280x720
  textAlign(CENTER, CENTER);
  
  // フォントの自動選択（OSに応じた日本語フォント）
  String fontName = (platform == MACOSX) ? "Hiragino Sans" : "MS Gothic";
  PFont font = createFont(fontName, 16);
  textFont(font);

  // dataフォルダからカード画像を読み込む
  loadCardImages();
  loadPlayer1Images();
  loadPlayer2Images();
  hands[0] = new ArrayList<Card>();
  hands[1] = new ArrayList<Card>();
  
  jamNoticeMessage[0] = "";
  jamNoticeMessage[1] = "";
  
  initCardPool();
  resetGame();
  
  gameState = 0; // 起動時はタイトル画面
}

// ==========================================
// カード画像の読み込み
// ==========================================
void loadCardImages() {
  loadCardImage("サラダ", "salad.png");
  loadCardImage("プロテイン", "purotein.png");
  loadCardImage("ケーキ", "cake.png");
  loadCardImage("ウォーキング", "walking.png");
  loadCardImage("ジム", "gym.png");
  loadCardImage("ランニング", "running.png");
  loadCardImage("睡眠", "sleep.png");
  loadCardImage("水を飲む", "water.png");
  loadCardImage("夜更かし", "late_night.png");
  loadCardImage("リフレッシュ", "refresh.png");
  loadCardImage("チートデイ", "cheat_day.png");
  loadCardImage("マンジャロ", "manjaro.png");
  loadCardImage("ご飯を奢る", "meal_jam.png");
  loadCardImage("睡眠薬", "sleep_jam.png");
  loadCardImage("マンジャロ注文", "manjaro_jam.png");
}
// ==========================================
// PLAYER 1の体重別画像を読み込む
// ==========================================
void loadPlayer1Images() {
  for (int weight = 30; weight <= 120; weight += 10) {
    PImage img = loadImage("p1_" + weight + ".png");

    if (img != null) {
      player1Images.put(weight, img);
    }
  }
}
// ==========================================
// PLAYER 2の体重別画像を読み込む
// ==========================================
void loadPlayer2Images() {
  for (int weight = 30; weight <= 120; weight += 10) {
    PImage img = loadImage("p2_" + weight + ".png");

    if (img != null) {
      player2Images.put(weight, img);
    }
  }
}


// PLAYER 2の現在体重に応じた画像を表示
void drawPlayer2WeightImage(
  float centerX,
  float centerY,
  float maxW,
  float maxH
) {
  // PLAYER 2の体重を10kg単位にする
  // 例：117kg → 110、89kg → 80
  int imageWeight = (taiju[1] / 10) * 10;

  // 画像を30～120kgの範囲にする
  imageWeight = constrain(imageWeight, 30, 120);

  PImage img = player2Images.get(imageWeight);

  // 画像がない場合
  if (img == null || img.width <= 0 || img.height <= 0) {
    fill(220);
    stroke(170);

    rectMode(CENTER);
    rect(centerX, centerY, maxW, maxH, 8);
    rectMode(CORNER);

    noStroke();
    fill(100);
    textSize(14);

    text(
      "p2_" + imageWeight + ".png",
      centerX,
      centerY
    );

    return;
  }

  // 縦横比を保って画像を表示
  float scaleValue = min(
    maxW / img.width,
    maxH / img.height
  );

  float drawW = img.width * scaleValue;
  float drawH = img.height * scaleValue;

  imageMode(CENTER);
  image(img, centerX, centerY, drawW, drawH);
  imageMode(CORNER);
}

// PLAYER 1の現在体重に応じた画像を表示
void drawPlayer1WeightImage(
  float centerX,
  float centerY,
  float maxW,
  float maxH
) {
  // 1の位を切り捨てて10kg単位にする
  // 例：117kg → 110、89kg → 80
  int imageWeight = (taiju[0] / 10) * 10;

  // 使用する画像を30～120kgの範囲にする
  imageWeight = constrain(imageWeight, 30, 120);

  PImage img = player1Images.get(imageWeight);

  // 画像がない場合
  if (img == null || img.width <= 0 || img.height <= 0) {
    fill(220);
    stroke(170);

    rectMode(CENTER);
    rect(centerX, centerY, maxW, maxH, 8);
    rectMode(CORNER);

    noStroke();
    fill(100);
    textSize(14);
    text(
      "p1_" + imageWeight + ".png",
      centerX,
      centerY
    );

    return;
  }

  // 縦横比を保って画像サイズを調整
  float scaleValue = min(
    maxW / img.width,
    maxH / img.height
  );

  float drawW = img.width * scaleValue;
  float drawH = img.height * scaleValue;

  imageMode(CENTER);
  image(img, centerX, centerY, drawW, drawH);
  imageMode(CORNER);
}
void loadCardImage(String cardName, String fileName) {
  PImage img = loadImage(fileName);
  if (img != null) {
    cardImages.put(cardName, img);
  }
}

void initCardPool() {
  manjaroCard = new Card("マンジャロ", CardType.SPECIAL, -30, -40, 40);

  // 食事
  cardPool.add(new Card("サラダ", CardType.MEAL, -2, 10, -5));
  cardPool.add(new Card("プロテイン", CardType.MEAL, 1, 15, 0));
  cardPool.add(new Card("ケーキ", CardType.MEAL, 8, -5, -25));
  
  // 運動
  cardPool.add(new Card("ウォーキング", CardType.EXERCISE, -3, 5, -5));
  cardPool.add(new Card("ジム", CardType.EXERCISE, -6, 12, 10));
  cardPool.add(new Card("ランニング", CardType.EXERCISE, -10, -5, 20));
  
  // 生活
  cardPool.add(new Card("睡眠", CardType.LIFE, 0, 20, -20));
  cardPool.add(new Card("水を飲む", CardType.LIFE, -1, 5, 0));
  cardPool.add(new Card("夜更かし", CardType.LIFE, 2, -15, 15));
  
  // 特殊
  cardPool.add(new Card("リフレッシュ", CardType.SPECIAL, 0, 10, -10));
  cardPool.add(new Card("チートデイ", CardType.SPECIAL, 12, -10, -20));
  
  // 妨害
  cardPool.add(new Card("ご飯を奢る", CardType.JAM, 1));
  cardPool.add(new Card("睡眠薬", CardType.JAM, 2));
  cardPool.add(new Card("マンジャロ注文", CardType.JAM, 3));
}

void resetGame() {
  targetTaiju = (int)random(TARGET_TAIJU_MIN, TARGET_TAIJU_MAX + 1);
  currentTurn = 1;
  activePlayer = 0;
  
  for (int i = 0; i < 2; i++) {
    taiju[i] = INIT_TAIJU;
    health[i] = INIT_HEALTH;
    stress[i] = INIT_STRESS;
    turnTimeLimit[i] = NORMAL_TURN_TIME;
    isManjaroOnly[i] = false;
    jamNoticeMessage[i] = "";
    
    hands[i].clear();
    for (int j = 0; j < 4; j++) {
      hands[i].add(drawRandomCard(i));
    }
  }
}

void startTurn(int player) {
  activePlayer = player;
  gameState = 1;
  turnStartTime = millis();

  // ターン開始時に手札を全部交換
  hands[activePlayer].clear();

  // マンジャロ注文の効果を受けている場合
  if (isManjaroOnly[activePlayer]) {
    for (int j = 0; j < 4; j++) {
      hands[activePlayer].add(manjaroCard);
    }
    // このターンだけで効果終了
    isManjaroOnly[activePlayer] = false;
  } else {
    // 通常カードを新しく4枚引く
    for (int j = 0; j < 4; j++) {
      hands[activePlayer].add(drawRandomCard(activePlayer));
    }
  }
}

Card drawRandomCard(int p) {
  float r = random(100);
  
  float threshold1 = MANJARO_RATE;
  float threshold2 = threshold1 + JAM_MEAL_RATE;
  float threshold3 = threshold2 + JAM_SLEEP_RATE;
  float threshold4 = threshold3 + JAM_MANJARO_RATE;
  
  if (r < threshold1) {
    return manjaroCard;
  } else if (r < threshold2) {
    return cardPool.get(11);
  } else if (r < threshold3) {
    return cardPool.get(12);
  } else if (r < threshold4) {
    return cardPool.get(13);
  } else {
    int idx = (int)random(0, 11);
    return cardPool.get(idx);
  }
}

// ==========================================
// メイン処理（描画＆更新）
// ==========================================
void draw() {
  background(240);
  
  if (gameState == 0) {
    drawTitle();
  } else {
    drawGameUI();
    
    if (gameState == 1) {
      updateTurn();
    } else if (gameState == 2) {
      updateCutin();
    } else if (gameState == 3) {
      updateRandomEventCutin();
    } else if (gameState == 4) {
      drawResult();
    }
  }

  // カード使用演出を最前面に描画
  updateCardEffects();
}

void updateCardEffects() {
  for (int i = cardEffects.size() - 1; i >= 0; i--) {
    CardEffect effect = cardEffects.get(i);
    effect.update();
    effect.display();

    if (effect.isFinished()) {
      cardEffects.remove(i);
    }
  }
}

void updateTurn() {
  float elapsed = (millis() - turnStartTime) / 1000.0;
  float remaining = turnTimeLimit[activePlayer] - elapsed;
  
  if (remaining <= 0) {
    endTurn();
  }
}

void endTurn() {
  turnTimeLimit[activePlayer] = NORMAL_TURN_TIME;
  
  if (checkInstantLoss()) return;

  if (activePlayer == 0) {
    cutinMessage = "PLAYER 2 TURN";
    gameState = 2;
    cutinStartTime = millis();
  } else {
    if (currentTurn >= MAX_TURNS) {
      triggerRandomEvents();
    } else {
      currentTurn++;
      cutinMessage = "TURN " + currentTurn;
      gameState = 2;
      cutinStartTime = millis();
    }
  }
}

void updateCutin() {
  float elapsed = (millis() - cutinStartTime) / 1000.0;
  
  fill(0, 180);
  rect(0, height/2 - 50, width, 100);
  fill(255);
  textSize(36);
  text(cutinMessage, width/2, height/2);
  textSize(16);
  
  if (elapsed >= CUTIN_DURATION) {
    if (cutinMessage.equals("PLAYER 2 TURN")) {
      startTurn(1);
    } else if (cutinMessage.startsWith("TURN ")) {
      startTurn(0);
    }
  }
}

// ==========================================
// ランダムイベント処理＆演出
// ==========================================
void triggerRandomEvents() {
  gameState = 3;
  eventStartTime = millis();
  eventLogs.clear();
  
  for (int i = 0; i < 2; i++) {
    String pName = "P" + (i + 1);
    boolean occurred = false;
    
    if (random(100) < health[i]) {
      int weightLoss = (int)random(3, 10);
      taiju[i] -= weightLoss;
      eventLogs.add("【健康イベント発生!】 " + pName + " の代謝UP! 体重 -" + weightLoss + "kg");
      occurred = true;
    }
    
    if (random(100) < stress[i]) {
      int weightGain = (int)random(3, 10);
      taiju[i] += weightGain;
      eventLogs.add("【ストレスイベント発生!】 " + pName + " がドカ食い! 体重 +" + weightGain + "kg");
      occurred = true;
    }
    
    if (!occurred) {
      eventLogs.add(pName + ": ランダムイベントなし");
    }
  }
}

void updateRandomEventCutin() {
  float elapsed = (millis() - eventStartTime) / 1000.0;
  
  fill(0, 210);
  rect(0, 0, width, height);
  
  fill(255, 200, 0);
  textSize(36);
  text("★ 最終体調チェック（ランダムイベント） ★", width/2, 180);
  
  fill(255);
  textSize(22);
  for (int i = 0; i < eventLogs.size(); i++) {
    text(eventLogs.get(i), width/2, 280 + (i * 60));
  }
  
  fill(180);
  textSize(16);
  text("集計中...", width/2, 560);
  
  if (elapsed >= EVENT_DURATION) {
    if (!checkInstantLoss()) {
      gameState = 4;
    }
  }
}

boolean checkInstantLoss() {
  for (int i = 0; i < 2; i++) {
    if (taiju[i] <= 0 || stress[i] >= MAX_STRESS) {
      gameState = 4;
      return true;
    }
  }
  return false;
}

// ==========================================
// 描画処理 (1280x720に調整)
// ==========================================
void drawGameUI() {
  // 中央上部情報表示ヘッダー
  fill(220);
  rect(width/2 - 140, 10, 280, 65, 10);
  fill(0);
  textSize(18);
  text("目標体重: " + targetTaiju + " kg", width/2, 28);
  text("TURN: " + currentTurn + " / " + MAX_TURNS, width/2, 54);
  
  // 制限時間タイマーバー
  if (gameState == 1) {
    float elapsed = (millis() - turnStartTime) / 1000.0;
    float remaining = max(0, turnTimeLimit[activePlayer] - elapsed);
    float barWidth = map(remaining, 0, turnTimeLimit[activePlayer], 0, width);
    fill(255, 90, 90);
    rect(0, 0, barWidth, 8);
  }

  // 両プレイヤーフィールドの描画
  float panelWidth = 600;
  float panelHeight = 610;
  drawPlayerPanel(0, 25, 85, panelWidth, panelHeight);
  drawPlayerPanel(1, 655, 85, panelWidth, panelHeight);
}

void drawPlayerPanel(int p, float x, float y, float w, float h) {
  boolean isActive = (p == activePlayer && gameState == 1);
  
  stroke(isActive ? color(255, 60, 60) : color(180));
  strokeWeight(isActive ? 4 : 1);
  fill(isActive ? color(255, 255, 242) : color(250));
  rect(x, y, w, h, 12);
  noStroke();
  
  fill(0);
  textSize(22);
  text("PLAYER " + (p + 1), x + w/2, y + 25);
  // PLAYER 1だけ、名前の下に体重別画像を表示
if (p == 0) {
  drawPlayer1WeightImage(
    x + w/2,
    y + 130,
    180,
    170
  );
}else if (p == 1) {
  drawPlayer2WeightImage(
    x + w/2,
    y + 130,
    180,
    170
  );
}
  // --- ステータス棒グラフ ---
  // イラストの下にグラフ
drawCurrentHorizontalBarGraph(p, x + 20, y + 480, w - 40, 95);

text("体重...", x+w/2, y+590);
text("健康...", x+w/2, y+615);
text("ストレス...", x+w/2, y+640);
  
  // --- 手札カード配置 ---
  float cardW = 130;
  float cardH = 220;
  float cardSpacing = (w - 30 - (cardW * 4)) / 3;
  float cardY = y + 235;
  
  for (int i = 0; i < hands[p].size(); i++) {
    float cardX = x + 15 + i * (cardW + cardSpacing);
    drawCard(hands[p].get(i), cardX, cardY, cardW, cardH, isActive);
  }
  
  // --- 相手フィールド内完結型の妨害通知ポップアップ ---
  if (!jamNoticeMessage[p].equals("")) {
    float elapsedNotice = (millis() - jamNoticeStartTime[p]) / 1000.0;
    if (elapsedNotice < JAM_NOTICE_DURATION) {
      // フィールド内にオーバーレイ表示
      fill(180, 0, 0, 200);
      stroke(255, 0, 0);
      strokeWeight(3);
      rect(x + 10, y + 10, w - 20, h - 20, 10);
      
      fill(255, 255, 0);
      textSize(22);
      text("【妨害発生!】", x + w/2, y + h/2 - 20);
      fill(255);
      textSize(18);
      text(jamNoticeMessage[p], x + w/2, y + h/2 + 20);
    } else {
      jamNoticeMessage[p] = ""; // 表示終了
    }
  }
}

// 現在のステータス専用：太くて見やすい水平棒グラフ描画関数
void drawCurrentHorizontalBarGraph(int p, float gx, float gy, float gw, float gh) {
  fill(235);
  stroke(200);
  strokeWeight(1);
  rect(gx, gy, gw, gh, 6);
  
  noStroke();
  float barHeight = 18;  // 棒の高さ（太さ）
  float barX = gx + 10;
  float maxW = gw - 20;
  
  // --- 目標体重の参照ライン＆マーク ---
  float targetX = map(targetTaiju, 0, 150, barX, barX + maxW);
  fill(255, 230, 0, 120);
  rect(targetX - 2, gy + 5, 4, gh - 10); 
  stroke(220, 180, 0);
  strokeWeight(2);
  line(targetX, gy + 2, targetX, gy + gh - 2); 
  
  noStroke();
  // 1. 体重バー (黒)
  float wT = map(constrain(taiju[p], 0, 150), 0, 150, 0, maxW);
  fill(50);
  rect(barX, gy + 12, wT, barHeight, 3);
  
  // 2. 健康バー (緑)
  float wH = map(constrain(health[p], 0, 100), 0, 100, 0, maxW);
  fill(0, 180, 0);
  rect(barX, gy + 38, wH, barHeight, 3);
  
  // 3. ストレスバー (赤)
  float wS = map(constrain(stress[p], 0, 100), 0, 100, 0, maxW);
  fill(220, 0, 0);
  rect(barX, gy + 64, wS, barHeight, 3);
  
  // 目標テキスト表示
  fill(180, 140, 0);
  textSize(10);
  text("目標:" + targetTaiju + "kg", targetX, gy + 6);
  
  // ラベルテキスト overlay
  textAlign(LEFT, CENTER);
  textSize(11);
  fill(255);
  text("体重: " + taiju[p] + "kg", barX + 5, gy + 12 + barHeight/2);
  text("健康: " + health[p] + "%", barX + 5, gy + 38 + barHeight/2);
  text("ストレス: " + stress[p] + "%", barX + 5, gy + 64 + barHeight/2);
  textAlign(CENTER, CENTER);
}

// カード画像を縦横比を保ったまま表示
void drawCardImage(String cardName, float centerX, float centerY, float maxW, float maxH) {
  PImage img = cardImages.get(cardName);

  if (img == null || img.width <= 0 || img.height <= 0) {
    noFill();
    stroke(0, 35);
    rectMode(CENTER);
    rect(centerX, centerY, maxW, maxH, 5);
    rectMode(CORNER);
    noStroke();
    return;
  }

  float scaleValue = min(maxW / img.width, maxH / img.height);
  float drawW = img.width * scaleValue;
  float drawH = img.height * scaleValue;

  imageMode(CENTER);
  image(img, centerX, centerY, drawW, drawH);
  imageMode(CORNER);
}

void drawCard(Card c, float x, float y, float w, float h, boolean interactable) {
  color cColor = color(230);
  if (c.type == CardType.MEAL) cColor = color(255, 220, 220);
  else if (c.type == CardType.EXERCISE) cColor = color(220, 255, 220);
  else if (c.type == CardType.LIFE) cColor = color(220, 220, 255);
  else if (c.type == CardType.SPECIAL) cColor = color(255, 255, 180);
  else if (c.type == CardType.JAM) cColor = color(230, 180, 255);
  
  fill(cColor);
  stroke(0);
  strokeWeight(2);
  rect(x, y, w, h, 8);
  
  fill(0);
  textSize(19);
  text(c.name, x + w/2, y + 25);
  
  stroke(0, 50);
  strokeWeight(1);
  line(x + 8, y + 42, x + w - 8, y + 42);

  // カード名の下に画像を表示
  drawCardImage(c.name, x + w/2, y + 91, w - 20, 82);

  textSize(18);
  if (c.type == CardType.JAM) {
    if (c.jamType == 1) text("【妨害】\n相手の体重UP", x + w/2, y + 174);
    if (c.jamType == 2) text("【妨害】\n相手ターン5秒", x + w/2, y + 174);
    if (c.jamType == 3) text("【妨害】\n相手次ターン\nマンジャロ固定", x + w/2, y + 174);
  } else {
    float startY = y + 148;
    float lineHeight = 20;
    int lineCount = 0;
    
    if (c.dTaiju != 0) {
      fill(c.dTaiju < 0 ? color(0, 100, 200) : color(200, 0, 0));
      text("体重: " + (c.dTaiju > 0 ? "+" : "") + c.dTaiju, x + w/2, startY + (lineCount * lineHeight));
      lineCount++;
    }
    if (c.dHealth != 0) {
      fill(0, 120, 0);
      text("健康: " + (c.dHealth > 0 ? "+" : "") + c.dHealth, x + w/2, startY + (lineCount * lineHeight));
      lineCount++;
    }
    if (c.dStress != 0) {
      fill(180, 0, 0);
      text("ストレス: " + (c.dStress > 0 ? "+" : "") + c.dStress, x + w/2, startY + (lineCount * lineHeight));
      lineCount++;
    }
  }
}

// 演出専用：透明度を指定してカードを描画
void drawCardEffect(Card c, float x, float y, float w, float h, float alphaValue) {
  pushStyle();

  color cardColor = color(230);
  if (c.type == CardType.MEAL) cardColor = color(255, 220, 220);
  else if (c.type == CardType.EXERCISE) cardColor = color(220, 255, 220);
  else if (c.type == CardType.LIFE) cardColor = color(220, 220, 255);
  else if (c.type == CardType.SPECIAL) cardColor = color(255, 255, 180);
  else if (c.type == CardType.JAM) cardColor = color(230, 180, 255);

  fill(red(cardColor), green(cardColor), blue(cardColor), alphaValue);
  stroke(0, alphaValue);
  strokeWeight(2);
  rect(x, y, w, h, 8);

  fill(0, alphaValue);
  textSize(19);
  text(c.name, x + w/2, y + 25);

  stroke(0, alphaValue * 0.25);
  strokeWeight(1);
  line(x + 8, y + 42, x + w - 8, y + 42);

  PImage img = cardImages.get(c.name);
  if (img != null && img.width > 0 && img.height > 0) {
    float maxImageW = w - 20;
    float maxImageH = 82;
    float scaleValue = min(maxImageW / img.width, maxImageH / img.height);
    float drawW = img.width * scaleValue;
    float drawH = img.height * scaleValue;

    tint(255, alphaValue);
    imageMode(CENTER);
    image(img, x + w/2, y + 91, drawW, drawH);
    imageMode(CORNER);
    noTint();
  }

  popStyle();
}

// ==========================================
// イベント入力処理
// ==========================================
void mousePressed() {
  if (gameState == 0) {
    startTurn(0);
    return;
  }
  
  if (gameState == 4) {
    if (millis() - cutinStartTime > 1000) {
      resetGame();
      gameState = 0;
    }
    return;
  }
  
  if (gameState != 1) return;
  
  int p = activePlayer;
  float panelWidth = 600;
  float x = (p == 0) ? 25 : 655;
  float y = 85;
  
  float cardW = 130;
  float cardH = 220;
  float cardSpacing = (panelWidth - 30 - (cardW * 4)) / 3;
  float cardY = y + 235;
  
  for (int i = 0; i < hands[p].size(); i++) {
    float cardX = x + 15 + i * (cardW + cardSpacing);
    if (mouseX >= cardX && mouseX <= cardX + cardW && mouseY >= cardY && mouseY <= cardY + cardH) {
      useCard(p, i);
      break;
    }
  }
}

void keyPressed() {
  // ゲーム中以外はカードを使えない
  if (gameState != 1) return;

  int cardIndex = -1;

  // PLAYER 1：1・2・3・4キー
  if (activePlayer == 0) {
    if (key == '1') cardIndex = 0;
    else if (key == '2') cardIndex = 1;
    else if (key == '3') cardIndex = 2;
    else if (key == '4') cardIndex = 3;
  }

  // PLAYER 2：7・8・9・0キー
  else if (activePlayer == 1) {
    if (key == '7') cardIndex = 0;
    else if (key == '8') cardIndex = 1;
    else if (key == '9') cardIndex = 2;
    else if (key == '0') cardIndex = 3;
  }

  if (cardIndex >= 0 && cardIndex < hands[activePlayer].size()) {
    useCard(activePlayer, cardIndex);
  }
}

void useCard(int p, int cardIndex) {
  Card c = hands[p].get(cardIndex);
  int opp = (p == 0) ? 1 : 0;

  // 選択したカードの画面上の位置を計算
  float panelWidth = 600;
  float panelX = (p == 0) ? 25 : 655;
  float panelY = 85;
  float cardW = 130;
  float cardH = 220;
  float cardSpacing = (panelWidth - 30 - (cardW * 4)) / 3;
  float cardX = panelX + 15 + cardIndex * (cardW + cardSpacing);
  float cardY = panelY + 235;

  // カードが上昇しながら透明になる演出を開始
  cardEffects.add(new CardEffect(c, cardX, cardY, cardW, cardH));
  
  if (c.type == CardType.JAM) {
    // 妨害演出：相手フィールドのポップアップのみセット
    jamNoticeStartTime[opp] = millis();
    
    if (c.jamType == 1) {
      int gain = (int)random(3, 8);
      taiju[opp] += gain;
      jamNoticeMessage[opp] = "「ご飯を奢られた!」\n体重 +" + gain + "kg";
    } else if (c.jamType == 2) {
      turnTimeLimit[opp] = 5.0;
      jamNoticeMessage[opp] = "「睡眠薬を盛られた!」\n次ターン制限時間 5秒!";
    } else if (c.jamType == 3) {
      isManjaroOnly[opp] = true;
      jamNoticeMessage[opp] = "「マンジャロを勝手に注文された!」\n次ターン全カード激痛化!";
    }
  } else {
    taiju[p] += c.dTaiju;
    health[p] = constrain(health[p] + c.dHealth, MIN_HEALTH, MAX_HEALTH);
    stress[p] = constrain(stress[p] + c.dStress, MIN_STRESS, MAX_STRESS);
  }
  
  hands[p].remove(cardIndex);
  if (isManjaroOnly[p]) {
    hands[p].add(manjaroCard);
  } else {
    hands[p].add(drawRandomCard(p));
  }
  
  checkInstantLoss();
}

// ==========================================
// 勝敗判定・結果表示
// ==========================================
void drawResult() {
  fill(0, 200);
  rect(0, 0, width, height);
  
  fill(255);
  textSize(44);
  text("GAME OVER", width/2, 140);
  
  String winnerText = "";
  
  boolean p1Burst = (taiju[0] <= 0 || stress[0] >= MAX_STRESS);
  boolean p2Burst = (taiju[1] <= 0 || stress[1] >= MAX_STRESS);
  
  if (p1Burst && p2Burst) {
    winnerText = "引き分け（両者脱落）";
  } else if (p1Burst) {
    winnerText = "PLAYER 2 WIN! (PLAYER 1 脱落)";
  } else if (p2Burst) {
    winnerText = "PLAYER 1 WIN! (PLAYER 2 脱落)";
  } else {
    int diff1 = abs(taiju[0] - targetTaiju);
    int diff2 = abs(taiju[1] - targetTaiju);
    
    if (diff1 < diff2) {
      winnerText = "PLAYER 1 WIN!";
    } else if (diff2 < diff1) {
      winnerText = "PLAYER 2 WIN!";
    } else {
      winnerText = "引き分け!";
    }
  }
  
  fill(255, 255, 100);
  textSize(36);
  text(winnerText, width/2, 240);
  
  fill(255);
  textSize(22);
  text("目標体重: " + targetTaiju + " kg", width/2, 330);
  text("P1 最終体重: " + taiju[0] + " kg", width/2, 380);
  text("P2 最終体重: " + taiju[1] + " kg", width/2, 420);
  
  fill(150);
  textSize(16);
  text("クリックでタイトルへ戻る", width/2, 530);
}

void drawTitle() {
  fill(0);
  textSize(38);
  text("二人対戦ダイエッターカードゲーム", width/2, 280);
  textSize(20);
  fill(100);
  text("画面をクリックしてスタート", width/2, 400);
}

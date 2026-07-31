// ==========================================
// 各種初期パラメータ（設定・バランス調整用）
// ==========================================
// ステータス初期値・限界値
int INIT_TAIJU = 120, INIT_HEALTH = 50, INIT_STRESS = 20;
int MAX_HEALTH = 100, MIN_HEALTH = 0, MAX_STRESS = 100, MIN_STRESS = 0;

// ゲーム進行に関する設定
int MAX_TURNS = 5;
float NORMAL_TURN_TIME = 15.0;
float CUTIN_DURATION = 1.2;
float EVENT_DURATION = 3.5;
float JAM_NOTICE_DURATION = 2.0;
float COUNTDOWN_DURATION = 3.0;
int TARGET_TAIJU_MIN = 30, TARGET_TAIJU_MAX = 80;

// --- カード排出率の設定（%） ---
float MANJARO_RATE = 8.0, JAM_MEAL_RATE = 5.0, JAM_SLEEP_RATE = 3.0, JAM_MANJARO_RATE = 1.0;

// --- カード使用演出の設定 ---
float CARD_EFFECT_DURATION = 0.3;
float CARD_EFFECT_RISE = 60.0;

// --- コンボ設定 ---
int COMBO_WEIGHT_MULTIPLIER = 3;
float COMBO_POPUP_DURATION = 1.0;

// ==========================================
// システム用変数定義
// ==========================================
int gameState = 0, rulePage = 0, RULE_PAGE_COUNT = 3; 
int activePlayer = 0, currentTurn = 1, targetTaiju;

// プレイヤーデータ [0]: P1, [1]: P2
int[] taiju = new int[2];
int[] health = new int[2];
int[] stress = new int[2];
float[] turnTimeLimit = new float[2];
boolean[] isManjaroOnly = new boolean[2];

// ホールドカード保存用 [0]: P1, [1]: P2
Card[] heldCards = new Card[2];

// ドラッグ＆ドロップ管理用
boolean isDragging = false;
int draggedCardIndex = -1;
float dragOffsetX = 0, dragOffsetY = 0;

// キー状態
boolean key5Pressed = false, keyMinusPressed = false;

// コンボ管理
CardType[] lastComboType = new CardType[2];
int[] comboCount = new int[2];

// タイマー用
int turnStartTime, cutinStartTime, eventStartTime, countdownStartTime;
String cutinMessage = "";

// 妨害演出用
String[] jamNoticeMessage = new String[2];
int[] jamNoticeStartTime = new int[2];

// ログ・オブジェクト管理
ArrayList<String> eventLogs = new ArrayList<String>();
ArrayList<Card>[] hands = new ArrayList[2];
Card manjaroCard;

ArrayList<CardEffect> cardEffects = new ArrayList<CardEffect>();
ArrayList<ComboEffect> comboEffects = new ArrayList<ComboEffect>();

// リソースキャッシュ
HashMap<String, PImage> cardImages = new HashMap<String, PImage>();
HashMap<Integer, PImage> player1Images = new HashMap<Integer, PImage>();
HashMap<Integer, PImage> player2Images = new HashMap<Integer, PImage>();

// ==========================================
// 構造体・クラス定義
// ==========================================
enum CardType { MEAL, EXERCISE, LIFE, SPECIAL, JAM }

class Card {
  String name;
  CardType type;
  int dTaiju, dHealth, dStress, jamType;

  Card(String n, CardType t, int dt, int dh, int ds) {
    name = n; type = t; dTaiju = dt; dHealth = dh; dStress = ds; jamType = 0;
  }
  
  Card(String n, CardType t, int jam) {
    name = n; type = t; dTaiju = 0; dHealth = 0; dStress = 0; jamType = jam;
  }
}

class CardEffect {
  Card card;
  float x, y, startY, w, h;
  int startTime;

  CardEffect(Card c, float startX, float startY, float cardW, float cardH) {
    card = c; x = startX; y = startY; this.startY = startY; w = cardW; h = cardH;
    startTime = millis();
  }

  boolean updateAndDisplay() {
    float elapsed = (millis() - startTime) * 0.001;
    if (elapsed >= CARD_EFFECT_DURATION) return true;

    float rate = elapsed / CARD_EFFECT_DURATION;
    y = startY - CARD_EFFECT_RISE * rate;
    drawCardEffect(card, x, y, w, h, 255 * (1.0 - rate));
    return false;
  }
}

class ComboEffect {
  float x, y, startY;
  String text;
  int startTime;

  ComboEffect(float startX, float startY, String txt) {
    x = startX; y = startY; this.startY = startY;
    text = txt; startTime = millis();
  }

  boolean updateAndDisplay() {
    float elapsed = (millis() - startTime) * 0.001;
    if (elapsed >= COMBO_POPUP_DURATION) return true;

    float rate = elapsed / COMBO_POPUP_DURATION;
    y = startY - 40.0 * rate;
    float alphaVal = 255 * (1.0 - rate);

    pushStyle();
    textAlign(CENTER, CENTER);
    textSize(24);
    fill(0, alphaVal);
    text(text, x + 2, y + 2);
    fill(255, 220, 0, alphaVal);
    text(text, x, y);
    popStyle();
    return false;
  }
}

ArrayList<Card> cardPool = new ArrayList<Card>();

void setup() {
  size(1280, 720);
  textAlign(CENTER, CENTER);
  
  String fontName = (platform == MACOSX) ? "Hiragino Sans" : "MS Gothic";
  textFont(createFont(fontName, 16));

  loadCardImages();
  loadPlayerImages(player1Images, "p1_");
  loadPlayerImages(player2Images, "p2_");

  hands[0] = new ArrayList<Card>();
  hands[1] = new ArrayList<Card>();
  jamNoticeMessage[0] = "";
  jamNoticeMessage[1] = "";
  
  initCardPool();
  resetGame();
  gameState = 0;
}

// ==========================================
// 画像読み込み・共通描画処理
// ==========================================
void loadCardImages() {
  String[][] files = {
    {"サラダ", "salad.png"}, {"プロテイン", "purotein.png"}, {"ケーキ", "cake.png"},
    {"ウォーキング", "walking.png"}, {"ジム", "gym.png"}, {"ランニング", "running.png"},
    {"睡眠", "sleep.png"}, {"水を飲む", "water.png"}, {"夜更かし", "late_night.png"},
    {"リフレッシュ", "refresh.png"}, {"チートデイ", "cheat_day.png"}, {"マンジャロ", "manjaro.png"},
    {"ご飯を奢る", "meal_jam.png"}, {"睡眠薬", "sleep_jam.png"}, {"マンジャロ注文", "manjaro_jam.png"}
  };
  for (String[] f : files) {
    PImage img = loadImage(f[1]);
    if (img != null) cardImages.put(f[0], img);
  }
}

void loadPlayerImages(HashMap<Integer, PImage> map, String prefix) {
  for (int w = 30; w <= 120; w += 10) {
    PImage img = loadImage(prefix + w + ".png");
    if (img != null) map.put(w, img);
  }
}

// P1/P2 の描画処理を1つの関数に共通化
void drawPlayerWeightImage(int p, float centerX, float centerY, float maxW, float maxH) {
  if (currentTurn >= 4) {
    drawHiddenPlayerImage(centerX, centerY, maxW, maxH, "P" + (p + 1));
    return;
  }

  int imageWeight = constrain((taiju[p] / 10) * 10, 30, 120);
  HashMap<Integer, PImage> map = (p == 0) ? player1Images : player2Images;
  PImage img = map.get(imageWeight);

  if (img == null || img.width <= 0 || img.height <= 0) {
    fill(220); stroke(170); rectMode(CENTER);
    rect(centerX, centerY, maxW, maxH, 8);
    rectMode(CORNER); noStroke(); fill(100); textSize(12);
    text((p == 0 ? "p1_" : "p2_") + imageWeight + ".png", centerX, centerY);
    return;
  }
  float scaleValue = min(maxW / img.width, maxH / img.height);
  imageMode(CENTER);
  image(img, centerX, centerY, img.width * scaleValue, img.height * scaleValue);
  imageMode(CORNER);
}

void drawHiddenPlayerImage(float centerX, float centerY, float maxW, float maxH, String playerLabel) {
  pushStyle();
  rectMode(CENTER);
  fill(40, 45, 60); stroke(100, 110, 130); strokeWeight(2);
  rect(centerX, centerY, maxW, maxH, 10);
  
  noStroke(); fill(70, 80, 100);
  ellipse(centerX, centerY - 25, 55, 55); 
  arc(centerX, centerY + 45, 100, 90, PI, TWO_PI); 
  
  textAlign(CENTER, CENTER); textSize(32); fill(255, 220, 0, 220);
  text("???", centerX, centerY - 10);
  
  textSize(14); fill(180, 190, 210);
  text(playerLabel + " UNKNOWN", centerX, centerY + 40);
  popStyle();
}

void initCardPool() {
  manjaroCard = new Card("マンジャロ", CardType.SPECIAL, -30, -30, 70);

  cardPool.add(new Card("サラダ", CardType.MEAL, -2, 10, -5));
  cardPool.add(new Card("プロテイン", CardType.MEAL, 1, 15, 0));
  cardPool.add(new Card("ケーキ", CardType.MEAL, 8, -5, -25));
  cardPool.add(new Card("ウォーキング", CardType.EXERCISE, -3, 5, -5));
  cardPool.add(new Card("ジム", CardType.EXERCISE, -6, 12, 10));
  cardPool.add(new Card("ランニング", CardType.EXERCISE, -10, -5, 20));
  cardPool.add(new Card("睡眠", CardType.LIFE, 0, 20, -20));
  cardPool.add(new Card("水を飲む", CardType.LIFE, -1, 5, 0));
  cardPool.add(new Card("夜更かし", CardType.LIFE, 2, -15, 15));
  cardPool.add(new Card("リフレッシュ", CardType.SPECIAL, 0, 10, -10));
  cardPool.add(new Card("チートデイ", CardType.SPECIAL, 12, -30, -20));
  cardPool.add(new Card("ご飯を奢る", CardType.JAM, 1));
  cardPool.add(new Card("睡眠薬", CardType.JAM, 2));
  cardPool.add(new Card("マンジャロ注文", CardType.JAM, 3));
}

void resetGame() {
  targetTaiju = (int)random(TARGET_TAIJU_MIN, TARGET_TAIJU_MAX + 1);
  currentTurn = 1; activePlayer = 0;
  key5Pressed = false; keyMinusPressed = false;
  isDragging = false; draggedCardIndex = -1;
  
  cardEffects.clear();
  comboEffects.clear();

  for (int i = 0; i < 2; i++) {
    taiju[i] = INIT_TAIJU; health[i] = INIT_HEALTH; stress[i] = INIT_STRESS;
    turnTimeLimit[i] = NORMAL_TURN_TIME;
    isManjaroOnly[i] = false;
    jamNoticeMessage[i] = "";
    lastComboType[i] = null;
    comboCount[i] = 0;
    heldCards[i] = null;
    
    hands[i].clear();
    for (int j = 0; j < 4; j++) hands[i].add(drawRandomCard(i));
  }
}

void startCountdown() {
  resetGame();
  gameState = 6;
  countdownStartTime = millis();
}

void startTurn(int player) {
  activePlayer = player;
  gameState = 1;
  turnStartTime = millis();
  key5Pressed = false; keyMinusPressed = false;
  isDragging = false; draggedCardIndex = -1;

  hands[activePlayer].clear();
  boolean manjaro = isManjaroOnly[activePlayer];
  if (manjaro) isManjaroOnly[activePlayer] = false;

  for (int j = 0; j < 4; j++) {
    hands[activePlayer].add(manjaro ? manjaroCard : drawRandomCard(activePlayer));
  }
}

Card drawRandomCard(int p) {
  float r = random(100);
  if (r < MANJARO_RATE) return manjaroCard;
  if (r < MANJARO_RATE + JAM_MEAL_RATE) return cardPool.get(11);
  if (r < MANJARO_RATE + JAM_MEAL_RATE + JAM_SLEEP_RATE) return cardPool.get(12);
  if (r < MANJARO_RATE + JAM_MEAL_RATE + JAM_SLEEP_RATE + JAM_MANJARO_RATE) return cardPool.get(13);
  return cardPool.get((int)random(0, 11));
}

// ==========================================
// メイン処理（描画＆更新）
// ==========================================
void draw() {
  background(240);
  
  if (gameState == 0) drawTitle();
  else if (gameState == 5) drawRules();
  else {
    drawGameUI();
    if (gameState == 6) updateCountdownCutin();
    else if (gameState == 1) updateTurn();
    else if (gameState == 2) updateCutin();
    else if (gameState == 3) updateRandomEventCutin();
    else if (gameState == 4) drawResult();
  }

  // エフェクトの更新と終了判定を同時に実行（逆順ループ）
  for (int i = cardEffects.size() - 1; i >= 0; i--) {
    if (cardEffects.get(i).updateAndDisplay()) cardEffects.remove(i);
  }
  for (int i = comboEffects.size() - 1; i >= 0; i--) {
    if (comboEffects.get(i).updateAndDisplay()) comboEffects.remove(i);
  }
  
  if (gameState == 1 && isDragging && draggedCardIndex != -1) {
    drawDraggedCard();
  }
}

void updateCountdownCutin() {
  float elapsed = (millis() - countdownStartTime) * 0.001;
  fill(0, 190); rect(0, 0, width, height);
  fill(255); textSize(28);
  text("TARGET WEIGHT: " + targetTaiju + " kg", width/2, height/2 - 120);

  if (elapsed < 1.0) { fill(255, 220, 50); textSize(110); text("3", width/2, height/2); }
  else if (elapsed < 2.0) { fill(255, 180, 50); textSize(110); text("2", width/2, height/2); }
  else if (elapsed < 3.0) { fill(255, 100, 50); textSize(110); text("1", width/2, height/2); }
  else startTurn(0);
}

void updateTurn() {
  if ((millis() - turnStartTime) * 0.001 >= turnTimeLimit[activePlayer]) endTurn();
}

void endTurn() {
  isDragging = false;
  draggedCardIndex = -1;
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
  fill(0, 180); rect(0, height/2 - 50, width, 100);
  fill(255); textSize(36);
  text(cutinMessage, width/2, height/2);
  
  if ((millis() - cutinStartTime) * 0.001 >= CUTIN_DURATION) {
    if (cutinMessage.charAt(0) == 'P') startTurn(1);
    else startTurn(0);
  }
}

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
    if (!occurred) eventLogs.add(pName + ": ランダムイベントなし");
  }
}

void updateRandomEventCutin() {
  fill(0, 210); rect(0, 0, width, height);
  fill(255, 200, 0); textSize(36);
  text("★ 最終体調チェック（ランダムイベント） ★", width/2, 180);
  
  fill(255); textSize(22);
  for (int i = 0; i < eventLogs.size(); i++) {
    text(eventLogs.get(i), width/2, 280 + (i * 60));
  }
  fill(180); textSize(16);
  text("集計中...", width/2, 560);
  
  if ((millis() - eventStartTime) * 0.001 >= EVENT_DURATION) {
    if (!checkInstantLoss()) gameState = 4;
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
// 画面UIレイアウト更新
// ==========================================
void drawGameUI() {
  fill(220); rect(width/2 - 140, 10, 280, 65, 10);
  fill(0); textSize(18);
  text("目標体重: " + targetTaiju + " kg", width/2, 28);
  text("TURN: " + currentTurn + " / " + MAX_TURNS, width/2, 54);

  drawPlayerPanel(0, 25, 85, 600, 610);
  drawPlayerPanel(1, 655, 85, 600, 610);
}

void drawPlayerPanel(int p, float x, float y, float w, float h) {
  boolean isActive = (p == activePlayer && gameState == 1);
  
  stroke(isActive ? #FF3C3C : 180);
  strokeWeight(isActive ? 4 : 1);
  fill(isActive ? #FFFFF2 : 250);
  rect(x, y, w, h, 12);
  noStroke();
  
  fill(0); textSize(20);
  text("PLAYER " + (p + 1), x + w/2, y + 22);

  float timeBarY = y + 36, timeBarMargin = 15;
  float timeBarW = w - (timeBarMargin * 2), timeBarH = 8;
  
  fill(220); rect(x + timeBarMargin, timeBarY, timeBarW, timeBarH, 4);
  
  if (isActive) {
    float elapsed = (millis() - turnStartTime) * 0.001;
    float remaining = max(0, turnTimeLimit[activePlayer] - elapsed);
    fill(255, 70, 70);
    rect(x + timeBarMargin, timeBarY, map(remaining, 0, turnTimeLimit[activePlayer], 0, timeBarW), timeBarH, 4);
  }

  drawPlayerWeightImage(p, x + 15 + 75, y + 45 + 105, 150, 210);
  drawCurrentHorizontalBarGraph(p, x + 175, y + 55, 305, 200);
  drawHoldSlot(p, x + w - 110, timeBarY + timeBarH + 10, 95, 200, isActive);

  float cardW = 130, cardH = 310;
  float cardSpacing = (w - 30 - (cardW * 4)) / 3;
  float cardY = y + 280;
  
  for (int i = 0; i < hands[p].size(); i++) {
    float cardX = x + 15 + i * (cardW + cardSpacing);
    if (isActive && isDragging && draggedCardIndex == i) {
      pushStyle(); tint(255, 100);
      drawCard(hands[p].get(i), cardX, cardY, cardW, cardH);
      popStyle();
    } else {
      drawCard(hands[p].get(i), cardX, cardY, cardW, cardH);
    }
  }

  if (!jamNoticeMessage[p].isEmpty()) {
    if ((millis() - jamNoticeStartTime[p]) * 0.001 < JAM_NOTICE_DURATION) {
      fill(180, 0, 0, 200); stroke(255, 0, 0); strokeWeight(3);
      rect(x + 10, y + 10, w - 20, h - 20, 10);
      
      fill(255, 255, 0); textSize(22);
      text("【妨害発生!】", x + w/2, y + h/2 - 20);
      fill(255); textSize(18);
      text(jamNoticeMessage[p], x + w/2, y + h/2 + 20);
    } else {
      jamNoticeMessage[p] = "";
    }
  }
}

void drawDraggedCard() {
  if (draggedCardIndex < 0 || draggedCardIndex >= hands[activePlayer].size()) return;
  float drawX = mouseX - dragOffsetX, drawY = mouseY - dragOffsetY;

  pushStyle();
  fill(0, 50); noStroke();
  rect(drawX + 8, drawY + 8, 130, 310, 8);
  drawCard(hands[activePlayer].get(draggedCardIndex), drawX, drawY, 130, 310);
  popStyle();
}

color getCardColor(CardType type) {
  switch (type) {
    case MEAL: return color(255, 220, 220);
    case EXERCISE: return color(220, 255, 220);
    case LIFE: return color(220, 220, 255);
    case SPECIAL: return color(255, 255, 180);
    case JAM: return color(230, 180, 255);
    default: return color(230);
  }
}

void drawHoldSlot(int p, float x, float y, float w, float h, boolean isActive) {
  pushStyle();
  fill(60, 70, 90); textSize(14); textAlign(CENTER, BOTTOM);
  text("HOLD", x + w/2, y);

  stroke(isActive ? #FF9600 : 160); strokeWeight(2);
  fill(240, 240, 245);
  rect(x, y, w, h, 8);

  fill(80); textSize(11); textAlign(CENTER, TOP);
  text((p == 0) ? "[5 + 1～4]" : "[= + 7～0]", x + w/2, y + 6);

  Card hc = heldCards[p];
  if (hc == null) {
    fill(160); textSize(11); textAlign(CENTER, CENTER);
    text("空き\n\n(D&Dで交換)", x + w/2, y + h/2);
  } else {
    fill(getCardColor(hc.type)); stroke(100); strokeWeight(1);
    rect(x + 5, y + 22, w - 10, h - 28, 5);

    fill(0); textSize(13); textAlign(CENTER, TOP);
    text(hc.name, x + w/2, y + 26);

    drawCardImage(hc.name, x + w/2, y + 95, w - 20, 80);

    textSize(11); textAlign(CENTER, BOTTOM);
    if (hc.type == CardType.JAM) {
      fill(120, 0, 120); text("【妨害】", x + w/2, y + h - 10);
    } else {
      String statText = "";
      if (hc.dTaiju != 0) statText += (hc.dTaiju > 0 ? "+" : "") + hc.dTaiju + "kg\n";
      if (hc.dHealth != 0) statText += "健" + (hc.dHealth > 0 ? "+" : "") + hc.dHealth + " ";
      if (hc.dStress != 0) statText += "ス" + (hc.dStress > 0 ? "+" : "") + hc.dStress;
      fill(40); text(statText, x + w/2, y + h - 8);
    }
  }
  popStyle();
}

void drawCurrentHorizontalBarGraph(int p, float gx, float gy, float gw, float gh) {
  fill(235); stroke(200); strokeWeight(1);
  rect(gx, gy, gw, gh, 8);
  
  float barX = gx + 12, barW = gw - 24, barH = 22;
  float targetX = map(targetTaiju, 0, 150, barX, barX + barW);
  
  fill(255, 230, 0, 100); rect(targetX - 2, gy + 5, 4, gh - 10); 
  stroke(220, 180, 0); strokeWeight(2); line(targetX, gy + 2, targetX, gy + gh - 2); 
  noStroke();

  if (currentTurn >= 4) {
    fill(200); rect(barX, gy + 32, barW, barH, 4);
    fill(120, 100);
    rect(barX, gy + 32, (sin(frameCount * 0.1) * 0.5 + 0.5) * barW, barH, 4);

    textAlign(LEFT, CENTER); textSize(12); fill(80);
    text("体重: ??? kg", barX + 8, gy + 32 + barH/2);
  } else {
    fill(60); rect(barX, gy + 32, map(constrain(taiju[p], 0, 150), 0, 150, 0, barW), barH, 4);
    textAlign(LEFT, CENTER); textSize(12); fill(255);
    text("体重: " + taiju[p] + " kg", barX + 8, gy + 32 + barH/2);
  }

  fill(40, 180, 70); rect(barX, gy + 86, map(constrain(health[p], 0, 100), 0, 100, 0, barW), barH, 4);
  fill(220, 60, 60); rect(barX, gy + 140, map(constrain(stress[p], 0, 100), 0, 100, 0, barW), barH, 4);

  fill(160, 120, 0); textSize(11); textAlign(CENTER, CENTER);
  text("目標:" + targetTaiju + "kg", targetX, gy + 14);

  textAlign(LEFT, CENTER); textSize(12); fill(255);
  text("健康: " + health[p] + " %", barX + 8, gy + 86 + barH/2);
  text("ストレス: " + stress[p] + " %", barX + 8, gy + 140 + barH/2);
  textAlign(CENTER, CENTER);
}

void drawCardImage(String cardName, float centerX, float centerY, float maxW, float maxH) {
  PImage img = cardImages.get(cardName);
  if (img == null || img.width <= 0 || img.height <= 0) return;

  float scaleValue = min(maxW / img.width, maxH / img.height);
  imageMode(CENTER);
  image(img, centerX, centerY, img.width * scaleValue, img.height * scaleValue);
  imageMode(CORNER);
}

void drawCard(Card c, float x, float y, float w, float h) {
  fill(getCardColor(c.type)); stroke(0); strokeWeight(2);
  rect(x, y, w, h, 8);
  
  fill(0); textSize(18); text(c.name, x + w/2, y + 25);
  stroke(0, 50); strokeWeight(1); line(x + 8, y + 42, x + w - 8, y + 42);

  drawCardImage(c.name, x + w/2, y + 120, w - 16, 130);

  textSize(16);
  if (c.type == CardType.JAM) {
    if (c.jamType == 1) text("【妨害】\n相手の体重UP", x + w/2, y + 235);
    else if (c.jamType == 2) text("【妨害】\n相手ターン5秒", x + w/2, y + 235);
    else if (c.jamType == 3) text("【妨害】\n相手次ターン\nマンジャロ固定", x + w/2, y + 235);
  } else {
    float startY = y + 210, lineHeight = 22;
    int lineCount = 0;
    
    if (c.dTaiju != 0) {
      fill(c.dTaiju < 0 ? #0064C8 : #C80000);
      text("体重: " + (c.dTaiju > 0 ? "+" : "") + c.dTaiju, x + w/2, startY + (lineCount++ * lineHeight));
    }
    if (c.dHealth != 0) {
      fill(0, 120, 0);
      text("健康: " + (c.dHealth > 0 ? "+" : "") + c.dHealth, x + w/2, startY + (lineCount++ * lineHeight));
    }
    if (c.dStress != 0) {
      fill(180, 0, 0);
      text("ストレス: " + (c.dStress > 0 ? "+" : "") + c.dStress, x + w/2, startY + (lineCount * lineHeight));
    }
  }
}

void drawCardEffect(Card c, float x, float y, float w, float h, float alphaValue) {
  pushStyle();
  fill(getCardColor(c.type), alphaValue);
  stroke(0, alphaValue); strokeWeight(2);
  rect(x, y, w, h, 8);

  fill(0, alphaValue); textSize(18); text(c.name, x + w/2, y + 25);
  stroke(0, alphaValue * 0.25); strokeWeight(1); line(x + 8, y + 42, x + w - 8, y + 42);

  PImage img = cardImages.get(c.name);
  if (img != null && img.width > 0 && img.height > 0) {
    float scaleValue = min((w - 16) / img.width, 130.0 / img.height);
    tint(255, alphaValue); imageMode(CENTER);
    image(img, x + w/2, y + 120, img.width * scaleValue, img.height * scaleValue);
    imageMode(CORNER); noTint();
  }
  popStyle();
}

// ==========================================
// イベント入力処理
// ==========================================
void mousePressed() {
  if (gameState == 0) {
    if (mouseX >= width/2 - 150 && mouseX <= width/2 + 150) {
      if (mouseY >= 370 && mouseY <= 430) startCountdown();
      else if (mouseY >= 455 && mouseY <= 515) { rulePage = 0; gameState = 5; }
    }
    return;
  }

  if (gameState == 5) {
    if (mouseY >= height - 95 && mouseY <= height - 35) {
      if (mouseX >= 85 && mouseX <= 185) rulePage = (rulePage - 1 + RULE_PAGE_COUNT) % RULE_PAGE_COUNT;
      else if (mouseX >= width - 185 && mouseX <= width - 85) rulePage = (rulePage + 1) % RULE_PAGE_COUNT;
      else if (mouseX >= width/2 - 110 && mouseX <= width/2 + 110) gameState = 0;
    }
    return;
  }
  
  if (gameState == 4) {
    if (millis() - cutinStartTime > 1000) { resetGame(); gameState = 0; }
    return;
  }
  
  if (gameState != 1) return;
  
  int p = activePlayer;
  float x = (p == 0) ? 25 : 655, cardY = 365;
  float cardW = 130, cardH = 310;
  float cardSpacing = (600 - 30 - (cardW * 4)) / 3;
  
  for (int i = 0; i < hands[p].size(); i++) {
    float cardX = x + 15 + i * (cardW + cardSpacing);
    if (mouseX >= cardX && mouseX <= cardX + cardW && mouseY >= cardY && mouseY <= cardY + cardH) {
      isDragging = true;
      draggedCardIndex = i;
      dragOffsetX = mouseX - cardX;
      dragOffsetY = mouseY - cardY;
      break;
    }
  }
}

void mouseReleased() {
  if (gameState != 1 || !isDragging) return;

  int p = activePlayer;
  float holdX = ((p == 0) ? 25 : 655) + 490;
  float holdY = 139;

  if (mouseX >= holdX && mouseX <= holdX + 95 && mouseY >= holdY - 20 && mouseY <= holdY + 200) {
    holdCard(p, draggedCardIndex);
  } else {
    useCard(p, draggedCardIndex);
  }

  isDragging = false;
  draggedCardIndex = -1;
}

void keyPressed() {
  if (key == '5') key5Pressed = true;
  if (key == '-') keyMinusPressed = true;

  if (gameState != 1) return;

  if (activePlayer == 0) {
    int idx = key - '1';
    if (idx >= 0 && idx < 4) {
      if (key5Pressed) holdCard(0, idx); else useCard(0, idx);
    }
  } else if (activePlayer == 1) {
    int idx = (key == '0') ? 3 : key - '7';
    if (idx >= 0 && idx < 4) {
      if (keyMinusPressed) holdCard(1, idx); else useCard(1, idx);
    }
  }
}

void keyReleased() {
  if (key == '5') key5Pressed = false;
  if (key == '-') keyMinusPressed = false;
}

void holdCard(int p, int cardIndex) {
  if (cardIndex < 0 || cardIndex >= hands[p].size()) return;
  
  Card cardInHand = hands[p].get(cardIndex);

  if (heldCards[p] == null) {
    heldCards[p] = cardInHand;
    hands[p].remove(cardIndex);
    hands[p].add(isManjaroOnly[p] ? manjaroCard : drawRandomCard(p));
  } else {
    Card temp = heldCards[p];
    heldCards[p] = cardInHand;
    hands[p].set(cardIndex, temp);
  }
}

boolean isComboCategory(CardType type) {
  return type == CardType.MEAL || type == CardType.EXERCISE || type == CardType.LIFE;
}

void updateCombo(int p, Card c, float cardCenterX, float cardCenterY) {
  if (!isComboCategory(c.type)) return;

  if (lastComboType[p] == null) {
    lastComboType[p] = c.type; comboCount[p] = 1;
    return;
  }

  if (lastComboType[p] == c.type) {
    comboCount[p]++;
    if (comboCount[p] >= 2) {
      comboEffects.add(new ComboEffect(cardCenterX, cardCenterY, comboCount[p] + " COMBO!"));
    }
    return;
  }

  if (comboCount[p] >= 2) {
    int finishedComboCount = comboCount[p];
    int comboWeightLoss = finishedComboCount * COMBO_WEIGHT_MULTIPLIER;
    taiju[p] -= comboWeightLoss;

    comboEffects.add(new ComboEffect(cardCenterX, cardCenterY, finishedComboCount + " COMBO FINISH!\n-" + comboWeightLoss + "kg"));
  }

  lastComboType[p] = c.type;
  comboCount[p] = 1;
}

void useCard(int p, int cardIndex) {
  if (cardIndex < 0 || cardIndex >= hands[p].size()) return;

  Card c = hands[p].get(cardIndex);
  int opp = 1 - p;

  float cardW = 130, cardH = 310;
  float cardSpacing = (600 - 30 - (cardW * 4)) / 3;
  float cardX = ((p == 0) ? 25 : 655) + 15 + cardIndex * (cardW + cardSpacing);
  float cardY = 365;

  cardEffects.add(new CardEffect(c, cardX, cardY, cardW, cardH));
  updateCombo(p, c, cardX + cardW / 2, cardY + 20);
  
  if (c.type == CardType.JAM) {
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
  hands[p].add(isManjaroOnly[p] ? manjaroCard : drawRandomCard(p));
  
  checkInstantLoss();
}

// ==========================================
// 勝敗判定・結果表示 & タイトル/ルール
// ==========================================
void drawResult() {
  fill(0, 200); rect(0, 0, width, height);
  fill(255); textSize(44); text("GAME OVER", width/2, 140);
  
  String winnerText = "";
  boolean p1Burst = (taiju[0] <= 0 || stress[0] >= MAX_STRESS);
  boolean p2Burst = (taiju[1] <= 0 || stress[1] >= MAX_STRESS);
  
  if (p1Burst && p2Burst) winnerText = "引き分け（両者脱落）";
  else if (p1Burst) winnerText = "PLAYER 2 WIN! (PLAYER 1 脱落)";
  else if (p2Burst) winnerText = "PLAYER 1 WIN! (PLAYER 2 脱落)";
  else {
    int diff1 = abs(taiju[0] - targetTaiju);
    int diff2 = abs(taiju[1] - targetTaiju);
    if (diff1 < diff2) winnerText = "PLAYER 1 WIN!";
    else if (diff2 < diff1) winnerText = "PLAYER 2 WIN!";
    else winnerText = "引き分け!";
  }
  
  fill(255, 255, 100); textSize(36); text(winnerText, width/2, 240);
  fill(255); textSize(22);
  text("目標体重: " + targetTaiju + " kg", width/2, 330);
  text("P1 最終体重: " + taiju[0] + " kg", width/2, 380);
  text("P2 最終体重: " + taiju[1] + " kg", width/2, 420);
  
  fill(150); textSize(16); text("クリックでタイトルへ戻る", width/2, 530);
}

void drawTitle() {
  background(245, 248, 252);
  fill(35, 55, 80); textSize(60); text("ヤセルバトル", width/2, 230);
  fill(90); textSize(18); text("健康的に目標体重を目指そう！", width/2, 290);

  drawMenuButton(width/2 - 150, 370, 300, 60, "ゲームスタート");
  drawMenuButton(width/2 - 150, 455, 300, 60, "ルール説明");
}

void drawMenuButton(float x, float y, float w, float h, String label) {
  boolean hover = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  stroke(60, 90, 130); strokeWeight(2);
  fill(hover ? #D2E6FA : #E6F0FA);
  rect(x, y, w, h, 12);

  noStroke(); fill(35, 55, 80); textSize(22);
  text(label, x + w/2, y + h/2);
}

void drawRules() {
  background(245, 248, 252);
  fill(35, 55, 80); textSize(34); text("ルール説明", width/2, 50);

  fill(255); stroke(150); strokeWeight(2);
  rect(110, 95, width - 220, height - 270, 16);
  noStroke();

  String title = "", body = "";

  if (rulePage == 0) {
    title = "基本ルール";
    body = "・2人で交互にカードを使う対戦ゲームです。\n\n" +
           "・各プレイヤーは制限時間内、手札のカードを何枚でも使えます。\n\n" +
           "・カードを使うたびに、新しいカードが1枚補充されます。\n\n" +
           "・最終ターン終了後、健康値,ストレス値によってランダムに体重が増減します。\n\n" +
           "・目標体重により近いプレイヤーが勝利です。\n\n" +
           "・ゲーム中体重が0kg以下、またはストレスが100になると脱落します。";
  } else if (rulePage == 1) {
    title = "コンボシステム";
    body = "・食事・運動・生活カードだけがコンボ対象です。\n\n" +
           "・同じカテゴリーを連続で使うと、コンボ数が増えます。\n\n" +
           "・別の対象カテゴリーを使うとコンボが終了します。\n\n" +
           "・終了時のコンボ数 × " + COMBO_WEIGHT_MULTIPLIER + "kgだけ、体重が減少します。\n\n" +
           "・特殊カードと妨害カードはコンボを途切れさせません。";
  } else if (rulePage == 2) {
    title = "特殊・妨害・操作方法";
    body = "【特殊カード】\nリフレッシュ、チートデイ、マンジャロがあります。\n\n" +
           "【妨害カード】\nご飯を奢る、睡眠薬、マンジャロ注文があります。\n\n" +
           "【操作方法】\nPLAYER 1：1〜4キー (使用) / 5キーを押しながら1〜4 (ホールド入れ替え)\nPLAYER 2：7〜0キー (使用) / -キーを押しながら7〜0 (ホールド入れ替え)\n\n" +
           "カードをドラッグ＆ドロップしてHOLD枠に置くことで入れ替えることもできます。";
  }

  fill(35, 55, 80); textSize(28); text(title, width/2, 135);

  fill(40); textSize(18); textAlign(LEFT, TOP); textLeading(29);
  text(body, 165, 185, width - 330, height - 350);
  textAlign(CENTER, CENTER);

  fill(100); textSize(16); text((rulePage + 1) + " / " + RULE_PAGE_COUNT, width/2, height - 125);

  drawRuleButton(85, height - 95, 100, 60, "＜ 前へ");
  drawRuleButton(width/2 - 110, height - 95, 220, 60, "タイトルへ戻る");
  drawRuleButton(width - 185, height - 95, 100, 60, "次へ ＞");
}

void drawRuleButton(float x, float y, float w, float h, String label) {
  boolean hover = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  stroke(80, 110, 145); strokeWeight(2);
  fill(hover ? #CDE1F5 : #E1EEFA);
  rect(x, y, w, h, 10);

  noStroke(); fill(35, 55, 80); textSize(16);
  text(label, x + w/2, y + h/2);
}

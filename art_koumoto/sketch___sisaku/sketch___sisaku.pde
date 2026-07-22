float weight = 77.0;
float bmi;

int health = 100;
int money = 100;
int stress = 30;
int charm = 0;

int turn = 0; 

boolean gameEnd = false;

boolean gameStart = false;

String[] allCards = {
  "サラダ",
  "ジム",
  "睡眠",
  "マンジャロ",
  "和食",
  "ヨガ",
  "美容院",
  "ウォーキング"
};

String[] cards = new String[4];
void setup() {

  size(1000,700);

  PFont font=createFont("Meiryo",24);
  textFont(font);

  bmi = weight / (1.70 * 1.70);

  cards[0] = allCards[int(random(allCards.length))];
  cards[1] = allCards[int(random(allCards.length))];
  cards[2] = allCards[int(random(allCards.length))];
  cards[3] = allCards[int(random(allCards.length))];

}

void draw() {

  background(245);
  
  if (gameStart == false) {

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(42);
  text("健康ダイエットゲーム", width / 2, 180);

  textSize(22);
  text("マンジャロに頼らず", width / 2, 260);
  text("健康的なダイエットを目指そう！", width / 2, 295);

  textSize(28);
  fill(0, 100, 255);
  text("SPACEキーでスタート", width / 2, 420);

  textAlign(LEFT, BASELINE);
  return;
}
  
  if (gameStart == false) {

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(42);
  text("健康ダイエットゲーム", width / 2, 220);

  textSize(22);
  text("健康的な方法で理想の自分を目指そう！", width / 2, 300);

  textSize(26);
  text("スペースキーでスタート", width / 2, 400);

  textAlign(LEFT, BASELINE);
  return;
}

  gameEnd = (turn >= 20);

if (gameEnd) {

    fill(0);
    textAlign(CENTER, CENTER);
    textSize(40);
    if (bmi >= 17.9 && bmi <= 18.5 &&
    health >= 80 &&
    charm >= 30 &&
    stress <= 20) {

  fill(0, 150, 0);
  text("TRUE END！", width / 2, 180);

}
else if (health <= 0) {

  fill(200, 0, 0);
  text("BAD END", width / 2, 180);

}
else {

  fill(200, 100, 0);
  text("NORMAL END", width / 2, 180);

}

    textSize(26);
    text("最終体重：" + nf(weight, 0, 1) + "kg", width / 2, 260);
    text("最終BMI：" + nf(bmi, 0, 1), width / 2, 310);
    text("健康：" + health, width / 2, 360);
    text("魅力度：" + charm, width / 2, 410);
    fill(0);
textSize(18);
text("Rキーで再挑戦！", width / 2, 560);

textSize(20);

if (bmi >= 17.9 && bmi <= 18.5 &&
    health >= 80 &&
    charm >= 30 &&
    stress <= 20) {

  fill(0, 150, 0);
  text("健康的なダイエットに成功しました！", width / 2, 470);
  text("マンジャロに頼らず理想の自分を達成！", width / 2, 500);

}
else if (health <= 0) {

  fill(200, 0, 0);
  text("健康を犠牲にしてしまいました…。", width / 2, 470);
  text("体重だけでは幸せになれません。", width / 2, 500);

}
else {

  fill(200, 100, 0);
  text("あと一歩でした！", width / 2, 470);
  text("もう一度チャレンジしてみよう！", width / 2, 500);

}
    textAlign(LEFT, BASELINE);
    return;
  }

  // タイトル
  fill(0);
  textSize(32);
  text("健康ダイエットゲーム", 40, 50);

  // 残り行動
  fill(200, 0, 0);
  textSize(24);
  text("残り行動：" + (20 - turn), 700, 40);

  // ステータス
  fill(0);
  textSize(22);
  text("体重：" + nf(weight, 0, 1) + "kg", 700, 100);
  text("BMI：" + nf(bmi, 0, 1), 700, 140);
  text("健康：" + health, 700, 180);
  text("お金：" + money, 700, 220);
  text("ストレス：" + stress, 700, 260);
  text("魅力度：" + charm, 700, 300);

  // 体重によって体の幅を変える
float bodyWidth;

if (weight >= 75) {
  bodyWidth = 140;
}
else if (weight >= 65) {
  bodyWidth = 110;
}
else {
  bodyWidth = 85;
}

// 顔
fill(255, 220, 200);
ellipse(430, 220, 100, 100);

// 目
fill(0);
ellipse(415, 210, 8, 8);
ellipse(445, 210, 8, 8);

// 口
noFill();
arc(430, 230, 25, 15, 0, PI);

// 体
fill(255, 170, 190);
rect(430 - bodyWidth / 2, 270, bodyWidth, 160, 20);

// 腕
line(430 - bodyWidth / 2, 300, 340, 350);
line(430 + bodyWidth / 2, 300, 520, 350);

// 足
line(405, 430, 395, 510);
line(455, 430, 465, 510);

  // カード
  drawCard(50,520,cards[0]);
  drawCard(280,520,cards[1]);
  drawCard(510,520,cards[2]);
  drawCard(740,520,cards[3]);
}
void drawCard(int x, int y, String name) {

  // カードの色
if (name.equals("サラダ") || name.equals("和食")) {
  fill(180, 255, 180);
}

else if (name.equals("ジム") ||
         name.equals("ヨガ") ||
         name.equals("ウォーキング")) {
  fill(180, 220, 255);
}
else if (name.equals("睡眠")) {
  fill(230, 230, 255);
}

else if (name.equals("美容院")) {
  fill(255, 200, 230);
}

else if (name.equals("マンジャロ")) {
  fill(255, 180, 180);
}

else {
  fill(255);
}

stroke(120);
rect(x, y, 180, 150, 20);

  fill(0);
  textAlign(CENTER, CENTER);

  // カード名
  textSize(24);
  text(name, x + 90, y + 30);

  // 効果
  textSize(13);

if (name.equals("サラダ")) {
  text("体重 -0.3kg", x + 90, y + 75);
  text("健康 +5", x + 90, y + 90);
  text("お金 -5", x + 90, y + 105);
}

else if (name.equals("ジム")) {
  text("体重 -0.7kg", x + 90, y + 70);
  text("健康 +10", x + 90, y + 85);
  text("お金 -15", x + 90, y + 100);
  text("ストレス +5", x + 90, y + 115);
}

else if (name.equals("睡眠")) {
  text("健康 +10", x + 90, y + 75);
  text("ストレス -15", x + 90, y + 90);
}

else if (name.equals("マンジャロ")) {
  text("体重 -5kg", x + 90, y + 65);
  text("健康 -35", x + 90, y + 80);
  text("お金 -20", x + 90, y + 95);
  text("ストレス +20", x + 90, y + 110);
  text("魅力 +10", x + 90, y + 135);
}

else if (name.equals("和食")) {
  text("体重 -0.2kg", x + 90, y + 75);
  text("健康 +8", x + 90, y + 90);
  text("お金 -8", x + 90, y + 105);
}

else if (name.equals("ヨガ")) {
  text("健康 +8", x + 90, y + 75);
  text("ストレス -6", x + 90, y + 90);
  text("お金 -5", x + 90, y + 105);
}

else if (name.equals("美容院")) {
  text("魅力 +10", x + 90, y + 75);
  text("お金 -20", x + 90, y + 90);
  text("ストレス -5", x + 90, y + 105);
}

else if (name.equals("ウォーキング")) {
  text("体重 -0.2kg", x + 90, y + 75);
  text("健康 +6", x + 90, y + 90);
  text("ストレス -3", x + 90, y + 105);
}
  textAlign(LEFT, BASELINE);
}
void useCard(String cardName) {

  if (cardName.equals("サラダ")) {
    weight -= 0.3;
    health += 5;
    money -= 5;
  }

  else if (cardName.equals("ジム")) {
    weight -= 0.7;
    health += 10;
    money -= 15;
    stress += 5;
  }

  else if (cardName.equals("睡眠")) {
    health += 10;
    stress -= 15;
  }

  else if (cardName.equals("マンジャロ")) {
    weight -= 5.0;
    health -= 35;
    money -= 20;
    stress += 20;
    charm += 10;
  }

  else if (cardName.equals("和食")) {
    weight -= 0.2;
    health += 8;
    money -= 8;
  }

  else if (cardName.equals("ヨガ")) {
    health += 8;
    stress -= 6;
    money -= 5;
  }

  else if (cardName.equals("美容院")) {
    money -= 20;
    charm += 10;
    stress -= 5;
  }

  else if (cardName.equals("ウォーキング")) {
    weight -= 0.2;
    health += 6;
    stress -= 3;
  }
}
void mousePressed() {

  if (gameEnd) {
    return;
  }

  // 左から1枚目
  

  // 左から1枚目
  // 左から1枚目
if (mouseX >= 50 && mouseX <= 230 &&
    mouseY >= 520 && mouseY <= 640) {

  useCard(cards[0]);

  turn++;

  cards[0] = allCards[int(random(allCards.length))];
}

  // 左から2枚目
  // 左から2枚目
else if (mouseX >= 280 && mouseX <= 460 &&
         mouseY >= 520 && mouseY <= 640) {

  useCard(cards[1]);

  turn++;

  cards[1] = allCards[int(random(allCards.length))];
}

  // 左から3枚目
  // 左から3枚目
else if (mouseX >= 510 && mouseX <= 690 &&
         mouseY >= 520 && mouseY <= 640) {

  useCard(cards[2]);

  turn++;

  cards[2] = allCards[int(random(allCards.length))];
}

  // 左から4枚目
  // 左から4枚目
else if (mouseX >= 740 && mouseX <= 920 &&
         mouseY >= 520 && mouseY <= 640) {

  useCard(cards[3]);

  turn++;

  cards[3] = allCards[int(random(allCards.length))];
}

  bmi = weight / (1.70 * 1.70);
}
void keyPressed() {
  
  if (key == ' ') {
  gameStart = true;
}

  if (key == 'r' || key == 'R') {

    weight = 77;
    bmi = weight / (1.70 * 1.70);
    health = 100;
    money = 100;
    stress = 30;
    charm = 0;
    turn = 0;
    gameEnd = false;

    cards[0] = allCards[int(random(allCards.length))];
    cards[1] = allCards[int(random(allCards.length))];
    cards[2] = allCards[int(random(allCards.length))];
    cards[3] = allCards[int(random(allCards.length))];
  }
}

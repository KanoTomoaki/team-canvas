void setup() {
size(600, 400);
background(255);
}
void draw() {
// マウスの位置に色付きの円を描く
if (mousePressed==true){
fill(random(255), random(255), random(255), 100);
noStroke();
ellipse(mouseX, mouseY, 40, 40);
}
}

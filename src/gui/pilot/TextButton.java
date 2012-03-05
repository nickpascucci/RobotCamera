import processing.core.PApplet;
import processing.core.PFont;

class TextButton {
  private PApplet parent;
  private int textColor;
  private int alternateColor;
  private int backgroundColor;
  private String buttonText;
  private PFont font;
  private float textX, textY, textW, textH;
  private boolean selected = false;

  public TextButton(PApplet parent, String text, float x, float y, float h){
    this.parent = parent;
    this.textX = x;
    this.textY = y;
    this.textW = parent.textWidth(text);
    this.textH = h;
    buttonText = text;
  }

  public TextButton(PApplet parent, String text, float x, float y, 
                    float w, float h){
    this.parent = parent;
    this.textX = x;
    this.textY = y;
    this.textW = w;
    this.textH = h;
    buttonText = text;
  }

  private void setDefaultColors(){
    this.textColor = this.parent.color(255);
    this.alternateColor = this.parent.color(255, 0, 0);
    this.backgroundColor = this.parent.color(0);
  }

  public void setColors(int main, int alternate, int background){
    textColor = main;
    alternateColor = alternate;
    backgroundColor = background;
  }

  public void setColors(int main, int alternate){
    textColor = main;
    alternateColor = alternate;
  }

  public void setFont(PFont font){
    this.font = font;
  }

  public void setText(String text){
    buttonText = text;
  }

  public String getText(){
    return buttonText;
  }

  public boolean contains(int x, int y){
    if(x >= textX && x <= textX+textW){
      if(y >= textY && y <= textY+textH){
        return true;
      }
    }
    return false;
  }

  public boolean isSelected(){
    return selected;
  }

  public void setSelected(boolean isSelected){
    selected = isSelected;
  }

  public void draw(){
    parent.noStroke();
    parent.fill(backgroundColor);
    parent.rect(textX, textY, textW, textH);
    parent.textFont(font);
    if(this.isSelected()){
      parent.fill(alternateColor);
    }
    else {
      parent.fill(textColor);
    }
    parent.text(buttonText, textX, textY, textW, textH);
  }
}
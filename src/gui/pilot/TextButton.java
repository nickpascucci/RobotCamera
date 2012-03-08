import processing.core.PApplet;
import processing.core.PFont;

class TextButton {
  private PApplet parent;
  private int textColor;
  private int alternateColor;
  private int disabledColor;
  private String buttonText;
  private PFont font;
  private float textX, textY, textW, textH;
  private boolean selected = false;
  private boolean enabled = true;

  public TextButton(PApplet parent, String text, float x, float y, float h){
    this.parent = parent;
    setDefaultColors();
    this.textX = x;
    this.textY = y;
    this.textW = parent.textWidth(text);
    this.textH = h;
    buttonText = text;
  }

  public TextButton(PApplet parent, String text, float x, float y, 
                    float w, float h){
    this.parent = parent;
    setDefaultColors();
    this.textX = x;
    this.textY = y;
    this.textW = w;
    this.textH = h;
    buttonText = text;
  }

  private void setDefaultColors(){
    this.textColor = this.parent.color(255);
    this.alternateColor = this.parent.color(255, 0, 0);
    this.disabledColor = this.parent.color(100);
  }

  public void setColors(int main, int alternate, int disabled){
    textColor = main;
    alternateColor = alternate;
    disabledColor = disabled;
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

  public void setEnabled(boolean enabled){
    this.enabled = enabled;
  }

  public boolean isEnabled(){
    return enabled;
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
    if(!enabled){
      return false;
    }
    return selected;
  }

  public void setSelected(boolean isSelected){
    selected = isSelected;
  }

  public void draw(){
    parent.noStroke();
    parent.textFont(font);
    if(this.isSelected()){
      parent.fill(alternateColor);
    } else if(this.isEnabled()) {
      parent.fill(textColor);
    } else {
      parent.fill(disabledColor);
    }
    parent.text(buttonText, textX, textY, textW, textH);
  }
}
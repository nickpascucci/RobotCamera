import processing.core.PApplet;
import processing.core.PImage;

public class OverlayButton {
  private PApplet parent;
  private int offsetX;
  private int offsetY;
  private int centerX;
  private int centerY;
  private PImage normalImage;
  private PImage selectedImage;
  private boolean selected = false;

  public OverlayButton(PApplet parent, int offsetX, int offsetY, 
                       PImage normalImage, PImage selectedImage){
    this.parent = parent;
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.selectedImage = selectedImage;
    this.normalImage = normalImage;
  }

  public void drawAt(int centerX, int centerY){
    this.centerX = centerX;
    this.centerY = centerY;
    parent.imageMode(parent.CENTER);
    if(selected){
      parent.image(selectedImage, centerX + offsetX, centerY - offsetY);
    } else {
      parent.image(normalImage, centerX + offsetX, centerY - offsetY);
    }
  }

  public void setSelected(boolean isSelected){
    selected = isSelected;
  }

  public boolean isSelected(){
    return selected;
  }

  private int quadrant(float angle){
    if(angle >= 0 && angle < parent.HALF_PI) return 1;
    else if(angle >= parent.HALF_PI && angle < parent.PI) return 2;
    else if(angle >= parent.PI && angle < parent.PI + parent.HALF_PI) return 3;
    else return 4;
  }

  public boolean contains(int x, int y){
    int dx = centerX - x;
    int dy = centerY - y;
    int adx = parent.abs(dx);
    int ady = parent.abs(dy);
    if(offsetX > 0 && dx < 0 && adx > ady){
      return true;
    } else if(offsetY < 0 && dy < 0 && ady > adx){
      return true;
    } else if(offsetX < 0 && dx > 0 && adx > ady){
      return true;
    } else if(offsetY > 0 && dy > 0 && ady > adx){
      return true;
    }
    return false;
  }
}
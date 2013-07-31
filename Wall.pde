public class Wall extends Sprite
{
  public int hitCount;
  
  public Wall(PApplet applet, String name, int cols, int rows, int zOrder)
  {
    super(applet, name, cols, rows, zOrder);
    hitCount = 0;
  }
}

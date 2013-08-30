//A bullet class that keeps track of who shot the bullet
public class Bullet extends Sprite
{
  public int player;
  
  public Bullet(PApplet applet, String name, int zOrder, int p)
  {
    super(applet, name, zOrder);
    player = p;
  }
}

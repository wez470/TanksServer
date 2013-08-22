import sprites.utils.*;
import sprites.*;

/**
 * A class for a tank on the server
 */
public class ServerTank
{
  public float tankSpeed;
  public float tankRot; 
  public float turretRot;
  public boolean moving;
  public boolean turretMoved;
  public boolean colliding;
  public boolean invincible;
  public Sprite tankBase;
  public Sprite tankTurret;
  public int health;
  
  /**
   * Constructor for ServerTank
   */
  public ServerTank(PApplet applet)
  {
    tankBase = new Sprite(applet, "Images/BaseDoneFitted.png", 100);
    tankTurret = new Sprite(applet, "Images/LongGunFitted.png", 100);
    tankBase.setScale(scaleSize);
    tankTurret.setScale(scaleSize * 1.2);
    moving = false;
    turretMoved = true;
    colliding = false;
    invincible = false;
    health = 100;
  }
  
  public void update(float deltaTime)
  {
    tankBase.update(deltaTime);
    tankTurret.setXY(tankBase.getX(), tankBase.getY());
  }
  
  public void spawn(int playerNum)
  {
    switch(playerNum)
    {
      case 1:
        tankBase.setXY(0.055 * width, 0.226 * height);
        tankTurret.setXY(0.055 * width, 0.226 * height);
        break;
      case 2:
        tankBase.setXY(0.85 * width, 0.0867 * height);
        tankTurret.setXY(0.85 * width, 0.0867 * height);        
        break;
      case 3:
        tankBase.setXY(0.945 * width, 0.773 * height);
        tankTurret.setXY(0.945 * width, 0.773 * height);        
        break;
      case 4:
        tankBase.setXY(0.145 * width, 0.913 * height);
        tankTurret.setXY(0.145 * width, 0.913 * height);        
        break;
      default:
        break;
    }    
  }
  
  /**
   * Used for debugging tank positions/orientations
   */
  public void draw()
  {
    tankBase.draw();
    tankTurret.draw();
  }
}

import com.esotericsoftware.kryonet.*;

import java.util.*;
import java.util.concurrent.*;

Server server;
ArrayList<Integer> players;
ConcurrentHashMap<Integer, Sprite> bullets;
HashMap<Sprite, Integer> bulletIDs;
int bulletID;
HashMap<Wall, Integer> wallIDs;
HashMap<Integer, Wall> walls;
ConcurrentHashMap<Integer, Sprite> powerUps;
HashMap<Sprite, Integer> powerUpIDs;
boolean[] connectedPlayers;
int numPlayers;
int playersDestroyed = 0;
ServerTank[] tanks;
float tankMaxSpeed = 125.0;
float bulletSpeed = 50.0;
float scaleSize; 
float deltaTime = 0.0;
int moveTimer = -20;
int rotateTimer = -20;
int time = 0;
boolean tanksSent = false;
StopWatch timer;
boolean powerUpTaken = false;
int powerUpTimer = 0;

void setup()
{
  size(800, 600);
  background(0);
  numPlayers = 0;
  bulletID = 0;
  players = new ArrayList<Integer>();
  bullets = new ConcurrentHashMap<Integer, Sprite>();
  bulletIDs = new HashMap<Sprite, Integer>();
  scaleSize = height / 2400.0;
  setupWalls();
  setupPowerUps();
  timer = new StopWatch();
  connectedPlayers = new boolean[4];
  tanks = new ServerTank[4];
  server = new Server();
  Network.register(server);
  server.addListener(new Listener() 
  {
    public void connected(Connection connection)
    {
      setupClient(connection);
    }
    
    public void received(Connection connection, Object object)
    {
      int currPlayer = connection.getID();   
      //check which message was sent and process it
      if(object instanceof Network.ShootServerMsg)
      {
        createBullet(currPlayer);
      }
      else if(object instanceof Network.MoveServerMsg)
      {
        Network.MoveServerMsg message = (Network.MoveServerMsg) object;
        tanks[currPlayer - 1].moving = true;
        tanks[currPlayer - 1].tankBase.setRot(radians(message.direction + 90.0));
        tanks[currPlayer - 1].tankBase.setSpeed(tankMaxSpeed * message.magnitude, radians(message.direction));
        tanks[currPlayer - 1].colliding = false;
      }
      else if(object instanceof Network.RotateServerMsg)
      {
        Network.RotateServerMsg message = (Network.RotateServerMsg) object;
        tanks[currPlayer - 1].tankTurret.setRot(radians((float)(message.turretRot + 90.0)));
        tanks[currPlayer - 1].turretMoved = true;
      }
      else if(object instanceof Network.StopMsg)
      {
        tanks[currPlayer - 1].moving = false;
      }
      else if(object instanceof Network.ChatMsg)
      {
        Network.ChatMsg chatMsg = (Network.ChatMsg) object;
        Network.ChatMsg newChatMsg = new Network.ChatMsg();
        newChatMsg.message = "Player " + currPlayer + ": " + chatMsg.message;
        server.sendToAllTCP(newChatMsg);
      }
      else if(object instanceof Network.DisconnectMsg)
      {
        disconnectEvent(currPlayer);
      }
    }  
  });
  try
  {
    server.bind(Network.TCPPort, Network.UDPPort);
  }
  catch (Exception e)
  {
    e.printStackTrace();
  }
  server.start();
}

/**
 * Set up the walls for the game
 */
void setupWalls()
{
  walls = new HashMap<Integer, Wall>();
  wallIDs = new HashMap<Wall, Integer>();
  //walls created top to bottom left to right
  float wallsX[] = {0.77 * width, 0.15 * width, 0.23 * width, 0.31 * width, 0.39 * width, 0.61 * width, 0.69 * width,
                    0.77 * width, 0.85 * width, 0.055 * width, 0.15 * width, 0.23 * width, 0.77 * width, 0.85 * width,
                    0.15 * width, 0.23 * width, 0.77 * width, 0.85 * width, 0.945 * width, 0.15 * width,
                    0.23 * width, 0.31 * width, 0.39 * width, 0.61 * width, 0.69 * width, 0.77 * width, 0.85 * width,
                    0.23 * width};
  float wallsY[] = {0.0867 * height, 0.2267 * height, 0.2267 * height, 0.2267 * height, 0.2267 * height, 0.2267 * height,
                    0.2267 * height, 0.2267 * height, 0.2267 * height, 0.3334 * height, 0.3334 * height, 0.3334 * height,
                    0.3334 * height, 0.3334 * height, 0.6667 * height, 0.6667 * height, 0.6667 * height,
                    0.6667 * height, 0.6667 * height, 0.773 * height, 0.773 * height, 0.773 * height, 0.773 * height, 
                    0.773 * height, 0.773 * height, 0.773 * height, 0.773 * height, 0.913 * height};
  int numWalls = wallsX.length;
  for(int i = 0; i < numWalls; i++)
  {
    Wall wall = new Wall(this, "Images/BlockTiles5Cracked.png", 5, 1, 100);
    wall.setFrame(0);
    wall.setXY(wallsX[i], wallsY[i]);
    wall.setScale(2 * scaleSize);
    walls.put(i + 1, wall);
    wallIDs.put(wall, i + 1);
  }
}

/**
 * Set up the power ups for the game
 */
void setupPowerUps()
{
  powerUps = new ConcurrentHashMap<Integer, Sprite>();
  powerUpIDs = new HashMap<Sprite, Integer>();
  float powerUpsX[] = {0.5};
  float powerUpsY[] = {0.5};
  int numPowerUps = powerUpsX.length;
  for(int i = 0; i < numPowerUps; i++)
  {
    Sprite powerUp = new Sprite(this, "Images/PowerUp.png", 1, 1, 100);
    powerUp.setXY(powerUpsX[i] * width, powerUpsY[i] * height);
    powerUp.setScale(3.75 * scaleSize);
    powerUps.put(i + 1, powerUp);
    powerUpIDs.put(powerUp, i + 1);
  }
}

void draw()
{
  deltaTime = (float) timer.getElapsedTime();
  //for debugging. Draws a background to the screen
//  background(255);  
  processCollisions(); 
//  for(Sprite currPowerUp: powerUps.values())
//  {
//    currPowerUp.draw();
//  }
  for(int i = 0; i < 4; i++)
  {
    //for debugging.  Draws tanks to screen
//    if(tanks[i] != null)
//    {
//      tanks[i].draw();
//    }
    if(tanks[i] != null && tanks[i].moving)
    {
      //if the player is moving, move them
      tanks[i].update(deltaTime);
      if(millis() - moveTimer > 20)
      {
        Network.MoveClientMsg moveMsg = new Network.MoveClientMsg();
        moveMsg.player = i + 1;
        moveMsg.x = tanks[i].tankBase.getX();
        moveMsg.y = tanks[i].tankBase.getY();
        moveMsg.baseRot = tanks[i].tankBase.getRot();
        moveMsg.turretRot = tanks[i].tankTurret.getRot();
        server.sendToAllUDP(moveMsg);
        tanksSent = true;
      }
    }
  }
  if(tanksSent)
  {
    rotateTimer = millis();
    moveTimer = millis();
    tanksSent = false;
  }
  boolean rotationSent = false;
  for(int i = 0; i < 4; i++)
  {
    if(tanks[i] != null && tanks[i].turretMoved && (millis() - rotateTimer > 25 || !tanks[i].moving))
    {
      rotationSent = true;
      tanks[i].turretMoved = false;
      Network.RotateClientMsg rotateMsg = new Network.RotateClientMsg();
      rotateMsg.player = i + 1;
      rotateMsg.turretRot = tanks[i].tankTurret.getRot();
      server.sendToAllUDP(rotateMsg);
    }
  }
  if(rotationSent)
  {
    rotateTimer = millis(); 
  }
  //for debugging. Draws all the walls to the screen.
//  for(Wall currWall: walls.values())
//  {
//    currWall.draw();
//  } 
  //update and draw bullets
  for(Sprite currBullet: bullets.values())
  {
    currBullet.update(deltaTime);
    //for debugging. Draws the current bullet to the screen
//    currBullet.draw();
  }
  if(numPlayers - playersDestroyed == 1 && playersDestroyed > 0)
  {
    //endgame
  }
  if(millis() - powerUpTimer > 10000 && powerUpTaken)
  {
    server.sendToAllTCP(new Network.PowerUpResetMsg());
    setupPowerUps();
    powerUpTaken = false;
  }
}

/**
 * Create a bullet and send the bullets info to clients
 */
void createBullet(int currPlayer)
{
  double turretLength = tanks[currPlayer - 1].tankTurret.getHeight();
  float turretRot = degrees((float)tanks[currPlayer - 1].tankTurret.getRot());
  Sprite bullet = new Sprite(this, "Images/Bullet.png", 101);
  bullet.setRot(radians(turretRot));
  bullet.setSpeed(bulletSpeed, radians(turretRot - 90.0));
  bullet.setX(tanks[currPlayer - 1].tankTurret.getX() + (turretLength / 2 + bullet.getHeight() / 2) * cos(radians(turretRot - 90.0)));
  bullet.setY(tanks[currPlayer - 1].tankTurret.getY() + (turretLength / 2 + bullet.getHeight() / 2) * sin(radians(turretRot - 90.0)));
  bullet.setScale(scaleSize);
  bullets.put(bulletID, bullet);
  bulletIDs.put(bullet, bulletID);
  Network.ShootClientMsg shootMsg = new Network.ShootClientMsg();
  shootMsg.x = bullet.getX();
  shootMsg.y = bullet.getY();
  shootMsg.bulletRot = bullet.getRot();
  shootMsg.bulletID = bulletID;
  shootMsg.heading = radians(turretRot - 90.0); 
  server.sendToAllTCP(shootMsg);
  bulletID++;  
}

/**
 * Check for collisions in all the game objects
 */
void processCollisions()
{
  for(int i = 0; i < 4; i++)
  {
    if(tanks[i] != null)
    {
      tankCollisions(i);
    }
  }
  bulletCollisions();
}

/**
 * Check for collision with the tank
 */
void tankCollisions(int tankIndex)
{
  //Window boundary detection
  Sprite tankBase = tanks[tankIndex].tankBase;
  float tankDegree = degrees((float)tankBase.getRot());
  if(((tankBase.getX() + tankBase.getWidth() / 2) > width && tankDegree > 0 && tankDegree < 180) 
  || ((tankBase.getX() - tankBase.getWidth() / 2) < 0 && (tankDegree < 0 || tankDegree > 180)))
  {
    if(!tanks[tankIndex].colliding)
    {
      tankBase.setVelY(tankBase.getVelY() / 2);
      tanks[tankIndex].colliding = true;
    }
    tankBase.setVelX(0);
  }
  if(((tankBase.getY() + tankBase.getHeight() / 2) > height && tankDegree > 90) 
  || (tankBase.getY() - tankBase.getHeight() / 2) < 0 && tankDegree < 90 )
  {
    if(!tanks[tankIndex].colliding)
    {
      tankBase.setVelX(tankBase.getVelX() / 2);
      tanks[tankIndex].colliding = true;
    }
    tankBase.setVelY(0);
  }
  
  //Wall collisions
  tankWallCollisions(tankIndex);

  //PowerUp collisions
  for(Sprite currPowerUp: powerUps.values())
  {
    if(collision(tanks[tankIndex].tankBase, currPowerUp))
    {
      int powerUpID = powerUpIDs.get(currPowerUp);
      //send power up taken message
      Network.HitPowerUpMsg hitPowerUpMsg = new Network.HitPowerUpMsg();
      hitPowerUpMsg.powerUpID = powerUpID;
      server.sendToAllTCP(hitPowerUpMsg);
      server.sendToTCP(tankIndex + 1, new Network.PowerUpReceivedMsg());
      powerUpIDs.remove(currPowerUp);
      powerUps.remove(powerUpID);
      powerUpTimer = millis();
      powerUpTaken = true;
      powerUpTimer = millis();
    }
  }
  
  //Bullet collision
  //handled in bulletCollisions()
}

/**
 * Method for handling collisions between tanks and walls
 */
void tankWallCollisions(int tankIndex)
{
  boolean speedCutX = false;
  boolean speedCutY = false;
  Sprite tankBase = tanks[tankIndex].tankBase;
  float tankDegree = degrees((float)tankBase.getRot());
  for(Wall currWall: walls.values())
  {
    if(collision(tankBase, currWall))
    {
      char side = collisionSide(tankBase, currWall);
      if((side == 'T' && tankDegree > 90) || (side == 'B' && tankDegree < 90))
      {
        if(!speedCutY)
        {
          if(!tanks[tankIndex].colliding)
          {
            tankBase.setVelX(tankBase.getVelX() / 2);
            tanks[tankIndex].colliding = true;
          }
          if(side == 'T')
          {
            tankBase.setY(tankBase.getY() - tankBase.getVelY() * deltaTime); 
          }
          else // 'B'
          {
            tankBase.setY(tankBase.getY() - tankBase.getVelY() * deltaTime);
          }
          speedCutY = true;
        }
      }
      if((side == 'L' && tankDegree > 0 && tankDegree < 180) || (side == 'R' && (tankDegree < 0 || tankDegree > 180)))
      {
        if(!speedCutX)
        {
          if(!tanks[tankIndex].colliding)
          {
            tankBase.setVelY(tankBase.getVelY() / 2);
            tanks[tankIndex].colliding = true;
          }
          if(side == 'L')
          {
            tankBase.setX(tankBase.getX() - tankBase.getVelX() * deltaTime);          
          }
          else // 'R'
          {
            tankBase.setX(tankBase.getX() - tankBase.getVelX() * deltaTime);
          }
          speedCutX = true;
        }
      }
    }
  }
}

/**
 * Check for collisions with bullets
 */
void bulletCollisions()
{
  Iterator<Sprite> bulletIt = bullets.values().iterator();
  while(bulletIt.hasNext())
  {
    Sprite currBullet = bulletIt.next();
    //check if out of bounds
    if(((currBullet.getX() + currBullet.getWidth() / 2) > width) 
    || (currBullet.getX() - currBullet.getWidth() / 2) < 0)
    {
      Network.HitBulletMsg hitMsg = new Network.HitBulletMsg();
      hitMsg.bulletID = bulletIDs.get(currBullet);
      server.sendToAllTCP(hitMsg);
      bulletIDs.remove(currBullet);
      bulletIt.remove();
      continue;
    }
    if(((currBullet.getY() + currBullet.getHeight() / 2) > height) 
    || (currBullet.getY() - currBullet.getHeight() / 2) < 0)
    {
      Network.HitBulletMsg hitMsg = new Network.HitBulletMsg();
      hitMsg.bulletID = bulletIDs.get(currBullet);
      server.sendToAllTCP(hitMsg);
      bulletIDs.remove(currBullet);
      bulletIt.remove();
      continue;
    }
    
    //check for collision with wall
    for(Wall currWall: walls.values())
    {
      if(collision(currBullet, currWall))
      {
        Network.HitWallMsg hitMsg = new Network.HitWallMsg();
        hitMsg.wallID = wallIDs.get(currWall);
        hitMsg.bulletID = bulletIDs.get(currBullet);
        server.sendToAllTCP(hitMsg);
        currWall.hitCount++;
        if(currWall.hitCount % 2 == 0 && currWall.hitCount < 10)
        {
          currWall.setFrame(currWall.getFrame() + 1);
        }
        if(currWall.hitCount >= 10)
        {
          int wallID = wallIDs.get(currWall);
          wallIDs.remove(currWall);
          walls.remove(wallID);
        }  
        bulletIDs.remove(currBullet);
        bulletIt.remove();
        break;
      }
    }
    
    //check for collision with tank
    for(int i = 0; i < 4; i++)
    {
      if(tanks[i] != null)
      {
        if(collision(currBullet, tanks[i].tankBase))
        {
          Network.HitTankMsg hitMsg = new Network.HitTankMsg();
          hitMsg.player = i + 1;
          int bulletID = bulletIDs.get(currBullet);
          hitMsg.bulletID = bulletID;
          server.sendToAllTCP(hitMsg);
          bulletIDs.remove(currBullet);
          bullets.remove(bulletID);
          
          tanks[i].spawn(i + 1);
          Network.MoveClientMsg moveMsg = new Network.MoveClientMsg();
          moveMsg.player = i + 1;
          moveMsg.x = tanks[i].tankBase.getX();
          moveMsg.y = tanks[i].tankBase.getY();
          moveMsg.baseRot = tanks[i].tankBase.getRot();
          moveMsg.turretRot = tanks[i].tankTurret.getRot();
          server.sendToAllTCP(moveMsg);
          playersDestroyed++;
        }
      } 
    }
  }
}

/**
 * Called every time a new client joins the server
 */
void setupClient(Connection connection)
{
  if(numPlayers < 5)
  {
    numPlayers++;
    int playerNum = 0;
    for(int i = 0; i < 4; i++)
    {
      if(connectedPlayers[i] == false)
      {
        playerNum = i + 1;
        connectedPlayers[i] = true;
        break;
      }
    }
    println("Client number " + playerNum + " connected with ID: " + connection.getID());
    players.add(playerNum);
    tanks[playerNum - 1] = new ServerTank(this);
    tanks[playerNum - 1].spawn(playerNum);
    for(int i = 0; i < 4; i++)
    {
      if(connectedPlayers[i] == true)
      {
          Network.MoveClientMsg moveMsg = new Network.MoveClientMsg();
          moveMsg.player = i + 1;
          moveMsg.x = tanks[i].tankBase.getX();
          moveMsg.y = tanks[i].tankBase.getY();
          moveMsg.baseRot = tanks[i].tankBase.getRot();
          moveMsg.turretRot = tanks[i].tankTurret.getRot();
          server.sendToAllTCP(moveMsg);
      }
    }
  }
}

/**
 * Method that gets called when a client disconnects
 */
void disconnectEvent(Integer deadPlayer)
{
  println("Client " + deadPlayer + " disconnected");
  players.remove(deadPlayer);
  connectedPlayers[deadPlayer - 1] = false;
  Network.DisconnectMsg disconMsg = new Network.DisconnectMsg();
  disconMsg.player = deadPlayer;
  server.sendToAllTCP(disconMsg);
  numPlayers--;
}

/**
 * Method to check if two sprites are colliding with each other
 * @param objOne: the first object for the collision check
 * @param objTwo: the second object for the collision check
 * @return true if there is a collision and false otherwise
 */
boolean collision(Sprite objOne, Sprite objTwo)
{
  double halfWidthOne = objOne.getWidth() / 2;
  double halfWidthTwo = objTwo.getWidth() / 2;
  double halfHeightOne = objOne.getHeight() / 2;
  double halfHeightTwo = objTwo.getHeight() / 2;
  return (objOne.getX() + halfWidthOne >= objTwo.getX() - halfWidthTwo
    && objOne.getX() - halfWidthOne <= objTwo.getX() + halfWidthTwo
    && objOne.getY() + halfHeightOne >= objTwo.getY() - halfHeightTwo
    && objOne.getY() - halfHeightOne <= objTwo.getY() + halfHeightTwo);
}

/**
 * Figures out which side(s) a collision is on
 * assumes objOne is colliding with objTwo
 * @precond  the two objects are colliding
 * @return char representing the collision side
 *         'T' for top collision
 *         'R' for right collision
 *         'B' for bottom collision
 *         'L' for left collision
 */
char collisionSide(Sprite objOne, Sprite objTwo)
{
  //sides of objOne
  double left1 = objOne.getX() - objOne.getWidth() / 2;
  double top1 = objOne.getY() - objOne.getHeight() / 2;
  double right1 = objOne.getX() + objOne.getWidth() / 2;
  double bottom1 = objOne.getY() + objOne.getHeight() / 2;  
  //sides of objTwo
  double left2 = objTwo.getX() - objTwo.getWidth() / 2;
  double top2 = objTwo.getY() - objTwo.getHeight() / 2;
  double right2 = objTwo.getX() + objTwo.getWidth() / 2;
  double bottom2 = objTwo.getY() + objTwo.getHeight() / 2;
  //amount of tank on each side
  double amountRight = right1 - right2;
  double amountLeft = left2 - left1;
  double amountTop = top2 - top1;
  double amountBottom = bottom1 - bottom2;
  //find which side the tank is on the most
  if(amountRight > amountLeft && amountRight > amountTop && amountRight > amountBottom)
  {
    return 'R';
  }
  else if(amountLeft > amountRight && amountLeft > amountTop && amountLeft > amountBottom)
  {
    return 'L';
  }
  else if(amountTop > amountRight && amountTop > amountLeft && amountTop > amountBottom)
  {
    return 'T';
  }
  else //bottom is largest
  {
    return 'B';
  }
}

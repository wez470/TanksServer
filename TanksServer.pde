import com.esotericsoftware.kryonet.*;

//import processing.net.*;

import java.util.*;
import java.util.concurrent.*;

Server server;
HashMap<Client, Integer> players;
HashMap<Integer, Client> clients;
HashMap<Integer, Sprite> bullets;
HashMap<Sprite, Integer> bulletIDs;
int bulletID;
HashMap<Wall, Integer> wallIDs;
HashMap<Integer, Wall> walls;
int numPlayers;
int playersDestroyed = 0;

ServerTank[] tanks;
float tankMaxSpeed = 100.0;
float bulletSpeed = 300.0;
float scaleSize; 
float deltaTime = 0.0;
int moveTimer = -20;
int rotateTimer = -20;
int bulletPositionTimer = -50;
int time = 0;
boolean tanksSent = false;
StopWatch timer;

void setup()
{
  size(800, 600);
  background(0);
  numPlayers = 0;
  bulletID = 0;
  clients = new HashMap<Integer, Client>();
  players = new HashMap<Client, Integer>();
  bullets = new HashMap<Integer, Sprite>();
  bulletIDs = new HashMap<Sprite, Integer>();
  scaleSize = height / 2400.0;
  setupWalls();
  timer = new StopWatch();
  connectedPlayers = new boolean[4];
  tanks = new ServerTank[4];
  server = new Server(this, 5115);
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
                    0.5 * width, 0.15 * width, 0.23 * width, 0.77 * width, 0.85 * width, 0.945 * width, 0.15 * width,
                    0.23 * width, 0.31 * width, 0.39 * width, 0.61 * width, 0.69 * width, 0.77 * width, 0.85 * width,
                    0.23 * width};
  float wallsY[] = {0.0867 * height, 0.2267 * height, 0.2267 * height, 0.2267 * height, 0.2267 * height, 0.2267 * height,
                    0.2267 * height, 0.2267 * height, 0.2267 * height, 0.3334 * height, 0.3334 * height, 0.3334 * height,
                    0.3334 * height, 0.3334 * height, 0.5 * height, 0.6667 * height, 0.6667 * height, 0.6667 * height,
                    0.6667 * height, 0.6667 * height, 0.773 * height, 0.773 * height, 0.773 * height, 0.773 * height, 
                    0.773 * height, 0.773 * height, 0.773 * height, 0.773 * height, 0.913 * height};
  int numWalls = 29;
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

void draw()
{
  deltaTime = (float) timer.getElapsedTime();
  Client currClient = server.available();
  if(currClient != null && tanks[players.get(currClient) - 1] != null)
  {
    String currString = currClient.readStringUntil('*');
    if(currString != null)
    {
      processMessage(currString, currClient);
    }
  }   
  background(255);  
  processCollisions(); 
  for(int i = 0; i < 4; i++)
  {
    if(tanks[i] != null)
    {
      tanks[i].draw();
    }
    if(tanks[i] != null && tanks[i].moving)
    {
      //if the player is moving, move them
      tanks[i].update(deltaTime);
      if(millis() - moveTimer > 30)
      {
        server.write("move," + (i + 1) + "," + tanks[i].tankBase.getX() + ","
                     + tanks[i].tankBase.getY() + "," + tanks[i].tankBase.getRot() + "," + tanks[i].tankTurret.getRot() + ",*");
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
  if(millis() - rotateTimer > 35)
  {
    for(int i = 0; i < 4; i++)
    {
      if(tanks[i] != null && tanks[i].turretMoved)
      {
        tanks[i].turretMoved = false;
        server.write("rotate," + (i + 1) + "," + tanks[i].tankTurret.getRot() + ",*");
      }
    }
    rotateTimer = millis(); 
  }
  for(Wall currWall: walls.values())
  {
    currWall.draw();
  } 
  //update and draw bullets
  for(Sprite currBullet: bullets.values())
  {
    currBullet.update(deltaTime);
    currBullet.draw();
  }
  if(numPlayers - playersDestroyed == 1 && playersDestroyed > 0)
  {
    //endgame
  }
}

/**
 * Process a message from a client
 */
void processMessage(String currString, Client currClient)
{
  String[] currMessage = currString.split(",");
  int currPlayer = players.get(currClient);
  if(currMessage[0].equals("shoot"))
  {
    createBullet(currPlayer);
  }
  else if(currMessage[0].equals("move"))
  {
    tanks[currPlayer - 1].moving = true;
    tanks[currPlayer - 1].tankBase.setRot(radians(float(currMessage[2]) + 90.0));
    tanks[currPlayer - 1].tankBase.setSpeed(tankMaxSpeed * float(currMessage[1]), radians(float(currMessage[2])));
    tanks[currPlayer - 1].colliding = false;
  }
  else if(currMessage[0].equals("rotate"))
  {
    tanks[currPlayer - 1].tankTurret.setRot(radians(float(currMessage[1]) + 90.0));
    tanks[currPlayer - 1].turretMoved = true;
  }
  else if(currMessage[0].equals("stop"))
  {
    tanks[currPlayer - 1].moving = false;
  }
  else if(currMessage[0].equals("disconnect"))
  {
    disconnectEvent(currClient);
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
  server.write("shoot," + bullet.getRot() + "," + bullet.getX() + "," + bullet.getY() + "," + bulletID + "," + radians(turretRot - 90.0) + ",*");
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
      server.write("hit,bullet," + bulletIDs.get(currBullet) + ",*");
      bulletIDs.remove(currBullet);
      bulletIt.remove();
      continue;
    }
    if(((currBullet.getY() + currBullet.getHeight() / 2) > height) 
    || (currBullet.getY() - currBullet.getHeight() / 2) < 0)
    {
      server.write("hit,bullet," + bulletIDs.get(currBullet) + ",*");
      bulletIDs.remove(currBullet);
      bulletIt.remove();
      continue;
    }
    
    //check for collision with wall
    for(Wall currWall: walls.values())
    {
      if(collision(currBullet, currWall))
      {
        server.write("hit,wall," + wallIDs.get(currWall) + "," + bulletIDs.get(currBullet) + ",*");
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
          server.write("hit,tank," + i + "," + bulletIDs.get(currBullet) + ",*");
          //tanks[i] = null;
          tanks[i].spawn(i + 1);
          server.write("move," + (i + 1) + "," + tanks[i].tankBase.getX() + ","
                       + tanks[i].tankBase.getY() + "," + tanks[i].tankBase.getRot() + "," + tanks[i].tankTurret.getRot() + ",*");
          playersDestroyed++;
        }
      } 
    }
  }
}

/**
 * Called every time a client joins the server
 */
void serverEvent(Server server, Client newClient)
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
    println("Client number " + playerNum + " connected: " + newClient.ip());
    clients.put(playerNum, newClient);
    players.put(newClient, playerNum);
    tanks[playerNum - 1] = new ServerTank(this);
    tanks[playerNum - 1].spawn(playerNum);
    for(int i = 0; i < 4; i++)
    {
      if(connectedPlayers[i] == true)
      {
        server.write("move," + (i + 1) + "," + tanks[i].tankBase.getX() + ","
                     + tanks[i].tankBase.getY() + "," + tanks[i].tankBase.getRot() + "," + tanks[i].tankTurret.getRot() + ",*");
      }
    }
  }
}

/**
 * Method that gets called when a client disconnects
 */
void disconnectEvent(Client deadClient)
{
  int deadPlayer = players.get(deadClient);
  println("Client " + deadPlayer + " disconnected");
  clients.remove(deadPlayer);
  players.remove(deadClient);
  connectedPlayers[deadPlayer - 1] = false;
  server.write("disconnect," + deadPlayer + ",*");
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

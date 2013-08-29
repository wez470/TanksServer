import com.esotericsoftware.kryonet.*;

import java.util.*;
import java.util.concurrent.*;

import javax.swing.JOptionPane; //JOptionPane

Server server;
ArrayList<Integer> players;
ConcurrentHashMap<Integer, Bullet> bullets;
HashMap<Bullet, Integer> bulletIDs;
int bulletID;
String[] killMessages = new String[]{"destroyed", "demolished", "annihilated", "exterminated", "obliterated", "slaughtered", "exterminated"};
ConcurrentHashMap<Wall, Integer> wallIDs;
ConcurrentHashMap<Integer, Wall> walls;
ArrayList<Integer> removedWalls;
ConcurrentHashMap<Integer, Sprite> powerUps;
HashMap<Sprite, Integer> powerUpIDs;
boolean[] connectedPlayers;
int numPlayers;
ServerTank[] tanks;
Score[] scores;
float tankMaxSpeed = 125.0;
float bulletSpeed = 200.0;
float scaleSize; 
float deltaTime = 0.0;
int moveTimer = -20;
int rotateTimer = -20;
int time = 0;
boolean tanksSent = false;
StopWatch timer;
boolean powerUpTaken = false;
int powerUpTimer = 0;
PrintWriter log; 
boolean[] setup;

void setup()
{
  size(800, 600);
  background(0);
  numPlayers = 0;
  bulletID = 0;
  players = new ArrayList<Integer>();
  bullets = new ConcurrentHashMap<Integer, Bullet>();
  bulletIDs = new HashMap<Bullet, Integer>();
  scaleSize = height / 2400.0;
  setupWalls();
  setupPowerUps();
  timer = new StopWatch();
  connectedPlayers = new boolean[4];
  tanks = new ServerTank[4];
  scores = new Score[4];
  setup = new boolean[4];
  for(int i = 0; i < 4; i++)
  {
    setup[i] = false;
  }
  server = new Server();
  String logID = JOptionPane.showInputDialog(this, "Enter the log file ID number");
  log = createWriter("logs/log" + logID + ".txt");
  log.println("EVENT LOG");
  log.flush();
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
      else if(object instanceof Network.InvincibleServerMsg)
      {
        tanks[currPlayer - 1].invincible = true;
        Network.InvincibleClientMsg invincibleMsg = new Network.InvincibleClientMsg();
        invincibleMsg.player = currPlayer;
        server.sendToAllTCP(invincibleMsg);
      }
      else if(object instanceof Network.InvincibleStopServerMsg)
      {
        tanks[currPlayer - 1].invincible = false;
        Network.InvincibleStopClientMsg invincibleMsg = new Network.InvincibleStopClientMsg();
        invincibleMsg.player = currPlayer;
        server.sendToAllTCP(invincibleMsg);
      }
      else if(object instanceof Network.ChatMsg)
      {
        Network.ChatMsg chatMsg = (Network.ChatMsg) object;
        Network.ChatMsg newChatMsg = new Network.ChatMsg();
        log.println("Chat Message: Player " + currPlayer + ": " + chatMsg.message.trim() + "\t" + time());
        log.flush();
        newChatMsg.message = "Player " + currPlayer + ": " + chatMsg.message.trim() + "   " + time();
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
  removedWalls = new ArrayList<Integer>();
  walls = new ConcurrentHashMap<Integer, Wall>();
  wallIDs = new ConcurrentHashMap<Wall, Integer>();
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

/** 
 * A method to get the current time as a string
 */
String time()
{
  return hour() + ":" + minute() + ":" + second();
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
        for(int k = 0; k < 4; k++)
        {
          if(setup[k])
          {
            server.sendToUDP(k + 1, moveMsg);
            tanksSent = true;
          }
        }
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
      for(int k = 0; k < 4; k++)
      {
        if(setup[k])
        {
          server.sendToUDP(k + 1, rotateMsg);
        }
      }
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
  if(millis() - powerUpTimer > 15000 && powerUpTaken)
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
  Bullet bullet = new Bullet(this, "Images/Bullet.png", 101, currPlayer);
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
  
  //Tank collisions
  tankTankCollisions(tankIndex);

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
      log.println("Player " + (tankIndex + 1) + " took power up\t" + time());
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
 * Checks for collisions between tanks
 */
void tankTankCollisions(int tankIndex)
{
  boolean speedCutX = false;
  boolean speedCutY = false;
  Sprite tankBase = tanks[tankIndex].tankBase;
  float tankDegree = degrees((float)tankBase.getRot());
  for(int i = 0; i < 4; i++)
  {
    if(tanks[i] != null && i != tankIndex)
    {
      if(collision(tankBase, tanks[i].tankBase))
      {
        char side = collisionSide(tankBase, tanks[i].tankBase);
        if((side == 'T' && tankDegree > 90) || (side == 'B' && tankDegree < 90))
        {
          tankBase.setVelXY(0.0, 0.0);
        }
        if((side == 'L' && tankDegree > 0 && tankDegree < 180) || (side == 'R' && (tankDegree < 0 || tankDegree > 180)))
        {
          tankBase.setVelXY(0.0, 0.0);
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
  Iterator<Bullet> bulletIt = bullets.values().iterator();
  while(bulletIt.hasNext())
  {
    Bullet currBullet = bulletIt.next();
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
        currWall.hitCount += 1;
        //println(currWall.getFrame()); ranges from 0 to 4
        if(currWall.hitCount % 2 == 0 && currWall.hitCount < 10)
        {
          currWall.setFrame(currWall.getFrame() + 1);
        }
        if(currWall.hitCount >= 10)
        {
          int wallID = wallIDs.get(currWall);
          removedWalls.add(wallID);
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
        if(!tanks[i].invincible && collision(currBullet, tanks[i].tankBase))
        {
          Network.HitTankMsg hitMsg = new Network.HitTankMsg();
          hitMsg.player = i + 1;
          int bulletID = bulletIDs.get(currBullet);
          int shooter = currBullet.player;
          hitMsg.shooter = shooter;
          hitMsg.bulletID = bulletID;
          server.sendToAllTCP(hitMsg);
          bulletIDs.remove(currBullet);
          bullets.remove(bulletID);
          tanks[i].health -= 20;      
          if(tanks[i].health <= 0)
          {
            tanks[i].spawn(i + 1);
            Network.MoveClientMsg moveMsg = new Network.MoveClientMsg();
            moveMsg.player = i + 1;
            moveMsg.x = tanks[i].tankBase.getX();
            moveMsg.y = tanks[i].tankBase.getY();
            moveMsg.baseRot = tanks[i].tankBase.getRot();
            moveMsg.turretRot = tanks[i].tankTurret.getRot();
            server.sendToAllTCP(moveMsg);
            Network.ChatMsg chatMsg = new Network.ChatMsg();
            scores[shooter - 1].kills++;
            log.println("Player " + shooter + " killed Player " + (i + 1) + "\t" + time());
            String score = "Score - ";
            for(int k = 0; k < 4; k++)
            {
              if(scores[k] != null)
              {
                score += "Player " + (k + 1) + ": " + scores[k].kills + "  ";
              }
            }
            score += "\t" + time();
            log.println(score);
            log.flush();
            chatMsg.message = "Player " + shooter + " " + killMessages[min(6, (int)random(0, 7))] + " Player " + (i + 1) + "!   " + time();
            server.sendToAllTCP(chatMsg);
            tanks[i].health = 100;
          }
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
    log.println("Client number " + playerNum + " connected with ID: " + connection.getID() + "\t" + time());
    log.flush();
    players.add(playerNum);
    scores[playerNum - 1] = new Score(playerNum);
    tanks[playerNum - 1] = new ServerTank(this);
    tanks[playerNum - 1].spawn(playerNum);
    createAndSendUpdateClientMsg(playerNum);
  }
}

/**
 * Method that creates and sends a UpdateClientMsg to a player. UpdateClientMsgs update the whole gamestate
 * @param player: the player to send the message to
 */
void createAndSendUpdateClientMsg(int player)
{
  Network.UpdateClientMsg updateMsg = new Network.UpdateClientMsg();
  updateMsg.playerPositions = new ArrayList<Network.MoveClientMsg>(); 
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
        updateMsg.playerPositions.add(moveMsg);
    }
  }
  updateMsg.removedWalls = removedWalls;
  updateMsg.wallHits = new HashMap<Integer, Integer>();
  for(int currWallID: wallIDs.values())
  {
    updateMsg.wallHits.put(currWallID, walls.get(currWallID).hitCount);
  }
  updateMsg.powerUpTaken = powerUpTaken;
  updateMsg.bullets = new ArrayList<Network.ShootClientMsg>();
  for(Sprite currBullet: bullets.values())
  {
    Network.ShootClientMsg shootMsg = new Network.ShootClientMsg();
    shootMsg.x = currBullet.getX();
    shootMsg.y = currBullet.getY();
    shootMsg.bulletRot = currBullet.getRot();
    shootMsg.bulletID = bulletIDs.get(currBullet);
    shootMsg.heading = currBullet.getRot() - PI / 2;
    updateMsg.bullets.add(shootMsg);
  }
  updateMsg.health = new HashMap<Integer, Integer>();
  updateMsg.scores = new HashMap<Integer, Integer>();
  for(int i = 0; i < 4; i++)
  {
    if(tanks[i] != null)
    {
      updateMsg.health.put(i, tanks[i].health);
      updateMsg.scores.put(i, scores[i].kills);
    }
  }
  server.sendToAllTCP(updateMsg);
  setup[player - 1] = true;
}

/**
 * Method that gets called when a client disconnects
 */
void disconnectEvent(Integer deadPlayer)
{
  println("Client " + deadPlayer + " disconnected");
  log.println("Client " + deadPlayer + " disconnected\t" + time());
  log.flush();
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

void exit()
{
  log.close();
  super.exit();
}

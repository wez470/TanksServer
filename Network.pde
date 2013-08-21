import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryonet.*;
import com.esotericsoftware.kryonet.EndPoint;

static public class Network 
{
  static public final int TCPPort = 5115;
  static public final int UDPPort = 5116;
  
  static public void register(EndPoint endPoint)
  {
    Kryo kryo = endPoint.getKryo();
    kryo.register(ShootClientMsg.class);
    kryo.register(ShootServerMsg.class);
    kryo.register(MoveClientMsg.class);
    kryo.register(MoveServerMsg.class);
    kryo.register(RotateClientMsg.class);
    kryo.register(RotateServerMsg.class);
    kryo.register(StopMsg.class);
    kryo.register(DisconnectMsg.class);
    kryo.register(HitBulletMsg.class);
    kryo.register(HitTankMsg.class);
    kryo.register(HitWallMsg.class);
    kryo.register(HitPowerUpMsg.class);
    kryo.register(PowerUpResetMsg.class);
    kryo.register(PowerUpReceivedMsg.class);
    kryo.register(ChatMsg.class);
    kryo.register(UpdateClientMsg.class);
    kryo.register(java.util.ArrayList.class);
    kryo.register(java.util.HashMap.class);
  } 
 
  static public class ShootClientMsg
  {
    double x;
    double y;
    double bulletRot;
    int bulletID;
    double heading;
  }
  
  static public class ShootServerMsg
  {
  }
  
  static public class HitBulletMsg
  {
    int bulletID;
  }
  
  static public class HitWallMsg
  {
    int wallID;
    int bulletID;
  }
  
  static public class HitTankMsg
  {
    int player;
    int bulletID;
  }
 
  static public class MoveClientMsg
  {
    int player;
    double x;
    double y;
    double baseRot;
    double turretRot;
  }
  
  static public class MoveServerMsg
  {
    float magnitude;
    float direction;
  }
  
  static public class RotateClientMsg
  {
    int player;
    double turretRot;
  }
  
  static public class RotateServerMsg
  {
    double turretRot;
  }
 
  static public class StopMsg
  {
  }
 
  static public class DisconnectMsg
  {
    int player;
  } 
  
  static public class HitPowerUpMsg
  {
    int powerUpID;
  }
  
  static public class PowerUpReceivedMsg
  {
  }
  
  static public class PowerUpResetMsg
  {
  }
  
  static public class ChatMsg
  {
    String message;
  }
  
  static public class UpdateClientMsg
  {
    HashMap<Integer, Integer> wallHits;
    ArrayList<Integer> removedWalls;
    ArrayList<ShootClientMsg> bullets;
    ArrayList<MoveClientMsg> playerPositions;
    HashMap<Integer, Integer> health;
    boolean powerUpTaken;
  }
}



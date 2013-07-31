import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryonet.EndPoint;

public class Network 
{
  static public final int port = 5115;
  
  static public void register(EndPoint endPoint)
  {
    Kryo kryo = endPoint.getKryo();
    kryo.register(shootMsg.class);
    kryo.register(moveMsg.class);
    kryo.register(rotateMsg.class);
    kryo.register(stopMsg.class);
    kryo.register(disconnectMsg.class);
    kryo.register(hitBulletMsg.class);
    kryo.register(hitTankMsg.class);
    kryo.register(hitWallMsg.class);
  } 
 
  static public class shootMsg
  {
    double x;
    double y
    double bulletRot
    int id
    double heading
  }
  
  static public class hitBulletMsg
  {
    int bulletID;
  }
  
  static public class hitWallMsg
  {
    int wallID;
    int bulletID;
  }
  
  static public class hitTankMsg
  {
    int player;
    int bulletID;
  }
 
  static public class moveMsg
  {
    int player;
    double x;
    double y;
    double baseRot;
    double turretRot;
  }
  
  static public class rotateMsg
  {
    int player;
    double turretRot;
  }
 
  static public class stopMsg
  {
  }
 
  static public class disconnectMsg
  {
    int player;
  } 
}



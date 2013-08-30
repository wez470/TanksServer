public class Score implements Comparable<Score>
{
  public int player;
  public int kills;
  
  public Score(int p)
  {
    player = p;
    kills = 0;
  }
  
  public int compareTo(Score other)
  {
    return other.kills - this.kills;
  }
  
  public String toString()
  {
    return "Player " + player + ": " + kills; 
  }
}

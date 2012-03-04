public interface SocketAdapter{
  public void flush();
  public void write(byte[] message);
  public void close();
  public int read();
  public int available();
}
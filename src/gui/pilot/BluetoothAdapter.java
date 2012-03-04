/**
   Adapter for standard Bluetooth sockets. Wraps the socket API and provides
   access to common functionality.
 */

import bluetoothDesktop.*;

public class BluetoothAdapter implements SocketAdapter {
  Client client;

  public BluetoothAdapter(Client client){
    this.client = client;
  }

  public void connect() {
    return;
  }

  public void flush(){
    return;
  }

  public void write(byte[] message){
    client.write(message);
  }

  public void close(){
    client.stop();
  }

  public int read() {
    return client.read();
  }

  public int available(){
    return client.available();
  }
}
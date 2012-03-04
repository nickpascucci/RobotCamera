/**
   Adapter for standard internet sockets. Wraps portions of the socket API and
   provides access to common functionality.
 */

import java.net.Socket;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;

public class InternetAdapter implements SocketAdapter {
  private Socket socket;
  private InputStream input;
  private OutputStream output;

  public InternetAdapter(Socket socket){
    this.socket = socket;
  }

  public void connect() throws IOException {
    input = socket.getInputStream();
    output = socket.getOutputStream();
  }

  public void flush() {
    try{
      output.flush();
    }
    catch(IOException ioe){
      // Do nothing
    }
  }

  public void write(byte[] message){
    try{
      output.write(message);
    }
    catch(IOException ioe){
      // Do nothing
    }
  }

  public void close(){
    try{
      socket.close();
    }
    catch(IOException ioe){
      // Do nothing
    }

  }

  public int read() {
    try{
      return input.read();
    }
    catch(IOException ioe){
      return -1;
    }
  }

  public int available(){
    try {
      return input.available();
    }
    catch(IOException ioe){
      return 0;
    }
  }
}
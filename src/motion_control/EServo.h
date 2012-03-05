/*
  EServo.h - Tools for calibrating encoded servos.
 */

struct EncodedServo {
  Servo servo;
  int encoder_interrupt;
  int zero_point;
  int forward_point;
  int backward_point;
  int speed;
  int ticks;
  long int last_tick;
  // Could also store the ISR here. Maybe later.
};

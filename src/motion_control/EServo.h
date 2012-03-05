/*
  EServo.h - Tools for calibrating encoded servos.
 */

struct EncodedServo {
  Servo servo;
  int encoder_interrupt;
  int zero_point;
  int cruise_point;
  int speed;
  int ticks;
  long int last_tick;
  // Could also store the ISR here. Maybe later.
};

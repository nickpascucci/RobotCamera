// Mounting bracket for servos
// Nick Pascucci
// December, 2011

servomount();

module servomount(){
  width = 40;
  thickness = 3; 
  height = 20;
  hole_width = 30;
  hole_height = 12;
  mounting_hole_x1 = 35;
  mounting_hole_x2 = 5;
  mounting_hole_z = 16;
  mounting_hole_size = 2;
  servo_hole_x1 = 37;
  servo_hole_x2 = 3;
  servo_hole_z = 4;
  servo_hole_size = 2;

  difference(){
    base(width, thickness, height, hole_width, hole_height);
    mountingholes(mounting_hole_x1, mounting_hole_x2, 
                  mounting_hole_z, mounting_hole_size);
    servoholes(servo_hole_x1, servo_hole_x2, servo_hole_z, servo_hole_size);
  }
}

module mountingholes(x1, x2, z, size){
  translate([x1, -1, z]){
    rotate([-90, 0, 0]){
      cylinder(h = 5, r = size, center=false);
    }
  }
  translate([x2, -1, z]){
    rotate([-90, 0, 0]){
      cylinder(h = 5, r = size, center=false);
    }
  }
}

module servoholes(x1, x2, z, size){
  translate([x1, -1, z]){
    rotate([-90, 0, 0]){
      cylinder(h = 5, r = size, center=false);
    }
  }
  translate([x2, -1, z]){
    rotate([-90, 0, 0]){
      cylinder(h = 5, r = size, center=false);
    }
  }
}

module base(width, thickness, height, hole_width, hole_height){
  difference(){
    cube([width, thickness, height]);
    translate([(width-hole_width)/2, -1, -1]){
      cube([hole_width, thickness + 2, hole_height+1]);
    }
  }
  
}

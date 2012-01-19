// Parametric bracket for robot chasis.
// Nick Pascucci
// December, 2011

bracket();

module bracket(){
  // Bracket customization parameters
  length = 40;            // Length of each arm
  arm_thickness = 3;      // Thickness of the shell
  arm_width = 23;         // Amount of material in each arm
  hole_d1 = .75 * length; // Distance of hole 1 from the adjacent surface
  hole_d2 = .75 * length; // Ditto, for hole 2
  hole_size = 3;        // Size of all of the holes.

  // Precalculated variables.
  cut_depth = length - arm_thickness;
  hole_offset = arm_width + (length - cut_depth);

  difference(){
    base_cube(length, cut_depth);
    cut_arms(length, cut_depth, arm_width);
    holes(hole_d1, hole_d2, hole_offset, hole_size);
  }
}

module base_cube(length, arm_length){
  hole_location = (length - arm_length) + (arm_length/2);

  difference(){
    cube([length, length, length], center=false);
    translate(v=[length-arm_length, length-arm_length, length-arm_length]){
      cube([arm_length+1, arm_length+1, arm_length+1], center=false);
    }
  }

}

module cut_arms(length, arm_length, arm_thickness){
  translate(v=[-(length-arm_length), -(length-arm_length), -(length-arm_length)]);
  translate(v=[-length, arm_thickness, arm_thickness]){
    cube([2 * length, length-arm_thickness + 1, length-arm_thickness + 1,]);
  }
  translate(v=[arm_thickness, -length, arm_thickness]){
    cube([length-arm_thickness + 1, 2 * length, length-arm_thickness + 1,]);
  }
  translate(v=[arm_thickness, arm_thickness, -length]){
    cube([length-arm_thickness + 1, length-arm_thickness + 1, 2 * length]);
  }
}

module holes(d1, d2, offset, hole_size){
  hole_pair(d1, d2, offset, hole_size);
  rotate([90, 0, 90]) hole_pair(d1, d2, offset, hole_size);
  rotate([-90, -90, 0]) hole_pair(d1, d2, offset, hole_size);
}

module hole_pair(d1, d2, offset, hole_size){
  translate([d1, offset/2, offset/2]){
    rotate([90, 0, 0]){
      cylinder(h=offset, r=hole_size, center=false);
    }
  }
  translate([d2, offset/2, -offset/2]){
    rotate([0, 0, 0]){
      cylinder(h=offset, r=hole_size, center=false);
    }
  }
}

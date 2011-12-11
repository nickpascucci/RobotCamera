// Mounting bracket for camera
// Nick Pascucci
// December, 2011

camera_mount();

module camera_mount(){
  slot_width = 33; // Width of the top of the T slot
  slot_base = 28; // Width of the base of the slot
  slot_thickness = 6; // Height of the slot's two portions in the X
  bracket_depth = 20; // Depth of the bracket slot
  bracket_height = 33; // Height of the entire bracket
  bracket_width = 43; // Width of the bracket in the Y
  bracket_thickness = 5; // Thickness of the bracket interface
  hole_size = 3; // Size of the screw holes
  hole_separation = 20; // Separation of the two holes
  bracket_length = (2 * slot_thickness + bracket_thickness + bracket_depth);

  difference(){
    cube([bracket_length, bracket_width, bracket_height]);
    translate([0, (bracket_width - slot_base)/2, 0]){
      t_slot(slot_base, slot_width, slot_thickness, bracket_height);
    }
    translate([2 * slot_thickness + bracket_thickness, 0, bracket_thickness]){
      cube([bracket_depth, bracket_width, (bracket_height - bracket_thickness)]);
    }
    translate([bracket_length - (bracket_depth / 2), bracket_width / 2, bracket_thickness]){
      holes(hole_size, hole_separation, bracket_thickness);
    }
  }
}

module t_slot(slot_base, slot_width, slot_thickness, bracket_height){
  cube([slot_thickness, slot_base, bracket_height]);
  translate([slot_thickness, -(slot_width - slot_base)/2, 0]){
    cube([slot_thickness, slot_width, bracket_height]);
  }
}

module holes(hole_size, hole_separation, bracket_thickness){
  translate([0, hole_separation/2, -bracket_thickness]){
    cylinder(h = bracket_thickness, r = hole_size);
  }
  translate([0, -hole_separation/2, -bracket_thickness]){
    cylinder(h = bracket_thickness, r = hole_size);
  }
}

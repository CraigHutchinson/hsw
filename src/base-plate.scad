// Original file:
// https://www.printables.com/model/380870-customizable-honeycomb-storage-wall-openscad

/* [Hidden] */
eMode_RowColumnCount = "Row/Column Count";
eMode_MaxDimensions = "Max Dimensions";

/* [ Plate Size ] */
// Select size calculation mode
Mode = "Max Dimensions"; // [Row/Column Count, Max Dimensions]
Rows = 10; // [ 1 : 100 ]
Columns = 10; // [ 1 : 100 ]

// Max plate width in millimeters. Only used when in "Max Dimensions" mode.
Max_Plate_Width = 256;

// Max plate height in millimeters. Only used when in "Max Dimensions" mode.
Max_Plate_Height = 256;

/* [ Stack Printing ] */
// Number of plates to be generated for stack printing
Plate_Count = 3;

/* [ Flat edges ] */
Left = false;
Top = false;
Right = false;
Bottom = false;

/* [Hidden] */

// Depth of the grid
depth = 8;
// Height of the hexagon's hole (flat side to flat side)
inner_short_diagonal = 20;
// Thickness of the wall forming each hexagon
wall_thickness = 1.8;
// Gap so the plates don't bind to one another
stack_printing_gap = 0.2;
//

// Edges
edge_left = Left;
edge_top = Top;
edge_right = Right;
edge_bottom = Bottom;


// Calculated global variables
outer_short_diagonal = inner_short_diagonal + wall_thickness * 2;
outer_radius = outer_short_diagonal / sqrt(3);
outer_diameter = 2 * outer_radius;
half_outer_apothem = outer_radius / 2;

// Grid dimensions
max_grid_hexagons_x = (Mode == eMode_RowColumnCount) ? Columns : floor(1 + (Max_Plate_Width-outer_diameter) / (outer_diameter - half_outer_apothem) + (edge_left ? 0.5 : 0) + (edge_right ? 0.5 : 0));
assert( max_grid_hexagons_x >= 1, "Grid Column  (x-axis) count is < 1. Increase plate size limits.");
max_grid_hexagons_y = (Mode == eMode_RowColumnCount) ? Rows : floor((Max_Plate_Height - outer_short_diagonal * ((max_grid_hexagons_x > 1 ? 0.5 : 0) - (edge_top ? 0.5 : 0) - (edge_bottom ? 0.5 : 0))) / outer_short_diagonal );
assert( max_grid_hexagons_y >= 1, "Grid Row (y-axis) count is < 1. Increase plate size limits.");

// Calculate total plate dimensions
total_width = (max_grid_hexagons_x * outer_diameter) - ((max_grid_hexagons_x-1) * half_outer_apothem) - (((edge_left ? 0.5 : 0) + (edge_right ? 0.5 : 0)) * outer_diameter);
total_height = (max_grid_hexagons_y + (max_grid_hexagons_x>1 ? 0.5: 0 )) * outer_short_diagonal - (((edge_top ? 0.5 : 0) + (edge_bottom ? 0.5 : 0)) * outer_short_diagonal);

if (Mode == eMode_MaxDimensions)
{
    assert( total_height < Max_Plate_Height, str("The total grid height of ", total_height, " exceeds maximum of ", Max_Plate_Height) );
    assert( total_width < Max_Plate_Width, str("The total grid width of ", total_width, " exceeds maximum of ", Max_Plate_Width) );
}

// Enable to preview the print and used area limits
if ( $preview )
{
    translate([0,-total_height,-0.5]) color("red") cube([total_width, total_height, 1]);
    translate([0,-Max_Plate_Height,-0.6]) color("green") cube([Max_Plate_Width, Max_Plate_Height, 1]);
}

module wall(height, wall_thickness, length, endBevel = false) {
  wall_height = height;
  back_fillet_start = wall_height - 5.1;
  back_fillet_end = 2;
  wall_bottom_thickness = wall_thickness;
  wall_top_thickness = wall_thickness - 1;
  front_fillet_size = 0.5;

  rotate([90, 0, 0])
    difference()
    {
    linear_extrude(length)
      polygon([
        [0, 0], 
        [0, wall_height], 
        [wall_bottom_thickness - front_fillet_size, wall_height], 
        [wall_bottom_thickness, wall_height - front_fillet_size], 
        [wall_bottom_thickness, back_fillet_start], 
        [wall_top_thickness, back_fillet_end], 
        [wall_top_thickness, 0]
      ]);
        if ( endBevel == true)
        {
            translate([0,-0.01,0])
            color("blue")
            rotate([0,60,0]) cube([5,wall_height+0.02,5]);
            color("blue")
            translate([0,-0.01,length]) rotate([0,30,0]) cube([5,wall_height+0.02,5]);
        }
    };
}

module hex(height, radius, wall_thickness, inner_short_diagonal) {
  for(i = [0:5]) {
    rotate([0, 0, i * 60 + 30])
      translate([-inner_short_diagonal / 2 - wall_thickness, radius / 2, 0])
        wall(height, wall_thickness, radius);
  }
}

module cell(height, radius, wall_thickness, inner_short_diagonal, left, top, right, bottom) {
  difference() {
    union() {
      hex(height, radius, wall_thickness, inner_short_diagonal);
      if (left)
        translate([0, outer_short_diagonal / 2, 0])
          wall(depth, wall_thickness, outer_short_diagonal);
      if (top)
        translate([outer_diameter / 2, 0, 0]) rotate([0, 0, -90]) wall(depth, wall_thickness, outer_diameter, true);
      if (right)
        translate([0, -outer_short_diagonal / 2, 0])
          rotate([0, 0, 180])
            wall(depth, wall_thickness, outer_short_diagonal);
      if (bottom)
        translate([-outer_diameter / 2, 0, 0])
          rotate([0, 0, 90])
            wall(depth, wall_thickness, outer_diameter);
    }
    if (left)
      translate([-outer_diameter / 2, -outer_short_diagonal, -0.01])
        cube([outer_diameter / 2, 2 * outer_short_diagonal, depth+0.02]);
    if (top)
      translate([-outer_diameter / 2, 0, -0.01]) cube([outer_diameter, outer_short_diagonal, depth+0.02]);
    if (right)
      translate([0, -outer_short_diagonal, -0.01])
        cube([outer_diameter / 2, 2 * outer_short_diagonal, depth+0.02]);
    if (bottom)
      translate([-outer_diameter / 2, -outer_short_diagonal, -0.01])
        cube([outer_diameter, outer_short_diagonal, depth+0.02]);
  }
}


module plate(height, inner_short_diagonal, wall_width) {
  for(col = [0:(max_grid_hexagons_x - 1)]) {
    for(row = [0:(max_grid_hexagons_y - 1)]) {
      x = (outer_diameter - half_outer_apothem) * col;
      y = -(outer_short_diagonal) * (row + (col % 2) / 2) + (edge_top ? outer_short_diagonal / 2 : 0);

      left = edge_left && col == 0;
      top = edge_top && row == 0 && col % 2 == 0;
      right = edge_right && col == max_grid_hexagons_x - 1;
      bottom = edge_bottom && (row + 1) == max_grid_hexagons_y && (outer_short_diagonal - y) > total_height + 0.01 && (outer_short_diagonal - y) / 2 <= total_height;

      translate([x, y, 0])
        cell(height, outer_radius, wall_width, inner_short_diagonal, left, top, right, bottom);
    }
  }
}

translate([edge_left ? 0 : outer_radius, -outer_short_diagonal / 2, 0])
  for(i = [0:max(Plate_Count - 1, 0)]) {
    translate([0, 0, i * (depth + stack_printing_gap)])       plate(depth, inner_short_diagonal, wall_thickness);
  }

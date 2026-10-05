// id1kb bottom tray case
// The tray shares the PCB's outline: its walls run under the PCB edge and the
// PCB rests on them, held by friction on the pins.
// Coordinates follow the top view (switch side up, "Designed by" text on the right),
// which matches KiCad's front view: origin at the PCB's top-left corner
// (USB/TRRS edge), y' grows downward.

/* [View] */
show_pcb = false;

/* [Board fit] */
// Clearance under the PCB for the Pro Micro, TRRS jack and reset switch.
under = 6.0;
pin_d = 4.95;
// How far the pin tip rises above the PCB's top surface.
pin_extra = 0.8;

/* [Openings] */
// The Pro Micro overhangs the top edge by ~2 mm, so the whole module needs room.
promicro_w = 20;
trrs_w = 9;
reset_w = 7;
reset_depth = 4.5;

/* [Case] */
floor_style = "full"; // [full, truss]
floor_t = 1.2;
wall = 1.2;
post_d = 6.5;

/* [Truss floor] */
truss_w = 5;
// Square pad inside each frame corner, room for a rubber foot.
foot_pad = 10;
// Radius of the pad's corner that faces the middle.
foot_r = 5;

/* [Hidden] */
$fn = 64;

pcb_w = 85.6;
pcb_h = 53.98;
pcb_r = 3.81;
pcb_t = 1.6;

holes = [[5.08, 5.08], [81.28, 5.08], [5.08, 49.53], [81.28, 49.53]];
promicro_x = 49.53;
trrs_x = 66.0;
reset_x = 15.28;
switches = [for (x = [11.43, 30.48, 49.53, 68.58], y = [21.59, 40.64]) [x, y]];

function pos(p) = [p[0], pcb_h - p[1]];

z_pcb = floor_t + under;

module outline(off) {
    translate([pcb_r, pcb_r])
        offset(r = pcb_r + off) square([pcb_w - 2 * pcb_r, pcb_h - 2 * pcb_r]);
}

// Measured from the PCB's corner, so it also covers the frame under the pad.
module foot_pad() {
    t = truss_w + foot_pad;
    square([t, t - foot_r]);
    square([t - foot_r, t]);
    translate([t - foot_r, t - foot_r]) circle(r = foot_r);
}

module floor_2d() {
    if (floor_style == "full") outline(0);
    else intersection() {
        outline(0);
        union() {
            difference() { outline(0); outline(-truss_w); }
            for (d = [[[0, 0], [pcb_w, pcb_h]], [[0, pcb_h], [pcb_w, 0]]])
                hull() for (p = d) translate(p) circle(d = truss_w);
            for (mx = [0, 1], my = [0, 1])
                translate([mx * pcb_w, my * pcb_h]) mirror([mx, 0]) mirror([0, my]) foot_pad();
        }
    }
}

module shell() {
    difference() {
        linear_extrude(z_pcb) outline(0);
        translate([0, 0, -1]) linear_extrude(z_pcb + 2) outline(-wall);
    }
    linear_extrude(floor_t) floor_2d();
}

// Starts slightly below its base so it fuses with the post instead of just touching it.
module pin(d) {
    hull() {
        translate([0, 0, -0.1]) cylinder(d = d, h = pcb_t + pin_extra - 0.4);
        cylinder(d = d - 1, h = pcb_t + pin_extra);
    }
}

// Bridged to the two nearest walls so no thin gap is left beside them.
module post_2d(h) {
    c = [h[0] < pcb_w / 2 ? 0 : pcb_w, h[1] < pcb_h / 2 ? 0 : pcb_h];
    intersection() {
        outline(0);
        for (e = [[c[0], h[1]], [h[0], c[1]]])
            hull() for (p = [h, e]) translate(pos(p)) circle(d = post_d);
    }
}

module posts() {
    for (h = holes) {
        linear_extrude(z_pcb) post_2d(h);
        translate(pos(h)) translate([0, 0, z_pcb]) pin(pin_d);
    }
}

module notch(x, w, z0) {
    translate([x - w / 2, pcb_h - wall - 1, z0]) cube([w, wall + 2, z_pcb]);
}

module case() {
    difference() {
        shell();
        // One opening for both: separate notches would leave a fragile ~2 mm strip between them.
        let (l = promicro_x - promicro_w / 2, r = trrs_x + trrs_w / 2)
            notch((l + r) / 2, r - l, floor_t);
        notch(reset_x, reset_w, z_pcb - reset_depth);
    }
    posts();
}

module pcb_ghost() {
    translate([0, 0, z_pcb]) difference() {
        linear_extrude(pcb_t) outline(0);
        for (h = holes) translate(pos(h)) translate([0, 0, -1]) cylinder(d = 4.8, h = pcb_t + 2);
    }
    for (s = switches) translate(pos(s)) translate([-7, -7, z_pcb + pcb_t]) cube([14, 14, 11]);
    translate([promicro_x - 9, pcb_h - 33 + 2, z_pcb - 5]) cube([18, 33, 5]);
    translate([trrs_x - 3, pcb_h - 12, z_pcb - 5]) cube([6, 12, 5]);
    translate([reset_x - 3.75, pcb_h - 8.7, z_pcb - 3.5]) cube([7.5, 7.5, 3.5]);
}

case();
if (show_pcb) %pcb_ghost();

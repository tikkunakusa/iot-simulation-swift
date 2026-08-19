/*
 ==============================================================================
 IoT Enclosure 3D CAD Master (Revisi Posisi Port Modem & Lubang Antena FPC)
 Project: Custom Enclosure for IoT Simulation
 
 REVISI POSISI SESUAI GAMBAR USER:
 1. Port Daya Modem 4G (Gambar 1):
    - Dipindahkan ke bagian bawah sudut depan (sesuai lingkaran biru muda di Gambar 1)
    - Sejajar presisi dengan colokan Micro-USB pada board modem di rak bawah
 2. Lubang Kabel Antena FPC 4G (Gambar 2):
    - Dipindahkan dari tengah ke sisi pinggir ujung ceruk (sesuai kotak pink di Gambar 2)
    - Memudahkan kabel koaksial antena masuk ke dalam bodi tanpa melipat stiker
 ==============================================================================
*/

$fn = 40; // Resolusi kurva silinder

part_to_render = "simulation_all";


// ==========================================
// 1. PARAMETER CASING UTAMA (11cm x 8cm x 8cm)
// ==========================================
main_total_w = 110.0; // Total Lebar 11.0 cm
main_total_l = 80.0;  // Total Panjang 8.0 cm
main_total_h = 80.0;  // Total Tinggi 8.0 cm

wall_t       = 2.4;
floor_t      = 2.4;
corner_r     = 4.5;

main_w       = main_total_w - 2 * wall_t; // 105.2 mm internal
main_l       = main_total_l - 2 * wall_t; // 75.2 mm internal
main_h       = main_total_h - floor_t;    // 77.6 mm internal

// Dimensi Standar PCB 4x6 cm (40 x 60 mm)
pcb_w        = 40.0;
pcb_l        = 60.0;
pcb_hole_x   = 36.0;
pcb_hole_y   = 56.0;
standoff_h   = 6.0;
standoff_od  = 6.5;
standoff_id  = 2.4; // Lubang baut M2.5

corner_post_od = 8.5;
corner_screw_d = 3.2; // Baut M3 pengunci bodi

gps_ant_w    = 25.8; // Antena GPS Keramik 25x25mm
gps_ant_l    = 25.8;
gps_rim_h    = 6.5;

fpc_w        = 18.0;
fpc_l        = 46.0;
fpc_recess   = 1.0;


// ==========================================
// 2. PARAMETER CASING DHT22 (4cm x 8cm x 6cm)
// ==========================================
dht_total_w  = 40.0; // Total Lebar 4 cm
dht_total_l  = 80.0; // Total Panjang 8 cm
dht_total_h  = 60.0; // Total Tinggi 6 cm

dht_wall     = 2.0;
dht_floor    = 2.0;
dht_r        = 3.5;

dht_w        = dht_total_w - 2 * dht_wall; // 36.0 mm internal
dht_l        = dht_total_l - 2 * dht_wall; // 76.0 mm internal
dht_h        = dht_total_h - dht_floor;    // 58.0 mm internal

dht_pcb_w    = 24.0; // PCB terpotong 8 pin
dht_pcb_l    = 48.0;

c_case = [0.15, 0.15, 0.16]; // Hitam Matte


// ==========================================
// MODUL GEOMETRI PEMBANTU
// ==========================================

module rounded_cube(w, l, h, r) {
    translate([r, r, 0])
    hull() {
        cylinder(r=r, h=h);
        translate([w - 2*r, 0, 0]) cylinder(r=r, h=h);
        translate([0, l - 2*r, 0]) cylinder(r=r, h=h);
        translate([w - 2*r, l - 2*r, 0]) cylinder(r=r, h=h);
    }
}

module standoff_post(x, y, z, od, id, h) {
    translate([x, y, z]) {
        difference() {
            cylinder(d=od, h=h);
            translate([0, 0, -0.5]) cylinder(d=id, h=h + 1.0);
        }
    }
}

module pcb_4x6_mount_anti_vibration(base_x, base_y) {
    off_x = (pcb_w - pcb_hole_x) / 2;
    off_y = (pcb_l - pcb_hole_y) / 2;
    
    // 4x Pilar Baut Pengunci PCB Dasar (M2.5)
    standoff_post(base_x + off_x, base_y + off_y, floor_t, standoff_od, standoff_id, standoff_h);
    standoff_post(base_x + off_x + pcb_hole_x, base_y + off_y, floor_t, standoff_od, standoff_id, standoff_h);
    standoff_post(base_x + off_x, base_y + off_y + pcb_hole_y, floor_t, standoff_od, standoff_id, standoff_h);
    standoff_post(base_x + off_x + pcb_hole_x, base_y + off_y + pcb_hole_y, floor_t, standoff_od, standoff_id, standoff_h);
    
    // Rel Pemandu Siku Anti-Guncangan
    guide_h = standoff_h + 3.5;
    translate([base_x - 1.2, base_y - 1.2, floor_t]) cube([4.0, 1.2, guide_h]);
    translate([base_x - 1.2, base_y - 1.2, floor_t]) cube([1.2, 4.0, guide_h]);
    translate([base_x + pcb_w - 2.8, base_y - 1.2, floor_t]) cube([4.0, 1.2, guide_h]);
    translate([base_x + pcb_w, base_y - 1.2, floor_t]) cube([1.2, 4.0, guide_h]);
    translate([base_x - 1.2, base_y + pcb_l, floor_t]) cube([4.0, 1.2, guide_h]);
    translate([base_x - 1.2, base_y + pcb_l - 2.8, floor_t]) cube([1.2, 4.0, guide_h]);
    translate([base_x + pcb_w - 2.8, base_y + pcb_l, floor_t]) cube([4.0, 1.2, guide_h]);
    translate([base_x + pcb_w, base_y + pcb_l - 2.8, floor_t]) cube([1.2, 4.0, guide_h]);
}

module vent_slots(w, h, slit_w, spacing, depth) {
    num_slits = floor((w - spacing) / (slit_w + spacing));
    start_x = (w - (num_slits * slit_w + (num_slits - 1) * spacing)) / 2;
    for (i = [0 : num_slits - 1]) {
        translate([start_x + i * (slit_w + spacing), 0, 0])
            cube([slit_w, depth, h]);
    }
}


// ==========================================
// 1. CASING UTAMA - BAGIAN BAWAH (MAIN BASE 11x8x8cm)
// ==========================================
module main_case_base() {
    esp_x = main_total_w - wall_t - pcb_w - 6.0;
    esp_y = wall_t + 7.5;
    
    modem_x = wall_t + 6.0;
    modem_y = wall_t + 7.5;
    
    // Posisi Ceruk Antena FPC di Dinding Kiri Luar
    fpc_y0 = wall_t + 16.0;
    fpc_z0 = floor_t + 24.0;

    difference() {
        union() {
            difference() {
                rounded_cube(main_total_w, main_total_l, main_total_h, corner_r);
                translate([wall_t, wall_t, floor_t])
                    rounded_cube(main_w, main_l, main_h + 1, max(1, corner_r - wall_t));
            }
            
            // 4x Pilar Baut Sudut M3 (Tinggi 80mm penuh)
            c_offset = corner_post_od / 2 + 0.8;
            standoff_post(wall_t + c_offset, wall_t + c_offset, floor_t, corner_post_od, corner_screw_d, main_h);
            standoff_post(main_total_w - wall_t - c_offset, wall_t + c_offset, floor_t, corner_post_od, corner_screw_d, main_h);
            standoff_post(wall_t + c_offset, main_total_l - wall_t - c_offset, floor_t, corner_post_od, corner_screw_d, main_h);
            standoff_post(main_total_w - wall_t - c_offset, main_total_l - wall_t - c_offset, floor_t, corner_post_od, corner_screw_d, main_h);
            
            // Dudukan PCB 1: ESP32-C6 Double Stack (Kanan) dengan Rel Anti-Guncang
            pcb_4x6_mount_anti_vibration(esp_x, esp_y);
            
            // Dudukan PCB 2: Modem 4G SimCom A7670C (Kiri) dengan Rel Anti-Guncang
            pcb_4x6_mount_anti_vibration(modem_x, modem_y);
        }
        
        // Port 1: USB-C ESP32-C6 di Dinding Kanan Atas
        translate([main_total_w - wall_t - 1, esp_y + 16.0, floor_t + 28.0])
            cube([wall_t + 2, 14.5, 9.0]);
            
        // REVISI GAMBAR 1: Port Micro-USB Modem 4G dipindahkan ke posisi biru muda (sudut depan-bawah)
        translate([-1, modem_y + 6.0, floor_t + 4.5])
            cube([wall_t + 2, 14.5, 9.0]);
            
        // Ceruk Tempel Stiker Antena FPC 4G di Dinding Kiri Luar
        translate([-0.1, fpc_y0, fpc_z0])
            cube([fpc_recess + 0.1, fpc_l, fpc_w]);
            
        // REVISI GAMBAR 2: Lubang Masuk Kabel Antena FPC dipindahkan ke sisi kanan/ujung ceruk (kotak pink)
        translate([-1, fpc_y0 + fpc_l - 6.5, fpc_z0 + 3.0])
            cube([wall_t + 2, 6.0, 12.0]);
            
        // Lubang Port Kabel Sensor Keluar Menuju Casing DHT22 (Dinding Belakang)
        translate([main_total_w / 2 - 5.0, main_total_l - wall_t - 1, floor_t + 10.0])
            cube([10.0, wall_t + 2, 7.0]);
            
        // Ventilasi Depan (Bawah & Atas)
        translate([wall_t + 16.0, -1, floor_t + 10.0])
            vent_slots(main_w - 32.0, 20.0, 2.5, 3.5, wall_t + 2);
        translate([wall_t + 16.0, -1, floor_t + 45.0])
            vent_slots(main_w - 32.0, 20.0, 2.5, 3.5, wall_t + 2);
            
        // Ventilasi Belakang Atas
        translate([wall_t + 16.0, main_total_l - wall_t - 1, floor_t + 35.0])
            vent_slots(main_w - 32.0, 25.0, 2.5, 3.5, wall_t + 2);
    }
}


// ==========================================
// 2. CASING UTAMA - TUTUP ATAS (MAIN LID 11x8cm FLAT)
// ==========================================
module main_case_lid() {
    lip_h   = 4.5;
    lip_t   = 1.5;
    clearance = 0.35;
    
    gps_x = wall_t + 12.0;
    gps_y = main_total_l - wall_t - gps_ant_l - 8.0;

    difference() {
        union() {
            rounded_cube(main_total_w, main_total_l, floor_t, corner_r);
            
            // Bibir Snap Pengunci Dalam (4.5mm)
            translate([wall_t + clearance, wall_t + clearance, -lip_h])
                difference() {
                    rounded_cube(main_w - 2*clearance, main_l - 2*clearance, lip_h, max(0.5, corner_r - wall_t));
                    translate([lip_t, lip_t, -0.5])
                        rounded_cube(main_w - 2*clearance - 2*lip_t, main_l - 2*clearance - 2*lip_t, lip_h + 1, max(0.2, corner_r - wall_t - lip_t));
                }
                
            // Saku Dudukan Antena GPS Keramik (25.8 x 25.8 mm)
            translate([gps_x - 1.8, gps_y - 1.8, floor_t]) {
                difference() {
                    cube([gps_ant_w + 3.6, gps_ant_l + 3.6, gps_rim_h]);
                    translate([1.8, 1.8, -0.5])
                        cube([gps_ant_w, gps_ant_l, gps_rim_h + 1.0]);
                }
            }
        }
        
        // 4x Lubang Baut Countersunk M3
        c_offset = corner_post_od / 2 + 0.8;
        for (pos = [
            [wall_t + c_offset, wall_t + c_offset],
            [main_total_w - wall_t - c_offset, wall_t + c_offset],
            [wall_t + c_offset, main_total_l - wall_t - c_offset],
            [main_total_w - wall_t - c_offset, main_total_l - wall_t - c_offset]
        ]) {
            translate([pos[0], pos[1], -lip_h - 1]) {
                cylinder(d=corner_screw_d + 0.4, h=floor_t + lip_h + 2);
                translate([0, 0, lip_h + floor_t - 1.2]) 
                    cylinder(d1=corner_screw_d + 0.4, d2=6.5, h=2.5);
            }
        }
        
        // Lubang Kabel Antena GPS Masuk ke Dalam
        translate([gps_x + gps_ant_w/2 - 3.5, gps_y - 4.0, -lip_h - 1])
            cube([7.0, 6.0, floor_t + lip_h + 2]);
            
        // Lubang LED Indikator Traffic Light
        led_x = wall_t + 25.0;
        led_y = wall_t + 15.0;
        for (i = [0 : 2]) {
            translate([led_x + i * 11.0, led_y, -lip_h - 1])
                cylinder(d=3.8, h=floor_t + lip_h + 2);
        }
    }
}


// ==========================================
// 3. CASING KHUSUS SENSOR DHT22 - KOTAK BAWAH (4x8x6cm)
// ==========================================
module dht22_case_base() {
    difference() {
        union() {
            difference() {
                rounded_cube(dht_total_w, dht_total_l, dht_total_h, dht_r);
                translate([dht_wall, dht_wall, dht_floor])
                    rounded_cube(dht_w, dht_l, dht_h + 1, max(1, dht_r - dht_wall));
            }
            
            // 4x Pilar Baut Pengunci Casing DHT22 (M2.5/M3)
            p_post = 6.5;
            standoff_post(dht_wall + 3.2, dht_wall + 3.2, dht_floor, p_post, 2.2, dht_h);
            standoff_post(dht_total_w - dht_wall - 3.2, dht_wall + 3.2, dht_floor, p_post, 2.2, dht_h);
            standoff_post(dht_wall + 3.2, dht_total_l - dht_wall - 3.2, dht_floor, p_post, 2.2, dht_h);
            standoff_post(dht_total_w - dht_wall - 3.2, dht_total_l - dht_wall - 3.2, dht_floor, p_post, 2.2, dht_h);
            
            // 4x Standoff Baut Pengunci PCB DHT22 yang Sudah Dipotong (~24x48mm)
            pcb_cx = dht_total_w / 2;
            pcb_cy = dht_wall + 16.0;
            standoff_post(pcb_cx - 9.0, pcb_cy, dht_floor, 4.8, 1.8, 4.0);
            standoff_post(pcb_cx + 9.0, pcb_cy, dht_floor, 4.8, 1.8, 4.0);
            standoff_post(pcb_cx - 9.0, pcb_cy + 38.0, dht_floor, 4.8, 1.8, 4.0);
            standoff_post(pcb_cx + 9.0, pcb_cy + 38.0, dht_floor, 4.8, 1.8, 4.0);
            
            // KANDANG PENJEPIT ANTI-GUNCANG BODI SENSOR DHT22 (Snug Clamp Cage)
            sensor_cy = pcb_cy + 22.0;
            translate([pcb_cx - 9.5, sensor_cy - 7.5, dht_floor + 4.0]) {
                difference() {
                    cube([19.0, 15.0, 30.0]);
                    translate([1.5, 1.5, -0.5])
                        cube([16.0, 12.0, 31.0]);
                    translate([-1.0, 2.5, 4.0]) cube([21.0, 10.0, 22.0]);
                }
            }
            
            // Telinga Baut Gantungan Dinding (Mounting Ears)
            translate([-6.5, dht_total_l/2 - 6.5, 0]) {
                difference() {
                    rounded_cube(dht_total_w + 13.0, 13.0, dht_floor, 2.5);
                    translate([3.2, 6.5, -0.5]) cylinder(d=3.2, h=dht_floor + 1.0);
                    translate([dht_total_w + 9.8, 6.5, -0.5]) cylinder(d=3.2, h=dht_floor + 1.0);
                }
            }
        }
        
        // Lubang Kabel Masuk + Klem Pengaman (Strain Relief)
        translate([dht_total_w/2 - 3.5, -1, dht_floor + 4.0])
            cube([7.0, dht_wall + 2, 5.0]);
            
        // Kisi-kisi Ventilasi 360 Derajat
        for (zi = [dht_floor + 8.0 : 4.5 : dht_total_h - 8.0]) {
            translate([-1, dht_wall + 8.0, zi]) cube([dht_wall + 2, dht_l - 16.0, 2.2]);
            translate([dht_total_w - dht_wall - 1, dht_wall + 8.0, zi]) cube([dht_wall + 2, dht_l - 16.0, 2.2]);
            translate([dht_wall + 6.0, dht_total_l - dht_wall - 1, zi]) cube([dht_w - 12.0, dht_wall + 2, 2.2]);
        }
    }
}


// ==========================================
// 4. CASING KHUSUS SENSOR DHT22 - TUTUP ATAS (4x8cm)
// ==========================================
module dht22_case_lid() {
    lip_h = 3.5;
    lip_t = 1.2;
    c = 0.3;
    
    difference() {
        union() {
            rounded_cube(dht_total_w, dht_total_l, dht_floor, dht_r);
            
            // Bibir Snap Pengunci
            translate([dht_wall + c, dht_wall + c, -lip_h])
                difference() {
                    rounded_cube(dht_w - 2*c, dht_l - 2*c, lip_h, max(0.5, dht_r - dht_wall));
                    translate([lip_t, lip_t, -0.5])
                        rounded_cube(dht_w - 2*c - 2*lip_t, dht_l - 2*c - 2*lip_t, lip_h + 1, max(0.2, dht_r - dht_wall - lip_t));
                }
                
            // Rib Penekan Bahu Atas Sensor DHT22
            pcb_cx = dht_total_w / 2;
            pcb_cy = dht_wall + 16.0;
            sensor_cy = pcb_cy + 22.0;
            translate([pcb_cx - 7.5, sensor_cy - 5.5, -lip_h - 2.0])
                cube([15.0, 11.0, 2.0]);
        }
        
        // 4x Lubang Baut Pengunci
        for (pos = [
            [dht_wall + 3.2, dht_wall + 3.2],
            [dht_total_w - dht_wall - 3.2, dht_wall + 3.2],
            [dht_wall + 3.2, dht_total_l - dht_wall - 3.2],
            [dht_total_w - dht_wall - 3.2, dht_total_l - dht_wall - 3.2]
        ]) {
            translate([pos[0], pos[1], -lip_h - 3]) {
                cylinder(d=2.6, h=dht_floor + lip_h + 5);
                translate([0, 0, lip_h + dht_floor - 1.0]) cylinder(d1=2.6, d2=5.0, h=2.0);
            }
        }
        
        // Kisi-kisi Ventilasi Atas
        translate([dht_wall + 6.0, dht_wall + 12.0, -lip_h - 3])
            vent_slots(dht_w - 12.0, dht_l - 24.0, 2.2, 3.0, dht_floor + lip_h + 5);
    }
}


// ==========================================
// 5. SIMULASI ELEKTRONIKA
// ==========================================

module sim_double_deck_esp32_stack() {
    color([0.1, 0.55, 0.25]) cube([pcb_w, pcb_l, 1.6]);
    color([0.85, 0.65, 0.15]) {
        for (pos = [[2,2], [38,2], [2,58], [38,58]]) {
            translate([pos[0], pos[1], 1.6]) cylinder(d=5.0, h=26.0);
        }
    }
    translate([0, 0, 27.6]) {
        color([0.1, 0.55, 0.25]) cube([pcb_w, pcb_l, 1.6]);
        color([0.12, 0.12, 0.12]) {
            translate([7.0, 5.0, 1.6]) cube([2.54, 50.0, 8.5]);
            translate([30.5, 5.0, 1.6]) cube([2.54, 50.0, 8.5]);
        }
        translate([7.0, 3.0, 10.1]) {
            color([0.15, 0.15, 0.15]) cube([26.0, 54.0, 1.6]);
            color([0.8, 0.8, 0.82]) translate([3.5, 18.0, 1.6]) cube([18.0, 24.0, 3.2]);
            color([0.7, 0.7, 0.75]) translate([8.0, -4.0, 0.0]) cube([9.0, 8.0, 3.5]);
        }
    }
}

module sim_a7670c_board() {
    color([0.1, 0.55, 0.25]) cube([pcb_w, pcb_l, 1.6]);
    color([0.12, 0.12, 0.12]) {
        translate([5.0, 8.0, 1.6]) cube([2.54, 44.0, 8.5]);
        translate([32.5, 8.0, 1.6]) cube([2.54, 44.0, 8.5]);
    }
    translate([5.0, 6.0, 10.1]) {
        color([0.1, 0.5, 0.3]) cube([30.0, 46.0, 1.6]);
        color([0.85, 0.85, 0.9]) translate([3.0, 6.0, 1.6]) cube([24.0, 32.0, 3.0]);
        color([0.75, 0.75, 0.78]) translate([11.0, -4.0, 0.0]) cube([8.0, 6.0, 3.0]);
        color([0.85, 0.65, 0.15]) translate([22.0, 40.0, 1.6]) cylinder(d=3.0, h=1.8);
    }
}

module sim_dht22_cut_pcb() {
    color([0.1, 0.55, 0.25]) cube([dht_pcb_w, dht_pcb_l, 1.6]);
    color([0.12, 0.12, 0.12]) translate([7.0, 18.0, 1.6]) cube([10.0, 3.0, 8.5]);
    translate([4.0, 13.0, 10.1]) {
        color([0.96, 0.96, 0.96]) {
            difference() {
                cube([16.0, 12.0, 25.0]);
                for (gz = [6 : 3 : 21]) {
                    translate([2.0, -0.5, gz]) cube([12.0, 1.5, 1.5]);
                }
            }
        }
    }
}

module sim_dual_typec_powerbank() {
    color([0.22, 0.22, 0.25]) rounded_cube(65.0, 130.0, 16.0, 4.0);
    color([0.1, 0.1, 0.1]) {
        translate([18.0, 128.0, 5.0]) cube([9.0, 3.0, 4.5]);
        translate([38.0, 128.0, 5.0]) cube([9.0, 3.0, 4.5]);
    }
}

module sim_fpc_sticker_antenna() {
    color([0.08, 0.08, 0.08]) cube([0.5, fpc_l, fpc_w]);
}

module sim_gps_antenna() {
    color([0.82, 0.76, 0.65]) cube([25.0, 25.0, 7.0]);
    color([0.9, 0.9, 0.9]) translate([12.5, 12.5, 7.0]) cylinder(d=4.0, h=0.4);
    color([0.7, 0.7, 0.7]) translate([-1.0, -1.0, -1.5]) cube([27.0, 27.0, 1.5]);
}


// ==========================================
// RENDER SELECTION LOGIC
// ==========================================

if (part_to_render == "simulation_all") {
    // 1. Casing Utama (Lebar 11cm, Panjang 8cm, Tinggi 8cm)
    color(c_case) main_case_base();
    translate([main_total_w - wall_t - pcb_w - 6.0, wall_t + 7.5, floor_t + standoff_h])
        sim_double_deck_esp32_stack();
    translate([wall_t + 6.0, wall_t + 7.5, floor_t + standoff_h])
        sim_a7670c_board();
    translate([-0.5, wall_t + 16.0, floor_t + 24.0])
        sim_fpc_sticker_antenna();
    translate([wall_t + 12.0, main_total_l - wall_t - gps_ant_l - 8.0, main_total_h + 2.4])
        sim_gps_antenna();
        
    translate([0, 0, 50.0]) {
        color(c_case) main_case_lid();
    }
    
    // Powerbank
    translate([-110.0, -25.0, 0.0])
        sim_dual_typec_powerbank();
        
    // 2. Casing Khusus Sensor DHT22 Terpisah (4cm x 8cm x 6cm)
    translate([main_total_w + 30.0, 0.0, 0.0]) {
        color(c_case) dht22_case_base();
        translate([dht_total_w/2 - dht_pcb_w/2, dht_wall + 16.0, dht_floor + 4.0])
            sim_dht22_cut_pcb();
        translate([0, 0, 35.0]) {
            color(c_case) dht22_case_lid();
        }
    }
    
    // Kabel Sensor
    color([0.2, 0.4, 0.85]) {
        translate([main_total_w/2, main_total_l, floor_t + 12.0])
            rotate([0, 90, 0]) cylinder(d=4.0, h=main_total_w/2 + 30.0);
    }
}
else if (part_to_render == "main_base") {
    color(c_case) main_case_base();
}
else if (part_to_render == "main_lid") {
    color(c_case) main_case_lid();
}
else if (part_to_render == "dht22_base") {
    color(c_case) dht22_case_base();
}
else if (part_to_render == "dht22_lid") {
    color(c_case) dht22_case_lid();
}
else if (part_to_render == "print_all") {
    main_case_base();
    translate([main_total_w + 15, 0, 0]) main_case_lid();
    translate([0, main_total_l + 15, 0]) dht22_case_base();
    translate([dht_total_w + 25, main_total_l + 15, 0]) dht22_case_lid();
}

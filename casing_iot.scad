/*
 ==============================================================================
 IoT Enclosure 3D CAD Master (100% Fit-In Lid & Base Mating Interface)
 Project: Custom Enclosure for IoT Simulation
 
 JAMINAN PRESISI FIT-IN TUTUP & CASING BAWAH:
 1. Casing Utama (Main Enclosure 12.5 x 8.5 x 8.0 cm):
    - Bibir snap tutup (Collar) setinggi 4.5 mm dibuat dengan toleransi clearance 0.35 mm 
      (Ukuran Collar: 119.5 x 79.5 mm) sehingga masuk pas ke dalam rongga bodi (120.2 x 80.2 mm).
    - Ke-4 sudut collar diberi saku relief silinder (Diameter 8.8 mm) yang memeluk 4 pilar baut M3 (OD 8.0 mm), 
      sehingga tutup menempel rapat (100% FLUSH) di atas bibir casing tanpa ada tabrakan sudut.
    - 4x lubang baut countersunk M3 di tutup tepat sejajar (koaksial) dengan lubang pilar di bodi.
 
 2. Casing Khusus DHT22 (Pod DHT22 4.0 x 8.0 x 6.0 cm):
    - Bibir snap tutup setinggi 3.5 mm dengan clearance 0.35 mm (Ukuran Collar: 35.3 x 75.3 mm) 
      masuk pas ke rongga bodi (36.0 x 76.0 mm).
    - Ke-4 sudut collar diberi saku relief silinder (Diameter 6.8 mm) untuk memeluk pilar baut bodi (OD 6.0 mm).
    - 4x lubang baut countersunk tepat sejajar dengan pilar bodi.
 
 3. Interior Casing Utama:
    - Memuat 2x PCB Full Standar 4x6 cm (40.0 x 60.0 mm).
    - Celah lorong tengah 2.0 cm & celah keliling 1.0 cm.
    - Casing DHT22 ruang tengah 100% plong untuk PCB potong 24 x 48 mm.
 ==============================================================================
*/

$fn = 40;

part_to_render = "simulation_all";


// ==========================================
// 1. PARAMETER CASING UTAMA (12.5cm x 8.5cm x 8.0cm)
// ==========================================
main_total_w = 125.0; // Lebar Total 12.5 cm
main_total_l = 85.0;  // Panjang Total 8.5 cm
main_total_h = 80.0;  // Tinggi Total 8.0 cm

wall_t       = 2.4;
floor_t      = 2.4;
corner_r     = 4.5;

main_w       = main_total_w - 2 * wall_t; // 120.2 mm internal
main_l       = main_total_l - 2 * wall_t; // 80.2 mm internal
main_h       = main_total_h - floor_t;    // 77.6 mm internal

// Parameter Dimensi PCB Standar Full 4x6 cm (40 x 60 mm)
pcb_w        = 40.0;
pcb_l        = 60.0;
pcb_t        = 1.6;
pcb_clearance = 0.5; // Toleransi pas presisi 0.5 mm

// Parameter Celah Ruang Kabel
gap_side     = 10.0; // Celah 1.0 cm di kiri, kanan, depan, belakang
gap_center   = 20.0; // Celah 2.0 cm di lorong tengah antara kedua PCB

shelf_bottom_h = 6.0;   // Rak penopang PCB dari lantai dasar (ruang solder 6mm)
rail_guide_w   = 2.2;   // Tebal bibir pemandu rel

corner_post_od = 8.0;
corner_screw_d = 3.2; // Baut M3

gps_ant_w    = 25.8;
gps_ant_l    = 25.8;
gps_rim_h    = 6.5;

fpc_w        = 18.0;
fpc_l        = 46.0;
fpc_recess   = 1.0;


// ==========================================
// 2. PARAMETER CASING DHT22 (4cm x 8cm x 6cm)
// ==========================================
dht_total_w  = 40.0; // Lebar Total 4.0 cm
dht_total_l  = 80.0; // Panjang Total 8.0 cm
dht_total_h  = 60.0; // Tinggi Total 6.0 cm

dht_wall     = 2.0;
dht_floor    = 2.0;
dht_r        = 3.5;

dht_w        = dht_total_w - 2 * dht_wall; // 36.0 mm internal
dht_l        = dht_total_l - 2 * dht_wall; // 76.0 mm internal
dht_h        = dht_total_h - dht_floor;    // 58.0 mm internal

dht_pcb_w    = 24.0; // Lebar PCB terpotong 8 pin
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

// MODUL REL ALUR VERTIKAL 4 SUDUT PRESISI UNTUK PCB FULL 4x6 CM
module pcb_vertical_drop_in_rails(base_x, base_y, target_pcb_w, target_pcb_l, guide_h) {
    p_len = 7.0;
    w_fit = target_pcb_w + pcb_clearance;
    l_fit = target_pcb_l + pcb_clearance;
    
    // Sudut 1: Depan - Kiri
    translate([base_x - rail_guide_w, base_y - rail_guide_w, floor_t]) {
        difference() {
            cube([rail_guide_w + 2.5, p_len + rail_guide_w, guide_h]);
            translate([rail_guide_w, rail_guide_w, shelf_bottom_h])
                cube([3.5, p_len + 1.0, guide_h]);
        }
        cube([rail_guide_w + 2.5, p_len + rail_guide_w, shelf_bottom_h]);
    }
    
    // Sudut 2: Depan - Kanan
    translate([base_x + w_fit - 2.5, base_y - rail_guide_w, floor_t]) {
        difference() {
            cube([rail_guide_w + 2.5, p_len + rail_guide_w, guide_h]);
            translate([-0.5, rail_guide_w, shelf_bottom_h])
                cube([3.0, p_len + 1.0, guide_h]);
        }
        cube([rail_guide_w + 2.5, p_len + rail_guide_w, shelf_bottom_h]);
    }
    
    // Sudut 3: Belakang - Kiri
    translate([base_x - rail_guide_w, base_y + l_fit - p_len, floor_t]) {
        difference() {
            cube([rail_guide_w + 2.5, p_len + rail_guide_w, guide_h]);
            translate([rail_guide_w, -0.5, shelf_bottom_h])
                cube([3.5, p_len + 0.5, guide_h]);
        }
        cube([rail_guide_w + 2.5, p_len + rail_guide_w, shelf_bottom_h]);
    }
    
    // Sudut 4: Belakang - Kanan
    translate([base_x + w_fit - 2.5, base_y + l_fit - p_len, floor_t]) {
        difference() {
            cube([rail_guide_w + 2.5, p_len + rail_guide_w, guide_h]);
            translate([-0.5, -0.5, shelf_bottom_h])
                cube([3.0, p_len + 0.5, guide_h]);
        }
        cube([rail_guide_w + 2.5, p_len + rail_guide_w, shelf_bottom_h]);
    }
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
// 1. CASING UTAMA - BAGIAN BAWAH (MAIN BASE 12.5x8.5x8.0cm)
// ==========================================
module main_case_base() {
    modem_x = wall_t + gap_side; // 12.4 mm (PCB Modem Kiri: X = 12.4 s/d 52.4 mm)
    modem_y = wall_t + gap_side; // 12.4 mm (Y = 12.4 s/d 72.4 mm)
    
    esp_x   = modem_x + pcb_w + gap_center; // 12.4 + 40 + 20 = 72.4 mm (PCB ESP32 Kanan: X = 72.4 s/d 112.4 mm)
    esp_y   = wall_t + gap_side;            // 12.4 mm (Y = 12.4 s/d 72.4 mm)
    
    fpc_y0 = wall_t + 18.0;
    fpc_z0 = floor_t + 24.0;

    difference() {
        union() {
            difference() {
                rounded_cube(main_total_w, main_total_l, main_total_h, corner_r);
                translate([wall_t, wall_t, floor_t])
                    rounded_cube(main_w, main_l, main_h + 1, max(1, corner_r - wall_t));
            }
            
            // 4x Pilar Baut Sudut M3
            c_offset_x = corner_post_od / 2 + 0.6;
            c_offset_y = corner_post_od / 2 + 0.6;
            standoff_post(wall_t + c_offset_x, wall_t + c_offset_y, floor_t, corner_post_od, corner_screw_d, main_h);
            standoff_post(main_total_w - wall_t - c_offset_x, wall_t + c_offset_y, floor_t, corner_post_od, corner_screw_d, main_h);
            standoff_post(wall_t + c_offset_x, main_total_l - wall_t - c_offset_y, floor_t, corner_post_od, corner_screw_d, main_h);
            standoff_post(main_total_w - wall_t - c_offset_x, main_total_l - wall_t - c_offset_y, floor_t, corner_post_od, corner_screw_d, main_h);
            
            // REL ALUR VERTIKAL UNTUK PCB FULL 4x6 CM: ESP32 (Kanan)
            pcb_vertical_drop_in_rails(esp_x, esp_y, pcb_w, pcb_l, 48.0);
            
            // REL ALUR VERTIKAL UNTUK PCB FULL 4x6 CM: MODEM 4G (Kiri)
            pcb_vertical_drop_in_rails(modem_x, modem_y, pcb_w, pcb_l, 48.0);
        }
        
        // Dinding Kiri: Lubang diperlebar memanjang & naik mendekati antena (Y = 14 s/d 70 mm, Z = 10 s/d 22 mm)
        translate([-1, 14.0, floor_t + 8.0])
            cube([wall_t + 2, 56.0, 12.0]);
            
        // Dinding Kanan: Lubang diperlebar memanjang di upperdeck (Y = 14 s/d 70 mm, Z = 24 s/d 36 mm)
        translate([main_total_w - wall_t - 1, 14.0, floor_t + 22.0])
            cube([wall_t + 2, 56.0, 12.5]);
            
        // Dinding Depan: Lubang bawah diperlebar melintasi bodi (X = 16 s/d 108 mm)
        translate([16.0, -1, floor_t + 6.0])
            cube([main_total_w - 32.0, wall_t + 2, 13.0]);
            
        // Ceruk Tempel Stiker Antena FPC 4G di Dinding Kiri Luar
        translate([-0.1, fpc_y0, fpc_z0])
            cube([fpc_recess + 0.1, fpc_l, fpc_w]);
            
        // Lubang Masuk Kabel Antena FPC di Sisi Kanan Ceruk
        translate([-1, fpc_y0 + fpc_l - 6.5, fpc_z0 + 3.0])
            cube([wall_t + 2, 6.0, 12.0]);
            
        // Lubang Port Kabel Sensor Menuju Casing DHT22 (Dinding Belakang)
        translate([main_total_w / 2 - 5.0, main_total_l - wall_t - 1, floor_t + 10.0])
            cube([10.0, wall_t + 2, 7.0]);
            
        // Ventilasi Depan Atas
        translate([wall_t + 16.0, -1, floor_t + 45.0])
            vent_slots(main_w - 32.0, 20.0, 2.5, 3.5, wall_t + 2);
            
        // Ventilasi Belakang Atas
        translate([wall_t + 16.0, main_total_l - wall_t - 1, floor_t + 35.0])
            vent_slots(main_w - 32.0, 25.0, 2.5, 3.5, wall_t + 2);
    }
}


// ==========================================
// 2. CASING UTAMA - TUTUP ATAS (MAIN LID 12.5x8.5cm - FIT-IN INTERFACE)
// ==========================================
module main_case_lid() {
    lip_h     = 4.5;
    lip_t     = 1.5;
    clearance = 0.35; // Toleransi fit-in 0.35 mm di sekeliling bibir
    
    gps_x = wall_t + 16.0;
    gps_y = main_total_l - wall_t - gps_ant_l - 10.0;
    
    c_offset_x = corner_post_od / 2 + 0.6;
    c_offset_y = corner_post_od / 2 + 0.6;

    difference() {
        union() {
            // Plat Tutup Atas Luar (125 x 85 mm)
            rounded_cube(main_total_w, main_total_l, floor_t, corner_r);
            
            // Bibir Snap Pengunci Fit-in (119.5 x 79.5 mm)
            translate([wall_t + clearance, wall_t + clearance, -lip_h])
                difference() {
                    rounded_cube(main_w - 2*clearance, main_l - 2*clearance, lip_h + 0.1, max(0.5, corner_r - wall_t));
                    translate([lip_t, lip_t, -0.5])
                        rounded_cube(main_w - 2*clearance - 2*lip_t, main_l - 2*clearance - 2*lip_t, lip_h + 1.2, max(0.2, corner_r - wall_t - lip_t));
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
        
        // Saku Relief 4 Pilar Sudut M3 (Memastikan bibir tutup tidak menabrak pilar bodi bawah)
        for (pos = [
            [wall_t + c_offset_x, wall_t + c_offset_y],
            [main_total_w - wall_t - c_offset_x, wall_t + c_offset_y],
            [wall_t + c_offset_x, main_total_l - wall_t - c_offset_y],
            [main_total_w - wall_t - c_offset_x, main_total_l - wall_t - c_offset_y]
        ]) {
            translate([pos[0], pos[1], -lip_h - 0.5])
                cylinder(d=corner_post_od + 0.8, h=lip_h + 0.5);
        }
        
        // 4x Lubang Baut Countersunk M3 (Koaksial presisi dengan pilar bodi)
        for (pos = [
            [wall_t + c_offset_x, wall_t + c_offset_y],
            [main_total_w - wall_t - c_offset_x, wall_t + c_offset_y],
            [wall_t + c_offset_x, main_total_l - wall_t - c_offset_y],
            [main_total_w - wall_t - c_offset_x, main_total_l - wall_t - c_offset_y]
        ]) {
            translate([pos[0], pos[1], -lip_h - 1]) {
                cylinder(d=corner_screw_d + 0.4, h=floor_t + lip_h + 4);
                translate([0, 0, floor_t - 1.2]) 
                    cylinder(d1=corner_screw_d + 0.4, d2=6.5, h=2.5);
            }
        }
        
        // Lubang Kabel Antena GPS Masuk ke Dalam
        translate([gps_x + gps_ant_w/2 - 3.5, gps_y - 4.0, -lip_h - 1])
            cube([7.0, 6.0, floor_t + lip_h + 2]);
            
        // Lubang LED Indikator Traffic Light
        led_x = wall_t + 30.0;
        led_y = wall_t + 16.0;
        for (i = [0 : 2]) {
            translate([led_x + i * 11.0, led_y, -lip_h - 1])
                cylinder(d=3.8, h=floor_t + lip_h + 2);
        }
    }
}


// ==========================================
// 3. CASING KHUSUS SENSOR DHT22 (BASE 4.0x8.0x6.0cm)
// ==========================================
module dht22_case_base() {
    pcb_cx = dht_total_w / 2; // 20.0 mm
    pcb_cy = dht_wall + 14.0; // 16.0 mm (spans y = 16.0 s/d 64.0 mm)
    
    rail_x = pcb_cx - dht_pcb_w / 2; // 8.0 mm
    p_len = 8.0;

    difference() {
        union() {
            difference() {
                rounded_cube(dht_total_w, dht_total_l, dht_total_h, dht_r);
                translate([dht_wall, dht_wall, dht_floor])
                    rounded_cube(dht_w, dht_l, dht_h + 1, max(1, dht_r - dht_wall));
            }
            
            // 4x Pilar Baut Pengunci Casing DHT22
            p_post = 6.0;
            standoff_post(dht_wall + 2.8, dht_wall + 2.8, dht_floor, p_post, 2.2, dht_h);
            standoff_post(dht_total_w - dht_wall - 2.8, dht_wall + 2.8, dht_floor, p_post, 2.2, dht_h);
            standoff_post(dht_wall + 2.8, dht_total_l - dht_wall - 2.8, dht_floor, p_post, 2.2, dht_h);
            standoff_post(dht_total_w - dht_wall - 2.8, dht_total_l - dht_wall - 2.8, dht_floor, p_post, 2.2, dht_h);
            
            // PENYANGGA 4 SUDUT UNTUK PCB POTONG (24 x 48 mm) - KOTAK TENGAH 100% PLONG
            // Sudut 1: Depan-Kiri
            translate([rail_x - 2.5, pcb_cy - 2.5, dht_floor]) {
                difference() {
                    cube([4.5, p_len + 2.5, 30.0]);
                    translate([2.0, 2.5, 6.0]) cube([3.5, p_len + 1.0, 25.0]);
                }
                cube([4.5, p_len + 2.5, 6.0]);
            }
            // Sudut 2: Depan-Kanan
            translate([rail_x + dht_pcb_w - 2.0, pcb_cy - 2.5, dht_floor]) {
                difference() {
                    cube([4.5, p_len + 2.5, 30.0]);
                    translate([-1.0, 2.5, 6.0]) cube([3.5, p_len + 1.0, 25.0]);
                }
                cube([4.5, p_len + 2.5, 6.0]);
            }
            // Sudut 3: Belakang-Kiri
            translate([rail_x - 2.5, pcb_cy + dht_pcb_l - p_len, dht_floor]) {
                difference() {
                    cube([4.5, p_len + 2.5, 30.0]);
                    translate([2.0, -0.5, 6.0]) cube([3.5, p_len + 0.5, 25.0]);
                }
                cube([4.5, p_len + 2.5, 6.0]);
            }
            // Sudut 4: Belakang-Kanan
            translate([rail_x + dht_pcb_w - 2.0, pcb_cy + dht_pcb_l - p_len, dht_floor]) {
                difference() {
                    cube([4.5, p_len + 2.5, 30.0]);
                    translate([-1.0, -0.5, 6.0]) cube([3.5, p_len + 0.5, 25.0]);
                }
                cube([4.5, p_len + 2.5, 6.0]);
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
// 4. CASING KHUSUS SENSOR DHT22 - TUTUP ATAS (FIT-IN INTERFACE)
// ==========================================
module dht22_case_lid() {
    lip_h     = 3.5;
    lip_t     = 1.2;
    clearance = 0.35; // Toleransi fit-in 0.35 mm
    p_post    = 6.0;

    difference() {
        union() {
            // Plat Tutup Atas Luar (40 x 80 mm)
            rounded_cube(dht_total_w, dht_total_l, dht_floor, dht_r);
            
            // Bibir Snap Pengunci Fit-in (35.3 x 75.3 mm)
            translate([dht_wall + clearance, dht_wall + clearance, -lip_h])
                difference() {
                    rounded_cube(dht_w - 2*clearance, dht_l - 2*clearance, lip_h + 0.1, max(0.5, dht_r - dht_wall));
                    translate([lip_t, lip_t, -0.5])
                        rounded_cube(dht_w - 2*clearance - 2*lip_t, dht_l - 2*clearance - 2*lip_t, lip_h + 1.2, max(0.2, dht_r - dht_wall - lip_t));
                }
        }
        
        // Saku Relief 4 Pilar Sudut DHT22 (Memeluk pilar bodi dengan pas)
        for (pos = [
            [dht_wall + 2.8, dht_wall + 2.8],
            [dht_total_w - dht_wall - 2.8, dht_wall + 2.8],
            [dht_wall + 2.8, dht_total_l - dht_wall - 2.8],
            [dht_total_w - dht_wall - 2.8, dht_total_l - dht_wall - 2.8]
        ]) {
            translate([pos[0], pos[1], -lip_h - 0.5])
                cylinder(d=p_post + 0.8, h=lip_h + 0.5);
        }
        
        // 4x Lubang Baut Pengunci Countersunk
        for (pos = [
            [dht_wall + 2.8, dht_wall + 2.8],
            [dht_total_w - dht_wall - 2.8, dht_wall + 2.8],
            [dht_wall + 2.8, dht_total_l - dht_wall - 2.8],
            [dht_total_w - dht_wall - 2.8, dht_total_l - dht_wall - 2.8]
        ]) {
            translate([pos[0], pos[1], -lip_h - 3]) {
                cylinder(d=2.6, h=dht_floor + lip_h + 6);
                translate([0, 0, dht_floor - 1.0]) cylinder(d1=2.6, d2=5.0, h=2.0);
            }
        }
        
        // Kisi-kisi Ventilasi Atas
        translate([dht_wall + 6.0, dht_wall + 8.0, -1])
            vent_slots(dht_w - 12.0, 14.0, 2.2, 3.0, dht_floor + 2);
    }
}


// ==========================================
// 5. SIMULASI ELEKTRONIKA
// ==========================================

module sim_double_deck_esp32_stack() {
    color([0.1, 0.55, 0.25]) cube([pcb_w, pcb_l, 1.6]);
    color([0.85, 0.65, 0.15]) {
        for (pos = [[2,2], [38,2], [2,58], [38,58]]) {
            translate([pos[0], pos[1], 1.6]) cylinder(d=5.0, h=20.4);
        }
    }
    translate([0, 0, 22.0]) {
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
    color(c_case) main_case_base();
    translate([72.4, 12.4, floor_t + shelf_bottom_h])
        sim_double_deck_esp32_stack();
    translate([12.4, 12.4, floor_t + shelf_bottom_h])
        sim_a7670c_board();
    translate([-0.5, wall_t + 18.0, floor_t + 24.0])
        sim_fpc_sticker_antenna();
    translate([wall_t + 16.0, main_total_l - wall_t - gps_ant_l - 10.0, main_total_h + 2.4])
        sim_gps_antenna();
        
    translate([0, 0, 50.0]) {
        color(c_case) main_case_lid();
    }
    
    translate([-110.0, -25.0, 0.0])
        sim_dual_typec_powerbank();
        
    translate([main_total_w + 30.0, 0.0, 0.0]) {
        color(c_case) dht22_case_base();
        translate([dht_total_w/2 - dht_pcb_w/2, dht_wall + 14.0, dht_floor + 6.0])
            sim_dht22_cut_pcb();
        translate([0, 0, 35.0]) {
            color(c_case) dht22_case_lid();
        }
    }
    
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

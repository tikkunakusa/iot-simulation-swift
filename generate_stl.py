#!/usr/bin/env python3
"""
IoT Enclosure STL Generator (Official 4-File Production Build)
Generates the 4 final STL files for 3D printing:
1. case_main_base.stl  (Casing Utama Bawah: Lebar 11cm, Panjang 8cm, Tinggi 8cm)
2. case_main_lid.stl   (Casing Utama Tutup: Lebar 11cm, Panjang 8cm)
3. case_dht22_base.stl (Casing DHT22 Bawah: Lebar 4cm, Panjang 8cm, Tinggi 6cm)
4. case_dht22_lid.stl  (Casing DHT22 Tutup: Lebar 4cm, Panjang 8cm)
"""

import os
import subprocess
import sys

def get_openscad_bin():
    possible_bins = [
        "/Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD",
        "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
        "openscad"
    ]
    for b in possible_bins:
        if os.path.exists(b) or b == "openscad":
            try:
                res = subprocess.run([b, "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if res.returncode == 0 or b.startswith("/Applications"):
                    return b
            except Exception:
                continue
    return None

def compile_stl(openscad_bin, scad_file, part_name, output_stl):
    print(f"Compiling {os.path.basename(output_stl)} ({part_name})...")
    cmd = [openscad_bin, "-D", f'part_to_render="{part_name}"', "-o", output_stl, scad_file]
    subprocess.run(cmd, check=True)
    print(f"  -> Generated: {output_stl}")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    openscad_bin = get_openscad_bin()
    
    if not openscad_bin:
        print("Error: OpenSCAD binary not found.")
        sys.exit(1)
        
    print(f"Using OpenSCAD binary: {openscad_bin}\n")
    scad_file = os.path.join(script_dir, "casing_iot.scad")
    
    # 1. Main Base
    compile_stl(openscad_bin, scad_file, "main_base", os.path.join(script_dir, "case_main_base.stl"))
    
    # 2. Main Lid
    compile_stl(openscad_bin, scad_file, "main_lid", os.path.join(script_dir, "case_main_lid.stl"))
    
    # 3. DHT22 Base
    compile_stl(openscad_bin, scad_file, "dht22_base", os.path.join(script_dir, "case_dht22_base.stl"))
    
    # 4. DHT22 Lid
    compile_stl(openscad_bin, scad_file, "dht22_lid", os.path.join(script_dir, "case_dht22_lid.stl"))

    print("\nAll 4 official STL production files generated successfully!")

if __name__ == '__main__':
    main()

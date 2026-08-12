# Tabel Koneksi Pin (Wiring)

Berikut adalah rekapitulasi sambungan kabel (wiring) final dari seluruh sensor dan perangkat Anda menuju modul **DFRobot FireBeetle 2 ESP32-C6**, yang selaras dengan kodingan di `main.swift` saat ini.

> [!IMPORTANT]
> Pastikan seluruh pin **GND (Ground)** dari semua modul terhubung menjadi satu jalur *(common ground)* ke pin GND pada ESP32 agar komunikasi data tidak *error/noise*.

## 1. Modem 4G SimCom A7670C

| Pin Modem | Pin ESP32-C6 | Keterangan |
| :--- | :--- | :--- |
| **TXD** | GPIO 22 | Jalur RX ESP32 (Menerima balasan AT dari Modem) |
| **RXD** | GPIO 21 | Jalur TX ESP32 (Mengirim perintah AT ke Modem) |
| **PEN / PWRKEY** | GPIO 23 | Kontrol untuk me-reset / menyalakan modem dari kodingan |
| **GND** | GND | Ground bersama (Wajib terhubung) |
| **VTTL / VEXT** | 3V3 (3.3V) | Referensi tegangan logika UART (agar aman untuk ESP32) |
| **VIN** | Eksternal 5V | Sebaiknya pasang kabel USB langsung ke modem (butuh minim 5V 2A) |

## 2. Modul GPS Neo-6M

| Pin GPS | Pin ESP32-C6 | Keterangan |
| :--- | :--- | :--- |
| **TX** | GPIO 5 | Jalur RX ESP32 (Menerima data koordinat satelit) |
| **RX** | GPIO 6 | Jalur TX ESP32 (Mengirim konfigurasi ke GPS) |
| **VCC** | 3V3 (3.3V) | Daya untuk modul GPS |
| **GND** | GND | Ground bersama |

## 3. Sensor Suhu DHT22

| Pin DHT22 | Pin ESP32-C6 | Keterangan |
| :--- | :--- | :--- |
| **OUT / DATA** | GPIO 4 | Jalur data sensor 1-wire |
| **+ / VCC** | 3V3 (3.3V) | Daya untuk sensor (tambahkan resistor 4.7k-10k pull-up ke VCC jika modul belum punya) |
| **- / GND** | GND | Ground bersama |

## 4. Modul LED Traffic Light

| Pin Traffic Light | Pin ESP32-C6 | Keterangan |
| :--- | :--- | :--- |
| **R (Red)** | GPIO 17 | Kontrol Lampu Merah |
| **Y (Yellow)** | GPIO 16 | Kontrol Lampu Kuning |
| **G (Green)** | GPIO 8 | Kontrol Lampu Hijau |
| **GND** | GND | Ground bersama |

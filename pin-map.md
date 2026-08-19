# Tabel Koneksi Pin (Wiring)

Berikut adalah rekapitulasi sambungan kabel (wiring) final dari seluruh sensor dan perangkat Anda menuju modul **DFRobot FireBeetle 2 ESP32-C6**, yang selaras dengan kodingan di `main.swift` saat ini.

> [!IMPORTANT]
> Pastikan seluruh pin **GND (Ground)** dari semua modul terhubung menjadi satu jalur *(common ground)* ke pin GND pada ESP32 agar komunikasi data tidak *error/noise*.

## 1. Modem 4G SimCom A7670C

> [!IMPORTANT]
> **Skema Daya Modem (Power Supply Terpisah):**
> - **ESP32 TIDAK menyediakan 5V:** Daya utama modem **TIDAK diambil dari pin ESP32**.
> - **Modem ditenagai langsung via port USB modem** (colok kabel USB Type-C/Micro-USB ke charger adaptor HP / powerbank 5V 2A).
> - **Pin 3V3 ESP32 HANYA dihubungkan ke pin VEXT / VTTL** modem sebagai referensi tegangan sinyal logika UART (arus sangat kecil, <1mA, aman untuk ESP32).

> [!WARNING]
> **Wajib Menghubungkan 3V3 ke VEXT/VTTL!**
> Pin **VEXT / VTTL / V_MCU** pada modul modem adalah pin referensi tegangan logika UART (*level shifter*).
> - **Hubungkan pin 3V3 dari ESP32 ke pin VEXT (atau VTTL) modem.**
> - Jika pin VEXT tidak terhubung ke 3V3, modul modem tidak akan mengirimkan atau merespons sinyal UART (perintah AT akan timeout / tidak ada respon sama sekali).

| Pin Modem | Pin ESP32-C6 | Keterangan |
| :--- | :--- | :--- |
| **VEXT / VTTL** | **3V3 (3.3V)** | **Wajib:** Referensi logika UART 3.3V (dari ESP32) |
| **TXD** | GPIO 22 | Jalur RX ESP32 (Menerima balasan AT dari Modem) |
| **RXD** | GPIO 21 | Jalur TX ESP32 (Mengirim perintah AT ke Modem) |
| **PEN / PWRKEY** | GPIO 23 | Kontrol untuk me-reset / menyalakan modem dari kodingan |
| **GND** | GND | Ground bersama / Common Ground (Wajib terhubung) |
| **Port USB Modem / VIN** | **Power Supply Eksternal 5V 2A** | **Daya Utama Modem:** Colok kabel USB langsung ke modem (BUKAN dari ESP32) |

## 2. Modul GPS Neo-6M

| Pin GPS | Pin ESP32-C6 | Keterangan |
| :--- | :--- | :--- |
| **TX** | GPIO 5 | Jalur RX ESP32 (Menerima data koordinat satelit) |
| **RX** | GPIO 6 | Jalur TX ESP32 (Mengirim konfigurasi ke GPS) |
| **VCC** | **3V3** | Daya 3.3V dari ESP32-C6 (Power murni yang terbukti mengaktifkan modul GPS & komunikasi UART) |
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

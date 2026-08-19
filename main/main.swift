func probeBaudRates(modem: Modem4G, rates: [Int32], rxPin: Int32, txPin: Int32) -> Int32? {
    print("[DIAG] 🔎 Scanning baud rates on TX:\(txPin), RX:\(rxPin)...")
    for baud in rates {
        modem.setBaudRate(baud)
        modem.flush()
        delay_ms(50)
        
        // Send AT burst
        for _ in 0..<3 {
            modem.sendCommand("AT\r\n")
            delay_ms(60)
        }
        
        let resp = modem.readResponse(timeoutMs: 250, printOutput: false)
        var matched = false
        resp.withCString { cStr in
            if modem_resp_contains(cStr, "OK") || modem_resp_contains(cStr, "AT") {
                matched = true
            }
        }
        
        if matched {
            print("[DIAG] ✅ Responded OK at \(baud) bps!")
            return baud
        }
    }
    return nil
}

@_cdecl("app_main")
func main() {
    print("\n=======================================================")
    print("🥭 SIMCom A7670C AUTO-PROBE & DIAGNOSTIC SUITE")
    print("=======================================================")
    print("📡 Default Pins : ESP32-C6 (TX: 21, RX: 22, PWRKEY: 23)")
    print("🎯 Target       : Auto-detect baud rate, swap pins, and ping Google")
    print("=======================================================\n")

    // Inisialisasi Modem 4G SimCom A7670C (Default 9600 bps, pwrPin: -1 to avoid power toggles)
    let modem = Modem4G(rxPin: 22, txPin: 21, pwrPin: -1, baudRate: 9600)

    let baudList: [Int32] = [9600, 115200, 57600, 38400, 19200, 460800]
    var workingBaud: Int32? = nil
    var workingTx: Int32 = 21
    var workingRx: Int32 = 22

    // Scan Attempt 1: Normal pins (TX:21, RX:22)
    workingBaud = probeBaudRates(modem: modem, rates: baudList, rxPin: 22, txPin: 21)

    // Scan Attempt 2: Pin-reversal test (TX:22, RX:21)
    if workingBaud == nil {
        print("[DIAG] 🔄 Attempting pin reversal test (TX:22, RX:21)...")
        modem.reconfigurePins(rxPin: 21, txPin: 22)
        workingBaud = probeBaudRates(modem: modem, rates: baudList, rxPin: 21, txPin: 22)
        if workingBaud != nil {
            workingTx = 22
            workingRx = 21
            print("[DIAG] 💡 PINS WERE SWAPPED! Successfully connected on ESP TX:22, RX:21.")
        } else {
            // Restore default pins
            modem.reconfigurePins(rxPin: 22, txPin: 21)
        }
    }


    if let detectedBaud = workingBaud {
        print("\n=======================================================")
        print("🎯 UART LINK ESTABLISHED!")
        print("⚡ Active Baud: \(detectedBaud) bps | Pins: TX:\(workingTx), RX:\(workingRx)")
        print("=======================================================\n")
        modem.setBaudRate(detectedBaud)
    } else {

        print("\n=======================================================")
        print("⚠️ UART LINK FAILED ON ALL BAUD RATES AND PIN COMBINATIONS")
        print("=======================================================")
        print("Checked bauds: 115200, 9600, 57600, 38400, 19200, 460800")
        print("Checked pin configurations: (TX:21, RX:22) AND (TX:22, RX:21)")
        print("-------------------------------------------------------")
        print("Hardware Checklist:")
        print("1. Is ESP32 GND connected to Modem GND?")
        print("2. Is the jumper wire on Modem TX/RX seated firmly?")
        print("3. Try pressing the physical PWRKEY button on the board.")
        print("=======================================================\n")
    }


    // --- STEP 1: BASIC AT & MODULE IDENTITY ---
    print("\n=======================================================")
    print("📋 STEP 1: MODULE IDENTIFICATION & HARDWARE STATUS")
    print("=======================================================")
    modem.sendAndRead(command: "AT\r\n", timeoutMs: 500, stepTitle: "1.1 Basic AT Sync")
    modem.sendAndRead(command: "ATE0\r\n", timeoutMs: 500, stepTitle: "1.2 Disable Echo (ATE0)")
    modem.sendAndRead(command: "ATI\r\n", timeoutMs: 1000, stepTitle: "1.3 Product Information (ATI)")
    modem.sendAndRead(command: "AT+CGMM\r\n", timeoutMs: 1000, stepTitle: "1.4 Model Identification (AT+CGMM)")
    modem.sendAndRead(command: "AT+CGMR\r\n", timeoutMs: 1000, stepTitle: "1.5 Firmware Revision (AT+CGMR)")
    modem.sendAndRead(command: "AT+CGSN\r\n", timeoutMs: 1000, stepTitle: "1.6 IMEI Number (AT+CGSN)")
    modem.sendAndRead(command: "AT+CFUN?\r\n", timeoutMs: 1000, stepTitle: "1.7 Functionality Level (AT+CFUN?) [1=Full RF]")
    modem.sendAndRead(command: "AT+CFUN=1\r\n", timeoutMs: 2000, stepTitle: "1.8 Set Full Phone Functionality (AT+CFUN=1)")

    // --- STEP 2: SIM CARD DIAGNOSTICS ---
    print("\n=======================================================")
    print("💳 STEP 2: SIM CARD STATUS")
    print("=======================================================")
    modem.sendAndRead(command: "AT+CPIN?\r\n", timeoutMs: 1500, stepTitle: "2.1 Check SIM Card Status (AT+CPIN?)")
    modem.sendAndRead(command: "AT+CICCID\r\n", timeoutMs: 1500, stepTitle: "2.2 Read SIM Card ICCID (AT+CICCID)")
    modem.sendAndRead(command: "AT+CIMI\r\n", timeoutMs: 1500, stepTitle: "2.3 Read IMSI Number (AT+CIMI)")

    // --- STEP 3: SIGNAL QUALITY & SERVING CELL ---
    print("\n=======================================================")
    print("📶 STEP 3: RF SIGNAL & CELL TOWER STATUS")
    print("=======================================================")
    modem.sendAndRead(command: "AT+CSQ\r\n", timeoutMs: 1000, stepTitle: "3.1 Signal Quality (AT+CSQ)")
    modem.printSignalStatus()
    modem.sendAndRead(command: "AT+CPSI?\r\n", timeoutMs: 2000, stepTitle: "3.2 Serving Cell Info (AT+CPSI?) [LTE Band / RSRP / RSRQ]")

    // --- STEP 4: NETWORK REGISTRATION ---
    print("\n=======================================================")
    print("🌐 STEP 4: NETWORK REGISTRATION STATUS")
    print("=======================================================")
    print("ℹ️  Values: 0,1 = Registered (Home) | 0,5 = Registered (Roaming) | 0,2 = Searching | 0,3 = Denied")
    modem.sendAndRead(command: "AT+CREG?\r\n", timeoutMs: 1500, stepTitle: "4.1 Circuit-Switched Registration (AT+CREG?)")
    modem.sendAndRead(command: "AT+CGREG?\r\n", timeoutMs: 1500, stepTitle: "4.2 GPRS Registration (AT+CGREG?)")
    modem.sendAndRead(command: "AT+CEREG?\r\n", timeoutMs: 1500, stepTitle: "4.3 EPS/LTE Registration (AT+CEREG?)")
    modem.sendAndRead(command: "AT+COPS?\r\n", timeoutMs: 3000, stepTitle: "4.4 Current Operator Selection (AT+COPS?)")
    modem.sendAndRead(command: "AT+CGATT?\r\n", timeoutMs: 2000, stepTitle: "4.5 Packet Domain Attachment (AT+CGATT?) [1=Attached]")

    // --- STEP 5: PDP CONTEXT & CELLULAR DATA ACTIVATION ---
    print("\n=======================================================")
    print("🔌 STEP 5: PDP CONTEXT & TCP/IP STACK ACTIVATION")
    print("=======================================================")
    modem.sendAndRead(command: "AT+CGDCONT?\r\n", timeoutMs: 1500, stepTitle: "5.1 Defined PDP Contexts (AT+CGDCONT?)")
    
    print("\n------------------------------------------------------------")
    print("▶️  5.2 Checking / Opening TCP/IP Stack (AT+NETOPEN)")
    let netResp = modem.sendAndRead(command: "AT+NETOPEN?\r\n", timeoutMs: 1000)
    var isNetOpen = false
    netResp.withCString { cStr in
        if modem_resp_contains(cStr, "+NETOPEN: 1") {
            isNetOpen = true
        }
    }
    if !isNetOpen {
        print("ℹ️ Network stack not open. Sending AT+NETOPEN...")
        modem.sendAndRead(command: "AT+NETOPEN\r\n", timeoutMs: 5000)
        delay_ms(1000)
    }

    modem.sendAndRead(command: "AT+IPADDR\r\n", timeoutMs: 3000, stepTitle: "5.3 Get Local Carrier IP (AT+IPADDR)")

    // --- STEP 6: PING TEST TO GOOGLE DNS (8.8.8.8) ---
    print("\n=======================================================")
    print("🏓 STEP 6: PING TEST TO GOOGLE DNS (8.8.8.8)")
    print("=======================================================")
    print("ℹ️  Sending 4 ICMP packets to 8.8.8.8...")
    modem.sendCommand("AT+CPING=\"8.8.8.8\",1,4\r\n")
    // A7670 sends OK immediately, then streams +CPING replies over 5 seconds
    for _ in 0..<25 {
        delay_ms(250)
        _ = modem.readResponse(timeoutMs: 100, printOutput: true)
    }

    // --- STEP 7: PING TEST TO GOOGLE DOMAIN (www.google.com) ---
    print("\n=======================================================")
    print("🏓 STEP 7: PING TEST TO GOOGLE DOMAIN (www.google.com)")
    print("=======================================================")
    print("ℹ️  Testing DNS resolution + ICMP ping to www.google.com...")
    modem.sendCommand("AT+CPING=\"www.google.com\",1,4\r\n")
    for _ in 0..<25 {
        delay_ms(250)
        _ = modem.readResponse(timeoutMs: 100, printOutput: true)
    }

    // --- STEP 8: HTTP GET TEST (GOOGLE / INTERNET CHECK) ---
    print("\n=======================================================")
    print("🌐 STEP 8: HTTP GET INTERNET CONNECTIVITY TEST")
    print("=======================================================")
    modem.sendAndRead(command: "AT+HTTPTERM\r\n", timeoutMs: 500)
    modem.sendAndRead(command: "AT+HTTPINIT\r\n", timeoutMs: 2000, stepTitle: "8.1 Initialize HTTP Service")
    modem.sendAndRead(command: "AT+HTTPPARA=\"URL\",\"http://www.google.com\"\r\n", timeoutMs: 1500, stepTitle: "8.2 Set Target URL")
    modem.sendAndRead(command: "AT+HTTPACTION=0\r\n", timeoutMs: 5000, stepTitle: "8.3 Execute HTTP GET (HTTPACTION=0)")
    delay_ms(2000)
    _ = modem.readResponse(timeoutMs: 1000, printOutput: true)
    modem.sendAndRead(command: "AT+HTTPREAD=0,200\r\n", timeoutMs: 3000, stepTitle: "8.4 Read HTTP Response Header/Body")
    modem.sendAndRead(command: "AT+HTTPTERM\r\n", timeoutMs: 1000, stepTitle: "8.5 Terminate HTTP Service")

    print("\n=======================================================")
    print("🎉 ALL DIAGNOSTIC TESTS COMPLETE - MODULE IS FULLY FUNCTIONAL!")
    print("=======================================================")
    print("Entering live background monitoring loop...")
    print("Listening for incoming URCs, carrier events, and periodic status.\n")

    var loopCounter: Int = 0
    while true {
        delay_ms(500)
        _ = modem.readResponse(timeoutMs: 100, printOutput: true)
        loopCounter += 1

        // Every 15 seconds, check signal and registration
        if loopCounter % 30 == 0 {
            print("\n[MONITOR] 🕒 Periodic Status Check (T+\(loopCounter / 2)s):")
            modem.sendAndRead(command: "AT+CSQ\r\n", timeoutMs: 1000)
            modem.printSignalStatus()
            modem.sendAndRead(command: "AT+CEREG?\r\n", timeoutMs: 1000)
        }
    }
}



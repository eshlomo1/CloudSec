# Post-Quantum Cryptography Lab

This document compiles all operational terminal commands needed to build, configure, test, and verify the post-quantum TLS 1.3 lab environment using OpenSSL 3, Apache, liboqs, and the Open Quantum Safe provider (`oqs-provider`).

---

## Environment Setup & Phase 1: Classical Baseline

### 1. Install Base Software on Ubuntu Server
```bash
sudo apt update
sudo apt install apache2 openssl
openssl version    # Verify you see 3.x
```

### 2. Generate Self-Signed Certificates for Lab Domain
```bash
sudo a2enmod ssl
sudo mkdir -p /etc/apache2/ssl

sudo openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/test.key \
  -out /etc/apache2/ssl/test.crt \
  -days 365
```

### 3. Enable Site and Verify Classical Configuration
```bash
sudo a2ensite default-ssl
sudo systemctl reload apache2
sudo apache2ctl configtest
curl -kiv https://localhost
```

---

## Headless Packet Analysis (tcpdump & tshark)

### Capture Live TLS Traffic to a PCAP File
```bash
sudo tcpdump -i en0 -w capture.pcap port 443
# (Browse to https://pqc-lab.local, then hit Ctrl+C to stop capture)
```

### Extract Client Hello Handshake Telemetry (Supported Groups)
```bash
tshark -r capture.pcap \
-Y "tls.handshake.type == 1" \
-T fields \
-e frame.number \
-e ip.src \
-e ip.dst \
-e tls.handshake.extensions_supported_group \
-E header=y -E separator=, -E quote=d -E occurrence=f
```

### Extract Server Hello Handshake Telemetry & Ciphersuites
```bash
tshark -r capture.pcap \
-Y "tls.handshake.type == 2" \
-T fields \
-e frame.number \
-e ip.src \
-e ip.dst \
-e tls.handshake.ciphersuite \
-E header=y -E separator=, -E quote=d -E occurrence=f
```

---

## Phase 2 & 3: Enable Hybrid PQC (`oqs-provider`) & Apache Integration

### 1. Install Build Dependencies & Build `liboqs`
```bash
sudo apt update
sudo apt install cmake libssl-dev git build-essential ninja-build
cd ~
rm -rf liboqs
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build
cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja
sudo ninja install
```

### 2. Verify `liboqs` CMake Config File Location
```bash
sudo find /usr /usr/local -name "liboqsConfig.cmake" 2>/dev/null
```

### 3. Build and Install `oqs-provider`
```bash
cd ~/build/oqs-provider
ls CMakeLists.txt

cmake -B _build -G "Unix Makefiles" \
  -Dliboqs_DIR=/usr/local/lib/cmake/liboqs
cmake --build _build
sudo cmake --install _build
```

### 4. Configure OpenSSL Provider Block
```bash
sudo bash -c 'cat << '\''EOF'\'' >> /etc/ssl/openssl.cnf

[provider_sect]
default = default_sect
oqsprovider = oqsprovider_sect

[default_sect]
activate = 1

[oqsprovider_sect]
activate = 1
module = /usr/local/lib64/ossl-modules/oqsprovider.so
EOF
'
```

### 5. Verify Registered Post-Quantum KEM Algorithms
```bash
openssl list -kem-algorithms -provider oqsprovider
```

### 6. Test TLS 1.3 Handshake using PQC Hybrid Group (`s_client`)
```bash
openssl s_client -connect 127.0.0.1:443 -tls1_3 -provider oqsprovider -provider default -groups X25519MLKEM768 -brief
```

### 7. Extract Key Exchange Group / Temp Key Details
```bash
openssl s_client -connect 127.0.0.1:443 -tls1_3 -provider oqsprovider -provider default -groups X25519MLKEM768 2>/dev/null | grep -E "Server Temp Key|Group"
```

### 8. Restart Apache & Validate Verification Checks
```bash
sudo systemctl restart apache2

openssl list -providers
openssl list -kem-algorithms | grep -i mlkem
openssl list -kem-algorithms | grep -i X25519MLKEM768
```

---

## Phase 4: Verification & Troubleshooting Diagnostics

### Inspect Packet Sizes & Payloads via tcpdump
```bash
sudo tcpdump -qns 0 -X -r capture.pcap port 443
```

### Parse Fresh Captures with Advanced tshark Filters
```bash
tshark -r capture.pcap \
-Y "tls.handshake.type == 2" \
-T fields \
-e frame.number \
-e ip.src \
-e ip.dst \
-e tls.handshake.extensions_key_share_group \
-E header=y -E separator=, -E quote=d
```

### Troubleshooting Diagnostics & Log Inspections
```bash
sudo apache2ctl configtest
sudo tail -n 50 /var/log/apache2/error.log
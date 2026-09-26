# Post-Quantum Cryptography Lab

This lab walks through configuring and validating a post-quantum TLS 1.3 setup using OpenSSL 3, Apache, `liboqs`, and the Open Quantum Safe (`oqs-provider`) provider. It starts with a classical TLS baseline, then enables a hybrid post-quantum key exchange and inspects the resulting handshake.

## Lab Guide

[Post-Quantum Cryptography Lab Commands](post_quantum_cryptography_lab_commands.md) contains the setup, build, configuration, test, packet-capture, and troubleshooting commands.

## Prerequisites

- An Ubuntu server with administrative access
- OpenSSL 3 and Apache
- Build tools and development dependencies for `liboqs` and `oqs-provider`
- Optional: `tcpdump` and `tshark` for packet capture and TLS handshake analysis

## Workflow

1. Establish a classical TLS baseline with Apache.
2. Build and install `liboqs` and `oqs-provider`.
3. Configure OpenSSL and test a TLS 1.3 hybrid key exchange.
4. Inspect handshake details and troubleshoot the server configuration.

Use this lab only in systems and environments you own or are authorized to test. PQC algorithm and provider support can vary by software version; verify compatibility with your installed OpenSSL and Apache builds.
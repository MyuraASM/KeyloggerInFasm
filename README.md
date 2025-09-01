# Windows Keylogger in FASM

This repository contains a proof-of-concept keylogger written in FASM (Flat Assembler) for Windows. The project demonstrates basic keylogging and data exfiltration capabilities using low-level Windows APIs and HTTP communication. **This is for educational purposes only. Unauthorized use of keyloggers is illegal and unethical.**

## Project Overview

The Keylogger consists of three main components:
1. **Starter** (`starter.asm`): Launches the logger and sender processes.
2. **Logger** (`logger.asm`): Captures keyboard and mouse input, saving them to a file (`Readme.txt`).
3. **Sender** (`sender.asm`): Reads the logged data and sends it to a remote server via HTTP POST.

## Components

### 1. Starter (`starter.asm`)
- **Purpose**: Executes the logger and sender executables concurrently.
- **Functionality**:
  - Uses `CreateProcess` to launch `logger.exe` and `sender.exe`.
  - Handles process creation errors and exits.
- **Dependencies**: Windows API (`kernel32.dll`).

### 2. Logger (`logger.asm`)
- **Purpose**: Captures keyboard and mouse events.
- **Functionality**:
  - Installs low-level keyboard (`WH_KEYBOARD_LL`) and mouse (`WH_MOUSE_LL`) hooks.
  - Logs printable characters, special keys (space, enter, backspace, tab), and mouse clicks (left and right).
  - Saves logs to `Readme.txt` in append mode.
- **Dependencies**: Windows API (`kernel32.dll`, `user32.dll`) and C runtime (`msvcrt.dll`).

### 3. Sender (`sender.asm`)
- **Purpose**: Sends logged data to a remote server.
- **Functionality**:
  - Initializes Winsock for network communication.
  - Reads the contents of `Readme.txt`.
  - Constructs an HTTP POST request to send data to `examplewebserver.com` on port 80.
  - Sends data every 5 seconds in a loop.
  - Displays status messages and handles errors.
- **Dependencies**: Windows API (`kernel32.dll`) and Winsock (`ws2_32.dll`).

## Setup and Compilation
1. **Requirements**:
   - FASM (Flat Assembler) installed.
   - Windows operating system.
2. **Compilation**:
   - Assemble each `.asm` file using FASM:
     ```bash
     fasm starter.asm starter.exe
     fasm logger.asm logger.exe
     fasm sender.asm sender.exe
     ```
3. **Execution**:
   - Run `starter.exe` to launch both `logger.exe` and `sender.exe`.
   - Ensure `Readme.txt` is writable in the working directory.
   - The sender requires an active internet connection to communicate with the server.

## Usage
- Run `starter.exe` to initiate the keylogger and sender.
- The logger will silently capture keystrokes and mouse clicks, saving them to `Readme.txt`.
- The sender periodically sends the contents of `Readme.txt` to the specified server (`examplewebserver.com`).

## Limitations
- The keylogger captures only basic printable characters and a few special keys.
- Mouse coordinates are not logged, only click events.
- The sender uses a hardcoded server URL and does not handle HTTPS.
- No encryption or obfuscation of logged data.
- File size is limited to 4096 bytes (minus headers) to prevent buffer overflow.

## Disclaimer
This project is a proof of concept for educational purposes only. Unauthorized use of keyloggers to capture user input without consent is illegal and unethical. The author is not responsible for any misuse of this code.

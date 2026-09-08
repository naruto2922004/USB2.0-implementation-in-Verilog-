# USB 2.0 Implementation in Verilog

A Verilog implementation of the USB 2.0 protocol for communication between a single host and a single device.

The complete control and interrupt transfer flow has been implemented and verified in simulation. The project is mainly focused on understanding and implementing the USB protocol from the protocol layer down to the bit-level interface.

## ✅ Implemented

- USB packet generation and decoding
- PID handling
- CRC-5 and CRC-16
- Bit stuffing and unstuffing
- Serialization and deserialization
- USB reset and enumeration
- Control transfers
- Standard USB requests
- HID class requests
- HID keyboard and mouse support
- Interrupt transfers
- Data toggle handling
- ACK, NAK and STALL handling
- Error handling
- Host and device protocol flow
- Simulation testbenches for keyboard and mouse
- Verification of the implemented cases

## 🧱 Structured but Not Implemented

The architecture has been made with space for the following, but they are not currently implemented:

- Bulk transfers
- Isochronous transfers
- Additional USB PIDs such as PRE, SPLIT, PING, etc.
- Other transfer-specific behavior

The transfer type and endpoint handling are already structured so these can be added later without changing the whole design.

## ❌ Not Implemented

- USB hub
- Communication with multiple devices
- Clock recovery and line sampling
- Automatic USB speed detection
- FPGA-ready USB PHY interface

The current implementation uses the same simulation clock for the protocol and differential-line layers, with one USB bit represented by one clock cycle. Because of this, it cannot be directly connected to a real USB differential line and run on an FPGA as it is.

## 🔭 Future Scope

- Add bulk and isochronous transfers
- Add the remaining special PIDs and their related behavior
- Implement USB hub support
- Implement proper PHY clocking and line sampling
- Add USB speed detection
- Separate the PHY and protocol clock domains
- Test the complete design on real FPGA hardware

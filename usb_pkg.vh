//=============================================================================
// usb_pkg.vh
// USB 2.0 Specification Constants — Verilog-2001/2005 Header File
//
// Source: Universal Serial Bus Specification Revision 2.0
//
// PURPOSE:
//   This file contains ONLY constants that come directly from the USB 2.0
//   specification. It does NOT contain:
//     - FSM state encodings
//     - Scheduler state encodings
//     - Internal bus widths
//     - Implementation-specific constants
//   Those belong inside their respective modules until they organically
//   become shared across three or more unrelated modules.
//
// USAGE:
//   `include "usb_pkg.vh" at the top of any module that needs these.
//   All constants are declared with `define so they are globally visible
//   after the include and do not pollute the module's parameter namespace.
//
// CODING STANDARD: IEEE Verilog-2001 / Verilog-2005 (`define only, no
//   SystemVerilog packages). All numeric literals use Verilog radix
//   notation: 4'b for 4-bit binary, 8'h for 8-bit hex, etc.
//
//=============================================================================

`ifndef USB_PKG_VH
`define USB_PKG_VH

//=============================================================================
// SECTION 1: PID ENCODINGS
// Source: USB 2.0 Specification, Section 8.3.1, Table 8-1
//
// PID format: 8 bits = {PID_CHECK[3:0], PID_TYPE[3:0]}
//   where PID_CHECK = ~PID_TYPE  (one's complement)
//
// The 4-bit PID TYPE values (PID<3:0>) are shown below as sent on the bus
// (bit 0 first). In Table 8-1 they are shown MSb-first; the values below
// match the table values directly (e.g., OUT = 4'b0001 = 4'h1).
//
// The 8-bit PID byte sent on the USB bus is:
//   {~PID_TYPE[3:0], PID_TYPE[3:0]}
//
// Constants below follow two naming conventions:
//   USB_PID_xxx      = 4-bit PID TYPE field only
//   USB_PIDBYTE_xxx  = full 8-bit PID byte including complement check field
//=============================================================================

// --- TOKEN group (PID[1:0] = 2'b01) ---
// Source: Table 8-1
`define USB_PID_OUT        4'b0001   // Host-to-function data OUT token
`define USB_PID_IN         4'b1001   // Function-to-host data IN token
`define USB_PID_SOF        4'b0101   // Start-of-Frame marker + frame number
`define USB_PID_SETUP      4'b1101   // SETUP token for control pipe

// --- DATA group (PID[1:0] = 2'b11) ---
// Source: Table 8-1
`define USB_PID_DATA0      4'b0011   // Even data packet PID
`define USB_PID_DATA1      4'b1011   // Odd data packet PID
`define USB_PID_DATA2      4'b0111   // HS high-bandwidth isochronous microframe data
`define USB_PID_MDATA      4'b1111   // HS split / high-bandwidth isochronous data

// --- HANDSHAKE group (PID[1:0] = 2'b10) ---
// Source: Table 8-1
`define USB_PID_ACK        4'b0010   // Receiver accepts error-free data packet
`define USB_PID_NAK        4'b1010   // Receiver cannot accept / transmitter cannot send
`define USB_PID_STALL      4'b1110   // Endpoint halted or control request unsupported
`define USB_PID_NYET       4'b0110   // No response yet from receiver (HS only)

// --- SPECIAL group (PID[1:0] = 2'b00) ---
// Source: Table 8-1
`define USB_PID_PRE        4'b1100   // (Token)     Host preamble for low-speed downstream
`define USB_PID_ERR        4'b1100   // (Handshake) Split transaction error (shares PRE value)
`define USB_PID_SPLIT      4'b1000   // (Token)     High-speed split transaction token
`define USB_PID_PING       4'b0100   // (Token)     HS flow control probe for bulk/control EP
`define USB_PID_RESERVED   4'b0000   // Reserved PID

// Full 8-bit PID bytes: {~PID[3:0], PID[3:0]}
// These are the values that appear on the wire after the SYNC field.
//   Rule: PIDBYTE = {~PID[3:0], PID[3:0]}  i.e. upper nibble = one's complement of lower nibble
`define USB_PIDBYTE_OUT    8'hE1   // PID=4'b0001, ~PID=4'b1110 → 8'b1110_0001
`define USB_PIDBYTE_IN     8'h69   // PID=4'b1001, ~PID=4'b0110 → 8'b0110_1001
`define USB_PIDBYTE_SOF    8'hA5   // PID=4'b0101, ~PID=4'b1010 → 8'b1010_0101
`define USB_PIDBYTE_SETUP  8'h2D   // PID=4'b1101, ~PID=4'b0010 → 8'b0010_1101
`define USB_PIDBYTE_DATA0  8'hC3   // PID=4'b0011, ~PID=4'b1100 → 8'b1100_0011
`define USB_PIDBYTE_DATA1  8'h4B   // PID=4'b1011, ~PID=4'b0100 → 8'b0100_1011
`define USB_PIDBYTE_DATA2  8'h87   // PID=4'b0111, ~PID=4'b1000 → 8'b1000_0111
`define USB_PIDBYTE_MDATA  8'h0F   // PID=4'b1111, ~PID=4'b0000 → 8'b0000_1111
`define USB_PIDBYTE_ACK    8'hD2   // PID=4'b0010, ~PID=4'b1101 → 8'b1101_0010
`define USB_PIDBYTE_NAK    8'h5A   // PID=4'b1010, ~PID=4'b0101 → 8'b0101_1010
`define USB_PIDBYTE_STALL  8'h1E   // PID=4'b1110, ~PID=4'b0001 → 8'b0001_1110
`define USB_PIDBYTE_NYET   8'h96   // PID=4'b0110, ~PID=4'b1001 → 8'b1001_0110
`define USB_PIDBYTE_PRE    8'h3C   // PID=4'b1100, ~PID=4'b0011 → 8'b0011_1100
`define USB_PIDBYTE_ERR    8'h3C   // same encoding as PRE (Table 8-1)
`define USB_PIDBYTE_SPLIT  8'h78   // PID=4'b1000, ~PID=4'b0111 → 8'b0111_1000
`define USB_PIDBYTE_PING   8'hB4   // PID=4'b0100, ~PID=4'b1011 → 8'b1011_0100
`define USB_PIDBYTE_RESERVED 8'hF0 // PID=4'b0000, ~PID=4'b1111 → 8'b1111_0000

// PID group identification mask
// The two LSBs of PID[3:0] identify the group:
//   2'b01 = TOKEN, 2'b11 = DATA, 2'b10 = HANDSHAKE, 2'b00 = SPECIAL
`define USB_PID_GROUP_MASK   2'b11
`define USB_PID_GROUP_TOKEN  2'b01
`define USB_PID_GROUP_DATA   2'b11
`define USB_PID_GROUP_HSHK   2'b10
`define USB_PID_GROUP_SPEC   2'b00

//=============================================================================
// SECTION 2: PACKET FIELD WIDTHS
// Source: USB 2.0 Specification, Sections 8.3.1–8.3.5, Figures 8-1 to 8-5
//=============================================================================

`define USB_PID_BITS          4    // PID TYPE field width (bits)
`define USB_PIDBYTE_BITS      8    // Full PID byte on wire (4-bit PID + 4-bit check)
`define USB_ADDR_BITS         7    // Function address field width; addresses 0–127
`define USB_ENDP_BITS         4    // Endpoint field width; endpoints 0–15
`define USB_FRAME_NUM_BITS   11    // SOF frame number field; range 0–2047, wraps at 7FFh
`define USB_CRC5_BITS         5    // CRC-5 field width (token packets)
`define USB_CRC16_BITS       16    // CRC-16 field width (data packets)

// Derived: maximum field values
`define USB_ADDR_MAX         7'h7F   // Maximum device address (127)
`define USB_ENDP_MAX         4'hF    // Maximum endpoint number (15)
`define USB_FRAME_MAX       11'h7FF  // Maximum frame number (2047); next value wraps to 0

//=============================================================================
// SECTION 3: CRC CONSTANTS
// Source: USB 2.0 Specification, Section 8.3.5
//
// Algorithm summary (Section 8.3.5):
//   - Shift registers seeded with all-ones pattern before each packet.
//   - For each data bit: XOR high-order bit of remainder with data bit,
//     shift left one, set low-order bit to zero; if XOR result was 1,
//     XOR remainder with generator polynomial.
//   - After last data bit: invert CRC and send MSb first.
//   - Receiver: if no errors, remainder equals the polynomial residual.
//
// CRC-5 (Section 8.3.5.1):
//   Generator polynomial: G(X) = X^5 + X^2 + 1
//   Binary pattern: 00101b
//   Residual (error-free): 01100b
//
// CRC-16 (Section 8.3.5.2):
//   Generator polynomial: G(X) = X^16 + X^15 + X^2 + 1
//   Binary pattern: 1000000000000101b
//   Residual (error-free): 1000000000001101b
//=============================================================================

// CRC-5
`define USB_CRC5_POLY         5'b00101    // Generator polynomial bits [4:0] = X^5+X^2+1
`define USB_CRC5_RESIDUAL     5'b01100    // Residue after error-free reception
`define USB_CRC5_INIT         5'b11111    // Shift register seed (all ones)

// CRC-16
`define USB_CRC16_POLY       16'h8005    // Generator polynomial X^16+X^15+X^2+1
`define USB_CRC16_RESIDUAL   16'h800D    // Residue after error-free reception
`define USB_CRC16_INIT       16'hFFFF    // Shift register seed (all ones)

//=============================================================================
// SECTION 4: SYNC FIELD PATTERNS
// Source: USB 2.0 Specification, Sections 7.1.10, 8.1
//
// SYNC is sent before every packet. NRZI-decoded, it appears as a specific
// bit pattern. The SYNC field is NOT included in CRC computation.
//
// FS/LS SYNC:
//   Line sequence KJKJKJKK; NRZI-decoded = 0000000 1
//   8 bits total; the final KK produces a single decoded 1.
//   Represented as 8'b00000001 (LSb first on the wire = last bit is '1').
//
// HS SYNC:
//   32 bits: 15 KJ pairs followed by KK.
//   NRZI-decoded = 0000000000000000000000000000000 1
//   Represented as 32'h00000001.
//=============================================================================

`define USB_SYNC_FS_LS       8'b00000001   // FS/LS SYNC pattern (NRZI-decoded, 8 bits)
`define USB_SYNC_HS         32'h00000001   // HS SYNC pattern (NRZI-decoded, 32 bits)
`define USB_SYNC_FS_BITS      8            // FS/LS SYNC field bit length
`define USB_SYNC_HS_BITS     32            // HS SYNC field bit length

//=============================================================================
// SECTION 5: ENDPOINT TYPE CODES
// Source: USB 2.0 Specification, Section 9.6.6, Table 9-13
//   bmAttributes[1:0] of the Endpoint Descriptor
//=============================================================================

`define USB_EP_TYPE_CONTROL     2'b00   // Control transfer
`define USB_EP_TYPE_ISO         2'b01   // Isochronous transfer
`define USB_EP_TYPE_BULK        2'b10   // Bulk transfer
`define USB_EP_TYPE_INTERRUPT   2'b11   // Interrupt transfer

// Isochronous synchronization type: bmAttributes[3:2]
`define USB_ISO_SYNC_NONE       2'b00   // No synchronization
`define USB_ISO_SYNC_ASYNC      2'b01   // Asynchronous
`define USB_ISO_SYNC_ADAPTIVE   2'b10   // Adaptive
`define USB_ISO_SYNC_SYNC       2'b11   // Synchronous

// Isochronous usage type: bmAttributes[5:4]
`define USB_ISO_USAGE_DATA      2'b00   // Data endpoint
`define USB_ISO_USAGE_FEEDBACK  2'b01   // Feedback endpoint
`define USB_ISO_USAGE_IMPLICIT  2'b10   // Implicit feedback data endpoint

// Endpoint direction bit (in bEndpointAddress[7] of Endpoint Descriptor)
`define USB_EP_DIR_OUT          1'b0
`define USB_EP_DIR_IN           1'b1

//=============================================================================
// SECTION 6: DESCRIPTOR TYPE CODES
// Source: USB 2.0 Specification, Section 9.4, Table 9-5
//=============================================================================

`define USB_DESC_DEVICE                8'h01
`define USB_DESC_CONFIGURATION         8'h02
`define USB_DESC_STRING                8'h03
`define USB_DESC_INTERFACE             8'h04
`define USB_DESC_ENDPOINT              8'h05
`define USB_DESC_DEVICE_QUALIFIER      8'h06
`define USB_DESC_OTHER_SPEED_CONFIG    8'h07
`define USB_DESC_INTERFACE_POWER       8'h08

// HID class descriptor types (USB HID 1.11 Specification)
`define USB_DESC_HID                   8'h21
`define USB_DESC_REPORT                8'h22
`define USB_DESC_PHYSICAL              8'h23

//=============================================================================
// SECTION 7: STANDARD REQUEST CODES
// Source: USB 2.0 Specification, Section 9.4, Table 9-4
//=============================================================================

`define USB_REQ_GET_STATUS        8'h00
`define USB_REQ_CLEAR_FEATURE     8'h01
// 8'h02 reserved
`define USB_REQ_SET_FEATURE       8'h03
// 8'h04 reserved
`define USB_REQ_SET_ADDRESS       8'h05
`define USB_REQ_GET_DESCRIPTOR    8'h06
`define USB_REQ_SET_DESCRIPTOR    8'h07
`define USB_REQ_GET_CONFIGURATION 8'h08
`define USB_REQ_SET_CONFIGURATION 8'h09
`define USB_REQ_GET_INTERFACE     8'h0A
`define USB_REQ_SET_INTERFACE     8'h0B
`define USB_REQ_SYNCH_FRAME       8'h0C

//=============================================================================
// SECTION 8: STANDARD FEATURE SELECTOR CODES
// Source: USB 2.0 Specification, Section 9.4, Table 9-6
//=============================================================================

`define USB_FEAT_ENDPOINT_HALT        8'h00   // Recipient: Endpoint
`define USB_FEAT_DEVICE_REMOTE_WAKEUP 8'h01   // Recipient: Device
`define USB_FEAT_TEST_MODE            8'h02   // Recipient: Device

//=============================================================================
// SECTION 9: SETUP PACKET BMREQUESTTYPE FIELD
// Source: USB 2.0 Specification, Section 9.3, Table 9-2
//
// bmRequestType[7]   = Direction: 0=Host-to-Device, 1=Device-to-Host
// bmRequestType[6:5] = Type:      00=Standard, 01=Class, 10=Vendor, 11=Reserved
// bmRequestType[4:0] = Recipient: 00000=Device, 00001=Interface,
//                                 00010=Endpoint, 00011=Other
//=============================================================================

`define USB_BMRT_DIR_HOST_TO_DEV   1'b0
`define USB_BMRT_DIR_DEV_TO_HOST   1'b1

`define USB_BMRT_TYPE_STANDARD     2'b00
`define USB_BMRT_TYPE_CLASS        2'b01
`define USB_BMRT_TYPE_VENDOR       2'b10

`define USB_BMRT_RCPT_DEVICE       5'b00000
`define USB_BMRT_RCPT_INTERFACE    5'b00001
`define USB_BMRT_RCPT_ENDPOINT     5'b00010
`define USB_BMRT_RCPT_OTHER        5'b00011

// Full bmRequestType byte values for the standard requests in Table 9-3
`define USB_BMRT_STD_DEV_H2D       8'b00000000  // Standard, Device, Host→Device
`define USB_BMRT_STD_DEV_D2H       8'b10000000  // Standard, Device, Device→Host
`define USB_BMRT_STD_IF_H2D        8'b00000001  // Standard, Interface, Host→Device
`define USB_BMRT_STD_IF_D2H        8'b10000001  // Standard, Interface, Device→Host
`define USB_BMRT_STD_EP_H2D        8'b00000010  // Standard, Endpoint, Host→Device
`define USB_BMRT_STD_EP_D2H        8'b10000010  // Standard, Endpoint, Device→Host

//=============================================================================
// SECTION 10: MAXIMUM PACKET SIZES PER SPEED AND TRANSFER TYPE
// Source: USB 2.0 Specification, Sections 5.5–5.8, 9.6.4, 9.6.6
//=============================================================================

// Control Endpoint 0 — bMaxPacketSize0 field of Device Descriptor
// Source: Section 9.6.1
`define USB_MPS_CTRL_LS            8    // Low-speed: must be 8 bytes
`define USB_MPS_CTRL_FS_MIN        8    // Full-speed: 8, 16, 32, or 64 bytes (minimum)
`define USB_MPS_CTRL_FS_MAX       64    // Full-speed maximum
`define USB_MPS_CTRL_HS           64    // High-speed: must be 64 bytes

// Bulk endpoints
// Source: Section 5.8.3
`define USB_MPS_BULK_FS_MIN        8    // Full-speed: 8, 16, 32, or 64 bytes
`define USB_MPS_BULK_FS_MAX       64
`define USB_MPS_BULK_HS          512    // High-speed: must be 512 bytes

// Interrupt endpoints
// Source: Section 5.7.3
`define USB_MPS_INTR_LS_MAX        8    // Low-speed: ≤8 bytes
`define USB_MPS_INTR_FS_MAX       64    // Full-speed: ≤64 bytes
`define USB_MPS_INTR_HS_MAX     1024    // High-speed: ≤1024 bytes

// Isochronous endpoints
// Source: Section 5.6.3
`define USB_MPS_ISO_FS_MAX      1023    // Full-speed: ≤1023 bytes
`define USB_MPS_ISO_HS_MAX      1024    // High-speed: ≤1024 bytes per transaction
                                        // (up to 3× for high-bandwidth)

// Data field maximum (absolute)
// Source: Section 8.3.4
`define USB_DATA_MAX_BYTES      1024    // Maximum data field size in any packet

//=============================================================================
// SECTION 11: USB TIMING CONSTANTS
// Source: USB 2.0 Specification, Sections 7.1.18, 7.1.7, Table 7-14
//
// All timing values are expressed in the units that are most natural for
// RTL implementation (bit periods or nanoseconds as labeled).
// Actual clock cycle counts depend on the system clock frequency and must
// be computed in each module as a localparam from these spec constants.
//=============================================================================

// --- Bit periods (in nanoseconds, from Section 7.1) ---
// FS: 12 Mbit/s → 1/12e6 s ≈ 83.333 ns per bit
// HS: 480 Mbit/s → 1/480e6 s ≈ 2.083 ns per bit
// LS: 1.5 Mbit/s → 1/1.5e6 s ≈ 666.667 ns per bit
//
// Represented as integer nanoseconds (rounded) for use with integer clock math.
`define USB_FS_BIT_NS            83    // FS bit period ≈ 83 ns (12 Mbit/s)
`define USB_HS_BIT_NS             2    // HS bit period ≈ 2 ns (480 Mbit/s)
`define USB_LS_BIT_NS           667    // LS bit period ≈ 667 ns (1.5 Mbit/s)

// --- SOF frame interval ---
// Source: Section 8.4.3 — SOF sent every 1 ms at FS and HS
// At FS: 1 ms / 83.333 ns ≈ 12,000 bit periods
// At HS: 1 ms / 2.083 ns ≈ 480,000 bit periods (each 125 µs microframe = 60,000)
`define USB_SOF_INTERVAL_NS   1_000_000  // 1 ms in nanoseconds
`define USB_SOF_INTERVAL_FS_BITS  12000  // FS bit periods per frame
`define USB_SOF_INTERVAL_HS_BITS 480000  // HS bit periods per frame (125 µs microframe = 60000)

// --- SE0 reset duration ---
// Source: Section 7.1.7.5 — Reset: SE0 for ≥ 10 ms
`define USB_RESET_SE0_MIN_NS  10_000_000  // 10 ms in nanoseconds
`define USB_RESET_SE0_MIN_FS_BITS  120000 // 10 ms in FS bit periods

// --- Bus turnaround time (inter-packet, token to response) ---
// Source: Section 7.1.18.1
// FS: device must respond within 7.5 bit times (TRSPIPD1 w/ detachable cable)
//     host must respond within 7.5 bit times
// For timeout detection: 16 bit periods is a safe conservative bound at FS.
`define USB_TURNAROUND_FS_BITS    16   // Maximum FS turnaround: 16 bit periods
                                       // (conservative; spec gives 7.5 for device response)

// --- Inter-Packet Delay Spacing (IPDS) ---
// Source: Section 7.1.18.1
// Minimum inter-packet delay: 2 bit periods (both FS device and host)
// HS host driving two sequential packets: minimum 88 bit periods (THSIPDSD)
`define USB_IPDS_FS_MIN_BITS       2   // FS minimum IPDS: 2 bit periods
`define USB_IPDS_HS_MIN_BITS       8   // HS minimum IPDS (device→device): 8 bit periods
`define USB_IPDS_HS_HOST_BITS     88   // HS host back-to-back minimum: 88 bit periods

// --- Suspend and resume timing ---
// Source: Section 7.1.7.6
// Suspend: 3 ms of continuous idle (J state) before device enters suspend
// Resume: host drives K state for at least 20 ms
`define USB_SUSPEND_IDLE_NS    3_000_000   // 3 ms idle before suspend
`define USB_RESUME_K_NS       20_000_000   // 20 ms K-state for resume
`define USB_SUSPEND_IDLE_FS_BITS   36000   // 3 ms in FS bit periods
`define USB_RESUME_K_FS_BITS      240000   // 20 ms in FS bit periods

// --- High-speed chirp timing ---
// Source: Table 7-13 (Section 7.1.7.5)
// Device chirp K duration: 1–7 ms
// Hub must detect chirp K filtered for at least TFILT = 2.5 µs
// Host chirp K burst width: 40–60 µs each, separated by 60 µs
`define USB_HS_CHIRP_DEV_MIN_NS    1_000_000   // Device chirp K minimum: 1 ms
`define USB_HS_CHIRP_DEV_MAX_NS    7_000_000   // Device chirp K maximum: 7 ms
`define USB_HS_CHIRP_FILT_NS           2_500   // Chirp filter duration: 2.5 µs
`define USB_HS_CHIRP_HOST_WIDTH_NS    40_000   // Host chirp K burst: 40 µs minimum
`define USB_HS_CHIRP_HOST_GAP_NS      60_000   // Gap between host chirp bursts: 60 µs

// --- Bit stuffing ---
// Source: Section 7.1.9
// A 0 bit is inserted after every 6 consecutive 1 bits on the TX path.
// The RX path removes the stuffed 0 after 6 consecutive 1 bits.
// If the bit following 6 consecutive 1s is itself a 1, it is a stuff error.
`define USB_BITSTUFF_MAX_ONES      6   // Maximum consecutive 1s before stuff bit

//=============================================================================
// SECTION 12: LINE STATE ENCODINGS
// Source: USB 2.0 Specification, Sections 7.1.1, 7.1.3
//
// FS/LS: Differential signaling
//   J state (FS): D+ high, D- low  (idle for FS)
//   K state (FS): D+ low, D+ high  (start of packet SOP)
//   SE0: both D+ and D- low         (EOP; reset)
//   SE1: both D+ and D- high         (illegal)
//
// These 2-bit line state codes are used by the PHY layer; they do not
// appear in the USB specification as named encodings but are standard
// RTL conventions derived from the spec.
//=============================================================================

`define USB_LS_J    2'b01   // FS Idle; LS Idle for device (D+ low, D- high for LS)
`define USB_LS_K    2'b10   // FS SOP; LS SOP (opposite polarity from J)
`define USB_LS_SE0  2'b00   // Both D+ and D- low; EOP and reset
`define USB_LS_SE1  2'b11   // Both D+ and D- high; illegal state

//=============================================================================
// SECTION 13: EOP (END OF PACKET)
// Source: USB 2.0 Specification, Section 7.1.13
//
// EOP consists of:
//   - Two bit periods of SE0
//   - Followed by one bit period of J (return to idle)
// The EOP is generated by the transmitter after the last CRC bit.
//=============================================================================

`define USB_EOP_SE0_BITS    2   // Number of SE0 bit periods in EOP
`define USB_EOP_J_BITS      1   // Number of J bit periods after SE0 in EOP

//=============================================================================
// SECTION 14: DEFAULT ADDRESS
// Source: USB 2.0 Specification, Section 8.3.2.1
//
// All devices reset to address 0. Address 0 is reserved as the default
// address and may not be permanently assigned to a device.
//=============================================================================

`define USB_DEFAULT_ADDR    7'h00   // Default device address after reset

//=============================================================================
// SECTION 15: SETUP PACKET SIZE
// Source: USB 2.0 Specification, Section 9.3
//
// Every SETUP transaction carries exactly 8 bytes of data in the DATA0
// packet. The 8-byte SETUP packet format is:
//   Byte 0: bmRequestType
//   Byte 1: bRequest
//   Bytes 2-3: wValue (LSB first)
//   Bytes 4-5: wIndex (LSB first)
//   Bytes 6-7: wLength (LSB first)
//=============================================================================

`define USB_SETUP_PKT_BYTES   8   // SETUP data packet is always exactly 8 bytes

// Byte offsets within the SETUP packet
`define USB_SETUP_OFF_BMREQUESTTYPE  0
`define USB_SETUP_OFF_BREQUEST       1
`define USB_SETUP_OFF_WVALUE_L       2
`define USB_SETUP_OFF_WVALUE_H       3
`define USB_SETUP_OFF_WINDEX_L       4
`define USB_SETUP_OFF_WINDEX_H       5
`define USB_SETUP_OFF_WLENGTH_L      6
`define USB_SETUP_OFF_WLENGTH_H      7

`endif // USB_PKG_VH

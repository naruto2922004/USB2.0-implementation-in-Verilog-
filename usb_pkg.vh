`ifndef USB_PKG_VH
`define USB_PKG_VH

// ============================================================================
// Packet Identifiers (PIDs)
// ============================================================================

// Token
`define PID_OUT        4'b0001
`define PID_IN         4'b1001
`define PID_SOF        4'b0101
`define PID_SETUP      4'b1101

// Data
`define PID_DATA0      4'b0011
`define PID_DATA1      4'b1011

// Handshake
`define PID_ACK        4'b0010
`define PID_NAK        4'b1010
`define PID_STALL      4'b1110

// Complete PID bytes
`define PIDBYTE_OUT      8'hE1
`define PIDBYTE_IN       8'h69
`define PIDBYTE_SOF      8'hA5
`define PIDBYTE_SETUP    8'h2D

`define PIDBYTE_DATA0    8'hC3
`define PIDBYTE_DATA1    8'h4B

`define PIDBYTE_ACK      8'hD2
`define PIDBYTE_NAK      8'h5A
`define PIDBYTE_STALL    8'h1E

// ============================================================================
// Packet Field Sizes
// ============================================================================

`define PID_BITS          4
`define PIDBYTE_BITS      8

`define ADDR_BITS         7
`define ENDP_BITS         4
`define FRAME_BITS       11

`define CRC5_BITS         5
`define CRC16_BITS       16

// ============================================================================
// CRC
// ============================================================================

`define CRC5_POLY         5'b00101
`define CRC5_INIT         5'b11111
`define CRC5_RESIDUAL     5'b01100

`define CRC16_POLY       16'h8005
`define CRC16_INIT       16'hFFFF
`define CRC16_RESIDUAL   16'h800D

// ============================================================================
// Sync Patterns
// ============================================================================

`define SYNC_FS          8'b00000001
`define SYNC_BITS        8

// ============================================================================
// Endpoint Types
// ============================================================================

`define EP_TYPE_CONTROL     2'b00
`define EP_TYPE_INTERRUPT   2'b11

`define EP_DIR_OUT          1'b0
`define EP_DIR_IN           1'b1

// ============================================================================
// Descriptor Types
// ============================================================================

`define DESC_DEVICE           8'h01
`define DESC_CONFIGURATION    8'h02
`define DESC_STRING           8'h03
`define DESC_INTERFACE        8'h04
`define DESC_ENDPOINT         8'h05

`define DESC_HID              8'h21
`define DESC_REPORT           8'h22

// ============================================================================
// Standard Requests
// ============================================================================

`define REQ_GET_STATUS         8'h00
`define REQ_CLEAR_FEATURE      8'h01
`define REQ_SET_FEATURE        8'h03
`define REQ_SET_ADDRESS        8'h05
`define REQ_GET_DESCRIPTOR     8'h06
`define REQ_SET_DESCRIPTOR     8'h07
`define REQ_GET_CONFIGURATION  8'h08
`define REQ_SET_CONFIGURATION  8'h09
`define REQ_GET_INTERFACE      8'h0A
`define REQ_SET_INTERFACE      8'h0B
`define REQ_SYNCH_FRAME        8'h0C

// ============================================================================
// bmRequestType
// ============================================================================

// Direction
`define BMRT_DIR_H2D   1'b0
`define BMRT_DIR_D2H   1'b1

// Type
`define BMRT_TYPE_STANDARD   2'b00
`define BMRT_TYPE_CLASS      2'b01
`define BMRT_TYPE_VENDOR     2'b10

// Recipient
`define BMRT_RCPT_DEVICE      5'b00000
`define BMRT_RCPT_INTERFACE   5'b00001
`define BMRT_RCPT_ENDPOINT    5'b00010
`define BMRT_RCPT_OTHER       5'b00011

// Common bmRequestType values
`define BMRT_STD_DEV_H2D    8'h00
`define BMRT_STD_DEV_D2H    8'h80
`define BMRT_STD_IF_H2D     8'h01
`define BMRT_STD_IF_D2H     8'h81
`define BMRT_STD_EP_H2D     8'h02
`define BMRT_STD_EP_D2H     8'h82

// ============================================================================
// Endpoint Packet Sizes
// ============================================================================

`define MPS_CTRL_MIN      8
`define MPS_CTRL_MAX     64

`define MPS_INTR_MAX     64

// ============================================================================
// USB Timing (Full-Speed)
// ============================================================================

`define SOF_INTERVAL_BITS   12000
`define RESET_SE0_BITS     120000

`define TURNAROUND_BITS       16
`define IPDS_MIN_BITS          2

// ============================================================================
// Bit Stuffing
// ============================================================================

`define BITSTUFF_MAX_ONES      6

// ============================================================================
// Bus States
// ============================================================================

`define LS_J      2'b01
`define LS_K      2'b10
`define LS_SE0    2'b00
`define LS_SE1    2'b11

// ============================================================================
// Default Address
// ============================================================================

`define DEFAULT_ADDR    7'h00

// ============================================================================
// Setup Packet
// ============================================================================

`define SETUP_PKT_BYTES      8

`define SETUP_BMREQUESTTYPE  0
`define SETUP_BREQUEST       1
`define SETUP_WVALUE_L       2
`define SETUP_WVALUE_H       3
`define SETUP_WINDEX_L       4
`define SETUP_WINDEX_H       5
`define SETUP_WLENGTH_L      6
`define SETUP_WLENGTH_H      7

`endif
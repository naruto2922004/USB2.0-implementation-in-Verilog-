# USB 2.0 RTL Implementation Roadmap
### Master Engineering Project Plan — Pure Verilog-2001/2005 RTL, Simulation-First

---

> **Engineering Note — PHY Realism:**
> This roadmap describes a complete USB 2.0 RTL implementation, including the PHY layer, and all protocol behavior is fully specified and verifiable in simulation. The synthesizable RTL represents the complete architectural intent. Physical realization of a compliant USB High-Speed PHY analog front-end may ultimately depend on the capabilities of the target implementation technology: an FPGA may require vendor-specific differential I/O primitives and PLLs, and a true HS-compliant ASIC PHY requires custom analog circuits outside the scope of digital RTL. This does not reduce the scope of this project. All USB protocol behavior, all digital logic, all signal processing, all state machines, and all verification objectives described herein are achievable entirely in simulation and in synthesizable Verilog-2001/2005 RTL.

---

## Section 1 — Project Directory Structure

```
usb_rtl/
│
├── rtl/
│   ├── phy/
│   │   ├── tx/
│   │   │   ├── serializer.v            # Parallel-to-serial bit stream converter
│   │   │   ├── nrzi_encoder.v          # TX NRZI encoding
│   │   │   ├── bitstuffer.v            # TX bit insertion (stuff 0 after six 1s)
│   │   │   ├── diff_tx_driver.v        # Differential D+/D- output driver
│   │   │   └── eop_gen.v               # SE0 + J EOP sequence generator
│   │   └── rx/
│   │       ├── diff_rx_sampler.v       # D+/D- differential input sampler
│   │       ├── nrzi_decoder.v          # RX NRZI decoding
│   │       ├── bitunstuffer.v          # RX bit removal and error detection
│   │       ├── deserializer.v          # Serial-to-parallel byte recovery
│   │       ├── sync_detect.v           # SYNC pattern detector
│   │       └── eop_detect.v            # SE0 + J EOP detector
│   │
│   ├── link/
│   │   ├── rx/
│   │   │   ├── packet_rx.v             # RX packet framer (SYNC→PID→payload→CRC→EOP)
│   │   │   ├── pid_decoder.v           # PID byte decode + complement check
│   │   │   └── rx_crc_checker.v        # CRC5/CRC16 residue validation on RX
│   │   └── tx/
│   │       ├── packet_tx.v             # TX packet assembler (SYNC→PID→payload→CRC→EOP)
│   │       ├── pid_encoder.v           # PID encode with complement fill
│   │       └── tx_crc_inserter.v       # CRC5/CRC16 append on TX
│   │
│   ├── protocol/
│   │   ├── packet_classifier.v         # Route decoded PID to correct packet handler
│   │   ├── token/
│   │   │   ├── token_rx.v              # Token packet extractor (ADDR, ENDP, CRC5)
│   │   │   └── token_tx.v              # Token packet generator
│   │   ├── data/
│   │   │   ├── data_rx.v               # DATA0/DATA1/DATA2/MDATA payload extractor
│   │   │   └── data_tx.v               # DATA packet builder
│   │   ├── handshake/
│   │   │   ├── handshake_rx.v          # ACK/NAK/STALL/NYET detector
│   │   │   └── handshake_tx.v          # ACK/NAK/STALL/NYET generator
│   │   └── sof/
│   │       ├── sof_rx.v                # SOF frame number extractor
│   │       └── sof_generator.v         # 1ms SOF frame pulse generator (host only)
│   │
│   ├── transaction/
│   │   ├── control/
│   │   │   ├── setup_tx.v              # SETUP token + DATA0 sequencer
│   │   │   ├── ctrl_data_tx.v          # Control DATA stage TX
│   │   │   ├── ctrl_data_rx.v          # Control DATA stage RX
│   │   │   └── status_stage.v          # STATUS stage sequencer
│   │   ├── bulk/
│   │   │   ├── bulk_tx.v               # BULK OUT transaction engine
│   │   │   └── bulk_rx.v               # BULK IN transaction engine
│   │   ├── interrupt/
│   │   │   ├── intr_tx.v               # Interrupt OUT transaction engine
│   │   │   └── intr_rx.v               # Interrupt IN transaction engine
│   │   ├── isochronous/
│   │   │   ├── iso_tx.v                # Isochronous OUT engine (no handshake, no retry)
│   │   │   └── iso_rx.v                # Isochronous IN engine (no ACK, no retry)
│   │   └── transaction_arbiter.v       # IPDS enforcement and bus arbitration
│   │
│   ├── transfer/
│   │   ├── control_transfer.v          # SETUP + DATA + STATUS multi-transaction sequencer
│   │   ├── bulk_transfer.v             # Multi-packet BULK sequencer with short-packet detection
│   │   ├── interrupt_transfer.v        # Interrupt polling and delivery
│   │   ├── iso_transfer.v              # Isochronous frame-aligned transfer
│   │   └── transfer_mux.v              # Transfer engine selector by endpoint type
│   │
│   ├── endpoint/
│   │   ├── endpoint_toggle.v           # DATA0/DATA1 toggle state machine
│   │   ├── endpoint_fifo_ctrl.v        # Per-endpoint dual-port FIFO controller
│   │   ├── endpoint_stall_ctrl.v       # Per-endpoint STALL assertion and clear
│   │   └── endpoint_engine.v           # Top-level configurable endpoint (parametric)
│   │
│   ├── host/
│   │   ├── port/
│   │   │   ├── port_reset_ctrl.v       # SE0 reset sequencer (>=10ms)
│   │   │   ├── port_speed_detect.v     # FS/HS chirp detection and speed signaling
│   │   │   └── port_suspend_resume.v   # Suspend/resume state machine
│   │   ├── schedule/
│   │   │   ├── host_frame_sched.v      # Master 1ms SOF frame timer
│   │   │   ├── periodic_sched.v        # Interrupt/ISO slot allocator (bInterval tracking)
│   │   │   └── async_sched.v           # Control/BULK queue scheduler (round-robin)
│   │   ├── enumeration/
│   │   │   ├── enum_fsm.v              # Enumeration state machine
│   │   │   ├── get_descriptor_seq.v    # GET_DESCRIPTOR control transfer sequencer
│   │   │   ├── set_address_seq.v       # SET_ADDRESS control transfer sequencer
│   │   │   ├── set_configuration_seq.v # SET_CONFIGURATION control transfer sequencer
│   │   │   └── descriptor_parser.v     # Descriptor byte extractor (class, EP params, ...)
│   │   ├── host_ctrl.v                 # Host controller core FSM
│   │   └── host_top.v                  # Host controller top-level
│   │
│   ├── device/
│   │   ├── dev_address_reg.v           # USB address register (updated by SET_ADDRESS)
│   │   ├── dev_config_reg.v            # Configuration value register (SET_CONFIGURATION)
│   │   ├── descriptor_rom.v            # Descriptor ROM (Device/Config/Interface/EP/String)
│   │   ├── get_descriptor_resp.v       # GET_DESCRIPTOR response segmenter
│   │   ├── std_request_handler.v       # Chapter 9 standard requests FSM
│   │   ├── device_ctrl.v               # Device controller core FSM
│   │   └── device_top.v                # Device controller top-level
│   │
│   └── shared/
│       ├── crc/
│       │   ├── crc5_engine.v           # Serial CRC-5 engine (token packets)
│       │   └── crc16_engine.v          # Serial CRC-16 engine (data packets)
│       └── fifo/
│           ├── sync_fifo.v             # Parameterized single-clock FIFO
│           └── async_fifo.v            # Parameterized gray-code dual-clock FIFO
│
├── sim/
│   ├── models/
│   │   └── phy_wire_model.v            # Simulation-only D+/D- wire propagation model
│   └── tb/
│       ├── tb_crc.v                    # CRC-5 and CRC-16 spec vector test
│       ├── tb_bitstuff.v               # Bit stuffer/unstuffer stress and error injection
│       ├── tb_nrzi.v                   # NRZI encode/decode round-trip fidelity
│       ├── tb_phy.v                    # PHY TX/RX loopback through wire model
│       ├── tb_link_layer.v             # Packet framer: all PID types, CRC error injection
│       ├── tb_protocol_layer.v         # Classifier + field extractors, SOF timing
│       ├── tb_endpoint_engine.v        # Toggle, STALL, FIFO corner cases
│       ├── tb_transaction_engine.v     # NAK stress, STALL, turnaround timeout
│       ├── tb_transfer_engine.v        # Short packet, ZLP, missed ISO frame
│       ├── tb_device_ctrl.v            # Chapter 9 request coverage
│       ├── tb_enumeration.v            # Host enumeration: connect to ACTIVE
│       ├── tb_host_device_loopback.v   # Full Host <-> Device integration
│       └── tb_usb_keyboard_system.v    # HID keyboard end-to-end demonstration
│
├── pkg/
│   └── usb_pkg.vh                      # USB 2.0 spec constants only (no impl details)
│
├── vectors/
│   ├── crc5_vectors.txt                # USB 2.0 spec Appendix CRC-5 test vectors
│   └── crc16_vectors.txt               # USB 2.0 spec Appendix CRC-16 test vectors
│
└── scripts/
    └── run_sim.sh                      # Simulation runner script
```

> **Architecture Note — Directory Structure:**
> The file names and directory layout above represent one reasonable starting organization and should be treated as recommendations, not mandates. Modules may be merged if they are always instantiated together and share most of their interface signals. Modules may be split if any single file grows to uncomfortable complexity. The `shared/clk/` subdirectory and a `clk_divider.v` utility are omitted from the initial tree; introduce a clock divider or prescaler only when the need for one arises naturally during implementation rather than speculatively.

---

## Section 2 — Module Dependency Order

```
[Bottom-Up Implementation Order]

crc5_engine + crc16_engine
        │
sync_fifo + async_fifo
        │
nrzi_encoder + nrzi_decoder
        │
bitstuffer + bitunstuffer
        │
sync_detect + eop_detect
        │
serializer + deserializer
        │
diff_tx_driver + eop_gen
diff_rx_sampler
        │
        ▼
   [PHY TX path]           [PHY RX path]
serializer                 diff_rx_sampler
bitstuffer                 nrzi_decoder
nrzi_encoder               bitunstuffer
diff_tx_driver             deserializer
eop_gen                    sync_detect
                           eop_detect
        │                        │
        └──────── phy_wire_model ─┘
                        │
                        ▼
              pid_encoder + pid_decoder
              tx_crc_inserter + rx_crc_checker
                        │
              packet_tx + packet_rx
                        │
                        ▼
              packet_classifier
                        │
         ┌──────────────┼──────────────┬──────────────┐
         ▼              ▼              ▼              ▼
    token_rx/tx    data_rx/tx   handshake_rx/tx   sof_rx
    sof_generator
                        │
                        ▼
              endpoint_toggle
              endpoint_fifo_ctrl
              endpoint_stall_ctrl
                        │
              endpoint_engine (parametric)
                        │
                        ▼
         ┌──────────────┼──────────────┬──────────────┐
         ▼              ▼              ▼              ▼
    setup_tx       bulk_tx/rx     intr_tx/rx     iso_tx/rx
    ctrl_data_tx/rx
    status_stage
                        │
              transaction_arbiter
                        │
                        ▼
         ┌──────────────┼──────────────┬──────────────┐
         ▼              ▼              ▼              ▼
 control_transfer  bulk_transfer  interrupt_transfer  iso_transfer
                        │
              transfer_mux
                        │
         ┌──────────────┴───────────────┐
         ▼                             ▼
   [DEVICE PATH]                 [HOST PATH]
dev_address_reg              host_frame_sched
dev_config_reg               periodic_sched
descriptor_rom               async_sched
get_descriptor_resp          port_reset_ctrl
std_request_handler          port_speed_detect
device_ctrl                  port_suspend_resume
device_top                   enum_fsm
                             get_descriptor_seq
                             set_address_seq
                             set_configuration_seq
                             descriptor_parser
                             host_ctrl
                             host_top
         │                             │
         └──────────────┬──────────────┘
                        │
               phy_wire_model
                        │
              tb_host_device_loopback
                        │
              tb_usb_keyboard_system
                   [Final Integration]
```

---

## Section 3 — Implementation Phases

---

### Phase 0 — Project Foundation

**Goal:**
Establish the project directory, version control, and the USB 2.0 specification constants file. Nothing in this phase assumes how the RTL will be architected. No interfaces, no module skeletons, no bus definitions.

**Items to Complete:**
- Directory tree created as shown in Section 1 and committed to version control
- `usb_pkg.vh` — Specification constants file containing:
  - All 16 PID encodings from USB 2.0 spec Table 8-1 (TOKEN, DATA, HANDSHAKE, SPECIAL groups)
  - CRC-5 polynomial (G(X) = X⁵+X²+1) and residue constant
  - CRC-16 polynomial (G(X) = X¹⁶+X¹⁵+X²+1) and residue constant
  - Standard descriptor type codes (Device, Configuration, Interface, Endpoint, String, HID, Report, Physical, Device_Qualifier, Other_Speed_Configuration, Interface_Power)
  - Standard request codes (GET_STATUS, CLEAR_FEATURE, SET_FEATURE, SET_ADDRESS, GET_DESCRIPTOR, SET_DESCRIPTOR, GET_CONFIGURATION, SET_CONFIGURATION, GET_INTERFACE, SET_INTERFACE, SYNCH_FRAME)
  - Packet field widths: ADDR (7 bits), ENDP (4 bits), Frame Number (11 bits), PID (8 bits: 4-bit PID + 4-bit complement), CRC-5 (5 bits), CRC-16 (16 bits)
  - Maximum packet sizes per speed and transfer type (see Section 5 for the full table)
  - USB timing constants: FS bit period (1/12 MHz), HS bit period (1/480 MHz), LS bit period (1/1.5 MHz), turnaround time (16 bit periods at FS), IPDS (2 bit periods minimum), SE0 reset duration (≥10 ms), chirp detection timing, suspend idle threshold (3 ms), resume K-state duration (20 ms)
  - SYNC field patterns: KJKJKJKK (FS/LS, 8 bits), extended 32-bit pattern (HS)
  - Endpoint type codes: Control, Bulk, Interrupt, Isochronous
  - Feature selector codes: ENDPOINT_HALT (0x00), DEVICE_REMOTE_WAKEUP (0x01), TEST_MODE (0x02)
- `scripts/run_sim.sh` — Simulation runner script for the chosen simulator
- `README` — Project scope and Verilog-2001/2005 coding conventions
- `vectors/crc5_vectors.txt` and `vectors/crc16_vectors.txt` — Reference test vectors from USB 2.0 specification Appendix

**Dependencies:**
- None. This phase has no RTL prerequisites.

**Deliverables:**
- Full directory tree version-controlled
- `usb_pkg.vh` containing all specification constants listed above

**Verification Goal:**
- `usb_pkg.vh` compiles cleanly in the target simulator with zero warnings or errors
- All PID values cross-checked manually against USB 2.0 specification Table 8-1
- CRC polynomial constants verified against USB 2.0 specification Section 8.3

**Completion Criteria:**
- Directory tree exists and is version-controlled
- `usb_pkg.vh` compiles without errors
- No module has been defined; no interface has been specified; no bus has been named

---

### Phase 1 — Signal Processing Primitives

**Goal:**
Build the fundamental signal processing building blocks that every higher layer depends on: CRC engines, NRZI codec, bit stuffing codec, SYNC detection, EOP detection, deserializer/serializer, and utility FIFOs. These are implemented and verified independently before being composed into larger structures.

**Required Functionality:**

The following functional capabilities must exist by the end of this phase. How they are partitioned into RTL modules is an implementation decision.

*CRC computation:*
- Serial CRC-5 computation using G(X) = X⁵+X²+1; running CRC output with synchronous reset per packet; residue 0x0C identifies a valid received token field
- Serial CRC-16 computation using G(X) = X¹⁶+X¹⁵+X²+1; running CRC output with synchronous reset per packet; residue 0x800D identifies a valid received data packet

*FIFO buffering:*
- Parameterized single-clock FIFO with full/empty flags and overflow/underflow protection
- Parameterized dual-clock gray-code pointer FIFO for any required clock domain crossings

*NRZI codec:*
- TX: toggle output on 0 input, hold output on 1 input; registered; operates at bit clock
- RX: output 0 on transition, output 1 on no transition; registered; operates at bit clock

*Bit stuffing codec:*
- TX: count consecutive 1 bits on the output bit stream; insert a 0 bit after six consecutive 1 bits and reset the count
- RX: count consecutive 1 bits on the input bit stream; remove the stuffed 0 after six consecutive 1 bits; assert a `stuff_error` flag if the removed bit is 1 (a protocol violation)

*SYNC detection:*
- Shift-register comparison against the SYNC pattern from `usb_pkg.vh` (KJKJKJKK for FS/LS, extended for HS)
- Assert a one-cycle `sync_detected` pulse at the bit immediately following the last SYNC bit
- Zero false triggers on idle line state or random data patterns

*EOP detection:*
- Monitor for SE0 lasting at least the minimum specified duration followed by J state
- Assert `eop_detected` at the end of the SE0 window
- Reject glitches shorter than the minimum SE0 duration

**Recommended RTL Organization:**

The suggested starting decomposition:
- `rtl/shared/crc/crc5_engine.v` — CRC-5 engine
- `rtl/shared/crc/crc16_engine.v` — CRC-16 engine
- `rtl/shared/fifo/sync_fifo.v` — Single-clock FIFO
- `rtl/shared/fifo/async_fifo.v` — Dual-clock gray-code FIFO
- `rtl/phy/rx/nrzi_decoder.v` — RX NRZI decoder
- `rtl/phy/rx/bitunstuffer.v` — RX bit unstuffer with error detection
- `rtl/phy/rx/sync_detect.v` — SYNC pattern detector
- `rtl/phy/rx/eop_detect.v` — EOP detector
- `rtl/phy/tx/nrzi_encoder.v` — TX NRZI encoder
- `rtl/phy/tx/bitstuffer.v` — TX bit stuffer

If, during implementation, it is natural to combine NRZI encoding and bit stuffing into a single module, or to combine SYNC and EOP detection into a single line-state monitor, those are acceptable architectural decisions. The functional requirements above remain unchanged.

> **Utility Note:** Introduce a clock divider or prescaler module only if and when the implementation requires one to generate a bit-rate clock from the system clock. Do not create it speculatively.

**Dependencies:**
- Phase 0: `usb_pkg.vh` (SYNC pattern constant, CRC polynomial constants, timing constants)

**Deliverables:**
- All signal processing functionality fully implemented and individually compilable
- All functionality independently verified by testbench before Phase 2 begins

**Verification Goal:**
- `tb_crc.v`:
  - Feed all test vectors from `vectors/crc5_vectors.txt` and `vectors/crc16_vectors.txt` into respective engines; verify bit-exact output match for every vector
  - Verify CRC residue constant correctly identifies a valid received packet; verify an intentionally corrupted packet fails residue check
- `tb_nrzi.v`:
  - Encode a randomized byte sequence with the NRZI encoder and decode with the NRZI decoder; verify bit-exact round-trip fidelity for all 256 byte values (0x00 through 0xFF)
  - Verify encode→decode is transparent for boundary cases: all-zeros, all-ones, alternating bits
- `tb_bitstuff.v`:
  - Inject a stream containing exactly 6 consecutive 1 bits followed by a 0; verify the TX stuffer inserts one additional 0 and the RX unstuffer removes it transparently
  - Inject a stream with 7 consecutive 1 bits (missing stuff bit on RX); verify `stuff_error` is asserted
  - Exercise TX stuffer followed immediately by RX unstuffer with long-duration randomized input data covering all byte values and boundary conditions; verify zero data corruption and zero false stuff errors
- SYNC detection:
  - Verify `sync_detected` asserted at the correct bit position on a valid SYNC sequence
  - Verify zero false triggers across extended randomized idle and random data patterns
- EOP detection:
  - Verify SE0 duration threshold is enforced; verify J state requirement is checked
  - Inject SE0 shorter than minimum duration; verify no false `eop_detected`
  - Verify correct `eop_detected` at the boundary-exact minimum SE0 duration
- FIFO:
  - Exercise full, empty, simultaneous read-write, overflow guard, and underflow guard for both FIFO variants
  - For the async FIFO: verify correct pointer behavior across asynchronous clock domain pairs with varying frequency relationships

**Completion Criteria:**
- CRC-5 and CRC-16 outputs match all specification test vectors bit-exactly
- NRZI encode→decode is transparent for all 256 byte values and boundary patterns
- Bit stuff/unstuff round-trip produces zero data corruption and zero false errors over comprehensive randomized testing
- SYNC false-positive rate is zero across extended idle and random data patterns
- EOP minimum duration threshold enforced with zero false triggers below threshold
- All FIFOs pass full/empty/boundary corner cases without data corruption

---

### Phase 2 — RTL PHY: Transmit and Receive Paths

**Goal:**
Compose the Phase 1 primitives into complete synthesizable transmit and receive signal paths, and build the simulation-only wire model that connects host and device PHY instances in loopback. This phase produces the project's first functional end-to-end bit path.

**Required Functionality:**

*TX path — the following must exist:*
- Parallel-to-serial conversion: accept parallel byte input with a valid strobe; output serial bits synchronized to the bit clock; interface with the bit stuffer and NRZI encoder from Phase 1
- Differential output driving: convert the NRZI-encoded bit to D+ and D- output levels per USB line-state rules (J = D+ high / D- low for FS; K = D+ low / D- high for FS; SE0 = both low; SE1 is illegal and must never be driven)
- EOP generation: on TX completion, override the normal TX path to drive SE0 for exactly two bit periods, then release to J (idle); synchronize with the serializer end-of-packet indication

*RX path — the following must exist:*
- Differential input sampling: sample D+ and D- at bit clock edges; decode line state (J, K, SE0, SE1); output the received bit to the NRZI decoder; detect idle line state; detect device connect and disconnect events based on D+/D- pull-up states
- Serial-to-parallel conversion: accumulate serial bits from the unstuffer output into parallel bytes; assert a byte-valid strobe; gating by `sync_detect` to begin accumulation only after SYNC reception; halt on `eop_detect`

*Simulation wire model — the following must exist:*
- Bidirectional D+ and D- propagation between a host PHY instance and a device PHY instance
- Configurable propagation delay in bit periods
- Optional glitch injection for robustness testing
- Zero USB protocol logic; must never appear in synthesizable RTL hierarchy

**Recommended RTL Organization:**

- `rtl/phy/tx/serializer.v` — Parallel-to-serial converter
- `rtl/phy/tx/diff_tx_driver.v` — D+/D- output driver
- `rtl/phy/tx/eop_gen.v` — EOP SE0+J generator
- `rtl/phy/rx/diff_rx_sampler.v` — D+/D- sampler and line-state decoder
- `rtl/phy/rx/deserializer.v` — Serial-to-parallel byte accumulator
- `sim/models/phy_wire_model.v` — Simulation-only wire propagation model

If the serializer, bit stuffer, and NRZI encoder are more naturally implemented as a single module, that is a valid architectural decision. The functional requirements are unchanged.

**Dependencies:**
- Phase 1: NRZI encoder/decoder, bit stuffer/unstuffer, SYNC detector, EOP detector

**Deliverables:**
- Complete synthesizable TX path from parallel byte to D+/D- output
- Complete synthesizable RX path from D+/D- input to parallel byte output with byte-valid strobe
- Simulation wire model connecting two PHY instances in loopback
- First passing end-to-end loopback test

**Verification Goal:**
- `tb_phy.v`:
  - Drive a known byte sequence into the TX path; observe correct NRZI-encoded D+/D- transitions at the differential output
  - Connect host TX path to device RX path through `phy_wire_model`; verify byte-exact loopback for all 256 byte values
  - Inject SE0 from the host side via EOP generation; verify EOP detection on the device RX side asserts at the correct bit position
  - Verify SYNC field propagates end-to-end and SYNC detection triggers at the correct bit position on the device side
  - Verify a bit stuffing event is handled transparently end-to-end (byte in equals byte out)
  - Run long-duration randomized byte traffic through the full loopback path; verify zero byte errors across all boundary conditions

**Completion Criteria:**
- End-to-end byte loopback is transparent for all 256 byte values
- SYNC detection triggers at the correct bit position end-to-end through the wire model
- EOP correctly detected end-to-end with zero false triggers
- Bit stuffing is transparent across the full loopback path
- Zero byte errors in long-duration randomized traffic simulation

---

### Phase 3 — Link Layer: Packet Framing

**Goal:**
Build the packet framer that converts the raw byte stream from the PHY into structured USB packets with PID validation and CRC checking, and the packet assembler that converts structured packet data back into a raw byte stream for the TX path. The link layer understands packet boundaries, PID fields, and CRC, but does not interpret packet semantics.

**Required Functionality:**

*RX packet framing — the following must exist:*
- PID extraction: extract the PID byte from the first received byte; validate the complement check (PID[3:0] == ~PID[7:4]); output the decoded 4-bit PID; assert a `pid_error` on complement violation
- CRC validation: feed received payload bytes into the running CRC engine (CRC-5 for token packets, CRC-16 for data packets, selected by PID type); assert a `crc_ok` flag when the residue check passes at EOP; assert a `crc_error` flag on residue mismatch
- Packet framing: wait for `sync_detected`; receive PID byte, payload bytes, and EOP; at EOP signal the upper layer with a packet-received indication and whatever fields naturally emerge from implementation; discard packets with PID errors or CRC errors and report the error condition

*TX packet assembly — the following must exist:*
- PID encoding: accept a 4-bit PID input and output the 8-bit PID byte with the complement field filled (PID[7:4] = ~PID[3:0])
- CRC appending: accept payload bytes; feed them into the running CRC engine in parallel; append CRC-5 or CRC-16 (selected by packet type) after the last payload byte in the correct bit order per specification
- Packet assembly: prefix SYNC pattern; encode PID; transmit payload bytes with CRC; drive EOP generation at packet end; drive the PHY byte stream input

**Recommended RTL Organization:**

*rtl/link/rx/:*
- `pid_decoder.v` — PID complement check and 4-bit PID output
- `rx_crc_checker.v` — CRC-5/CRC-16 residue validation
- `packet_rx.v` — RX packet framer top-level

*rtl/link/tx/:*
- `pid_encoder.v` — 4-bit to 8-bit PID encoding with complement
- `tx_crc_inserter.v` — CRC computation and payload append
- `packet_tx.v` — TX packet assembler top-level

It is architecturally valid to implement PID decoding inside `packet_rx` rather than as a separate module, or to implement CRC checking inside `packet_rx` directly. The functional requirements — PID complement validation, CRC residue checking, and packet boundary framing — are mandatory regardless of how the code is organized.

**Dependencies:**
- Phase 1: CRC-5 engine, CRC-16 engine, SYNC detector, EOP detector
- Phase 2: PHY RX byte stream output, PHY TX byte stream input

**Deliverables:**
- Functional packet RX framer producing valid packet indications with PID and payload
- Functional packet TX assembler accepting packet inputs and driving the PHY
- PID complement error detection and CRC error detection both operational

**Verification Goal:**
- `tb_link_layer.v`:
  - Feed raw byte sequences for each packet type (SOF, IN, OUT, SETUP, PING, DATA0, DATA1, DATA2, MDATA, ACK, NAK, STALL, NYET, PRE/ERR, SPLIT) into the RX framer; verify correct PID decoding and payload capture for each
  - Inject a packet with an intentional CRC-16 error in the payload; verify `crc_error` asserted and packet flagged as invalid
  - Inject a packet with an intentional CRC-5 error in a token; verify `crc_error` asserted
  - Inject a packet with invalid PID complement (PID[7:4] != ~PID[3:0]); verify `pid_error` asserted
  - Assemble each packet type with the TX assembler; route through `phy_wire_model`; receive with the RX framer; verify byte-exact match for all packet types
  - Run long-duration randomized packet injection with intentional CRC errors; verify zero false CRC passes

**Completion Criteria:**
- All 16 PID types decode correctly with zero misidentification
- CRC-5 errors and CRC-16 errors each reliably detected with zero false passes across comprehensive randomized error injection
- TX-to-RX loopback through `phy_wire_model` is packet-lossless for all packet types

---

### Phase 4 — Protocol Layer: Packet Classification and Field Extraction

**Goal:**
Decode the structured packet output from the link layer into semantic USB packet types — token, data, handshake, SOF — and extract all protocol-level fields. Build the corresponding generators for each packet type on TX. The interface between the link layer and the protocol layer will emerge naturally during implementation of these two phases; it is not pre-defined.

**Required Functionality:**

*Packet classification — the following must exist:*
- Inspect the decoded PID from the link layer and route the packet indication to the correct handler (token, data, handshake, or SOF) based on the PID group bits [1:0] per USB 2.0 Table 8-1; classify SPECIAL PIDs (PRE/ERR, SPLIT, PING, Reserved) without misrouting them as token, data, or handshake packets

*Token packet handling — the following must exist:*
- RX: extract ADDR[6:0], ENDP[3:0], and CRC5 from IN, OUT, SETUP, and PING tokens; extract Frame Number[10:0] from SOF tokens; validate CRC-5 on all token fields
- TX: generate token packets from ADDR, ENDP, and PID inputs; compute and append CRC-5; drive the link layer TX path

*Data packet handling — the following must exist:*
- RX: receive payload bytes; capture the toggle PID (DATA0, DATA1, DATA2, MDATA); present payload bytes with byte-valid strobes to the layer above; preserve toggle PID identity through the receive path
- TX: build a DATA packet from a payload input and a PID input (DATA0, DATA1, DATA2, or MDATA); drive the link layer TX path

*Handshake packet handling — the following must exist:*
- RX: detect and classify ACK, NAK, STALL, and NYET from the decoded PID; assert the appropriate output flag to the transaction layer
- TX: generate ACK, NAK, STALL, or NYET packet on a command input; drive the link layer TX path

*SOF handling — the following must exist:*
- RX: extract the 11-bit frame number from a received SOF token; present to the host logic
- TX (host only): generate one SOF token per 1ms frame interval at Full Speed; maintain a monotonically incrementing 11-bit frame counter wrapping at 2048; the master frame boundary pulse output must be the sole timing reference for all frame-periodic host operations; the SOF frame counter must not wrap with a gap — it must be continuous

**Recommended RTL Organization:**

- `rtl/protocol/packet_classifier.v` — PID group routing
- `rtl/protocol/token/token_rx.v` and `token_tx.v` — Token field extraction and generation
- `rtl/protocol/data/data_rx.v` and `data_tx.v` — Data payload extraction and assembly
- `rtl/protocol/handshake/handshake_rx.v` and `handshake_tx.v` — Handshake classification and generation
- `rtl/protocol/sof/sof_rx.v` and `sof_generator.v` — SOF frame number extraction and SOF emission

If the packet classifier is more naturally implemented as part of `packet_rx`, that is an acceptable architectural decision. The functional requirement — correct routing of all 16 PID types — is mandatory.

**Dependencies:**
- Phase 3: link layer packet framer and assembler

**Deliverables:**
- Complete bidirectional packet codec for all USB 2.0 packet types (excluding split transactions)
- Packet classifier correctly routing all 16 PID types to their handlers

**Verification Goal:**
- `tb_protocol_layer.v`:
  - Drive SOF, IN, OUT, SETUP, PING, DATA0, DATA1, DATA2, MDATA, ACK, NAK, STALL, NYET, PRE/ERR, SPLIT, and Reserved packets through the classifier; verify the correct handler receives each with the correct fields
  - Verify token field extraction produces correct ADDR and ENDP for all valid address (0–127) and endpoint (0–15) combinations, including address 0 endpoint 0
  - Verify `sof_generator` produces exactly one SOF per 1ms with a monotonically incrementing 11-bit frame number over many consecutive frames; verify frame number wraps correctly at 2047→0
  - Verify all four handshake types (ACK, NAK, STALL, NYET) are correctly distinguished on RX with zero misclassification
  - Verify DATA0 and DATA1 toggle PID is correctly preserved through the data RX path
  - Verify DATA2 and MDATA are recognized (required for HS high-bandwidth transfers)
  - Verify PING token is recognized and not misrouted as an IN or OUT token

**Completion Criteria:**
- Classifier never misroutes any of the 16 PID types
- Token field extraction matches the USB 2.0 specification bit layout for all address and endpoint combinations
- SOF frame number increments monotonically with timing accuracy within specification limits over many consecutive frames
- All four handshake types distinguished with zero misclassification

---

### Phase 5 — Endpoint Engine

**Goal:**
Implement the configurable endpoint primitive that all transaction engines use. The endpoint engine is the core reusable hardware block of the project. Its internal decomposition into sub-modules will emerge from implementation; the modules listed below are starting points, not fixed requirements.

**Required Functionality:**

The following capabilities must exist in the endpoint engine, however they are organized internally:

*Toggle management — the following must exist:*
- Per-endpoint DATA0/DATA1 toggle state: flip on every successfully ACKed transaction; hold on NAK, error, or timeout; reset to DATA0 on USB bus reset, configuration change (SET_CONFIGURATION), STALL assertion, or CLEAR_FEATURE(ENDPOINT_HALT)
- SETUP transactions must always use DATA0 and must never cause a toggle flip, regardless of ACK receipt
- Toggle state must be readable by the transaction layer at the time each transaction is initiated

*FIFO buffering — the following must exist:*
- Per-endpoint FIFO: for IN endpoints, application logic writes and the transaction layer reads; for OUT endpoints, the transaction layer writes and application logic reads
- Flow control: the transaction layer must be able to determine whether data is available (IN) or buffer space is available (OUT) before initiating a transaction
- Overflow and underflow conditions must be flagged without corrupting previously buffered data
- FIFO must be empty and all pointers zeroed within one clock cycle of synchronous reset deassertion

*STALL control — the following must exist:*
- Per-endpoint STALL flag: asserted by the standard request handler or application logic; cleared by CLEAR_FEATURE(ENDPOINT_HALT) on that endpoint
- When STALL is asserted, the endpoint must return STALL to the transaction layer regardless of toggle or FIFO state
- Clearing STALL via CLEAR_FEATURE must also reset the toggle to DATA0

*Parametric configuration — the following must exist:*
- Endpoint number (0–15) configurable by parameter
- Direction (IN, OUT, or bidirectional for Control) configurable by parameter
- Transfer type (Control, Bulk, Interrupt, Isochronous) configurable by parameter
- Maximum packet size configurable by parameter; must match the wMaxPacketSize in the endpoint's descriptor
- Endpoint 0 must always be configured as Control type

**Recommended RTL Organization:**

- `rtl/endpoint/endpoint_toggle.v` — Toggle state machine
- `rtl/endpoint/endpoint_fifo_ctrl.v` — FIFO controller built on the Phase 1 FIFO
- `rtl/endpoint/endpoint_stall_ctrl.v` — STALL flag and CLEAR_FEATURE handler
- `rtl/endpoint/endpoint_engine.v` — Parametric top-level instantiating the above

These sub-modules may be merged into `endpoint_engine.v` if the implementation naturally flows that way. The functional requirements are unchanged.

**Dependencies:**
- Phase 1: `sync_fifo`

**Deliverables:**
- A single parametric endpoint engine instantiatable with endpoint number, direction, transfer type, and max packet size
- Verified against Control, Bulk, Interrupt, and Isochronous configurations

**Verification Goal:**
- `tb_endpoint_engine.v`:
  - Instantiate an endpoint configured as INTERRUPT IN, max 8 bytes
  - Write 8 bytes from the application side; trigger an IN transaction from the transaction side; verify correct 8-byte output with DATA0 toggle PID
  - Trigger a second IN transaction; verify toggle has flipped to DATA1
  - Trigger a third IN transaction returning NAK; verify toggle has not changed
  - Assert STALL; verify the endpoint signals STALL to the transaction side regardless of FIFO contents
  - Issue CLEAR_FEATURE(ENDPOINT_HALT); verify STALL is cleared and toggle is reset to DATA0
  - Overflow the FIFO; verify overflow flag asserted with no corruption of previously buffered bytes
  - Underflow the FIFO (transaction-side read with empty buffer); verify underflow flag asserted
  - Simulate a SETUP transaction; verify DATA0 is used and toggle does not flip on ACK
  - Simulate a bus reset; verify toggle resets to DATA0 and FIFO pointers clear

**Completion Criteria:**
- Toggle never fails to flip on a successfully ACKed non-SETUP transaction
- Toggle never flips on NAK, error, timeout, or SETUP
- STALL clears correctly and resets toggle to DATA0
- FIFO overflow and underflow both flagged without data corruption
- All pointers and flags clear within one clock cycle of synchronous reset

---

### Phase 6 — Transaction Layer

**Goal:**
Build the state machines that execute single USB transactions: one token, optionally one data packet, and optionally one handshake. Each transaction engine handles exactly one transaction type for one transfer type. The transaction layer is unaware of multi-transaction sequencing. Transaction engines drive and consume protocol-layer packets from Phase 4 and interact with the endpoint engine from Phase 5. The exact interface signals between these layers will emerge during implementation.

**Required Functionality:**

The following transaction sequences must be correctly implemented. Internal state machine organization is an implementation decision.

*Control transfer transaction engines — the following must exist:*
- SETUP stage execution: send SETUP token followed by 8-byte DATA0 (the request packet); wait for device ACK; complete or report error on timeout or unexpected response
- Control data stage TX: send OUT token followed by DATAx; handle NAK by retrying with a configurable retry limit; halt immediately on STALL and propagate STALL upward; advance toggle on ACK
- Control data stage RX: send IN token; receive DATAx; send ACK; validate toggle; report error on toggle mismatch; handle NAK by retrying
- STATUS stage: execute the STATUS stage: for device-to-host transfers, send OUT token with zero-length DATA1; for host-to-device transfers, send IN token and expect zero-length DATA1; handle NAK on status; complete or report error

*Bulk transaction engines — the following must exist:*
- Bulk OUT: send OUT token followed by DATAx; handle NAK by retrying with a configurable retry limit; halt immediately on STALL
- Bulk IN: send IN token; receive DATAx; send ACK; handle NAK by re-polling; halt immediately on STALL; correct retry count must be bounded and not loop indefinitely

*Interrupt transaction engines — the following must exist:*
- Interrupt OUT: send OUT token followed by DATAx at an interrupt endpoint; on NAK, defer to the next polling interval without retrying within the same frame
- Interrupt IN: send IN token at an interrupt endpoint; receive DATA or NAK; on NAK defer to next polling interval without retrying within the same frame

*Isochronous transaction engines — the following must exist:*
- ISO OUT: send OUT token followed by DATA0 at a SOF-aligned time slot; generate no handshake under any condition; perform no retry under any condition whatsoever; report completion immediately after the data packet is sent
- ISO IN: send IN token at a SOF-aligned time slot; receive DATA; generate no ACK under any condition; perform no retry under any condition whatsoever; any received data is presented to the transfer layer; no response is treated as a missed frame

*Bus arbitration and inter-packet timing — the following must exist:*
- Serialized access to the protocol layer from multiple transaction engines: only one transaction engine may drive the bus at any time
- Inter-packet delay (IPDS) enforcement: a minimum gap of at least 2 bit periods must be enforced between consecutive packets; all IPDS enforcement lives in the arbiter and nowhere else; no transaction engine pads inter-packet timing independently
- Turnaround timeout: if no device response arrives within the specification-defined turnaround window (16 bit periods at FS) after a token or data packet, assert `turnaround_timeout` to the requesting engine; this is distinct from a NAK response

**Recommended RTL Organization:**

- `rtl/transaction/control/setup_tx.v`, `ctrl_data_tx.v`, `ctrl_data_rx.v`, `status_stage.v`
- `rtl/transaction/bulk/bulk_tx.v`, `bulk_rx.v`
- `rtl/transaction/interrupt/intr_tx.v`, `intr_rx.v`
- `rtl/transaction/isochronous/iso_tx.v`, `iso_rx.v`
- `rtl/transaction/transaction_arbiter.v`

Control TX and RX for the data stage may be merged if implementation makes them naturally interdependent. The SETUP and STATUS stages are distinct enough to remain separate. The functional requirements are unchanged.

**Dependencies:**
- Phase 4: all protocol layer packet codecs (token, data, handshake generators and receivers)
- Phase 5: endpoint engine

**Deliverables:**
- Transaction engines for all four USB transfer types (Control, Bulk, Interrupt, Isochronous), individually verified
- `transaction_arbiter` enforcing correct inter-packet timing on the shared bus
- NAK retry with configurable retry limit in Bulk and Control engines

**Verification Goal:**
- `tb_transaction_engine.v`:
  - `setup_tx`: drive a known 8-byte SETUP payload; verify correct SETUP token + DATA0 sequence emitted; inject ACK response; verify completion flag asserted
  - `bulk_rx`: inject NAK three consecutive times, then DATA0; verify three retries followed by successful data capture and ACK; verify toggle advances only on the ACK
  - `intr_rx`: inject NAK; verify deferred-to-next-frame flag asserted; verify no immediate retry within the same frame
  - `iso_rx`: inject DATA; verify no ACK packet is generated; verify still no ACK on a subsequent frame; verify a missing device response is reported as a missed frame rather than triggering retry
  - `transaction_arbiter`: drive two transaction engines simultaneously; verify IPDS-compliant gap between consecutive packets; verify only one engine drives the bus at a time
  - Turnaround timeout: drive no device response for the full turnaround window; verify `turnaround_timeout` flag asserted; verify this is distinct from a NAK (NAK requires a response packet; timeout requires no response)
  - STALL: inject STALL on a bulk OUT; verify the engine halts immediately and propagates STALL upward without retrying

**Completion Criteria:**
- No transaction engine violates inter-packet delay; all IPDS enforced exclusively by the arbiter
- NAK retry count is bounded and configurable; does not loop indefinitely
- STALL propagates as an error to the layer above without any retry
- Turnaround timeout is correctly distinguished from a NAK response
- ISO transaction engines generate zero handshake packets and perform zero retries under all conditions

---

### Phase 7 — Transfer Layer

**Goal:**
Build the multi-transaction sequencers for each USB transfer type. While the transaction layer executes single transactions, the transfer layer sequences multiple transactions to complete a full USB transfer as defined by the USB 2.0 specification.

**Required Functionality:**

*Control transfer sequencing — the following must exist:*
- SETUP stage → optional DATA stage → STATUS stage sequencing
- Correct toggle PID management at each stage per specification: SETUP always uses DATA0; DATA stage alternates starting from DATA1; STATUS stage uses DATA1
- Transfer completion reporting with result codes: success, STALL, timeout, error
- Handling all response combinations at each stage without deadlock: ACK, NAK (retry within retry limit), STALL (halt and report), turnaround timeout (halt and report)

*Bulk transfer sequencing — the following must exist:*
- Multiple BULK IN or OUT transactions sequenced across packet boundaries
- Short packet detection on IN: a packet shorter than MaxPacketSize signals transfer completion; a full-size packet signals that more data follows
- Zero-length packet (ZLP) handling: a ZLP on IN after a MaxPacketSize-aligned transfer signals transfer completion
- Toggle continuity: toggle alternates correctly across all transactions in the transfer with no reset between transactions

*Interrupt transfer sequencing — the following must exist:*
- Polling an interrupt IN or OUT endpoint at the bInterval rate (derived from the SOF frame boundary, not an independent timer)
- On NAK: report "no data" and defer to the next polling interval; do not retry within the current interval
- On DATA: deliver payload to the application layer
- On STALL: halt and report STALL to the application layer

*Isochronous transfer sequencing — the following must exist:*
- Schedule one ISO IN or OUT transaction per SOF frame at the SOF-aligned slot
- Missed frames: report to the application layer; continue without stalling or resetting; the next frame proceeds normally after a missed frame
- No retry logic of any kind

*Transfer routing — the following must exist:*
- Route transfer engine commands from the host or device controller to the correct transfer engine based on endpoint transfer type
- Present a unified transfer command interface upward to the host and device controllers

**Recommended RTL Organization:**

- `rtl/transfer/control_transfer.v`
- `rtl/transfer/bulk_transfer.v`
- `rtl/transfer/interrupt_transfer.v`
- `rtl/transfer/iso_transfer.v`
- `rtl/transfer/transfer_mux.v`

**Dependencies:**
- Phase 6: all transaction layer engines and `transaction_arbiter`

**Deliverables:**
- Four independent transfer engine modules, each verified
- `transfer_mux` providing a unified transfer command interface

**Verification Goal:**
- `tb_transfer_engine.v`:
  - `control_transfer`: execute a full GET_DESCRIPTOR(Device) transfer: SETUP(GET_DESCRIPTOR) → 18-byte DATA IN → STATUS OUT; verify all 18 bytes received and STATUS stage completes correctly with DATA1
  - `bulk_transfer` OUT: execute a multi-packet OUT transfer split across multiple transactions; verify toggle alternates correctly across all transactions
  - `bulk_transfer` IN: inject a full-size packet followed by a short packet; verify the short packet is recognized as transfer completion
  - `bulk_transfer` IN: inject a MaxPacketSize-aligned transfer followed by a ZLP; verify the ZLP is recognized as transfer completion
  - `interrupt_transfer`: simulate several polling intervals; inject NAK for some intervals and DATA for one; verify data is captured only at the DATA interval with no spurious retries and correct deferral on NAK intervals
  - `iso_transfer`: execute several consecutive ISO IN frames; suppress device response on one frame; verify that frame is flagged as missed; verify adjacent frames are received correctly and the engine continues

**Completion Criteria:**
- Control transfer handles all three stages without deadlock under all response combinations
- Bulk transfer correctly detects and terminates on short packet and ZLP
- Interrupt transfer never retries within a frame on NAK; polling derives timing from SOF frame boundary
- ISO transfer continues after a missed frame without stalling or resetting

---

### Phase 8 — Device Controller

**Goal:**
Build the USB device controller: the hardware logic that responds to host-initiated transactions, manages the device USB address, processes Chapter 9 standard requests, and connects the endpoint engine array to the transfer layer.

**Required Functionality:**

*Descriptor storage and response — the following must exist:*
- ROM or register-based storage of the full descriptor set: Device Descriptor (18 bytes), Configuration Descriptor, Interface Descriptor(s), Endpoint Descriptor(s), String Descriptors (including string index 0 with language ID list)
- Descriptor content must be parameterized to allow different device classes and endpoint configurations without modifying the response logic
- GET_DESCRIPTOR response segmentation: index the descriptor storage; segment the response into max-packet-size chunks for the DATA stage; return no more bytes than the wLength field requests; handle wLength smaller than the full descriptor length correctly

*Address management — the following must exist:*
- USB address register: reset to 0 on power-on or USB bus reset; latch the new address from SET_ADDRESS only after the STATUS stage of that control transfer completes; never latch the new address before STATUS stage ACK
- All incoming transaction address comparisons must use the registered address; no hardcoded address literals in the data path

*Configuration management — the following must exist:*
- Configuration value register: on SET_CONFIGURATION with a non-zero value, activate the non-EP0 endpoint engines for that configuration; on SET_CONFIGURATION(0), deactivate all non-EP0 endpoints and return the device to the Address state

*Standard request processing — the following must exist:*
- Decode the 8-byte SETUP packet received on Endpoint 0
- Mandatory standard requests per USB 2.0 Chapter 9: GET_STATUS (device, interface, endpoint recipients), CLEAR_FEATURE (ENDPOINT_HALT, DEVICE_REMOTE_WAKEUP), SET_FEATURE (ENDPOINT_HALT, DEVICE_REMOTE_WAKEUP, TEST_MODE), SET_ADDRESS, GET_DESCRIPTOR, SET_DESCRIPTOR (optional; if not supported, return STALL), GET_CONFIGURATION, SET_CONFIGURATION, GET_INTERFACE, SET_INTERFACE, SYNCH_FRAME
- Return STALL on the STATUS stage for any unsupported, reserved, vendor-specific, or malformed request
- GET_STATUS on a device must return the correct remote-wakeup and self-powered bits
- GET_STATUS on an endpoint must return the correct ENDPOINT_HALT bit reflecting the current STALL state
- CLEAR_FEATURE(ENDPOINT_HALT) must clear STALL on the target endpoint and reset its toggle to DATA0

*Device controller core — the following must exist:*
- Receive transactions from the protocol/transaction layer addressed to this device's current USB address
- Route each transaction to the correct endpoint engine based on ENDP field
- Return the appropriate handshake (ACK, NAK, STALL) based on endpoint state
- Dispatch control transactions on Endpoint 0 to the standard request handler
- Handle address filtering correctly: after SET_ADDRESS, respond only to the new address

**Recommended RTL Organization:**

- `rtl/device/descriptor_rom.v` — Descriptor storage
- `rtl/device/get_descriptor_resp.v` — Descriptor segmentation and wLength handling
- `rtl/device/dev_address_reg.v` — USB address register with post-STATUS latching
- `rtl/device/dev_config_reg.v` — Configuration register with endpoint activation
- `rtl/device/std_request_handler.v` — Chapter 9 FSM
- `rtl/device/device_ctrl.v` — Device controller core
- `rtl/device/device_top.v` — Top-level

`std_request_handler` and `device_ctrl` may be merged if the implementation naturally unifies them. The functional requirements are unchanged.

**Dependencies:**
- Phase 5: endpoint engine
- Phase 7: `control_transfer`, `transfer_mux`
- Phase 4: protocol layer (for address matching and transaction dispatch)

**Deliverables:**
- Fully self-contained device controller capable of responding to USB enumeration
- Parameterized descriptor storage supporting arbitrary device class and endpoint configurations
- Endpoint 0 always present as Control type; additional endpoints configurable by parameter

**Verification Goal:**
- `tb_device_ctrl.v` (drive host stimulus manually, no host controller yet):
  - Reset device to address 0; send GET_DESCRIPTOR(Device, 8 bytes); verify first 8 bytes of device descriptor returned including correct bMaxPacketSize0
  - Send SET_ADDRESS(5); verify STATUS stage ACKs; verify device now responds to address 5 and does not respond to address 0
  - Send GET_DESCRIPTOR(Device, 18 bytes) to address 5; verify all 18 bytes returned correctly
  - Send GET_DESCRIPTOR(Configuration) to address 5; verify Configuration Descriptor + Interface Descriptor + Endpoint Descriptor(s) returned as a contiguous segmented response
  - Send GET_DESCRIPTOR with wLength smaller than the full descriptor; verify exactly wLength bytes returned, not the full descriptor
  - Send SET_CONFIGURATION(1); verify non-EP0 endpoint engines are activated
  - Send GET_STATUS(device); verify correct self-powered and remote-wakeup bits returned
  - Send GET_STATUS(endpoint) on a STALLed endpoint; verify ENDPOINT_HALT bit is set; issue CLEAR_FEATURE(ENDPOINT_HALT); verify STALL cleared and ENDPOINT_HALT bit cleared on subsequent GET_STATUS
  - Send an unsupported or vendor-specific request; verify STALL returned on the STATUS stage

**Completion Criteria:**
- Device passes all mandatory Chapter 9 standard requests without deadlock under all response conditions
- STALL correctly returned for all unsupported, reserved, or malformed requests
- Descriptor bytes returned match the stored descriptor content exactly, byte for byte, respecting wLength
- SET_ADDRESS address latching occurs after STATUS stage ACK, not before
- GET_STATUS returns correct bitmap for each recipient (device, interface, endpoint)

---

### Phase 9 — Host Controller

**Goal:**
Build the USB host controller: the hardware that drives bus power-on and reset, detects device speed, schedules the SOF frame, schedules transactions, and drives autonomous device enumeration.

**Required Functionality:**

*Port management — the following must exist:*
- Bus reset: drive SE0 for at least 10ms upon device connect detection; release the bus; wait for the device to recover; signal reset complete to the enumeration FSM
- Speed detection: detect Full Speed (D+ pulled high at idle) or High Speed chirp handshake sequence (K-state chirp from device; host responds with chirp K bursts; detect HS chirp K from device confirming HS capability); output the detected speed mode to all downstream logic
- Suspend: assert 3ms of bus idle to enter suspend state on command
- Resume: drive K-state for 20ms to resume a suspended device
- Disconnect detection: detect device removal from D+/D- pull-up state change; notify the host controller to invalidate all active pipes

*Frame scheduling — the following must exist:*
- Master 1ms SOF frame timer: generate a frame boundary pulse every 1ms at Full Speed; drive SOF token emission at each frame boundary; this pulse is the sole timing reference for all frame-periodic host operations; no other module may generate an independent 1ms timer
- Periodic scheduling: interrupt and ISO slot allocation within each 1ms frame; track bInterval for each active interrupt and ISO pipe; allocate transaction slots for each pipe within the frame without overcommitting bus bandwidth; report schedule overrun if allocated transactions exceed available frame time
- Asynchronous scheduling: Control and Bulk transfer queue management; round-robin arbitration between pending transfers with priority for Control transfers over Bulk; manage empty queue gracefully

*Autonomous enumeration — the following must exist:*
- GET_DESCRIPTOR sequencer: drive GET_DESCRIPTOR control transfers with the correct SETUP packet and expected data length
- SET_ADDRESS sequencer: drive SET_ADDRESS control transfer; verify device responds to the new address after STATUS stage
- SET_CONFIGURATION sequencer: drive SET_CONFIGURATION with the selected configuration value
- Descriptor parsing: parse received descriptor bytes; extract bDeviceClass, bNumConfigurations, bMaxPacketSize0 from the Device Descriptor; extract endpoint type, direction, wMaxPacketSize, bInterval, and bmAttributes from all endpoint descriptors in the Configuration Descriptor response
- Enumeration FSM: autonomous sequence: DISCONNECTED → RESET → GET_DEV_DESC(8 bytes) → SET_ADDRESS → GET_DEV_DESC(18 bytes) → GET_CFG_DESC → SET_CONFIGURATION → ACTIVE; drive the sequencer modules; issue transactions exclusively to Endpoint 0; handle NAK retries without deadlock; halt on STALL or turnaround timeout and report the failure condition

**Recommended RTL Organization:**

- `rtl/host/port/port_reset_ctrl.v`, `port_speed_detect.v`, `port_suspend_resume.v`
- `rtl/host/schedule/host_frame_sched.v`, `periodic_sched.v`, `async_sched.v`
- `rtl/host/enumeration/get_descriptor_seq.v`, `set_address_seq.v`, `set_configuration_seq.v`, `descriptor_parser.v`, `enum_fsm.v`
- `rtl/host/host_ctrl.v`, `host_top.v`

**Dependencies:**
- Phase 4: `sof_generator`, `token_tx`
- Phase 6: `transaction_arbiter`, all control transaction engines
- Phase 7: `control_transfer`, `transfer_mux`

**Deliverables:**
- Host controller capable of autonomous USB enumeration without supervisor intervention
- Periodic scheduler correctly allocating interrupt and ISO polling slots
- Asynchronous scheduler managing the Control + Bulk queue

**Verification Goal:**
- `tb_enumeration.v` (host + Phase 8 device, connected via `phy_wire_model`):
  - Start simulation with device connected; verify host drives SE0 reset for at least 10ms; verify bus released and FS speed correctly detected
  - Verify `enum_fsm` transitions through all states in the correct order: DISCONNECTED → RESET → GET_DEV_DESC(8) → SET_ADDRESS → GET_DEV_DESC(18) → GET_CFG_DESC → SET_CONFIGURATION → ACTIVE
  - Verify correct device address assigned (e.g., address 1); verify device responds to address 1 and not address 0 after enumeration
  - Verify SET_CONFIGURATION sent and ACKed by device
  - Verify `enum_fsm` reaches ACTIVE state and asserts enumeration complete signal
  - Verify `descriptor_parser` correctly extracts all fields from the multi-descriptor GET_DESCRIPTOR(Configuration) response
  - Verify SOF generated at exactly 1ms intervals throughout the entire enumeration sequence
  - Inject NAK on one GET_DESCRIPTOR response; verify `enum_fsm` retries and continues without deadlock
  - Simulate device disconnect after enumeration; verify host controller invalidates active state and returns to DISCONNECTED

**Completion Criteria:**
- Enumeration completes without manual forcing in simulation
- SOF generated at correct 1ms intervals throughout enumeration
- Enumeration FSM handles NAK retries without deadlock
- `descriptor_parser` correctly extracts all required fields from the full configuration descriptor response
- `enum_fsm` never issues a transaction to any endpoint other than Endpoint 0
- Disconnect detection correctly invalidates host state

---

### Phase 10 — Full System Integration

**Goal:**
Connect the host controller, device controller, and simulation PHY wire model into a single cohesive simulation environment. Verify end-to-end USB Host ↔ USB Device operation and demonstrate the final HID keyboard use case.

**Required Functionality:**

*Integration testbench — the following must exist:*
- Instantiate host controller, device controller, and `phy_wire_model`; connect host PHY TX output to device PHY RX input and vice versa through the wire model; provide stimulus control; drive no protocol manually — all sequencing driven by host and device controllers

*HID keyboard demonstration — the following must exist:*
- Device configured as USB HID keyboard (boot protocol): device class HID (0x03), subclass boot (0x01), protocol keyboard (0x01); Interrupt IN endpoint: wMaxPacketSize=8, bInterval=10
- Host enumerates device autonomously; host periodic scheduler polls Interrupt IN endpoint at bInterval; device delivers 8-byte HID boot reports on the Interrupt IN endpoint; host presents the received report on its application interface
- Toggle alternation across consecutive reports: first report with DATA0, second report with DATA1

**Recommended RTL Organization:**

- `sim/tb/tb_host_device_loopback.v` — Integration testbench
- `sim/tb/tb_usb_keyboard_system.v` — HID keyboard system testbench

**Dependencies:**
- Phase 8: `device_top`
- Phase 9: `host_top`
- Phase 2: `phy_wire_model`
- All prior phases

**Deliverables:**
- Single simulation demonstrating the complete sequence: connect → reset → enumeration → SET_CONFIGURATION → interrupt IN polling → HID report delivery
- Final captured waveform of the complete HID keyboard report transfer sequence

**Verification Goal:**
- `tb_usb_keyboard_system.v`:
  - Device descriptor: bDeviceClass=0, test-value idVendor and idProduct
  - Interface descriptor: bInterfaceClass=0x03 (HID), bInterfaceSubClass=0x01 (boot), bInterfaceProtocol=0x01 (keyboard)
  - Endpoint descriptor: Interrupt IN, wMaxPacketSize=8, bInterval=10
  - Host successfully enumerates device to ACTIVE state without manual forcing
  - Host periodic scheduler polls Interrupt IN at the correct bInterval
  - Device endpoint engine delivers 8-byte HID boot report on Interrupt IN
  - Host application interface presents the 8-byte report with correct DATA0 PID
  - Second report delivered with toggled DATA1 PID
  - Third poll returns NAK (no new data); host defers correctly without error or stall

**Completion Criteria:**
- Full enumeration completes end-to-end in simulation with zero manual forcing
- At least two consecutive HID reports successfully delivered and received with correct toggle
- NAK handling on Interrupt IN poll does not cause host to stall or error
- Waveform shows correct SYNC, PID, payload, CRC, and EOP for every packet in the transfer sequence

---

### Phase 11 — Verification Hardening and Regression

**Goal:**
Stress-test all corner cases, establish a complete regression suite across all modules, and confirm the implementation is robust and extensible for future device types and transfer configurations.

**Required Functionality:**

The following testbenches must be completed and added to the regression suite:

- `tb_crc.v` — Exhaustive CRC-5 and CRC-16 vector test against all USB 2.0 specification Appendix vectors; include known-bad inputs to verify error detection
- `tb_bitstuff.v` — Bit stuffer/unstuffer stress: long-duration randomized data with intentional stuffing error injection at boundary conditions
- `tb_link_layer.v` — Randomized packet injection with intentional CRC errors and PID complement errors; verify zero false CRC passes and zero false PID accepts across comprehensive randomized injection
- `tb_protocol_layer.v` — All 16 PID types classified under random ordering; SOF timing accuracy measurement over many consecutive frames; verify no misclassification under adversarial PID ordering
- `tb_transaction_engine.v` — NAK stress to maximum retry count; STALL handling on all transaction types; turnaround timeout edge cases; IPDS boundary verification
- `tb_transfer_engine.v` — Short packet detection at every length from 1 byte to MaxPacketSize; ZLP handling; missed ISO frame sequences including consecutive misses; control transfer all-stage error injection
- `tb_endpoint_engine.v` — Toggle integrity under error injection across many concurrent transactions; STALL clear sequence; FIFO boundary conditions; concurrent toggle + STALL + CLEAR_FEATURE interaction

**Dependencies:**
- All prior phases

**Deliverables:**
- Complete regression suite covering all modules
- All testbenches runnable from `scripts/run_sim.sh`

**Verification Goal:**
- CRC: 100% vector match on all USB 2.0 specification Appendix test vectors; randomized stress testing with error injection confirms correct error detection
- Bit stuffing: zero data corruption and zero false errors across long-duration randomized input coverage
- Link layer: zero false CRC passes across comprehensive randomized error packet injection
- Transaction layer: zero timeout violations in long-duration NAK stress testing; zero IPDS violations under concurrent engine stress
- Transfer layer: correct short-packet and ZLP handling verified at every packet size from 1 byte to MaxPacketSize; missed ISO frame recovery verified under consecutive miss conditions
- Endpoint engine: toggle integrity never violated across comprehensive concurrent error injection; STALL/CLEAR_FEATURE interaction verified under all ordering conditions

**Completion Criteria:**
- All testbenches pass with zero assertion failures
- No X-propagation from any registered output at simulation start after synchronous reset
- All FSMs have default state transitions (no latch inference from incomplete case statements)
- Synthesis lint check: zero latches, zero combinational feedback loops in any RTL module

---

## Section 4 — Implementation Timeline

```
WEEK  1  │  Phase 0   │  Directory tree, version control, usb_pkg.vh, spec vectors
WEEK  2  │  Phase 1   │  crc5_engine, crc16_engine — verify against spec vectors
WEEK  3  │  Phase 1   │  nrzi_encoder, nrzi_decoder, bitstuffer, bitunstuffer
WEEK  4  │  Phase 1   │  sync_detect, eop_detect, sync_fifo, async_fifo
WEEK  5  │  Phase 2   │  serializer, diff_tx_driver, eop_gen — TX path complete
WEEK  6  │  Phase 2   │  diff_rx_sampler, deserializer, phy_wire_model — RX path and loopback
WEEK  7  │  Phase 3   │  pid_decoder, rx_crc_checker, packet_rx — RX framer complete
WEEK  8  │  Phase 3   │  pid_encoder, tx_crc_inserter, packet_tx — TX assembler complete
WEEK  9  │  Phase 4   │  packet_classifier, token_rx, token_tx, sof_rx
WEEK 10  │  Phase 4   │  data_rx, data_tx, handshake_rx, handshake_tx, sof_generator
WEEK 11  │  Phase 5   │  endpoint_toggle, endpoint_fifo_ctrl, endpoint_stall_ctrl
WEEK 12  │  Phase 5   │  endpoint_engine parametric top — endpoint engine complete
WEEK 13  │  Phase 6   │  setup_tx, ctrl_data_tx, ctrl_data_rx, status_stage
WEEK 14  │  Phase 6   │  bulk_tx, bulk_rx, intr_tx, intr_rx, iso_tx, iso_rx
WEEK 15  │  Phase 6   │  transaction_arbiter — transaction layer complete
WEEK 16  │  Phase 7   │  control_transfer, bulk_transfer
WEEK 17  │  Phase 7   │  interrupt_transfer, iso_transfer, transfer_mux
WEEK 18  │  Phase 8   │  descriptor_rom, get_descriptor_resp, dev_address_reg, dev_config_reg
WEEK 19  │  Phase 8   │  std_request_handler, device_ctrl, device_top — device controller complete
WEEK 20  │  Phase 9   │  port_reset_ctrl, port_speed_detect, port_suspend_resume
WEEK 21  │  Phase 9   │  host_frame_sched, periodic_sched, async_sched
WEEK 22  │  Phase 9   │  get_descriptor_seq, set_address_seq, set_configuration_seq, descriptor_parser
WEEK 23  │  Phase 9   │  enum_fsm, host_ctrl, host_top — host controller complete
WEEK 24  │  Phase 10  │  tb_host_device_loopback — end-to-end loopback verification
WEEK 25  │  Phase 10  │  tb_usb_keyboard_system — HID keyboard demonstration
WEEK 26  │  Phase 11  │  Regression suite construction and first full run
WEEK 27  │  Phase 11  │  Corner case hardening, X-propagation check, synthesis lint, final sign-off
```

> **Timeline Note:** The weekly schedule above reflects a single-engineer sequential implementation. Individual phases may parallelize or compress as familiarity with the codebase grows. If a module takes longer than its allocated week, the downstream phases accommodate; the dependency order in Section 2 is the binding constraint, not the calendar.

---

## Section 5 — usb_pkg.vh Content Reference

`usb_pkg.vh` contains only definitions that come directly from the USB 2.0 specification. It does not contain FSM state encodings, scheduler state encodings, internal bus widths, or any implementation-specific constants. Those belong inside their respective modules until they organically become shared across three or more unrelated modules.

**PID Group encodings (USB 2.0 spec Table 8-1):**
- TOKEN group: OUT (0001), IN (1001), SOF (0101), SETUP (1101)
- DATA group: DATA0 (0011), DATA1 (1011), DATA2 (0111), MDATA (1111)
- HANDSHAKE group: ACK (0010), NAK (1010), STALL (1110), NYET (0110)
- SPECIAL group: PRE/ERR (1100), SPLIT (1000), PING (0100), Reserved (0000)

**CRC constants:**
- CRC-5: polynomial X⁵+X²+1; generator 0x05; residue 0x0C
- CRC-16: polynomial X¹⁶+X¹⁵+X²+1; generator 0x8005; residue 0x800D

**Descriptor type codes:**
- DEVICE (0x01), CONFIGURATION (0x02), STRING (0x03), INTERFACE (0x04), ENDPOINT (0x05)
- DEVICE_QUALIFIER (0x06), OTHER_SPEED_CONFIGURATION (0x07), INTERFACE_POWER (0x08)
- HID (0x21), REPORT (0x22), PHYSICAL (0x23)

**Standard request codes:**
- GET_STATUS (0x00), CLEAR_FEATURE (0x01), SET_FEATURE (0x03), SET_ADDRESS (0x05)
- GET_DESCRIPTOR (0x06), SET_DESCRIPTOR (0x07), GET_CONFIGURATION (0x08)
- SET_CONFIGURATION (0x09), GET_INTERFACE (0x0A), SET_INTERFACE (0x0B), SYNCH_FRAME (0x0C)

**Feature selector codes:**
- ENDPOINT_HALT (0x00), DEVICE_REMOTE_WAKEUP (0x01), TEST_MODE (0x02)

**bmAttributes endpoint transfer type encoding:**
- Control (00b), Isochronous (01b), Bulk (10b), Interrupt (11b)

**bmAttributes isochronous synchronization type (bits [3:2]):**
- No Synchronization (00b), Asynchronous (01b), Adaptive (10b), Synchronous (11b)

**bmAttributes isochronous usage type (bits [5:4]):**
- Data endpoint (00b), Feedback endpoint (01b), Implicit feedback data endpoint (10b)

**Packet field widths:**
- ADDR: 7 bits (addresses 0–127)
- ENDP: 4 bits (endpoints 0–15)
- Frame Number: 11 bits (0–2047, wraps at 2047→0)
- PID: 8 bits (4-bit PID + 4-bit complement)
- CRC-5: 5 bits; CRC-16: 16 bits

**USB timing constants (Full Speed unless noted):**
- FS bit period: 1/12,000,000 s (~83.3 ns)
- HS bit period: 1/480,000,000 s (~2.08 ns)
- LS bit period: 1/1,500,000 s (~666.7 ns)
- SOF interval: 1 ms (FS/HS)
- SE0 reset duration: ≥10 ms
- Turnaround time: 16 bit periods (FS)
- IPDS (inter-packet delay): 2 bit periods minimum
- Suspend: 3 ms of idle
- Resume K-state: 20 ms
- HS chirp K duration (device): 1–7 ms
- HS chirp K response (host): three chirp K bursts, each 40 µs, separated by 60 µs

**SYNC patterns:**
- FS/LS SYNC: KJKJKJKK (7 transitions + final KK = 8 bits; decoded as 0x80 after NRZI)
- HS SYNC: 32 bits (KJKJKJKJ...KK, 15 KJ pairs followed by KK)

**Max packet sizes:**
- Control EP0 LS: 8 bytes; FS: 8, 16, 32, or 64 bytes; HS: 64 bytes
- Bulk FS: 8, 16, 32, or 64 bytes; HS: 512 bytes
- Interrupt LS: ≤8 bytes; FS: ≤64 bytes; HS: ≤1024 bytes
- Isochronous FS: ≤1023 bytes; HS: ≤1024 bytes (up to 3× per microframe for high-bandwidth)

---

## Section 6 — Architecture Flexibility Notes

These are intentional open decisions, not gaps. The implementation will resolve them.

- **Link-to-Protocol interface**: The exact signals passed from the link layer framer to the protocol layer classifier are not pre-defined. They will emerge naturally when both modules are implemented in Phases 3 and 4. Document the interface when it stabilizes.
- **Protocol-to-Transaction interface**: How the protocol layer communicates received packets to the transaction engines — whether as a parallel bus, individual valid strobes, a small status register, or another mechanism — will emerge from implementing both layers. The roadmap does not constrain this choice.
- **Endpoint engine decomposition**: The endpoint engine may be implemented as a single file or may instantiate toggle, FIFO, and STALL logic as separate sub-modules. The implementation will determine the natural boundary. Either is equally valid.
- **Module splitting and merging**: If any module grows beyond comfortable complexity, split it. If two modules always appear together and share most of their interface, merge them. The phase structure accommodates both without requiring revision to the roadmap.
- **When to move constants to usb_pkg.vh**: If a constant is needed only within one module, define it as a `localparam` inside that module. Move it to `usb_pkg.vh` only when it is (a) directly from the USB 2.0 specification and (b) duplicated across three or more unrelated modules.
- **Clock divider**: Introduce a clock divider or prescaler utility only if and when the implementation requires one to derive a bit-rate clock from the system clock. Do not create it speculatively.
- **Transaction engine merging**: The control transaction stages (setup, data TX, data RX, status) are separately specified because they have different retry and toggle rules. However, if implementation naturally unifies them within a single control transaction FSM, that is architecturally valid.

---

## Section 7 — Critical Design Rules

These constraints apply to every module in the project from Phase 0 onward. They are protocol-correctness requirements derived directly from the USB 2.0 specification.

1. **Toggle ownership**: DATA0/DATA1 toggle state lives exclusively in the endpoint engine. No other module tracks or modifies toggle independently. The transaction layer reads toggle from the endpoint engine; it does not maintain its own copy.
2. **Handshake is final**: No transaction engine advances its state until the handshake phase resolves — ACK, NAK, STALL, or turnaround timeout. No exceptions.
3. **ISO never retries**: Isochronous transaction engines have zero retry logic. Any retry path in an ISO engine is a design error.
4. **ISO never handshakes**: Isochronous transaction engines generate zero handshake packets under any condition. Any handshake generation in an ISO engine is a design error.
5. **STALL does not retry**: Any transfer engine that receives STALL halts immediately and reports the error upward without retrying. The distinction between STALL and NAK must be preserved through all layers.
6. **EP0 is always Control**: Endpoint 0 must always be configured as Control type. Other transfer types on Endpoint 0 are a design error.
7. **Enumeration to EP0 only**: The enumeration FSM must never issue a transaction to any endpoint other than Endpoint 0. Doing so is a design error.
8. **SOF is the frame boundary**: Every module that cares about frame timing derives that timing from the frame boundary pulse in the host frame scheduler. Independent 1ms timers elsewhere are prohibited.
9. **IPDS at the arbiter**: All inter-packet delay enforcement lives in the transaction arbiter. No transaction engine pads inter-packet timing independently.
10. **No hardcoded addresses**: All address and endpoint comparisons use registered values from the address register. No hardcoded address literals in the data path.
11. **Reset-synchronous state**: All FIFOs must be empty and all pointers zeroed; all FSMs must be in their reset state; all flags must be deasserted within one clock cycle of synchronous reset deassertion.
12. **SET_ADDRESS timing**: The new USB address must be latched only after the STATUS stage ACK of the SET_ADDRESS control transfer completes. Latching before STATUS stage completion is a specification violation.
13. **SETUP toggle immunity**: SETUP transactions always use DATA0 and do not advance the toggle on ACK. The toggle may only advance on non-SETUP ACK.
14. **Turnaround timeout vs. NAK**: Turnaround timeout (no response within 16 bit periods) and NAK (explicit NAK packet received) are distinct error conditions and must be separately reported to the transfer layer. Conflating them is a design error.

---

*End of USB 2.0 RTL Implementation Roadmap — Refined Engineering Review*

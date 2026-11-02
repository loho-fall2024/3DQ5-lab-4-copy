/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

module experiment3 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// LEDs                              ////////////
		output logic[8:0] LED_GREEN_O             // 9 green LEDs
);

logic resetn;
assign resetn = ~SWITCH_I[17];

enum logic [1:0] {
	S_IDLE,
	S_READ,
	S_WRITE
} state;

/*
Assume m iterates from 0 through 255:

    Y[2m]   = signed minimum of W[2m]   and X[2m+1]
    Z[2m]   = signed maximum of W[2m]   and X[2m+1]

    Y[2m+1] = signed minimum of W[2m+1] and X[2m]
    Z[2m+1] = signed maximum of W[2m+1] and X[2m]

In each iteration, both ports of both DP-RAMs first read the four
original values. In the following clock cycle, both ports write the
four compare-exchange results.
*/

logic [8:0] address_a [1:0];
logic [8:0] address_b [1:0];
logic [7:0] write_data_a [1:0];
logic [7:0] write_data_b [1:0];
logic write_enable_a [1:0];
logic write_enable_b [1:0];
logic [7:0] read_data_a [1:0];
logic [7:0] read_data_b [1:0];

// These bits store m, from 0 through 255. Appending 0 or 1 selects
// locations 2m or 2m+1, respectively.
logic [7:0] msbits_address;

assign address_a[0] = {msbits_address, 1'b0};
assign address_b[0] = {msbits_address, 1'b1};
assign address_a[1] = {msbits_address, 1'b0};
assign address_b[1] = {msbits_address, 1'b1};

// Both ports of both memories write during the write cycle.
assign write_enable_b[0] = write_enable_a[0];
assign write_enable_a[1] = write_enable_a[0];
assign write_enable_b[1] = write_enable_a[0];

// $signed interprets each 8-bit pattern as a two's-complement number.
// Compare W[2m] with X[2m+1]; write the minimum to Y[2m] and maximum to Z[2m].
assign write_data_a[0] =
	($signed(read_data_a[0]) <= $signed(read_data_b[1])) ?
		read_data_a[0] : read_data_b[1];
assign write_data_a[1] =
	($signed(read_data_a[0]) <= $signed(read_data_b[1])) ?
		read_data_b[1] : read_data_a[0];

// Compare W[2m+1] with X[2m]; write the minimum to Y[2m+1] and maximum to Z[2m+1].
assign write_data_b[0] =
	($signed(read_data_b[0]) <= $signed(read_data_a[1])) ?
		read_data_b[0] : read_data_a[1];
assign write_data_b[1] =
	($signed(read_data_b[0]) <= $signed(read_data_a[1])) ?
		read_data_a[1] : read_data_b[0];

// instantiate RAM0
// Its original values W are replaced by the minimum values Y.
dual_port_RAM0 RAM_inst0 (
	.address_a ( address_a[0] ),
	.address_b ( address_b[0] ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_b[0] ),
	.wren_a ( write_enable_a[0] ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
);

// instantiate RAM1
// Its original values X are replaced by the maximum values Z.
dual_port_RAM1 RAM_inst1 (
	.address_a ( address_a[1] ),
	.address_b ( address_b[1] ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[1] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_enable_a[1] ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
);

// FSM to control the read and write sequence
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		msbits_address <= 8'd0;
		write_enable_a[0] <= 1'b0;
		state <= S_IDLE;
	end else begin
		case (state)
		S_IDLE: begin
			msbits_address <= 8'd0;
			write_enable_a[0] <= 1'b0;
			// wait for switch[0] to be asserted
			if (SWITCH_I[0])
				state <= S_READ;
		end
		S_READ: begin
			// Both ports of both RAMs read at this edge. Their four original
			// values drive the comparisons before the next edge writes the results.
			write_enable_a[0] <= 1'b1;
			state <= S_WRITE;
		end
		S_WRITE: begin
			// The four writes complete at this edge, before the address changes.
			write_enable_a[0] <= 1'b0;
			if (msbits_address == 8'd255) begin
				msbits_address <= 8'd0;
				state <= S_IDLE;
			end else begin
				msbits_address <= msbits_address + 8'd1;
				state <= S_READ;
			end
		end
		default: begin
			msbits_address <= 8'd0;
			write_enable_a[0] <= 1'b0;
			state <= S_IDLE;
		end
		endcase
	end
end

// dump some dummy values on the output green LEDs to constrain
// the synthesis tools not to remove the circuit logic
assign LED_GREEN_O[7:0] = write_data_a[0] ^ write_data_b[0] ^
	write_data_a[1] ^ write_data_b[1];
assign LED_GREEN_O[8] = write_enable_a[0] & write_enable_b[0] &
	write_enable_a[1] & write_enable_b[1];

/*
Register usage (each bit counted below is one flip-flop).

The always_ff block describes the registers that store the address, write
enable and state between clock edges. The assign statements describe
connections and combinational logic between registers. A logic declaration
gives a signal its width; the way it is driven determines the hardware.

The source declares eight bits for msbits_address, one for write_enable_a[0]
and two for state: 8 + 1 + 2 = 11 register bits before synthesis.
In this compilation, Quartus recodes the three-state FSM using three bits.
One-hot encoding assigns one bit to each state, which can simplify the logic
that detects a state.

The implemented circuit therefore uses:

  msbits_address[7:0]         8  Current value of m
  write_enable_a[0]           1  Write enable shared by all four RAM ports
  state                       3  Three recoded state bits
  Total                      12

The other three write-enable signals are connected to write_enable_a[0],
so all four RAM ports share one write-enable register. The address_a and
address_b signals are connections to msbits_address with a constant bit
appended. They require no additional registers. The signed comparisons,
result-selection muxes and LED logic are also combinational.

Critical path.

After a rising clock edge, the RAM outputs and combinational logic need
time to settle. The value at a receiving register must become stable
early enough to meet its setup requirement at the next rising edge.
The setup critical path is the path with the smallest remaining time
margin, called setup slack.

Here, the RAM values pass through a signed comparator and then through
the muxes that select the minimum and maximum. The comparison result must
settle before the mux output can settle. RAM output delay, comparison,
mux selection and routing delays all contribute to this path. The two
compare-exchange operations work in parallel, so their delays are not
added together. The address-update and FSM paths are shorter in this 
implementation.

The critical path shown in the Quartus timing report starts at RAM_inst0's
internal port-B write-enable register (portb_we_reg) and ends at its port-A
data-input register (porta_datain_reg0). The write-enable register affects
the RAM output. That output passes through the signed-comparison logic and
the write_data_a[0] mux before returning to the RAM data input. These
endpoints are registers inside the M9K block, consistent with the separate
memory and logic-register counts above.

Quartus reports 7.694 ns of data delay and
12.310 ns of setup slack with the required 20 ns clock period (50 MHz).
Positive slack means the data arrives before its required time. The
reported Fmax is 130.04 MHz.

The timing analysis includes register timing and clock arrival times as
well as the RAM, logic and routing delays.

Logic elements.

A Cyclone IV logic element (LE) contains a four-input look-up table (LUT)
and a register. The LUT implements a Boolean function of up to four input
bits. Several LEs can be connected to implement functions with more inputs
or multi-bit results. Carry connections between LEs support operations
such as addition and comparison.

Here, the combinational logic includes two signed 8-bit comparisons, four
8-bit result-selection muxes, the address incrementer, the test for the
last address, FSM next-state logic and the LED logic. Each comparison
result controls both a minimum mux and a maximum mux, allowing Quartus to
share that comparison logic between two outputs.

An 8-bit mux describes eight one-bit selections. A single RTL expression
can therefore require several LEs. Quartus can also combine expressions
into the same LUT and remove redundant logic. The compilation summary
shows the final LE count after these optimizations.

The Quartus compilation report lists:

  Combinational logic without a register    66 LEs
  Combinational logic with a register       12 LEs
  Register only                              0 LEs
  Total                                     78 LEs

The 12 register bits counted above occupy the registers inside 12 of these
78 LEs. Those same LEs also implement combinational logic in their LUTs.
Thus, 66 + 12 = 78 LEs accounts for both the combinational logic and all
12 logic registers. The M9K memory block is a separate FPGA resource.

*/

endmodule

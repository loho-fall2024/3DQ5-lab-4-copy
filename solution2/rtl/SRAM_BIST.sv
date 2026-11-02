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

module SRAM_BIST (
	input logic Clock,
	input logic Resetn,
	input logic BIST_start,

	output logic [17:0] BIST_address,
	output logic [15:0] BIST_write_data,
	output logic BIST_we_n,
	input logic [15:0] BIST_read_data,

	output logic BIST_finish,
	output logic BIST_mismatch
);

enum logic [2:0] {
	S_IDLE,
	S_DELAY_1,
	S_DELAY_2,
	S_WRITE_CYCLE,
	S_READ_CYCLE,
	S_DELAY_3,
	S_DELAY_4
} BIST_state;

logic BIST_start_buf;
logic [15:0] BIST_expected_data;

// Address bit 0 selects the even or odd background pattern. A step of two
// keeps this bit unchanged throughout each write/read session.
assign BIST_write_data = BIST_address[15:0] ^
	(BIST_address[0] ? 16'h5A5A : 16'hA5A5);

// In S_READ_CYCLE, BIST_read_data comes from the address requested two
// rising edges of Clock earlier. BIST_address decreases by two at each
// edge, so adding four gives the address of the data being compared.
// BIST_address is held at the last address in S_DELAY_3 and S_DELAY_4.
// The remaining read values then come from that address + 2 and that
// address, respectively.
assign BIST_expected_data =
	(BIST_address[15:0] + ((BIST_state == S_DELAY_3) ? 16'd2 :
		(BIST_state == S_DELAY_4) ? 16'd0 : 16'd4)) ^
	(BIST_address[0] ? 16'h5A5A : 16'hA5A5);

always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		BIST_state <= S_IDLE;
		BIST_start_buf <= 1'b0;
		BIST_address <= 18'd0;
		BIST_we_n <= 1'b1;
		BIST_finish <= 1'b0;
		BIST_mismatch <= 1'b0;
	end else begin
		BIST_start_buf <= BIST_start;

		case (BIST_state)
		S_IDLE: begin
			BIST_address <= 18'd0;
			BIST_we_n <= 1'b1;
			BIST_finish <= 1'b1;
			if (BIST_start && !BIST_start_buf) begin
				// start the BIST engine
				BIST_address <= 18'h00000;
				BIST_we_n <= 1'b0;
				BIST_finish <= 1'b0;
				BIST_mismatch <= 1'b0;
				BIST_state <= S_WRITE_CYCLE;
			end
		end

		S_WRITE_CYCLE: begin
			// The last write uses 3FFFE for even addresses or 3FFFF for odd
			// addresses. Hold that address for the first read of the session.
			if (BIST_address[17:1] == 17'h1FFFF) begin
				BIST_we_n <= 1'b1;
				BIST_state <= S_DELAY_1;
			end else begin
				BIST_address <= BIST_address + 18'd2;
			end
		end

		// Initiate the first two reads before the first returned value is ready.
		S_DELAY_1: begin
			BIST_address <= BIST_address - 18'd2;
			BIST_state <= S_DELAY_2;
		end

		S_DELAY_2: begin
			BIST_address <= BIST_address - 18'd2;
			BIST_state <= S_READ_CYCLE;
		end

		S_READ_CYCLE: begin
			// complete the READ initiated two clock cycles earlier and perform comparison
			// A mismatch stays high until reset or the next start request.
			if (BIST_read_data != BIST_expected_data) begin
				BIST_mismatch <= 1'b1;
			end
			if (BIST_address[17:1] == 17'd0) begin
				// delay for checking the last address
				BIST_state <= S_DELAY_3;
			end else begin
				BIST_address <= BIST_address - 18'd2;
			end
		end

		// All read requests for this session have been issued. BIST_address
		// stays at the last address: 0 in the even session, 1 in the odd session.
		// The controller delay leaves two read values still to be compared.
		S_DELAY_3: begin
			// BIST_read_data comes from the next-to-last read request:
			// address 2 in the even session, or address 3 in the odd session.
			// The data from the final read request will be compared one cycle later.
			if (BIST_read_data != BIST_expected_data) begin
				BIST_mismatch <= 1'b1;
			end
			BIST_state <= S_DELAY_4;
		end

		S_DELAY_4: begin
			// check for data mismatch
			// BIST_read_data now comes from the last requested address (0 or 1).
			// This rising edge records any mismatch and starts the odd session
			// or asserts BIST_finish after the odd session.
			if (BIST_read_data != BIST_expected_data) begin
				BIST_mismatch <= 1'b1;
			end
			if (!BIST_address[0]) begin
				// The even session is complete; begin writing the odd addresses.
				BIST_address <= 18'h00001;
				BIST_we_n <= 1'b0;
				BIST_state <= S_WRITE_CYCLE;
			end else begin
				// finish the whole SRAM
				BIST_address <= 18'd0;
				BIST_finish <= 1'b1;
				BIST_state <= S_IDLE;
			end
		end

		default: begin
			BIST_address <= 18'd0;
			BIST_we_n <= 1'b1;
			BIST_finish <= 1'b0;
			BIST_state <= S_IDLE;
		end
		endcase
	end
end

endmodule

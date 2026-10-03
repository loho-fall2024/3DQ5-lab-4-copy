### Take-home exercise 2

Modify the built-in self-test (BIST) engine from __experiment 4__ to verify all 2<sup>18</sup>, or 256k, locations of the external SRAM. The BIST consists of one session for the even addresses followed by one session for the odd addresses.

During the even-address session, perform the following phases:

1. Write the even addresses in increasing order: 00000, 00002, 00004, and so on through 3FFFE. At each address, write the bitwise XOR of the 16 least significant address bits and the fixed hexadecimal pattern `16'hA5A5`. For example, write A5A5 at address 00000, A5A7 at address 00002, and 5A5B at address 3FFFE.
2. Read and check the even addresses in decreasing order: 3FFFE, 3FFFC, and so on through 00000. Compare each value returned by the SRAM with the value written previously at the same address.

After the even-address session, perform the following phases for the odd addresses:

1. Write the odd addresses in increasing order: 00001, 00003, 00005, and so on through 3FFFF. At each address, write the bitwise XOR of the 16 least significant address bits and the fixed hexadecimal pattern `16'h5A5A`. For example, write 5A5B at address 00001, 5A59 at address 00003, and A5A5 at address 3FFFF.
2. Read and check the odd addresses in decreasing order: 3FFFF, 3FFFD, and so on through 00001. Compare each value returned by the SRAM with the value written previously at the same address.

Each SRAM location must be written once and read and checked once. Account for the latency of the SRAM controller so that each returned value is compared with the expected value for the address that produced it.

The BIST begins when `SWITCH_I[0]` changes from low to high. Starting a BIST clears `BIST_mismatch` and makes `BIST_finish` low. A mismatched read sets `BIST_mismatch` high, and it remains high until the next BIST begins or reset is asserted. `BIST_finish` becomes high only after the value returned by the final read from address 00001 has been checked.

Submit your sources and approximately half a page of reasoning, with a maximum length of one page. Follow the directory structure provided in the `exercise2` folder. Place your report, in `.pdf`, `.txt`, or `.md` format, in `exercise2/doc`. Although this lab is assessed through simulation, your design must pass a complete Quartus compilation before you simulate it and write the report.

Your submission is due 16 hours before your next lab session. Late submissions will be penalized.

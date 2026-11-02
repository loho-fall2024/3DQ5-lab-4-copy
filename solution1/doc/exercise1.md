### Take-home exercise 1

Modify the design from __experiment 3__ as follows.

The first and second DP-RAMs contain arrays **W** and **X**, respectively. Each array contains 512 elements, and every element is an 8-bit signed integer. The arrays are initialized through memory initialization files, as in the in-lab experiment.

For each _m_ from 0 through 255, the circuit performs the following two signed compare-exchange operations:

- compare **W**[_2m_] with **X**[_2m+1_]. Store the smaller signed value in **Y**[_2m_] and the larger signed value in **Z**[_2m_];
- compare **W**[_2m+1_] with **X**[_2m_]. Store the smaller signed value in **Y**[_2m+1_] and the larger signed value in **Z**[_2m+1_].

For example, suppose **W**[_2m_] is -12, **W**[_2m+1_] is 20, **X**[_2m_] is -50, and **X**[_2m+1_] is 7. The first comparison produces **Y**[_2m_] = -12 and **Z**[_2m_] = 7. The second comparison produces **Y**[_2m+1_] = -50 and **Z**[_2m+1_] = 20. If the two values in a comparison are equal, both corresponding outputs contain that value.

The signals in the supplied RTL are declared using the `logic` type. Keep multi-bit declarations in the form `logic [7:0] signal_name;`. A `logic` vector is interpreted as an unsigned value by default. Therefore, apply the `$signed` system function to both operands whenever their signed values are compared. For example, a signed comparison can be written as `$signed(first_signal) > $signed(second_signal)`.

Each element **Y**[_k_] overwrites **W**[_k_] in the first DP-RAM, and each element **Z**[_k_] overwrites **X**[_k_] in the second DP-RAM, for every _k_ from 0 through 511. All four original values associated with one value of _m_ must be acquired before any corresponding result is written. The complete calculation requires one pass through the original arrays and should use as few clock cycles as the two DP-RAMs can facilitate.

For this exercise only, your report __MUST__ discuss the number of registers used by your circuit. Compare your estimate with the register count in the Quartus compilation report. You must also inspect the critical path using the Timing Analyzer, as shown in the circuit implementation and timing videos from **lab 3**, or the `.sta.rpt` file in the `syn/output_files` sub-folder. Explain why this path is the critical path in your design.

Submit your sources and approximately half a page of reasoning, with a maximum length of one page. Follow the directory structure provided in the `exercise1` folder. Place your report, in `.pdf`, `.txt`, or `.md` format, in `exercise1/doc`.

Your submission is due 16 hours before your next lab session. Late submissions will be penalized.

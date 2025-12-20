onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/clk
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/rst
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/input_port
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/output_port
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/out_en
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_PC/pc_in
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_PC/pc_out
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_PC/pc_reg
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_Control/opcode
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_Control/reg_write
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_Control/reg_write_2
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_Control/branch_type
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_RegFile/write_addr1
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_RegFile/write_addr2
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_RegFile/read_data1
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_RegFile/read_data2
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_RegFile/registers
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_SP/sp_reg
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ForwardingUnit/forward_a
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ForwardingUnit/forward_b
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ALU/SrcA
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ALU/SrcB
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ALU/ALU_Sel
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ALU/ALU_Result
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ALU/Zero
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ALU/Negative
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_ALU/Carry
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_Memory/data_in
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_Memory/data_out
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_Memory/ram
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_EX_MEM/reg_write_in
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_EX_MEM/reg_write_2_in
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_EX_MEM/rdst_addr_in
add wave -noupdate -radix hexadecimal /tb_pipeline/uut/U_EX_MEM/rsrc_addr_in
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {56543 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 248
configure wave -valuecolwidth 188
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {45654 ps} {106663 ps}

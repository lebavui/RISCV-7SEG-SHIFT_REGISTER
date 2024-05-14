.global init

.eqv GPIO_ENABLE_REG, 0x60004020    # Cho phép xuất tín hiệu các chân GPIO
.eqv GPIO_OUT_REG, 0x60004004       # Thiết lập mức logic đầu ra
.eqv GPIO_OUT_W1TS_REG, 0x60004008
.eqv GPIO_OUT_W1TC_REG, 0x6000400C

.data
  digits: .word 0x03, 0x9F, 0x25, 0x0D, 0x99, 0x49, 0x41, 0x1F, 0x01, 0x09

.text

# Code thử nghiệm kết nối LED7 đoạn sử dụng thanh ghi dịch
# GPIO0 -> Data In
# GPIO1 -> CLK
# GPIO2 -> Load

init:
  li a1, GPIO_ENABLE_REG  
  li a2, 0x07             # Xuất tín hiệu các chân GPIO0 đến GPIO2 (thiết lập 8 bits)
  sw a2, 0(a1)            # Thiết lập các bits trong GPIO_ENABLE_REG

  # li a1, GPIO_OUT_W1TC_REG
  # li a2, 1
  # sw a2, 0(a1)

  li a0, 0x99
  call shift_1_byte

  li a0, 0x01
  call shift_1_byte

  li a0, 0x09
  call shift_1_byte

  li a0, 0x9F
  call shift_1_byte

  call latch

main_loop:  
  nop
  nop
  nop
next:
  j main_loop


shift_1_byte:
  addi sp, sp, -8
  sw ra, 0(sp)
  sw a0, 4(sp)

  addi t0, a0, 0
  addi t1, zero, 0xFF
shift_loop:
  andi a0, t0, 1
  call shift_1_bit
  srli t0, t0, 1
  srli t1, t1, 1
  bne t1, zero, shift_loop
  
  lw a0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 8
  ret


latch:
  addi sp, sp, -4
  sw ra, 0(sp)

  li a2, 2
  li a1, GPIO_OUT_W1TS_REG  # Set latch
  sw a2, 0(a1)
  li a1, GPIO_OUT_W1TC_REG  # Clear latch
  sw a2, 0(a1)

  lw ra, 0(sp)
  addi sp, sp, 4
  ret


shift_1_bit:
  addi sp, sp, -4
  sw ra, 0(sp)

  beq a0, zero, clear_bit
set_bit:
  li a1, GPIO_OUT_W1TS_REG
  j update_bit
clear_bit:
  li a1, GPIO_OUT_W1TC_REG
update_bit:
  li a2, 1
  sw a2, 0(a1)

  li a2, 4
  li a1, GPIO_OUT_W1TS_REG  # Set CLK
  sw a2, 0(a1)
  li a1, GPIO_OUT_W1TC_REG  # Clear CLK
  sw a2, 0(a1)

  lw ra, 0(sp)
  addi sp, sp, 4
  ret

delay:
  li a3, 0
  li a4, 1000000
delay_loop:
  addi a3, a3, 1
  blt a3, a4, delay_loop
  li a3, 0
  ret
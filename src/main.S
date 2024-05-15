.global init

.eqv GPIO_ENABLE_REG, 0x60004020    # Cho phép xuất tín hiệu các chân GPIO
.eqv GPIO_OUT_REG, 0x60004004       # Thiết lập mức logic đầu ra
.eqv GPIO_OUT_W1TS_REG, 0x60004008
.eqv GPIO_OUT_W1TC_REG, 0x6000400C

.data
  digits: .word 0x03, 0x9F, 0x25, 0x0D, 0x99, 0x49, 0x41, 0x1F, 0x01, 0x09

.text

# Điều khiển LED 7 đoạn sử dụng thanh ghi dịch
# 2 đèn LED 7 đoạn, mỗi LED điều khiển bởi 1 thanh ghi dịch (có sẵn module 2 LED 7 đoạn)
#
# Để điều khiển module này cần nối 5 chân
# VCC -> 3.3V
# GND -> GND
# SDI (Data In) -> GPIO0
# SCK (Data Clock) -> GPIO2 (mỗi khi có sườn + của CLK thì thanh ghi dịch 1 bit)
# Load -> GPIO1 (khi có sườn + thì chốt dữ liệu ra các chân của thanh ghi dịch)
#
# Chương trình sau điều khiển module 2 LED 7 đoạn, đếm các số từ 0 đến 99

init:
  li a1, GPIO_ENABLE_REG  
  li a2, 0x07             # Xuất tín hiệu các chân GPIO0 đến GPIO2 (thiết lập 8 bits)
  sw a2, 0(a1)            # Thiết lập các bits trong GPIO_ENABLE_REG

  li s0, 0                # Biến đếm từ 00 đến 99
  li s1, 100              # Giá trị chặn trên
  li s2, 10               # Giá trị tạm thời dùng để tách các chữ số

  la t0, digits           # Mảng digits chứa mã bit hiển thị LED 7 đoạn các chữ số từ 0 đến 9

main_loop:  
  rem s3, s0, s2          # s3 chứa chữ số hàng đơn vị
  div s4, s0, s2          # s4 chứa chữ số hàng chục

  addi t1, s3, 0          # t1 chứa địa chỉ mã bit ứng với chữ số hàng đơn vị
  slli t1, t1, 2
  add t1, t1, t0
  lw a0, 0(t1)            # lấy giá trị mã bit và đưa vào thanh ghi dịch
  call shift_1_byte

  addi t1, s4, 0          # t1 chứa địa chỉ mã bit ứng với chữ số hàng chục
  slli t1, t1, 2
  add t1, t1, t0
  lw a0, 0(t1)            # lấy giá trị mã bit và đưa vào thanh ghi dịch
  call shift_1_byte

  call latch              # chốt dữ liệu, cập nhật LED 7 đoạn

  li a0, 10000000         # chờ trước khi hiển thị số tiếp theo
  call delay

  addi s0, s0, 1          # tăng bước lặp
  bne s0, s1, next        # nếu đến 100 thì quay về 0
  li s0, 0
next:
  j main_loop

# Hàm dịch 1 byte ra thanh ghi
# Tham số:
# a0 - byte cần dịch
shift_1_byte:
  addi sp, sp, -16        # lưu giá trị các thanh ghi bị thay đổi
  sw ra, 0(sp)
  sw a0, 4(sp)
  sw t0, 8(sp)
  sw t1, 12(sp)

  addi t0, a0, 0          # tách từng bit để dịch
  addi t1, zero, 0xFF
shift_loop:
  andi a0, t0, 1
  call shift_1_bit
  srli t0, t0, 1
  srli t1, t1, 1
  bne t1, zero, shift_loop
  
  lw t1, 12(sp)           # khôi phục giá trị các thanh ghi đã lưu
  lw t0, 8(sp)
  lw a0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 16
  ret


# Hàm chốt dữ liệu ra thanh ghi
# GPIO1 -> Load
latch:
  addi sp, sp, -12
  sw ra, 0(sp)
  sw t0, 4(sp)
  sw t1, 8(sp)

  li t1, 2
  li t0, GPIO_OUT_W1TS_REG  # Set latch
  sw t1, 0(t0)
  li t0, GPIO_OUT_W1TC_REG  # Clear latch
  sw t1, 0(t0)

  lw t1, 8(sp)
  lw t0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 12
  ret

# Hàm dịch 1 bit vào thanh ghi dịch
# GPIO0 -> Data in 
# GPIO2 -> Data clock
# Tham số:
# a0 - giá trị bit cần dịch (0 hoặc khác 0)
shift_1_bit:
  addi sp, sp, -12
  sw ra, 0(sp)
  sw t0, 4(sp)
  sw t1, 8(sp)

  # Ghi giá trị ra GPIO0
  beq a0, zero, clear_bit
set_bit:
  li t0, GPIO_OUT_W1TS_REG
  j update_bit
clear_bit:
  li t0, GPIO_OUT_W1TC_REG
update_bit:
  li t1, 1
  sw t1, 0(t0)

  # Bật tắt CLK để dịch bit
  li t1, 4
  li t0, GPIO_OUT_W1TS_REG  # Set CLK
  sw t1, 0(t0)
  li t0, GPIO_OUT_W1TC_REG  # Clear CLK
  sw t1, 0(t0)

  lw t1, 8(sp)
  lw t0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 12
  ret

# Hàm delay
# Tham số:
# a0 - số lần lặp (khoảng 10^6)
delay:
  addi sp, sp, -8
  sw ra, 0(sp)
  sw t0, 4(sp)

  li t0, 0                  # Giá trị biến đếm
loop_delay:
  addi t0, t0, 1            
  blt t0, a0, loop_delay

  lw t0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 8
  ret
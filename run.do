# Закрыть предыдущую симуляцию
quit -sim

# Создать библиотеку
vlib work
vmap work work

# Компиляция
vlog -sv apb_slave.sv tb_apb_slave.sv

# Запуск симуляции с отключением оптимизации
vsim -voptargs="+acc" TB

# Открыть окно Wave
view wave

# Добавить сигналы
add wave -divider "Clocks & Reset"
add wave -position end sim:/TB/pclk
add wave -position end sim:/TB/presetn

add wave -divider "APB Control"
add wave -position end sim:/TB/psel
add wave -position end sim:/TB/penable
add wave -position end sim:/TB/pwrite
add wave -position end sim:/TB/pready
add wave -position end sim:/TB/pslverr

add wave -divider "APB Data"
add wave -position hex sim:/TB/paddr
add wave -position hex sim:/TB/pwdata
add wave -position hex sim:/TB/prdata

add wave -divider "DUT Registers"
add wave -position hex sim:/TB/DUT/reg_id
add wave -position hex sim:/TB/DUT/reg_date
add wave -position hex sim:/TB/DUT/reg_surname
add wave -position hex sim:/TB/DUT/reg_name
add wave -position hex sim:/TB/DUT/register_with_some_name
add wave -position end sim:/TB/DUT/apb_st

# Запустить симуляцию
run -all
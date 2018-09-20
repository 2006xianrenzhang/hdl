
package require qsys
source ../../scripts/adi_env.tcl
source ../../scripts/adi_ip_intel.tcl

ad_ip_create axi_spi_engine {AXI SPI Engine} p_elaboration
ad_ip_files axi_spi_engine [list\
  $ad_hdl_dir/library/common/up_axi.v \
  axi_spi_engine.v]

# parameters

ad_ip_parameter ID INTEGER 0
ad_ip_parameter DATA_WIDTH INTEGER 8
ad_ip_parameter NUM_OF_SDI INTEGER 1
ad_ip_parameter CMD_FIFO_ADDRESS_WIDTH INTEGER 4
ad_ip_parameter SDO_FIFO_ADDRESS_WIDTH INTEGER 5
ad_ip_parameter SDI_FIFO_ADDRESS_WIDTH INTEGER 5
ad_ip_parameter MM_IF_TYPE INTEGER 1
ad_ip_parameter UP_ADDRESS_WIDTH INTEGER 14
ad_ip_parameter ASYNC_SPI_CLK INTEGER 0
ad_ip_parameter NUM_OFFLOAD INTEGER 1
ad_ip_parameter OFFLOAD0_CMD_MEM_ADDRESS_WIDTH INTEGER 4
ad_ip_parameter OFFLOAD0_SDO_MEM_ADDRESS_WIDTH INTEGER 4

proc p_elaboration {} {

  # read parameters

  set mm_if_type [get_parameter_value "MM_IF_TYPE"]

  set up_address_width [get_parameter_value UP_ADDRESS_WIDTH]
  set num_of_sdi [get_parameter_value NUM_OF_SDI]
  set data_width [get_parameter_value DATA_WIDTH]

  # interrupt

  add_interface interrupt_sender interrupt end
  add_interface_port interrupt_sender irq irq Output 1

  if {$mm_if_type} {

    # Microprocessor interface

    ad_interface clock   up_clk    input                  1
    ad_interface reset-n up_rstn   input                  1   if_up_clk
    ad_interface signal  up_wreq   input                  1
    ad_interface signal  up_wack   output                 1
    ad_interface signal  up_waddr  input  $up_address_width
    ad_interface signal  up_wdata  input                 31
    ad_interface signal  up_rreq   input                  1
    ad_interface signal  up_rack   output                 1
    ad_interface signal  up_raddr  output $up_address_width
    ad_interface signal  up_rdata  output                31

  } else {

    # AXI Memory Mapped interface

    ad_ip_intf_s_axi s_axi_aclk s_axi_aresetn 15

    set_interface_property interrupt_sender associatedAddressablePoint s_axi
    set_interface_property interrupt_sender associatedClock s_axi_clock
    set_interface_property interrupt_sender associatedReset s_axi_reset
    set_interface_property interrupt_sender ENABLED true

  }

  # SPI Engine interfaces

  ad_interface clock spi_clk     input 1
  ad_interface reset spi_resetn  input 1 if_spi_clk

  add_interface cmd_if conduit end
  add_interface_port cmd_if cmd_ready enable  input   1
  add_interface_port cmd_if cmd_valid valid   output  1
  add_interface_port cmd_if cmd       data    output 16

  set_interface_property cmd_if associatedClock if_spi_clk
  set_interface_property cmd_if associatedReset if_spi_resetn

  add_interface sdo_if conduit end
  add_interface_port sdo_if sdo_data_ready  enable  input           1
  add_interface_port sdo_if sdo_data_valid  valid   output          1
  add_interface_port sdo_if sdo_data        data    output $data_width

  set_interface_property sdo_if associatedClock if_spi_clk
  set_interface_property sdo_if associatedReset if_spi_resetn

  add_interface sdi_if conduit end
  add_interface_port sdi_if sdi_data_ready  ready output                      1
  add_interface_port sdi_if sdi_data_valid  valid input                       1
  add_interface_port sdi_if sdi_data        data  input [expr $num_of_sdi * $data_width]

  set_interface_property sdo_if associatedClock if_spi_clk
  set_interface_property sdo_if associatedReset if_spi_resetn

  add_interface sync_if conduit end
  add_interface_port sync_if sync_data_valid  valid input   1
  add_interface_port sync_if sync_data_ready  ready output  1
  add_interface_port sync_if sync_data        data  input   8

  set_interface_property sync_if associatedClock if_spi_clk
  set_interface_property sync_if associatedReset if_spi_resetn

  # Offload interfaces

  add_interface offload0_cmd_if conduit end
  add_interface_port offload0_cmd_if cmd_wre    wre   output  1
  add_interface_port offload0_cmd_if cmd_data   data  output 16

  set_interface_property offload0_cmd_if associatedClock if_spi_clk
  set_interface_property offload0_cmd_if associatedReset if_spi_resetn

  add_interface offload0_sdo_if conduit end
  add_interface_port offload0_sdo_if sdo_wre    wre   output  1
  add_interface_port offload0_sdo_if sdo_data   data  output  $data_width

  set_interface_property offload0_sdo_if associatedClock if_spi_clk
  set_interface_property offload0_sdo_if associatedReset if_spi_resetn

  ad_interface signal  offload0_mem_reset  output  1   reset
  ad_interface signal  offload0_enable     output  1   enable
  ad_interface signal  offload0_enabled    input   1   enabled

}

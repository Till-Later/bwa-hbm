set_property file_type {VHDL 2008} [get_files $action_hw_dir/generated/ctrl_reg_demux.vhd]

set_property file_type {VHDL 2008} [get_files $action_hw_dir/generated/*]

#create_pblock pblock_board_support
#resize_pblock pblock_board_support -add CLOCKREGION_X0Y4:CLOCKREGION_X2Y7
#add_cells_to_pblock pblock_board_support [get_cells [list oc_func0/fw_afu/snap_core_i]] -clear_locs
#add_cells_to_pblock pblock_board_support [get_cells [list bsp0]] -clear_locs
#add_cells_to_pblock pblock_board_support [get_cells [list cfg0]] -clear_locs
#add_cells_to_pblock pblock_board_support [get_cells [list oc_func0/cfg_f1]] -clear_locs
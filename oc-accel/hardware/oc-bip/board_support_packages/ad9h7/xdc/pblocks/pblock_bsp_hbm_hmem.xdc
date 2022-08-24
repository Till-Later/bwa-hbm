create_pblock pblock_bsp
add_cells_to_pblock [get_pblocks pblock_bsp] [get_cells {
    bsp0/dlx_phy
    bsp0/tlx
    bsp0/DLx_phy_vio_0_inst
    bsp0/vio_reset_n_inst_tlx
}]
remove_cells_from_pblock pblock_bsp [get_cells bsp0/dlx_phy/BUFGCE_DIV_inst]
resize_pblock pblock_bsp -add CLOCKREGION_X0Y4:CLOCKREGION_X0Y7
set_property CONTAIN_ROUTING 1 [get_pblocks pblock_bsp]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_bsp]

create_pblock pblock_hmem
add_cells_to_pblock pblock_hmem [get_cells {
    oc_func0/cfg_f1
    oc_func0/fw_afu/snap_core_i
    oc_func0/fw_afu/desc
    oc_func0/fw_afu/mvio_soft_reset
    oc_func0/fw_afu/action_w/i_multiplexed_axi_rw_port_hlshmem_3/i_rd_multiplexer
    oc_func0/fw_afu/action_w/i_multiplexed_axi_rw_port_hlshmem_3/i_wr_multiplexer
    oc_func0/fw_afu/action_w/i_multiplexed_axi_rw_port_hlshmem_3/i_pipeline_stage_in
    oc_func0/fw_afu/action_w/i_action_control
    oc_func0/fw_afu/action_w/i_ctrl_reg_demux
}]
resize_pblock pblock_hmem -add CLOCKREGION_X1Y4:CLOCKREGION_X7Y7

create_pblock pblock_action
add_cells_to_pblock pblock_action [get_cells {
    oc_func0/fw_afu/action_w/i_results_to_host_manager
    oc_func0/fw_afu/action_w/i_smem_task_scheduler

    oc_func0/fw_afu/action_w/i_init_bwt/i_hls/init_bwt_host_mem_V_m_axi_U
    oc_func0/fw_afu/action_w/i_init_bwt/i_hls/grp_membus_to_HBMbus_fu_425
    oc_func0/fw_afu/action_w/i_init_bwt/i_hls/distribution_buffers_*_V_U
    oc_func0/fw_afu/action_w/i_init_bwt/i_hls/buffer1024_V_U
    oc_func0/fw_afu/action_w/i_init_bwt/i_hls/buffer256_U

    oc_func0/fw_afu/action_w/i_sequence_buffer_uram_group_*
    oc_func0/fw_afu/action_w/i_sequence_read_bus_arbiter_group_*
    oc_func0/fw_afu/action_w/i_sequences_mem_write_distributor

    oc_func0/fw_afu/action_w/i_smem_core_*
    oc_func0/fw_afu/action_w/i_bwt_request_controller
    oc_func0/fw_afu/action_w/i_stream_monitor_aggregator
}]
resize_pblock pblock_action -add {CLOCKREGION_X0Y0:CLOCKREGION_X7Y3  CLOCKREGION_X4Y4:CLOCKREGION_X7Y7 CLOCKREGION_X0Y8:CLOCKREGION_X7Y11}

create_pblock pblock_slr0
add_cells_to_pblock pblock_slr0 [get_cells {}]
resize_pblock pblock_slr0 -add {CLOCKREGION_X0Y0:CLOCKREGION_X7Y3}

create_pblock pblock_slr2
add_cells_to_pblock pblock_slr2 [get_cells {}]
resize_pblock pblock_slr2 -add CLOCKREGION_X0Y8:CLOCKREGION_X7Y11

create_pblock pblock_hbm
add_cells_to_pblock pblock_hbm [get_cells [list oc_func0/fw_afu/hbm_top_wrapper_i/hbm_top_i/hbm]]
resize_pblock pblock_hbm -add CLOCKREGION_X0Y0:CLOCKREGION_X7Y0

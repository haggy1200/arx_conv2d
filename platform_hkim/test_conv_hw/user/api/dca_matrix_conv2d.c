#include "platform_info.h"
#include "ervp_malloc.h"
#include "ervp_matrix_op_sw.h"
#include "ervp_printf.h"
#include "dca_matrix_info.h"

#include "dca_matrix_conv2d.h"

typedef struct {
	dca_matrix_info_t mi;
	dca_matrix_info_t mk;
	dca_matrix_info_t mo;
  unsigned int stride_m1 : 16;
  unsigned int pad : 16;
} dca_matrix_conv2d_inst_t;

void dca_matrix_conv2d_hwinfo_elaborate(dca_matrix_conv2d_hwpara_t* hwpara, dca_matrix_conv2d_hwinfo_t* hwinfo)
{
	hwinfo->input_matrix_size = hwpara->input_matrix_size;
	hwinfo->kernel_matrix_size = hwpara->kernel_matrix_size;
	hwinfo->output_matrix_size = hwpara->output_matrix_size;
}

void dca_matrix_conv2d(ervp_mop_mapping_t *mop_mapping, const dca_matrix_conv2d_hwinfo_t* const hwinfo, const ErvpMatrixInfo *mi_info, const ErvpMatrixInfo *mk_info, ErvpMatrixInfo *mo_info, int conv_options)
{
	dca_matrix_conv2d_inst_t inst;

  ervp_mconv_option_t conv_option;
	conv_option.value = conv_options;
	inst.stride_m1 = conv_option.br.stride_m1;
	//inst.pad = conv_option.br.pad;
	inst.pad = 0; // by hkim, V250818

	dca_generate_matrix_info(mi_info, &(inst.mi));
	dca_generate_matrix_info(mk_info, &(inst.mk));
	dca_generate_matrix_info(mo_info, &(inst.mo));
	flush_cache();
	
	mmiox1_inst_push(hwinfo->mmiox_info, &inst, 1, 0);
	printf("run @ dca_matrix_conv2d.c");
	mmiox1_inst_wait_busy(hwinfo->mmiox_info);
	// just for test
  //matrix_conv_sw(mi_info, mk_info, mo_info, conv_options);
}

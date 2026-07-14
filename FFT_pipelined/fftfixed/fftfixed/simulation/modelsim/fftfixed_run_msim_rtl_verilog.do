transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/top.v}
vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/simple_twiddle_blk.v}
vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/s2p.v}
vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/pipeline_regs.v}
vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/p2s.v}
vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/no_twiddle_blk.v}
vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/fft_core.v}
vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/complex_twiddle_blk.v}

vlog -vlog01compat -work work +incdir+C:/Users/kollu/dspquartus/fftfixed {C:/Users/kollu/dspquartus/fftfixed/tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaii_ver -L rtl_work -L work -voptargs="+acc"  tb

add wave *
view structure
view signals
run -all

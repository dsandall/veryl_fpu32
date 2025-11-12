package veryl_fpu_FPops;
    import veryl_fpu_FPdefs::*;


    function automatic veryl_fpu_FPdefs::fp_num subtract(
        input var veryl_fpu_FPdefs::fp_num X,
        input var veryl_fpu_FPdefs::fp_num Y
    ) ;
        // flipped sign copy of Y
        veryl_fpu_FPdefs::fp_num Yy  ;
        Yy   = Y;
        Yy.s = ~Yy.s;
        return veryl_fpu_Add::add(X, Yy);
    endfunction

    function automatic veryl_fpu_FPdefs::fp_num sqrt(
        input var veryl_fpu_FPdefs::fp_num X,
        input var veryl_fpu_FPdefs::fp_num Y
    ) ;
        //TODO:
    endfunction
    function automatic veryl_fpu_FPdefs::fp_num min(
        input var veryl_fpu_FPdefs::fp_num X,
        input var veryl_fpu_FPdefs::fp_num Y
    ) ;
        //TODO:
        //edge cases in rv manual 20.5
    endfunction
    function automatic veryl_fpu_FPdefs::fp_num max(
        input var veryl_fpu_FPdefs::fp_num X,
        input var veryl_fpu_FPdefs::fp_num Y
    ) ;
        //TODO:
        //edge cases in rv manual 20.5
    endfunction
    function automatic veryl_fpu_FPdefs::fp_num div(
        input var veryl_fpu_FPdefs::fp_num X,
        input var veryl_fpu_FPdefs::fp_num Y
    ) ;
        //TODO:
    endfunction
endpackage
//# sourceMappingURL=fp_package.sv.map

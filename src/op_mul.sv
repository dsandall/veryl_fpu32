package veryl_fpu_Mul;
    import veryl_fpu_FPdefs::*;

    function automatic veryl_fpu_FPdefs::fp_num mul(
        input var veryl_fpu_FPdefs::fp_num X,
        input var veryl_fpu_FPdefs::fp_num Y
    ) ;
        logic      s;
        int signed e;
        longint unsigned mm;
        veryl_fpu_FPdefs::fp_num sum;
        $display("MUL BEGIN");
        $display("x = %d, %d, %d", X.s, X.e, X.m);
        $display("y = %d, %d, %d", Y.s, Y.e, Y.m);

        ////////
        // multiply by 0
        ////////

        if ((X.e == 0 && X.m == 0)) begin
            return 0;
        end else if ((Y.e == 0 && Y.m == 0)) begin
            return 0;
        end

        $display("not zero");

        ////////
        // math
        ////////
        s = X.s ^ Y.s;

        e = X.e + Y.e - 127;

        mm = (unsigned'(int'(X.m)) | (1 << veryl_fpu_FPdefs::man_bits)) * (unsigned'(int'(Y.m)) | (1 << veryl_fpu_FPdefs::man_bits));

        $display("sem %d,%d,%d", s, e, mm);
        ////////
        // shift mantissa down
        ////////
        for (int signed i = 0; i < veryl_fpu_FPdefs::man_bits; i++) begin
            // shift down to implicit one
            if ((mm > (1 << (veryl_fpu_FPdefs::man_bits + 1)) - 1 && e > 0)) begin
                e  -=  1;
                mm >>= 1;
            end
        end
        $display("sem %d,%d,%d", s, e, mm);

        if ((e < 0)) begin
            //return underflow;
            return 0;
        end else if ((e >= 2 * 8)) begin
            //return overflow;
            return 0;
        end
        $display("sem %d,%d,%d", s, e, mm);

        sum = '{
            s  : s ,
            e  : e ,
            m  : mm
        };
        return sum;
    endfunction

endpackage
//# sourceMappingURL=op_mul.sv.map

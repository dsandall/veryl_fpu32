

package veryl_fpu_Add;
    import veryl_fpu_FPdefs::*;

    function automatic veryl_fpu_FPdefs::fp_num add(
        input var veryl_fpu_FPdefs::fp_num X,
        input var veryl_fpu_FPdefs::fp_num Y
    ) ;
        ////////////
        //// fp addition:
        ////////////
        veryl_fpu_FPdefs::fp_num sum;
        int unsigned         Am;
        int unsigned         Bm;
        int signed           Ae;
        int signed           Be;
        logic        [1-1:0] As;
        logic        [1-1:0] Bs;
        int unsigned diff      ;
        int unsigned Bm_shifted;
        int unsigned m_sum;
        int signed   e_sum;

        ////////////////////////
        // Sign/magnitude logic
        ////////////////////////
        // Determine addition or subtraction of mantissas
        longint unsigned a       ;
        logic            gaurd   ;
        logic            round   ;
        logic            sticky  ;
        $display("ADD BEGIN");
        $display("x = %d, %d, %d", X.s, X.e, X.m);
        $display("y = %d, %d, %d", Y.s, Y.e, Y.m);


        // select larger magnitude, put at A

        if ((X.e > Y.e)) begin
            Am = X.m;
            Bm = Y.m;
            Ae = X.e;
            Be = Y.e;
            As = X.s;
            Bs = Y.s;

        end else begin
            Am = Y.m;
            Bm = X.m;
            Ae = Y.e;
            Be = X.e;
            As = Y.s;
            Bs = X.s;
        end


        // check for infinities or NaNs
        if ((Ae == 255)) begin
            if ((Am != 0)) begin
                // a is NaN
                $display("a is NaN");
                return veryl_fpu_FPdefs::canonNaN;
            end else begin
                // a is inf
                if ((Be == 255 && Bm == 0)) begin
                    if ((As != Bs)) begin
                        // inf - inf = NaN
                        $display("diff of infinities");
                        return veryl_fpu_FPdefs::canonNaN;
                    end
                end
                // answer is inf
                sum.e    = Ae;
                sum.s    = As;
                sum.m    = Am;
                $display("A is inf");
                return sum;
            end
        end

        if ((Be == 255)) begin
            if ((Bm != 0)) begin
                // b is NaN
                $display("b is NaN");
                return veryl_fpu_FPdefs::canonNaN;
            end else begin
                // b is inf
                if ((Ae == 255 && Am == 0)) begin
                    if ((Bs != As)) begin
                        // inf - inf = NaN
                        $display("diff of infinities");
                        return veryl_fpu_FPdefs::canonNaN;
                    end
                end
                // answer is inf
                sum.e    = Be;
                sum.m    = Bm;
                sum.s    = Bs;
                $display("B is inf");
                return sum;
            end
        end

        ////////////////////////
        // Now we can treat them like real numbers
        ////////////////////////

        // normalize the sum: ensure the "secret bit" beyond the mantissa is 1
        // add the implicit leading one on mantissas, unless Ae is 0
        Am = (((Ae != 0)) ? ( (Am | (1 << veryl_fpu_FPdefs::man_bits)) ) : ( Am ));
        Bm = (((Be != 0)) ? ( (Bm | (1 << veryl_fpu_FPdefs::man_bits)) ) : ( Bm ));

        $display("A = %d, %d, %d", As, Ae, Am);
        $display("B = %d, %d, %d", Bs, Be, Bm);

        // Align mantissas

        // check that the shifting would not = 0, skip if no need for shift
        diff       = Ae - Be;
        Bm_shifted = Bm >> diff;

        if ((As == Bs)) begin
            // same sign → add
            $display("same sign, add");
            $display("%d,%d", Am, Bm_shifted);
            m_sum    = Am + Bm_shifted;
            sum.s    = As;
        end else begin
            // opposite signs → subtract
            if ((Am == Bm_shifted)) begin
                $display("self - self = 0");
                // same equalized mantissas
                // -> +-0
                sum.e = 0;
                sum.m = 0;
                return sum;
            end else if ((Am > Bm_shifted)) begin
                $display("diff signs, A is bigger");
                m_sum    = Am - Bm_shifted;
                sum.s    = As; // A had larger magnitude
            end else begin
                $display("diff signs, B is bigger");
                m_sum    = Bm_shifted - Am;
                sum.s    = Bs; // B had larger magnitude
            end
        end
        // Restore implied Exp offset
        e_sum = Ae;

        $display("output 1: %d, %d, %d", sum.s, e_sum, m_sum);




        ////////////////////////
        // rounding
        ////////////////////////
        a        = (unsigned'(longint'(Bm)) << veryl_fpu_FPdefs::man_bits) >> diff; // shift up to preserve, then down
        gaurd    = a[veryl_fpu_FPdefs::man_bits - 1];
        round    = a[veryl_fpu_FPdefs::man_bits - 2];
        sticky   = a[veryl_fpu_FPdefs::man_bits - 3:0] > 0;
        $display("g r s (%d%d%d)", gaurd, round, sticky);

        if ((gaurd)) begin
            if ((round || sticky || (m_sum & 1))) begin
                $display("rounding up");
                m_sum    += 1;
            end
        end

        ////////////////////////
        // shifting / normalizing to the implicit binary point
        ////////////////////////
        // if mantissa too large (larger than the implicit 1+all mantissa bits)
        if ((m_sum > ((1 << (veryl_fpu_FPdefs::man_bits + 1)) - 1))) begin
            $display("normalize once", m_sum);
            // shift right, inc exponent
            m_sum =  m_sum >> 1;
            e_sum += 1;
        end else begin
            // if mantissa too small, (no implicit one exists yet)
            for (int signed i = 0; i < veryl_fpu_FPdefs::man_bits; i++) begin //NOTE: while loop please
                // m_sum less than the implicit leading one AND e_sum not abs min.
                if ((m_sum < (1 << veryl_fpu_FPdefs::man_bits) && e_sum > 0)) begin
                    $display("normalize loop", m_sum);
                    // mantissa too small, move up
                    // shift left, dec exponent until done
                    m_sum =  m_sum << 1;
                    e_sum -= 1;
                end
            end
        end


        // correct for subnormal numbers - which DONT have an implicit one and may need it to be carried over
        if ((e_sum == 0 && m_sum[23] == 1)) begin
            $display ("DUMB HACK TRIGGERED, BE CAREFUL");
            e_sum     += 1;
            m_sum[23] =  0;
        end


        // now we check that all the bits fit and other edge cases
        if ((e_sum >= (2 ** veryl_fpu_FPdefs::exp_bits) - 1)) begin
            $display("overflow", sum);
            sum.e    = 255;
            sum.m    = 0;
            return sum;
        end else if ((e_sum < 0)) begin
            //TODO:
            $display("underflow", sum);
            return veryl_fpu_FPdefs::fp_num'(69.0);
        end

        // truncate and package
        sum.m    = m_sum[veryl_fpu_FPdefs::man_bits - 1:0];
        sum.e    = e_sum[veryl_fpu_FPdefs::exp_bits - 1:0];
        $display("output fin: %d, %d, %d", sum.s, sum.e, sum.m);
        return sum;
    endfunction
endpackage
//# sourceMappingURL=op_add.sv.map

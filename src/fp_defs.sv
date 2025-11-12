package veryl_fpu_FPdefs;
    localparam byte unsigned sign_bits = 1;
    localparam byte unsigned exp_bits  = 8;
    localparam byte unsigned man_bits  = 23;

    typedef struct packed {
        logic [sign_bits-1:0] s;
        logic [exp_bits-1:0]  e;
        logic [man_bits-1:0]  m;
    } fp_num;

    // as per the riscv spec, the only NaN to output from FPU shall be the canonNaN
    localparam fp_num canonNaN = '{
        s       : 1                  ,
        e       : 255                ,
        m       : 1 << (man_bits - 1)
    };

    typedef enum logic [3-1:0] {
        round_mode_RNE = $bits(logic [3-1:0])'(0),
        round_mode_RTZ = $bits(logic [3-1:0])'(1),
        round_mode_RDN = $bits(logic [3-1:0])'(2),
        round_mode_RUP = $bits(logic [3-1:0])'(3),
        round_mode_RMM = $bits(logic [3-1:0])'(4),
        round_mode_DYN = $bits(logic [3-1:0])'(7)
    } round_mode;

    typedef struct packed {
        logic NV;
        logic DZ;
        logic OF;
        logic UF;
        logic NX;
    } err_flags;
endpackage
//# sourceMappingURL=fp_defs.sv.map

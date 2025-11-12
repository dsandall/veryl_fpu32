`ifndef SYNTHESIS
  /*verilator lint_off WIDTHEXPAND*/
`endif

module veryl_fpu_fp_unit
    import veryl_fpu_FPdefs::*;
(
    input  var logic [32-1:0] X      ,
    input  var logic [32-1:0] Y      ,
    output var logic [32-1:0] out    ,
    input  var logic          i_clk  ,
    input  var logic          i_rst  ,
    input  var logic          i_start,
    output var logic          o_done ,
    // Refer to RV ext F spec
    input  var round_mode         i_round, //TODO:
    output var err_flags          o_flags, //TODO:
    input  var logic      [3-1:0] i_sel  
);


    typedef enum byte unsigned {
        FPU_state_idle,
        FPU_state_work,
        FPU_state_done
    } FPU_state;
    FPU_state state;

    logic [32-1:0] res;
    always_ff @ (posedge i_clk, negedge i_rst) begin
        if (!i_rst) begin
            $display("reset hit!");
            state    <= FPU_state_idle;
        end else begin
            case ((state)) inside
                FPU_state_idle: begin
                    $display("idle state");
                    if (i_start) begin
                        case ((i_sel)) inside
                            1: res <= veryl_fpu_Add::add(X, Y);
                            2: res <= veryl_fpu_Mul::mul(X, Y);
                            3: res <= veryl_fpu_FPops::subtract(X, Y);
                        endcase
                        $display("computing!");
                        state    <= FPU_state_work;
                    end
                end
                FPU_state_work: begin
                    $display("working");
                    out      <= res;
                    $display("output is %f", res);
                    o_done   <= 1;
                    state    <= FPU_state_done;
                end
                FPU_state_done: begin
                    if ((i_start)) begin
                        $display("done, waiting for ack");
                    end else begin
                        $display("done, ack complete");
                        o_done   <= 0;
                        state    <= FPU_state_idle;
                    end
                end
                default: begin
                    $display("unexpected state! plsfix");
                end
            endcase
        end
    end
endmodule
//# sourceMappingURL=fpu.sv.map

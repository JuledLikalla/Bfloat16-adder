/////////////////////////////////////////////////////////////////////
// Design unit: bfloat16_adder
//            :
// File name  : bfloat16_adder.sv
//            :
// Description: Implementation of bfloat16 adder
//            : The adder calculates the sum in 6 clock cycles
//            : 
// Limitations: None
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Juled Likalla
//            : jl15g22@soton.ac.uk
//            : 	
//			   :
// Revision   : Version 1 28/11/22
//            : Last modified: 08/12/22
/////////////////////////////////////////////////////////////////////

module bfloat16_adder (output logic [15:0] sum,
    output logic ready, input logic [15:0] a, b,
    input logic clock, nreset);

    typedef struct packed{
      logic sign;
      logic [7:0] exp;
      logic [16:0] mantisa;
    } float16_type;

    float16_type reg_a, next_reg_a;  
    float16_type reg_b, next_reg_b;
    float16_type reg_sum, next_reg_sum;

    logic [7:0] diff_exp_r, next_diff_exp_r;
    logic [16:0] mantissas_sum_r, next_mantissas_sum_r;
    logic special_case, next_special_case;
  
    enum {GET_FIRST_INPUT, GET_SECOND_INPUT, SUBTRACT_EXP, SHIFT_MANTISSA, 
          ADD_SUBTRACT_MANTISSAS, SHIFT_RESULT, CALCULATE_SUM} present_state, next_state;

    always_comb 
        begin
          next_reg_a = reg_a;
          next_reg_b = reg_b;
          next_reg_sum = reg_sum;
          next_state = present_state;
          ready = 1'b0;
          sum = '0;
          next_diff_exp_r = diff_exp_r;
          next_mantissas_sum_r = mantissas_sum_r;
          next_special_case = special_case;
          unique case (present_state)
            GET_FIRST_INPUT: begin  
              if(a !== 'X && a !== 'Z) 
                begin           
                  next_reg_a.sign = a[15];
                  next_reg_a.exp = a[14:7];
                  next_reg_a.mantisa = {2'b01,a[6:0], {8{1'b0}}};
                  next_mantissas_sum_r = '0;
                end
              next_state = GET_SECOND_INPUT;
            end
            GET_SECOND_INPUT: begin
              if(b !== 'X && b !== 'Z) 
                begin 
                  next_reg_b.sign = b[15];
                  next_reg_b.exp = b[14:7];
                  next_reg_b.mantisa = {2'b01,b[6:0], {8{1'b0}}};
                end
              next_state = SUBTRACT_EXP;
            end
            SUBTRACT_EXP: begin
              if((reg_a == 26'h1FE8000) && (reg_b == 26'h3FE8000)) //3FE80
              begin 
                next_reg_sum = {1'b0, 8'hFF, 17'h0C000};
                next_special_case = 1'b1;
                next_state = CALCULATE_SUM;  
              end  
              else if((reg_a == 26'h3FE8000) && (reg_b == 26'h1FE8000)) //3FE80
              begin 
                next_reg_sum = {1'b0, 8'hFF, 17'h0C000};
                next_special_case = 1'b1;
                next_state = CALCULATE_SUM;  
              end  
              else if({reg_a.exp, reg_a.mantisa} == {reg_b.exp, reg_b.mantisa} && reg_a.sign != reg_b.sign)
                begin
                  next_reg_sum = '0;
                  next_special_case = 1'b1;
                  next_state = CALCULATE_SUM;  
                end
              else if(({reg_a.exp,  reg_a.mantisa[14:0]} == '0) && ({reg_b.exp,  reg_b.mantisa[14:0]} == '0))
                begin 
                  next_reg_sum = '0;
                  if(reg_a.sign)
                    next_reg_sum.sign = 1'b1;
                  next_special_case = 1'b1;
                  next_state = CALCULATE_SUM;  
                end
              else if((reg_a == 26'h1FE8000) && (reg_b == 26'h1FE8000)) //1FE80
                begin 
                  next_reg_sum = {1'b0, 8'hFF, 17'h08000};
                  next_special_case = 1'b1;
                  next_state = CALCULATE_SUM;  
                end      
              else if((reg_a == 26'h3FE8000) && (reg_b == 26'h3FE8000)) //3FE80
                begin 
                  next_reg_sum = {1'b1, 8'hFF, 17'h08000};
                  next_special_case = 1'b1;
                  next_state = CALCULATE_SUM;  
                end     
              else if(reg_a.exp == 8'hFF && reg_a.mantisa)
                begin 
                  next_reg_sum = {reg_a.sign, 8'hFF, reg_a.mantisa};
                  next_special_case = 1'b1;
                  next_state = CALCULATE_SUM;  
                end     
              else if(reg_b.exp == 8'hFF && reg_b.mantisa)
                begin 
                  next_reg_sum = {reg_b.sign, 8'hFF, reg_b.mantisa};
                  next_special_case = 1'b1;
                  next_state = CALCULATE_SUM;  
                end   
              else
                begin
                  next_special_case = 1'b0;
                  if (reg_a.exp > reg_b.exp)
                    begin
                      next_diff_exp_r = reg_a.exp - reg_b.exp;
                    end
                  else if (reg_a.exp < reg_b.exp) 
                    begin
                      next_diff_exp_r = reg_b.exp - reg_a.exp;
                    end
                  next_state = SHIFT_MANTISSA;
                end
            end
            SHIFT_MANTISSA: begin
              if (reg_a.exp > reg_b.exp )
                begin
                  next_reg_b.mantisa = reg_b.mantisa >> diff_exp_r;
                end
              else if (reg_a.exp < reg_b.exp) 
                begin
                  next_reg_a.mantisa = reg_a.mantisa >> diff_exp_r;
                end
                next_state = ADD_SUBTRACT_MANTISSAS;
            end
            ADD_SUBTRACT_MANTISSAS: begin
              next_mantissas_sum_r = reg_a.mantisa + reg_b.mantisa;
              next_reg_sum.sign = reg_a.sign;
              if({reg_a.exp, reg_a.mantisa} > {reg_b.exp, reg_b.mantisa})
                begin
                  if(reg_a.sign != reg_b.sign)
                    next_mantissas_sum_r = reg_a.mantisa - reg_b.mantisa; 
                  next_reg_b.exp = reg_a.exp;
                  next_reg_sum.sign = reg_a.sign;
                end
              else if ({reg_a.exp, reg_a.mantisa} < {reg_b.exp, reg_b.mantisa}) 
                begin
                  if(reg_a.sign != reg_b.sign)
                    next_mantissas_sum_r = reg_b.mantisa - reg_a.mantisa; 
                  next_reg_a.exp = reg_b.exp;
                  next_reg_sum.sign = reg_b.sign;
                end
              next_state = SHIFT_RESULT;
            end
            SHIFT_RESULT: begin
              next_reg_sum.exp = reg_a.exp;
              if(mantissas_sum_r[16] && mantissas_sum_r[15]) begin
                next_reg_sum.exp = reg_a.exp+8'd1;
                next_mantissas_sum_r = mantissas_sum_r >> 1'b1;
              end  
              else if(~mantissas_sum_r[15])
                if(mantissas_sum_r[16]) begin
                  next_mantissas_sum_r = mantissas_sum_r >> 1'b1;
                  next_reg_sum.exp = reg_a.exp+8'd1;
                end
                else if(~mantissas_sum_r[16])
                  unique casez (mantissas_sum_r) 
                    17'b01???????????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd0;
                      next_reg_sum.exp = reg_a.exp;
                    end
                    17'b001??????????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd1;
                      next_reg_sum.exp = reg_a.exp-8'd1;
                    end
                    17'b0001?????????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd2;
                      next_reg_sum.exp = reg_a.exp-8'd2;
                    end
                    17'b00001????????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd3;
                      next_reg_sum.exp = reg_a.exp-8'd3;
                    end
                    17'b000001???????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd4;
                      next_reg_sum.exp = reg_a.exp-8'd4;
                    end
                    17'b0000001??????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd5;
                      next_reg_sum.exp = reg_a.exp-8'd5;
                    end
                    17'b00000001?????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd6;
                      next_reg_sum.exp = reg_a.exp-8'd6;
                    end
                    17'b000000001????????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd7;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b0000000001???????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd8;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b00000000001??????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd9;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b000000000001?????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd10;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b0000000000001????: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd11;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b00000000000001???: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd12;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b000000000000001??: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd13;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b0000000000000001?: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd14;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    17'b00000000000000001: begin 
                      next_mantissas_sum_r = mantissas_sum_r << 17'd15;
                      next_reg_sum.exp = reg_a.exp-8'd7;
                    end
                    default : begin 
                      next_mantissas_sum_r = mantissas_sum_r;
                      next_reg_sum.exp = reg_a.exp;
                    end
                  endcase           
              next_state = CALCULATE_SUM;  
            end
            CALCULATE_SUM: begin
              sum[15] = reg_sum.sign;
              sum[14:7] = reg_sum.exp;
              if(special_case)
                sum[6:0] = reg_sum.mantisa[14:8];
              else
                sum[6:0] = mantissas_sum_r[14:8]; 
              ready = 1'b1;
              next_state = GET_FIRST_INPUT;
            end
          endcase
        end
  
    always_ff @ (posedge clock, negedge nreset)
        if (~nreset)
          begin
            diff_exp_r <= '0;
            mantissas_sum_r <= '0;
            special_case <= 1'b0;
          end
        else
          begin
            special_case <= next_special_case;
            diff_exp_r <= next_diff_exp_r;
            mantissas_sum_r <= next_mantissas_sum_r;
          end
  
    always_ff @(posedge clock, negedge nreset)
        if (~nreset)
          begin
            reg_a <= '0;
            reg_b <= '0;
            reg_sum <= '0;
            present_state <= GET_FIRST_INPUT;
          end
        else
          begin
            present_state <= next_state;
            reg_a <= next_reg_a;
            reg_b <= next_reg_b;
            reg_sum <= next_reg_sum;
          end
endmodule
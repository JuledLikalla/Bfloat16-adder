/////////////////////////////////////////////////////////////////////
// Design unit: test_bfloat16_adder
//            :
// File name  : test_bfloat16_adder.sv
//            :
// Description: Testbench for bfloat16 adder
//            :
//			   :
// Limitations: None
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Juled Likalla
//            : jl15g22@soton.ac.uk
//			   :	
// Revision   : Version 1 28/11/22
//            : Last modified: 08/12/22
/////////////////////////////////////////////////////////////////////

module test_bfloat16_adder;

logic [15:0] sum; 
logic ready;
logic [15:0] a, b;
logic clock, nreset;

shortreal reala, realb, realsum;
logic [31:0] ra, rb;

logic [4:0] total_passed, total_failed;

bfloat16_adder a1 (.*);

function automatic logic isNaN (input [14:0] operand);
  unique casez (operand) 
      15'b111111111??????: isNaN = 1'b1; // 111111111??????
      15'b11111111?1?????: isNaN = 1'b1; // 11111111?1?????
      15'b11111111??1????: isNaN = 1'b1; // 11111111??1????
      15'b11111111???1???: isNaN = 1'b1; // 11111111???1???
      15'b11111111????1??: isNaN = 1'b1; // 11111111????1??
      15'b11111111?????1?: isNaN = 1'b1; // 11111111?????1?
      15'b11111111??????1: isNaN = 1'b1; // 11111111??????1
    default : begin 
      isNaN = 1'b0;
    end
  endcase           
endfunction: isNaN

initial
  begin
  total_passed = '0;
  total_failed = '0;
  nreset = '1;
  clock = '0;
  #5ns nreset = '1;
  #5ns nreset = '0;
  #5ns nreset = '1;
  forever #5ns clock = ~clock;
  end
  
initial
  begin
    //Test 1 -- reset
    @(posedge ready); // wait for ready
    $info("Test 1: Reset\n");
    if (sum == '0)begin
      $display("** Test Passed\n\n");
      total_passed++;
    end
    else
      begin
        $error("Test Failed\n\n");
        total_failed++;
      end

    //Test 2 -- 1.0 + 1.0 = 2.0
    //@(posedge clock); //wait for next clock tick
    reala = 1.0;
    ra = $shortrealtobits(reala);
    realb = 1.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 2: %f + %f\n", reala, realb);
    if (sum == 16'b0100000000000000) begin
      $display("** Test Passed\n** Sum = %f\n\n", realsum);
      total_passed++;
    end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end
    //$display("Test 2 %f\n", realsum);
    
    //Test 3 -- 42.0 + 3.14159 = 45.ca
    //@(posedge clock);
    reala = 42.0;
    ra = $shortrealtobits(reala);
    realb = 3.14159;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 3: %f + %f\n", reala, realb);
    if (sum[15:7] == 9'b010000100 && (realsum<=46.0 && realsum>=44.0)) begin
      $display("** Test Passed\n** Sum = %f\n\n", realsum);
      total_passed++;
    end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end
    //$display("Test 3 %f\n", realsum);
    
    //Test 4 -- 5.0 + 0.0 = 5.0
    //@(posedge clock); //wait for next clock tick
    reala = 5.0;
    ra = $shortrealtobits(reala);
    realb = 0.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 4: %f + %f\n", reala, realb);
    if (sum == 16'b0100000010100000) begin
      $display("** Test Passed\n** Sum = %f\n\n", realsum);
      total_passed++;
    end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end
    //$display("Test 2 %f\n", realsum);

    //Test 5 -- -7.0 + 0.0 = -7.0
    //@(posedge clock); //wait for next clock tick
    reala = -7.0;
    ra = $shortrealtobits(reala);
    realb = 0.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 5: %f + %f\n", reala, realb);
    if (sum == 16'b1100000011100000) begin
      $display("** Test Passed\n** Sum = %f\n\n", realsum);
      total_passed++;
    end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 6 -- -5.0 + 0.0 = 5.0
    //@(posedge clock); //wait for next clock tick
    reala = -5.0;
    ra = $shortrealtobits(reala);
    realb = 0.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 6: %f + %f\n", reala, realb);
    if (sum == 16'b1100000010100000) begin
      $display("** Test Passed\n** Sum = %f\n\n", realsum);
      total_passed++;
    end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 7 -- -5.0 + 5.0 = 0.0
    //@(posedge clock); //wait for next clock tick
    reala = -5.0;
    ra = $shortrealtobits(reala);
    realb = 5.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 7: %f + %f\n", reala, realb);
    if (sum == '0) begin
      $display("** Test Passed\n** Sum = %f\n\n", realsum);
      total_passed++;
    end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end
    
    //Test 8 -- -35.0 + 70.0 = 0.0
    //@(posedge clock); //wait for next clock tick
    reala = -35.0;
    ra = $shortrealtobits(reala);
    realb = 70.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 8: %f + %f\n", reala, realb);
    if (sum == 16'b0100001000001100) begin
      $display("** Test Passed\n** Sum = %f\n\n", realsum);
      total_passed++;
    end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end
    //Test 9 -- -85.5 + 24.25.0 = 0.0
    //@(posedge clock); //wait for next clock tick
    reala = -85.5;
    ra = $shortrealtobits(reala);
    realb = 24.25;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 9: %f + %f\n", reala, realb);
    if (realsum >= -62.0 && realsum <= -61.0)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 10 -- 1.0 + NaN = NaN
    //@(posedge clock);
    reala = 1.0;
    ra = $shortrealtobits(reala);
    realb = (0.0/0.0);
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 10: %f + %f\n", reala, realb);
    if (isNaN(sum[14:0]))
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 11 -- 87.0 + inf = inf
    //@(posedge clock);
    reala = 87.0;
    ra = $shortrealtobits(reala);
    realb = (1.0/0.0);
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 11: %f + %f\n", reala, realb);
    if (sum[14:0] == 15'h7F80)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 12 -- 1.0 + (-inf) = -inf
    //@(posedge clock);
    reala = 87.0;
    ra = $shortrealtobits(reala);
    realb = (-1.0/0.0);
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 12: %f + %f\n", reala, realb);
    if (sum == 16'hFF80)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 13 -- 255.0 + 15.0 = 270.0
    //@(posedge clock);
    reala = 255.0;
    ra = $shortrealtobits(reala);
    realb = 15.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 13: %f + %f\n", reala, realb);
    if (sum == 16'h4387)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 14 -- -255.0 + -15.0 = -270
    //@(posedge clock);
    reala = -255.0;
    ra = $shortrealtobits(reala);
    realb = -15.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 14: %f + %f\n", reala, realb);
    if (sum == 16'hC387)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end
    
    //Test 15 -- 0.0 + 0.0 = 0.0
    //@(posedge clock);
    reala = 0.0;
    ra = $shortrealtobits(reala);
    realb = 0.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 15: %f + %f\n", reala, realb);
    if (sum == 16'h0000)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end
    
    //Test 16 -- 0.0 + 18.0 = 0.0
    //@(posedge clock);
    reala = 0.0;
    ra = $shortrealtobits(reala);
    realb = 18.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 16: %f + %f\n", reala, realb);
    if (sum == 16'h4190)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end  

    //Test 17 -- -0.0 + -0.0 = -0.0
    //@(posedge clock);
    reala = -0.0;
    ra = $shortrealtobits(reala);
    realb = -0.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 17: %f + %f\n", reala, realb);
    if (sum == 16'h8000)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

    //Test 18 -- 18.0 + -0.0 = 18.0
    //@(posedge clock);
    reala = 18.0;
    ra = $shortrealtobits(reala);
    realb = -0.0;
    rb = $shortrealtobits(realb);
    a = ra[31:16];
    b = rb[31:16];
    @(posedge ready);
    @(posedge clock);
    realsum = $bitstoshortreal({sum, {16{1'b0}}});
    $info("Test 18: %f + %f\n", reala, realb);
    if (sum == 16'h4190)
      begin
        $display("** Test Passed");
        $display("** Sum = %f\n\n", realsum);
        total_passed++;
      end
    else
      begin
        $error("Test Failed");
        $display("** Sum = %f\n\n", realsum);
        total_failed++;
      end

  //Test 19 -- inf + inf = inf
  //@(posedge clock);
  reala = (1.0/0.0);
  ra = $shortrealtobits(reala);
  realb = (1.0/0.0);
  rb = $shortrealtobits(realb);
  a = ra[31:16];
  b = rb[31:16];
  @(posedge ready);
  @(posedge clock);
  realsum = $bitstoshortreal({sum, {16{1'b0}}});
  $info("Test 19: %f + %f\n", reala, realb);
  if (sum == 16'h7F80)
    begin
      $display("** Test Passed");
      $display("** Sum = %f\n\n", realsum);
      total_passed++;
    end
  else
    begin
      $error("Test Failed");
      $display("** Sum = %f\n\n", realsum);
      total_failed++;
    end

  //Test 20 -- -inf + -inf = -inf
  //@(posedge clock);
  reala = (-1.0/0.0);
  ra = $shortrealtobits(reala);
  realb = (-1.0/0.0);
  rb = $shortrealtobits(realb);
  a = ra[31:16];
  b = rb[31:16];
  @(posedge ready);
  @(posedge clock);
  realsum = $bitstoshortreal({sum, {16{1'b0}}});
  $info("Test 20: %f + %f\n", reala, realb);
  if (sum == 16'hFF80)
    begin
      $display("** Test Passed");
      $display("** Sum = %f\n\n", realsum);
      total_passed++;
    end
  else
    begin
      $error("Test Failed");
      $display("** Sum = %f\n\n", realsum);
      total_failed++;
    end

  //Test 21 -- NaN + NaN = NaN
  //@(posedge clock);
  reala = (0.0/0.0);
  ra = $shortrealtobits(reala);
  realb = (0.0/0.0);
  rb = $shortrealtobits(realb);
  a = ra[31:16];
  b = rb[31:16];
  @(posedge ready);
  @(posedge clock);
  realsum = $bitstoshortreal({sum, {16{1'b0}}});
  $info("Test 21: %f + %f\n", reala, realb);
  if (isNaN(sum[14:0]))
    begin
      $display("** Test Passed");
      $display("** Sum = %f\n\n", realsum);
      total_passed++;
    end
  else
    begin
      $error("Test Failed");
      $display("** Sum = %f\n\n", realsum);
      total_failed++;
    end 
  
  //Test 22 -- NaN + inf = NaN
  //@(posedge clock);
  reala = (0.0/0.0);
  ra = $shortrealtobits(reala);
  realb = (1.0/0.0);
  rb = $shortrealtobits(realb);
  a = ra[31:16];
  b = rb[31:16];
  @(posedge ready);
  @(posedge clock);
  realsum = $bitstoshortreal({sum, {16{1'b0}}});
  $info("Test 22: %f + %f\n", reala, realb);
  if (isNaN(sum[14:0]))
    begin
      $display("** Test Passed");
      $display("** Sum = %f\n\n", realsum);
      total_passed++;
    end
  else
    begin
      $error("Test Failed");
      $display("** Sum = %f\n\n", realsum);
      total_failed++;
    end 
  
  //Test 23 -- NaN + -inf = NaN
  //@(posedge clock);
  reala = (0.0/0.0);
  ra = $shortrealtobits(reala);
  realb = (-1.0/0.0);
  rb = $shortrealtobits(realb);
  a = ra[31:16];
  b = rb[31:16];
  @(posedge ready);
  @(posedge clock);
  realsum = $bitstoshortreal({sum, {16{1'b0}}});
  $info("Test 23: %f + %f\n", reala, realb);
  if (isNaN(sum[14:0]))
    begin
      $display("** Test Passed");
      $display("** Sum = %f\n\n", realsum);
      total_passed++;
    end
  else
    begin
      $error("Test Failed");
      $display("** Sum = %f\n\n", realsum);
      total_failed++;
    end 

  //Test 24 -- +inf + -inf = NaN
  //@(posedge clock);
  reala = (1.0/0.0);
  ra = $shortrealtobits(reala);
  realb = (-1.0/0.0);
  rb = $shortrealtobits(realb);
  a = ra[31:16];
  b = rb[31:16];
  @(posedge ready);
  @(posedge clock);
  realsum = $bitstoshortreal({sum, {16{1'b0}}});
  $info("Test 24: %f + %f\n", reala, realb);
  if (isNaN(sum[14:0]))
    begin
      $display("** Test Passed");
      $display("** Sum = %f\n\n", realsum);
      total_passed++;
    end
  else
    begin
      $error("Test Failed");
      $display("** Sum = %f\n\n", realsum);
      total_failed++;
    end 

  //Test 25 -- 359.167300 + 250.623400 = 0
  //@(posedge clock);
  reala = 0.9609375;
  ra = $shortrealtobits(reala);
  realb = -0.6250000;
  rb = $shortrealtobits(realb);
  a = ra[31:16];
  b = rb[31:16];
  @(posedge ready);
  @(posedge clock);
  realsum = $bitstoshortreal({sum, {16{1'b0}}});
  $info("Test 25: %f + %f\n", reala, realb);
  if (sum == 16'h3EAC )
    begin
      $display("** Test Passed");
      $display("** Sum = %f\n\n", realsum);
      total_passed++;
    end
  else
    begin
      $error("Test Failed");
      $display("** Sum = %f\n\n", realsum);
      total_failed++;
    end 


  $info("Testing Completed\nPassed Tests: %d/25\nFailed Tests: %d/25\n", total_passed, total_failed);
  end
endmodule
  
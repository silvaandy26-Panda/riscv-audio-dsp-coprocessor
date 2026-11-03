`timescale 1ns / 1ps

module tb_audio_dsp_apb;

  // Clock and design parameters
  localparam CLK_SYS_PERIOD   = 10;        // 10 ns (100 MHz)
  localparam CLK_AUDIO_PERIOD = 20833;     // 20.833 us (48 kHz)
  localparam DATA_WIDTH       = 16;

  // clock and reset signals
  reg pclk;
  reg presetn;
  reg clk_audio_i;
  reg rst_audio_ni;

  // Interface APB3
  reg  [31:0] paddr;
  reg         psel;
  reg         penable;
  reg         pwrite;
  reg  [31:0] pwdata;
  wire [31:0] prdata;
  wire        pready;
  wire        pslverr;

  // Audio and Control
  reg  [DATA_WIDTH-1:0] audio_in_data_i;
  reg                   audio_in_valid_i;
  wire [DATA_WIDTH-1:0] audio_out_data_o;
  wire                  audio_out_valid_o;
  wire                  irq_o;

  // DUT (Netlist Gate-Level / RTL)
  audio_dsp_apb_wrapper u_dut (
    .pclk             (pclk),
    .presetn          (presetn),
    .paddr            (paddr),
    .psel             (psel),
    .penable          (penable),
    .pwrite           (pwrite),
    .pwdata           (pwdata),
    .prdata           (prdata),
    .pready           (pready),
    .pslverr          (pslverr),
    .clk_audio_i      (clk_audio_i),
    .rst_audio_ni     (rst_audio_ni),
    .audio_in_valid_i (audio_in_valid_i),
    .audio_in_data_i   (audio_in_data_i),
    .audio_out_valid_o(audio_out_valid_o),
    .audio_out_data_o (audio_out_data_o),
    .irq_o            (irq_o)
  );

  // clk generation
  always #(CLK_SYS_PERIOD / 2)       pclk = ~pclk;
  always #(CLK_AUDIO_PERIOD / 2.0) clk_audio_i = ~clk_audio_i;

  // Write APB task
  task apb_write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge pclk);
      paddr   = addr;
      pwdata  = data;
      pwrite  = 1'b1;
      psel    = 1'b1;
      penable = 1'b0;

      @(posedge pclk);
      penable = 1'b1;

      @(posedge pclk);
      while (!pready) @(posedge pclk);

      psel    = 1'b0;
      pwrite  = 1'b0;
      penable = 1'b0;
    end
  endtask

// Read APB task
  task apb_read(input [31:0] addr);
    begin
      @(posedge pclk);
      paddr   = addr;
      pwrite  = 1'b0;
      psel    = 1'b1;
      penable = 1'b0;

      @(posedge pclk);
      penable = 1'b1; 

      @(posedge pclk);
      while (!pready) @(posedge pclk);

      psel    = 1'b0;
      penable = 1'b0;
    end
  endtask

  // Stimulus
  initial begin
    // Signal init
    pclk             = 1'b0;
    clk_audio_i      = 1'b0;
    presetn          = 1'b0;
    rst_audio_ni     = 1'b0;
    paddr            = 32'h0;
    pwdata           = 32'h0;
    psel             = 1'b0;
    penable          = 1'b0;
    pwrite           = 1'b0;
    audio_in_data_i  = {DATA_WIDTH{1'b0}};
    audio_in_valid_i = 1'b0;

    // waveform dump
    $dumpfile("gls_output.vcd");
    $dumpvars(0, tb_audio_dsp_apb);

    // Reset DUT
    #50;
    presetn      = 1'b1;
    rst_audio_ni = 1'b1;
    #50;

    $display("[TB] Reset liberado. Iniciando escritura de coeficientes por APB...");

    // h0 = 0.5 (0x4000 Q1.15) -> Offset 0x10
    apb_write(32'h00000010, 32'h00004000);

    // h1 = 0.25 (0x2000 Q1.15) -> Offset 0x14
    apb_write(32'h00000014, 32'h00002000);

    // h2 = 0.125 (0x1000 Q1.15) -> Offset 0x18
    apb_write(32'h00000018, 32'h00001000);

    // h3 = 0.0625 (0x0800 Q1.15) -> Offset 0x1C
    apb_write(32'h0000001C, 32'h00000800);

    // Enable DSP processor (Bit 0: Enable DSP, Bit 1: Enable IRQ)
    apb_write(32'h00000000, 32'h00000003);

    // Read verification of h0
    apb_read(32'h00000010);

    // Send audio samples
    $display("[TB] Coeficientes cargados. Generando impulso de entrada en audio_in...");
    @(posedge clk_audio_i);
    audio_in_data_i  = 16'h2000; // Impulse in Q1.15 format
    audio_in_valid_i = 1'b1;

    @(posedge clk_audio_i);
    audio_in_data_i  = 16'h0000;
    audio_in_valid_i = 1'b0;

    
    #300000;

    $display("[TB] Simulación de 300 us completada exitosamente.");
    $finish;
  end

endmodule
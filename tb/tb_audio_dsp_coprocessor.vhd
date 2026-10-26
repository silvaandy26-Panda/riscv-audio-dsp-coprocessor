library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_audio_dsp_coprocessor is
end entity tb_audio_dsp_coprocessor;

architecture sim of tb_audio_dsp_coprocessor is

    -- Clock and Reset Signals
    constant CLK_SYS_PERIOD : time := 10 ns; -- 100 MHz
    constant CLK_AUDIO_PERIOD : time := 20.833 us; -- 48 kHz

    -- DUT PARAM
    constant DATA_WIDTH : integer := 16;
    constant ADDR_WIDTH : integer := 8; 

    -- CLK SYSTEM SIGNALS
    signal clk_sys_s : std_logic := '0';
    signal rst_sys_ns: std_logic := '0';
    signal ctrl_en_s : std_logic := '0';
    signal ctrl_we_s : std_logic := '0';
    signal ctrl_addr_s : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal ctrl_data_i_s : std_logic_vector(31 downto 0) := (others => '0');
    signal ctrl_data_o_s : std_logic_vector(31 downto 0);
    signal irq_s : std_logic;
    
    -- CLK AUDIO SIGNALS
    signal clk_audio_s : std_logic := '0';
    signal rst_audio_ns: std_logic := '0';
    signal audio_in_valid_s : std_logic := '0';
    signal audio_in_data_s  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal audio_out_valid_s : std_logic;
    signal audio_out_data_s  : std_logic_vector(DATA_WIDTH-1 downto 0);
  
begin

--Instantiate the DUT

    dut: entity work.audio_dsp_coprocessor
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk_sys_i   => clk_sys_s,
            rst_sys_ni  => rst_sys_ns,
            ctrl_en_i   => ctrl_en_s,
            ctrl_we_i   => ctrl_we_s,
            ctrl_addr_i => ctrl_addr_s,
            ctrl_data_i => ctrl_data_i_s,
            ctrl_data_o => ctrl_data_o_s,
            irq_o       => irq_s,
            clk_audio_i => clk_audio_s,
            rst_audio_ni=> rst_audio_ns,
            audio_in_valid_i => audio_in_valid_s,
            audio_in_data_i  => audio_in_data_s,
            audio_out_valid_o => audio_out_valid_s,
            audio_out_data_o  => audio_out_data_s
        );


    -- CLOCK GENERATION PROCESS
    clk_sys_s   <= not clk_sys_s after CLK_SYS_PERIOD/2;
    clk_audio_s <= not clk_audio_s after CLK_AUDIO_PERIOD/2;

    --Stimulus
    stmt_proc: process
    begin

        rst_sys_ns <= '0';
        rst_audio_ns <= '0';
        ctrl_en_s <= '0';
        ctrl_we_s <= '0';

        wait for 30 ns;

        rst_sys_ns <= '1';
        rst_audio_ns <= '1';
        wait for 50 ns;

        -- Initialize Control Interface
        wait until falling_edge(clk_sys_s);
        ctrl_en_s <= '1';
        ctrl_we_s <= '1';

        -- Coefficients
        ctrl_addr_s <= x"10";
        ctrl_data_i_s <= x"00004000"; -- 0.5 in Q15"
        
        wait until falling_edge(clk_sys_s);
        ctrl_addr_s <= x"14";
        ctrl_data_i_s <= x"00002000"; -- 0.25 in Q15"
        
        wait until falling_edge(clk_sys_s);
        ctrl_addr_s <= x"18";
        ctrl_data_i_s <= x"00001000"; -- 0.125 in Q15"

        wait until falling_edge(clk_sys_s);
        ctrl_addr_s <= x"1C";
        ctrl_data_i_s <= x"00000800"; -- 0.0625 in Q15"
        
        wait until falling_edge(clk_sys_s);
        -- Control Register
        ctrl_addr_s <= x"00";
        ctrl_data_i_s <= x"00000003"; -- Start DSP and interruptions

        wait until falling_edge(clk_sys_s);
        ctrl_en_s <= '0';
        ctrl_we_s <= '0';
       

        wait for 10 ns;

        -- Audio Signals
        wait until falling_edge(clk_audio_s);
        audio_in_valid_s <= '1';
        audio_in_data_s  <= x"7FFF"; -- Impulse signal
      
        wait until falling_edge(clk_audio_s);
        audio_in_data_s  <= x"0000"; -- Zero signal

        -- Zeros to shift the impulse through the FIR filter
        for i in 1 to 5 loop
            wait until falling_edge(clk_audio_s);
            
        end loop;
        
        
        -- End of Streaming
        wait until falling_edge(clk_audio_s);
        audio_in_valid_s <= '0';
        

        wait;


    end process;


end architecture sim;
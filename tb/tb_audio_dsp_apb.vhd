library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_audio_dsp_apb is
end entity tb_audio_dsp_apb;

architecture sim of tb_audio_dsp_apb is

    -- Clock and Reset Signals
    constant CLK_SYS_PERIOD : time := 10 ns; -- 100 MHz
    constant CLK_AUDIO_PERIOD : time := 20.833 us; -- 48 kHz

    -- DUT PARAM
    constant DATA_WIDTH : integer := 16;
    
    -- DUT Ports Signals
    signal pclk_sig     : std_logic:= '0';
    signal presetn_sig  : std_logic:= '0';

    signal paddr_sig    : std_logic_vector(31 downto 0):= (others => '0');
    signal psel_sig     : std_logic:= '0';
    signal penable_sig  : std_logic:= '0';
    signal pwrite_sig   : std_logic:= '0';
    signal pwdata_sig   : std_logic_vector(31 downto 0):= (others => '0');
    signal prdata_sig   : std_logic_vector(31 downto 0):= (others => '0');

    signal pready_sig      : std_logic:= '0';
    signal pslverr_sig     : std_logic:= '0';

    signal clk_audio_i_sig : std_logic:= '0';
    signal rst_audio_ni_sig : std_logic:= '0';
    signal audio_in_valid_i_sig : std_logic:= '0';
    signal audio_in_data_i_sig  : std_logic_vector(DATA_WIDTH-1 downto 0):= (others => '0');
    signal audio_out_valid_o_sig : std_logic:= '0';
    signal audio_out_data_o_sig  : std_logic_vector(DATA_WIDTH-1 downto 0):= (others => '0');

    signal irq_o_sig          : std_logic:= '0';

   
    -- Use of procedures for APB transactions
    procedure apb_write(
        constant addr : in std_logic_vector(31 downto 0);
        constant data : in std_logic_vector(31 downto 0);
        signal pclk   : in std_logic;
        signal psel   : out std_logic;
        signal penable: out std_logic;
        signal pwrite : out std_logic;
        signal paddr  : out std_logic_vector(31 downto 0);
        signal pwdata : out std_logic_vector(31 downto 0);
        signal pready : in std_logic
    ) is
    begin
        -- Set up the write transaction
        wait until rising_edge(pclk);

        paddr <= addr;
        pwdata <= data;
        pwrite <= '1';
        psel <= '1';
        penable <= '0';

        -- Wait for one clock cycle
        wait until rising_edge(pclk);

        -- Enable the transaction
        penable <= '1';

        -- Wait for pready to be asserted
        wait until pready = '1';

        -- Deassert signals after transaction is complete
        wait until rising_edge(pclk);
        psel <= '0';
        pwrite <= '0';
        penable <= '0';
    end procedure;

    -- Procedure for APB read transaction
    procedure apb_read(
        constant addr : in std_logic_vector(31 downto 0);
        signal pclk   : in std_logic;
        signal psel   : out std_logic;
        signal penable: out std_logic;
        signal pwrite : out std_logic;
        signal paddr  : out std_logic_vector(31 downto 0);
        signal prdata : in std_logic_vector(31 downto 0);
        signal pready : in std_logic
    ) is
    begin
        -- Set up the read transaction
        wait until rising_edge(pclk);

        paddr <= addr;
        pwrite <= '0';
        psel <= '1';
        penable <= '0';

        -- Wait for one clock cycle
        wait until rising_edge(pclk);

        -- Enable the transaction
        penable <= '1';

        -- Wait for pready to be asserted
        wait until pready = '1';

        -- Deassert signals after transaction is complete
        wait until rising_edge(pclk);
        psel <= '0';
        penable <= '0';
    end procedure;

begin

    -- Instantiate the DUT

    dut: entity work.audio_dsp_apb_wrapper
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            pclk        => pclk_sig,
            presetn     => presetn_sig,
            paddr       => paddr_sig,
            psel        => psel_sig,
            penable     => penable_sig,
            pwrite      => pwrite_sig,
            pwdata      => pwdata_sig,
            prdata      => prdata_sig,
            pready      => pready_sig,
            pslverr     => pslverr_sig,
            clk_audio_i => clk_audio_i_sig,
            rst_audio_ni=> rst_audio_ni_sig,
            audio_in_valid_i => audio_in_valid_i_sig,
            audio_in_data_i  => audio_in_data_i_sig,
            audio_out_valid_o => audio_out_valid_o_sig,
            audio_out_data_o  => audio_out_data_o_sig,
            irq_o       => irq_o_sig
        );


-- CLOCK GENERATION PROCESS
pclk_sig   <= not pclk_sig after CLK_SYS_PERIOD/2;
clk_audio_i_sig <= not clk_audio_i_sig after CLK_AUDIO_PERIOD/2;

--Stimulus
stmt_proc: process
begin
    -- Reset the DUT
    presetn_sig <= '0';
    rst_audio_ni_sig <= '0';
    wait for 50 ns;

    -- Release reset
    presetn_sig <= '1';
    rst_audio_ni_sig <= '1';
    wait for 50 ns;

    -- First Sequence 
    -- Write to a register coeficients of the Filter

    --coef h0 = 0.5 (0x4000 in Q1.15) -> Offset 0x10
    apb_write(x"00000010", x"00004000", pclk_sig, psel_sig, penable_sig, pwrite_sig, paddr_sig, pwdata_sig, pready_sig);

    --coef h1 = 0.25 (0x2000 in Q1.15) -> Offset 0x14
    apb_write(x"00000014", x"00002000", pclk_sig, psel_sig, penable_sig, pwrite_sig, paddr_sig, pwdata_sig, pready_sig);

    --coef h2 = 0.125 (0x1000 in Q1.15) -> Offset 0x18
    apb_write(x"00000018", x"00001000", pclk_sig, psel_sig, penable_sig, pwrite_sig, paddr_sig, pwdata_sig, pready_sig);

    --coef h3 = 0.0625 (0x800 in Q1.15) -> Offset 0x1C
    apb_write(x"0000001C", x"00000800", pclk_sig, psel_sig, penable_sig, pwrite_sig, paddr_sig, pwdata_sig, pready_sig);

    -- Second Sequence
    -- Enable the DSP Processor (Bit 0: Enable DSP, Bit 1: Enable Interruptions)
    apb_write(x"00000000", x"00000003", pclk_sig, psel_sig, penable_sig, pwrite_sig, paddr_sig, pwdata_sig, pready_sig);

    -- Third Sequence
    -- Read coef0 as verification that it stays
    apb_read(x"00000010", pclk_sig, psel_sig, penable_sig, pwrite_sig, paddr_sig, prdata_sig, pready_sig);

    -- Fourth Sequence
    -- Send Audio Samples

    wait until rising_edge(clk_audio_i_sig);
    audio_in_data_i_sig <= x"2000"; --Pulse in Q1.15
    audio_in_valid_i_sig <= '1';

    wait until rising_edge(clk_audio_i_sig);
    audio_in_data_i_sig <= (others => '0');
    audio_in_valid_i_sig <= '0';

    --Wait for filter response
    wait for 300 us;

    assert false report "Simulation Complete" severity failure;
    wait;

end process;
end architecture;
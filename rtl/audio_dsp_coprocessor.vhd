library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_dsp_coprocessor is
    generic (
        DATA_WIDTH : integer := 16; -- Data Samples Size (Audio Precision)
        ADDR_WIDTH : integer := 8   -- Bus bandwidth for control addresses
    );
    port (

        -- Clock of the System (RISC-V Bus)

        clk_sys_i   : in  std_logic; -- System Clock (e.g., 100 MHz)
        rst_sys_ni  : in  std_logic; -- Asynchronous Reset active low
        
        -- Control Interface (Memory-Mapped)
        ctrl_en_i   : in  std_logic; -- Enable of control interface
        ctrl_we_i   : in  std_logic; -- Write Enable of input
        ctrl_addr_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0); -- Control register address
        ctrl_data_i : in  std_logic_vector(31 downto 0); -- Control input data
        ctrl_data_o : out std_logic_vector(31 downto 0); -- Control output data
        
        -- Interrupt Signal to RISC-V
        irq_o       : out std_logic;


        -- Audio Clock Domain (I2S Interface)

        clk_audio_i : in  std_logic; -- Slow Clock (e.g., 48 kHz)
        rst_audio_ni: in  std_logic; -- Asynchronous Reset active low
        
        -- Data Streaming (Microphone/ADC Input)
        audio_in_valid_i : in  std_logic; -- Signal of input data validity
        audio_in_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Input audio data
        
        -- Data Streaming (Speaker/DAC Output)
        audio_out_valid_o : out std_logic; -- Signal of output data validity
        audio_out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity audio_dsp_coprocessor;

architecture rtl of audio_dsp_coprocessor is

    -- Control Registers and Coefficients (R/W by RISC-V)
    signal ctrl_reg  : std_logic_vector(31 downto 0);
    signal coef0_reg : std_logic_vector(15 downto 0);
    signal coef1_reg : std_logic_vector(15 downto 0);
    signal coef2_reg : std_logic_vector(15 downto 0);
    signal coef3_reg : std_logic_vector(15 downto 0);

    -- Internal state signals driven by the DSP FSM (Read-Only by RISC-V)
    signal busy_s : std_logic;
    signal done_s : std_logic;

    signal fir_out_valid_s : std_logic;

begin


    -- Control Register Write/Read Process
process(clk_sys_i, rst_sys_ni) 
begin
    if rst_sys_ni = '0' then

        ctrl_reg  <= (others => '0');
        coef0_reg <= (others => '0');
        coef1_reg <= (others => '0');
        coef2_reg <= (others => '0');
        coef3_reg <= (others => '0');
        ctrl_data_o <= (others => '0');

    elsif rising_edge(clk_sys_i) then
        if ctrl_en_i = '1' then -- Enable control interface
            if ctrl_we_i = '1' then --Write to Control Registers
                case ctrl_addr_i is
                    when x"00" => ctrl_reg <= ctrl_data_i;
                    when x"10" => coef0_reg <= ctrl_data_i(15 downto 0);
                    when x"14" => coef1_reg <= ctrl_data_i(15 downto 0);
                    when x"18" => coef2_reg <= ctrl_data_i(15 downto 0);
                    when x"1C" => coef3_reg <= ctrl_data_i(15 downto 0);
                    when others => null;
                end case;
            
            
            else --Read from Control Registers
                case ctrl_addr_i is
                    when x"00" => ctrl_data_o <= ctrl_reg;
                    when x"04" => ctrl_data_o <= x"0000000" & "00" & done_s & busy_s;
                    when x"10" => ctrl_data_o <= x"0000" & coef0_reg;
                    when x"14" => ctrl_data_o <= x"0000" & coef1_reg;
                    when x"18" => ctrl_data_o <= x"0000" & coef2_reg;
                    when x"1C" => ctrl_data_o <= x"0000" & coef3_reg;
                    when others => ctrl_data_o <= (others => '0');
                end case;
            end if;
        else 
            ctrl_data_o <= (others => '0');
        end if;
    end if; 

end process;

-- Logic Signals for the DSP FSM
busy_s              <= ctrl_reg(0); -- Bit 0 of control register indicates busy state 
done_s              <= fir_out_valid_s; -- Bit 1 of control register indicates done state
audio_out_valid_o   <= fir_out_valid_s; -- Output valid signal from FIR filter

irq_o               <= done_s and ctrl_reg(1); -- Interrupt signal to RISC-V when processing is done

-- FIR filter instance
u_fir_filter : entity work.fir_filter
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        TAP_COUNT  => 4
    )
    port map (
        clk_audio_i => clk_audio_i,
        rst_audio_ni => rst_audio_ni,
        
        coef0_i => coef0_reg,
        coef1_i => coef1_reg,
        coef2_i => coef2_reg,
        coef3_i => coef3_reg,

        data_in_valid_i => audio_in_valid_i and ctrl_reg(0), -- Only process input when busy
        data_in_i       => audio_in_data_i,
        
        data_out_valid_o => fir_out_valid_s,
        data_out_o       => audio_out_data_o
    );

end architecture rtl;
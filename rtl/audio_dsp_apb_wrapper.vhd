library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_dsp_apb_wrapper is
    generic(
        DATA_WIDTH : integer := 16 -- Data Samples Size (Audio Precision)
        );
    port (
        
        pclk        : in std_logic;
        presetn     : in std_logic;

        paddr       : in std_logic_vector(31 downto 0);
        psel        : in std_logic;
        penable     : in std_logic;
        pwrite      : in std_logic;
        pwdata      : in std_logic_vector(31 downto 0);
        prdata      : out std_logic_vector(31 downto 0);

        pready      : out std_logic;
        pslverr     : out std_logic;

        -- Not control Ports
        clk_audio_i : in std_logic;
        rst_audio_ni: in std_logic;
        audio_in_valid_i : in std_logic;
        audio_in_data_i  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        audio_out_valid_o : out std_logic;
        audio_out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);

        irq_o       : out std_logic
   
    );

end entity audio_dsp_apb_wrapper;

architecture rtl of audio_dsp_apb_wrapper is

    -- Internal signals for the DSP coprocessor
    signal ctrl_en_i   : std_logic;
    signal ctrl_we_i   : std_logic;
    signal ctrl_addr_i : std_logic_vector(7 downto 0);
    signal ctrl_data_i : std_logic_vector(31 downto 0);
    signal ctrl_data_o : std_logic_vector(31 downto 0);
    

    -- FSM state signals for APB interface
    type state_type is (IDLE, STATE_ACCESS);
    signal state : state_type := IDLE;

begin
    

    -- Single clock State process
    process(pclk, presetn)
    begin
        if presetn ='0'then
            state <= IDLE;
            prdata <= (others => '0');
            pready <= '0';
            pslverr <= '0';

            ctrl_en_i <= '0';
            ctrl_we_i <= '0';
            ctrl_addr_i <= (others => '0');
            ctrl_data_i <= (others => '0');

        elsif rising_edge(pclk) then
            case state is
                when IDLE =>
                    ctrl_en_i <= '0';
                    ctrl_we_i <= '0';
                    pready <= '0';
                    

                    if psel ='1' then
                        state <= STATE_ACCESS;

                    end if;
                when STATE_ACCESS =>
                    ctrl_en_i <= '1';
                    ctrl_we_i <= pwrite;
                    ctrl_addr_i <= paddr(7 downto 0);
                    ctrl_data_i <= pwdata;

                    prdata <= ctrl_data_o;
                    
                    pready <= '1';
                    pslverr <= '0';

                if penable ='1' then
                    state <= IDLE;
                    
                    
                end if;
                when others =>
                    state <= IDLE;
                end case;
        end if;

    end process;


-- Instantiate the audio DSP coprocessor
audio_dsp_inst : entity work.audio_dsp_coprocessor
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => 8
    )
    port map (
        clk_sys_i   => pclk,
        rst_sys_ni  => presetn,

        ctrl_en_i   => ctrl_en_i,
        ctrl_we_i   => ctrl_we_i,
        ctrl_addr_i => ctrl_addr_i,
        ctrl_data_i => ctrl_data_i,
        ctrl_data_o => ctrl_data_o,
        irq_o       => irq_o,
        clk_audio_i => clk_audio_i,
        rst_audio_ni=> rst_audio_ni,
        audio_in_valid_i => audio_in_valid_i,
        audio_in_data_i  => audio_in_data_i,
        audio_out_valid_o => audio_out_valid_o,
        audio_out_data_o  => audio_out_data_o
    );

end architecture rtl;
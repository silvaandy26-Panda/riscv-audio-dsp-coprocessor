library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter is
    generic (
        DATA_WIDTH : integer := 16; -- Precision of the audio samples
        TAP_COUNT  : integer := 4   -- Number of taps of the FIR filter
    );
    port (
        clk_audio_i : in  std_logic; -- Input clock
        rst_audio_ni: in  std_logic; -- Asynchronous reset active low
        
        -- Coeficients
        coef0_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        coef1_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        coef2_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        coef3_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Input data of audio
        data_in_valid_i : in  std_logic; -- Signal of input data validity
        data_in_i       : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Input data
        
        -- Output data of filtered audio
        data_out_valid_o : out std_logic; -- Signal of output data validity
        data_out_o       : out std_logic_vector(DATA_WIDTH-1 downto 0) -- Filtered data
    );
end entity fir_filter;

architecture rtl of fir_filter is

    -- Register to store the last TAP_COUNT samples of audio input
    type sample_array_type is array (0 to TAP_COUNT-1) of signed(DATA_WIDTH-1 downto 0);
    signal x_reg : sample_array_type := (others => (others => '0'));

    type product_array_type is array (0 to TAP_COUNT-1) of signed(2*DATA_WIDTH-1 downto 0);
    signal products : product_array_type := (others => (others => '0'));

    -- Signal for the filter output
    signal filter_output : signed(33 downto 0):= (others => '0');

begin
    process(clk_audio_i, rst_audio_ni)
    begin

        if rst_audio_ni = '0' then
            x_reg <= (others => (others => '0'));
            data_out_valid_o <= '0';
            

        elsif rising_edge(clk_audio_i) then

            data_out_valid_o <= data_in_valid_i;

            if data_in_valid_i = '1' then
                -- Shift the samples in the register and insert the new sample
                x_reg(0) <= signed(data_in_i);
                for i in 1 to TAP_COUNT-1 loop
                    x_reg(i) <= x_reg(i-1);
                end loop;
                
            else
                data_out_valid_o <= '0';
            end if;
        end if;

    end process;

    -- Products of the samples and coefficients
        products(0) <= x_reg(0) * signed(coef0_i);
        products(1) <= x_reg(1) * signed(coef1_i);
        products(2) <= x_reg(2) * signed(coef2_i);
        products(3) <= x_reg(3) * signed(coef3_i);

        -- Sum of the products to get the filter output
        filter_output <= resize(products(0), 34) + 
                            resize(products(1), 34) + 
                            resize(products(2), 34) + 
                            resize(products(3), 34);

        
        data_out_o <= std_logic_vector(filter_output(30 downto 15));


end architecture rtl;
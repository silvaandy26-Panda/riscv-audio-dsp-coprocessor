library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter is
    generic (
        DATA_WIDTH : integer := 16; -- Precisión de las muestras de audio
        TAP_COUNT  : integer := 4   -- Número de taps del filtro FIR
    );
    port (
        clk_audio_i : in  std_logic; -- Reloj de entrada
        rst_audio_ni: in  std_logic; -- Reset asíncrono activo en bajo
        
        -- Coeficientes
        coef0_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        coef1_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        coef2_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        coef3_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Entrada de datos de audio
        data_in_valid_i : in  std_logic; -- Señal de validez de datos de entrada
        data_in_i       : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Datos de entrada
        
        -- Salida de datos filtrados
        data_out_valid_o : out std_logic; -- Señal de validez de datos de salida
        data_out_o       : out std_logic_vector(DATA_WIDTH-1 downto 0) -- Datos filtrados
    );
end entity fir_filter;

architecture rtl of fir_filter is

    -- Registro de desplazamiento para almacenar las muestras de entrada
    type sample_array_type is array (0 to TAP_COUNT-1) of signed(DATA_WIDTH-1 downto 0);
    signal x_reg : sample_array_type := (others => (others => '0'));

    type product_array_type is array (0 to TAP_COUNT-1) of signed(2*DATA_WIDTH -1);
    signal products : product_array_type := (others => (others => '0'));

    -- Señal para la salida del filtro
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
                -- Desplazar las muestras de entrada
                x_reg(0) <= signed(data_in_i);
                for i in 1 to TAP_COUNT-1 loop
                    x_reg(i) <= x_reg(i-1);
                end loop;
                
            else
                data_out_valid_o <= '0';
            end if;
        end if;

    end process;

    -- Calcular los productos de cada tap con su coeficiente correspondiente
        products(0) <= x_reg(0) * signed(coef0_i);
        products(1) <= x_reg(1) * signed(coef1_i);
        products(2) <= x_reg(2) * signed(coef2_i);
        products(3) <= x_reg(3) * signed(coef3_i);

        -- Sumar los productos para obtener la salida del filtro
        filter_output <= resize(products(0), 34) + 
                            resize(products(1), 34) + 
                            resize(products(2), 34) + 
                            resize(products(3), 34);

        
        data_out_o <= std_logic_vector(filter_output(30 downto 15));


end architecture rtl;
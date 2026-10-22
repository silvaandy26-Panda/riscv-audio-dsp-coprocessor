library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_dsp_coprocessor is
    generic (
        DATA_WIDTH : integer := 16; -- Precisión de las muestras de audio
        ADDR_WIDTH : integer := 8   -- Ancho del bus de direcciones de control
    );
    port (
        -- ==========================================
        -- Dominio de Reloj del Sistema (RISC-V Bus)
        -- ==========================================
        clk_sys_i   : in  std_logic; -- Reloj rápido (ej. 100 MHz)
        rst_sys_ni  : in  std_logic; -- Reset asíncrono activo en bajo
        
        -- Interfaz de Control (Memory-Mapped)
        ctrl_en_i   : in  std_logic; -- Enable de interfaz de control
        ctrl_we_i   : in  std_logic; -- Write Enable de entrada
        ctrl_addr_i : in  std_logic_vector(ADDR_WIDTH-1 downto 0); -- Dirección de registro de control
        ctrl_data_i : in  std_logic_vector(31 downto 0); -- Datos de entrada de control
        ctrl_data_o : out std_logic_vector(31 downto 0); -- Datos de salida de control
        
        -- Interrupción al RISC-V para avisar que terminó
        irq_o       : out std_logic;

        -- ==========================================
        -- Dominio de Reloj de Audio (I2S Interface)
        -- ==========================================
        clk_audio_i : in  std_logic; -- Reloj lento (ej. 48 kHz)
        rst_audio_ni: in  std_logic; -- Reset asíncrono activo en bajo
        
        -- Streaming de Datos (Entrada del micrófono/ADC)
        audio_in_valid_i : in  std_logic; -- Señal de validez de datos de entrada
        audio_in_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Datos de entrada de audio
        
        -- Streaming de Datos (Salida al parlante/DAC)
        audio_out_valid_o : out std_logic; -- Señal de validez de datos de salida
        audio_out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity audio_dsp_coprocessor;

architecture rtl of audio_dsp_coprocessor is

    -- Registros de Control y Coeficientes (R/W por RISC-V)
    signal ctrl_reg  : std_logic_vector(31 downto 0);
    signal coef0_reg : std_logic_vector(15 downto 0);
    signal coef1_reg : std_logic_vector(15 downto 0);
    signal coef2_reg : std_logic_vector(15 downto 0);
    signal coef3_reg : std_logic_vector(15 downto 0);

    -- Señales internas de estado impulsadas por la FSM del DSP (Read-Only por RISC-V)
    signal busy_s : std_logic;
    signal done_s : std_logic;

begin

-- Senales de interrupción y audio MODIFICAR DESPUES
irq_o <= '0';
audio_out_valid_o <= '0';
audio_out_data_o <= (others => '0');



process(clk_sys_i, rst_sys_ni) -- Proceso de escritura
begin
    if rst_sys_ni = '0' then

        ctrl_reg  <= (others => '0');
        coef0_reg <= (others => '0');
        coef1_reg <= (others => '0');
        coef2_reg <= (others => '0');
        coef3_reg <= (others => '0');
        ctrl_data_o <= (others => '0');

    elsif rising_edge(clk_sys_i) then
        if ctrl_en_i = '1' then --Habilitado el bus de control
            if ctrl_we_i = '1' then --Escritura de registros de control
                case ctrl_addr_i is
                    when x"00" => ctrl_reg <= ctrl_data_i;
                    when x"10" => coef0_reg <= ctrl_data_i(15 downto 0);
                    when x"14" => coef1_reg <= ctrl_data_i(15 downto 0);
                    when x"18" => coef2_reg <= ctrl_data_i(15 downto 0);
                    when x"1C" => coef3_reg <= ctrl_data_i(15 downto 0);
                    when others => null;
                end case;
            
            
            else --Lectura de Registros de Control
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





end architecture rtl;
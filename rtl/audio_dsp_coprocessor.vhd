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
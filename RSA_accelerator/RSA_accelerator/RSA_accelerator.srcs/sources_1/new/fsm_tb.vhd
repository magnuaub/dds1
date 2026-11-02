----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.10.2026 19:32:01
-- Design Name: 
-- Module Name: fsm_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rsa_fsm_tb is
end rsa_fsm_tb;

architecture sim of rsa_fsm_tb is

    constant H     : positive := 8;                          -- small H for fast simulation
    constant E_VAL : std_logic_vector(H-1 downto 0) := "10110101";   -- five 1-bits

    signal clk          : std_logic := '0';
    signal reset_n      : std_logic := '0';
    signal msgin_valid  : std_logic := '0';
    signal msgin_ready  : std_logic;
    signal msgout_valid : std_logic;
    signal msgout_ready : std_logic := '0';
    signal e_bit        : std_logic;
    signal done         : std_logic;
    signal load_en, mul_start, sq_start, update_c, update_p, shift_e : std_logic;

    signal e_sr      : std_logic_vector(H-1 downto 0) := (others => '0');
    signal delay     : std_logic_vector(2 downto 0) := (others => '0');
    signal n_start   : integer := 0;
    signal n_update_c : integer := 0;
    signal finished  : boolean := false;

begin

    clk <= not clk after 5 ns when not finished;

    dut : entity work.rsa_fsm
        generic map (H => H)
        port map (
            clk => clk, reset_n => reset_n,
            msgin_valid => msgin_valid, msgin_ready => msgin_ready,
            msgout_valid => msgout_valid, msgout_ready => msgout_ready,
            e_bit => e_bit, mul_done => done, sq_done => done,
            load_en => load_en, mul_start => mul_start, sq_start => sq_start,
            update_c => update_c, update_p => update_p, shift_e => shift_e);

    -- Models: e shift register, Blakley delay (3 cycles), counters
    process(clk)
    begin
        if rising_edge(clk) then
            if load_en = '1' then
                e_sr <= E_VAL;
            elsif shift_e = '1' then
                e_sr <= '0' & e_sr(H-1 downto 1);
            end if;

            delay <= delay(1 downto 0) & mul_start;

            if mul_start = '1' then n_start    <= n_start + 1;    end if;
            if update_c  = '1' then n_update_c <= n_update_c + 1; end if;
        end if;
    end process;

    e_bit <= e_sr(0);
    done  <= delay(2);

    -- Stimulus and checks
    process
    begin
        wait for 50 ns;
        reset_n <= '1';

        wait until rising_edge(clk) and msgin_ready = '1';
        msgin_valid <= '1';
        wait until rising_edge(clk);
        msgin_valid <= '0';

        wait until msgout_valid = '1';
        wait until rising_edge(clk);
        msgout_ready <= '1';
        wait until rising_edge(clk);
        msgout_ready <= '0';
        wait until rising_edge(clk);

        assert n_start    = H report "ERROR: wrong number of rounds"    severity error;
        assert n_update_c = 5 report "ERROR: wrong number of C updates" severity error;
        assert msgin_ready = '1' report "ERROR: FSM not back in IDLE"   severity error;

        report "Simulation finished";
        finished <= true;
        wait;
    end process;

end sim;
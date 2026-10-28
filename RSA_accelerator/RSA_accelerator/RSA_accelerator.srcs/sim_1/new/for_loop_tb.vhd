----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.10.2026 16:52:38
-- Design Name: 
-- Module Name: for_loop_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;




entity for_loop_tb is

end for_loop_tb;

architecture sim of for_loop_tb is

    constant BLOCK_SIZE : integer := 256;
    
    signal clk      : STD_LOGIC := '0';
    signal reset_n  : STD_LOGIC := '0';
    signal n        : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal b        : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal a        : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');  -- full vector of a -- full vector of a
    signal a_i      : STD_LOGIC := '0';                                 -- one bit of a
    signal R        : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal done     : STD_LOGIC;
    signal result   : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);


constant clk_period : time := 10 ns;
signal sim_done: boolean := false;

begin
    DUT: entity work.for_loop_logic(Behavioral)
        generic map (
            BLOCK_SIZE => BLOCK_SIZE
        )
        port map (
            clk     => clk,
            reset_n => reset_n,
            n       => n,
            b       => b,
            a_i     => a_i,
            R       => R,
            done    => done,
            result  => result
    );

    -- clock generator
    clk_gen: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    --stimuli
    stim_proc: process
            procedure run_for_loop(a_v,b_v,n_v: integer) is
            begin
                --apply inputs for reset
                reset_n <= '0';
                a <= std_logic_vector(to_unsigned(a_v, BLOCK_SIZE));
                b <= std_logic_vector(to_unsigned(b_v, BLOCK_SIZE));
                n <= std_logic_vector(to_unsigned(n_v, BLOCK_SIZE));
                R <= (others => '0');
                wait for 2 * CLK_PERIOD;
                reset_n <= '1';

                --feed one bit at a time, MSB first
                for i in BLOCK_SIZE-1 downto 0 loop
                    a_i <= a(i);
                    wait until done = '1';
                    R <= result;
                end loop;
                
                wait for 5 * CLK_PERIOD;
            end procedure;
        

    begin
        run_for_loop(7,5,13);
        run_for_loop(200, 150, 211);
        run_for_loop(0,7,13);
        run_for_loop(255,250,251);

        sim_done <= true; 
        wait;
    end process;
end sim;


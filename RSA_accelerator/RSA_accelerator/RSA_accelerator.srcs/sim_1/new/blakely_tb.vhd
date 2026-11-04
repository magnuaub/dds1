
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity blakely_tb is
end blakely_tb;

architecture sim of blakely_tb is
        constant CLK_PERIOD : time := 10 ns;
        constant BLOCK_SIZE : integer := 256;
        
        signal clk     : STD_LOGIC := '0';
        signal reset_n : STD_LOGIC := '0';
        signal n       : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
        signal b       : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0):= (others => '0');
        signal a       : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0):= (others => '0');
        signal R       : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        signal done    : STD_LOGIC;
        
         signal sim_done : boolean := false;
        
       
begin
    uut: entity work.blakely
        port map (
            clk => clk,
            reset_n => reset_n,
            n => n,
            b => b,      
            a => a,     
            R => R,      
            done => done
        );
        
    clk_process: process
     begin
          while not sim_done loop
              clk <= '0';
              wait for CLK_PERIOD / 2;
              clk <= '1';
              wait for CLK_PERIOD / 2;
            end loop;
            wait;
    end process;

process
    procedure run_test(a_v, b_v, n_v: integer) is
        variable expected : integer;
    begin
        report "Starting test: a_i=" & integer'image(a_v)
                & ", b=" & integer'image(b_v)
                & ", n=" & integer'image(n_v)
                severity note;
        expected := (a_v*b_v) mod n_v;
        
        reset_n <= '0'; 
        -- load inputs while in reset
        a <= std_logic_vector(to_unsigned(a_v, BLOCK_SIZE));
        b <= std_logic_vector(to_unsigned(b_v, BLOCK_SIZE));
        n <= std_logic_vector(to_unsigned(n_v, BLOCK_SIZE));
        wait for 2* CLK_PERIOD;
        reset_n <= '1';
        
        --wait for result
        wait until done = '1' for 50 us;
        

            -- Check result
assert unsigned(R) = to_unsigned(expected, BLOCK_SIZE)
    report "TEST FAILED: expected=" & integer'image(expected)
         & ", got=" & integer'image(to_integer(unsigned(R(31 downto 0))))
    severity error;
    
    report "Result: expected=" & integer'image(expected)
             & ", got=" & integer'image(to_integer(unsigned(R(31 downto 0))));

            
            wait until rising_edge(clk);
            reset_n <= '0';
            wait until rising_edge(clk);
         
        
 end procedure; 

    begin
        run_test(5, 6, 7);      -- 30 mod 7  = 2
        run_test(10, 10, 13);   -- 100 mod 13 = 9
        run_test(0, 20, 23);    -- 0
        run_test(1, 17, 23);    -- 17
        run_test(22, 22, 23);   -- 484 mod 23 = 1
 
        report "Simulation finished";
        sim_done <= true;
        wait;
    end process;
end sim;

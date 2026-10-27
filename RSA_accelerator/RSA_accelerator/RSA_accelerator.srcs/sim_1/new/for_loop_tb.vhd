library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_for_loop_logic is
end tb_for_loop_logic;

architecture test of tb_for_loop_logic is

    signal clk    : STD_LOGIC := '0';
    signal b      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal a_i    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal n      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal R      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal done   : STD_LOGIC;
    signal reset_n : STD_LOGIC;
    signal result : STD_LOGIC_VECTOR(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the design under test
    uut: entity work.for_loop_logic
         port map (
            clk    => clk,
            n      => n,
            b      => b,
            a_i    => a_i,
            R      => R,
            done   => done,
            reset_n => reset_n,
            result => result
        );
    -- Clock generation
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Test stimulus
    stim_process: process

        procedure run_test(
            constant R_val        : in integer;
            constant a_val    : in integer;
            constant b_val    : in integer;
            constant n_val    : in integer;
            constant expected : in integer
        ) is
        begin
            
            -- Apply inputs
            R   <= std_logic_vector(to_unsigned(R_val, 8));
            a_i <= std_logic_vector(to_unsigned(a_val, 8));
            b   <= std_logic_vector(to_unsigned(b_val, 8));
            n   <= std_logic_vector(to_unsigned(n_val, 8));
            
            wait until rising_edge(clk);
            reset_n <= '1';
            
            report "Starting test: a_i=" & integer'image(a_val)
                & ", b=" & integer'image(b_val)
                & ", n=" & integer'image(n_val)
                severity note;

            -- Wait until the MODULO stage is active
            wait until done = '1';

            -- Wait for the modulo stage to execute
            wait until rising_edge(clk);
            wait for 1 ns;

            -- Check result
            assert to_integer(unsigned(result)) = expected
                report "TEST FAILED: expected="
                    & integer'image(expected)
                    & ", got="
                    & integer'image(to_integer(unsigned(result)))
                severity error;

            report "Test passed: result="
                & integer'image(to_integer(unsigned(result)))
                severity note;
            
            wait until rising_edge(clk);
            reset_n <= '0';
            wait until rising_edge(clk);
         
        end procedure;

    begin
        reset_n <= '0';
        
        wait for 20 ns;

        -- Test 1: (3 * 2 * 4) mod 7 = 3
        run_test(10, 2, 4, 7, 3);

        -- Test 2: (3 * 5 * 6) mod 11 = 2
        run_test(10, 5, 6, 11, 2);

        -- Test 3: (3 * 10 * 10) mod 13 = 1
        run_test(5, 10, 10, 13, 1);

        -- Test 4: result is zero
        run_test(0, 0, 20, 7, 0);

        -- Test 5: modulus equals 1
        run_test(5, 5, 6, 1, 0);

        -- Test 6: modulus is zero
        a_i <= std_logic_vector(to_unsigned(5, 8));
        b   <= std_logic_vector(to_unsigned(6, 8));
        n   <= (others => '0');

        wait until done = '1';
        wait until rising_edge(clk);
        wait for 1 ns;

        assert unsigned(result) = 0
            report "Test failed: result should be zero when n=0"
            severity error;

        report "Test 6 passed: result is zero when n=0"
            severity note;

        report "All test cases completed."
            severity note;

        wait;
    end process;

end test;
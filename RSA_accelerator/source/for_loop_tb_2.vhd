
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity for_loop_tb is
end for_loop_tb;

architecture sim of for_loop_tb is

    constant BLOCK_SIZE : integer := 256;
    constant CLK_PERIOD : time := 10 ns;

    signal clk     : STD_LOGIC := '0';
    signal reset_n : STD_LOGIC := '0';

    signal n       : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal b       : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal a_i     : STD_LOGIC := '0';
    signal R       : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');

    signal done    : STD_LOGIC;
    signal result  : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);

    signal sim_done : boolean := false;

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

    -- Clock generator
    clk_gen: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Test stimuli
    stim_proc: process

        procedure run_test(
            R_v, a_i_v, b_v, n_v : integer
        ) is
            variable expected : integer;
            variable actual   : integer;
        begin

            -- Reset before each independent test
            reset_n <= '0';

            R <= std_logic_vector(to_unsigned(R_v, BLOCK_SIZE));

            if a_i_v = 1 then
                a_i <= '1';
            else
                a_i <= '0';
            end if;

            b <= std_logic_vector(to_unsigned(b_v, BLOCK_SIZE));
            n <= std_logic_vector(to_unsigned(n_v, BLOCK_SIZE));

            expected := (2 * R_v + a_i_v * b_v) mod n_v;

            wait for 2 * CLK_PERIOD;
            wait until falling_edge(clk);
            reset_n <= '1';

            -- Wait for one iteration to finish
            wait until rising_edge(done);
            wait for 1 ns;

            actual := to_integer(unsigned(result(31 downto 0)));

            -- Check result and print PASS or FAIL
            if unsigned(result) = to_unsigned(expected, BLOCK_SIZE) then

                report "PASS: R=" & integer'image(R_v) &
                       " a_i=" & integer'image(a_i_v) &
                       " b=" & integer'image(b_v) &
                       " n=" & integer'image(n_v) &
                       " result=" & integer'image(actual)
                       severity note;

            else

                report "FAIL: R=" & integer'image(R_v) &
                       " a_i=" & integer'image(a_i_v) &
                       " b=" & integer'image(b_v) &
                       " n=" & integer'image(n_v) &
                       " expected=" & integer'image(expected) &
                       " actual=" & integer'image(actual)
                       severity error;

            end if;

            -- Reset so DUT cannot restart
            reset_n <= '0';
            wait for 2 * CLK_PERIOD;

        end procedure;

    begin

        run_test(7,  1, 5,  11);  -- Expected 8
        run_test(3,  0, 5,  13);  -- Expected 6
        run_test(5,  1, 7,  13);  -- Expected 4
        run_test(0,  0, 5,  13);  -- Expected 0
        run_test(0,  1, 9,  13);  -- Expected 9
        run_test(8,  1, 6,  11);  -- Expected 0
        run_test(10, 0, 7,  13);  -- Expected 7
        run_test(12, 1, 15, 17);  -- Expected 5
        run_test(20, 1, 30, 23);  -- Expected 1
        run_test(50, 0, 25, 31);  -- Expected 7

        report "ALL TEST CASES COMPLETED" severity note;

        sim_done <= true;
        wait;

    end process;

end sim;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.ALL;

entity rsa_toplevel_tb is
end rsa_toplevel_tb;

architecture Behavioral of rsa_toplevel_tb is

    constant H          : positive := 256;
    constant CLK_PERIOD : time := 10 ns;
    constant MAX_CYCLES : natural := 1000000;

    signal clk          : std_logic := '0';
    signal reset_n      : std_logic := '0';

    signal msgin_valid  : std_logic := '0';
    signal msgin_ready  : std_logic;
    signal msgin_last   : std_logic := '0';
    signal msgin_data   : std_logic_vector(H-1 downto 0)
                          := (others => '0');

    signal msgout_valid : std_logic;
    signal msgout_ready : std_logic := '0';
    signal msgout_last  : std_logic;
    signal msgout_data  : std_logic_vector(H-1 downto 0);

    signal n : std_logic_vector(H-1 downto 0)
               := (others => '0');
    signal e : std_logic_vector(H-1 downto 0)
               := (others => '0');

begin

    ------------------------------------------------------------
    -- Clock
    ------------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2;

    ------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------
    DUT : entity work.rsa_toplevel
        generic map (
            H => H
        )
        port map (
            clk          => clk,
            reset_n      => reset_n,

            msgin_valid  => msgin_valid,
            msgin_ready  => msgin_ready,
            msgin_last   => msgin_last,
            msgin_data   => msgin_data,

            msgout_valid => msgout_valid,
            msgout_ready => msgout_ready,
            msgout_last  => msgout_last,
            msgout_data  => msgout_data,

            n            => n,
            e            => e
        );

    ------------------------------------------------------------
    -- Test process
    ------------------------------------------------------------
    STIMULUS : process

        procedure run_test(
            constant test_id  : natural;
            constant m_val    : std_logic_vector(H-1 downto 0);
            constant e_val    : std_logic_vector(H-1 downto 0);
            constant n_val    : std_logic_vector(H-1 downto 0);
            constant expected : std_logic_vector(H-1 downto 0)
        ) is
            variable cycles : natural;
        begin

            report "Starting RSA test " &
                   integer'image(test_id);

            ----------------------------------------------------
            -- Apply input
            ----------------------------------------------------
            wait until falling_edge(clk);

            msgin_data  <= m_val;
            e           <= e_val;
            n           <= n_val;

            msgin_last  <= '1';
            msgin_valid <= '1';
            msgout_ready <= '0';

            ----------------------------------------------------
            -- Input handshake
            ----------------------------------------------------
            cycles := 0;

            loop
                wait until rising_edge(clk);
                exit when msgin_ready = '1';

                cycles := cycles + 1;

                assert cycles < MAX_CYCLES
                    report "TIMEOUT: input handshake"
                    severity failure;
            end loop;

            wait until falling_edge(clk);
            msgin_valid <= '0';
            msgin_last  <= '0';

            ----------------------------------------------------
            -- Wait for output
            ----------------------------------------------------
            cycles := 0;

            loop
                wait until rising_edge(clk);
                exit when msgout_valid = '1';

                cycles := cycles + 1;

                assert cycles < MAX_CYCLES
                    report "TIMEOUT: RSA calculation"
                    severity failure;
            end loop;

            ----------------------------------------------------
            -- Check output
            ----------------------------------------------------
            assert msgout_last = '1'
                report "FAIL: msgout_last is not 1"
                severity failure;

            assert msgout_data = expected
                report "FAIL: Incorrect RSA result in test " &
                       integer'image(test_id)
                severity failure;

            report "PASS: Test " &
                   integer'image(test_id) &
                   " cycles = " & integer'image(cycles);

            ----------------------------------------------------
            -- Test output backpressure
            ----------------------------------------------------
            -- Keep ready low for three additional cycles.
            -- Output must remain valid and unchanged.
            for i in 1 to 3 loop
                wait until rising_edge(clk);

                assert msgout_valid = '1'
                    report "FAIL: msgout_valid dropped"
                    severity failure;

                assert msgout_last = '1'
                    report "FAIL: msgout_last dropped"
                    severity failure;

                assert msgout_data = expected
                    report "FAIL: output data changed"
                    severity failure;
            end loop;

            ----------------------------------------------------
            -- Complete output handshake
            ----------------------------------------------------
            wait until falling_edge(clk);
            msgout_ready <= '1';

            wait until rising_edge(clk);

            wait until falling_edge(clk);
            msgout_ready <= '0';

            assert msgin_ready = '1'
                report "FAIL: DUT did not return to IDLE"
                severity failure;

        end procedure;

    begin

        --------------------------------------------------------
        -- Reset
        --------------------------------------------------------
        reset_n <= '0';
        wait for 5 * CLK_PERIOD;

        wait until falling_edge(clk);
        reset_n <= '1';

        --------------------------------------------------------
        -- Test 1: 7^13 mod 33 = 13
        --------------------------------------------------------
        run_test(
            1,
            std_logic_vector(to_unsigned(7, H)),
            std_logic_vector(to_unsigned(13, H)),
            std_logic_vector(to_unsigned(33, H)),
            std_logic_vector(to_unsigned(13, H))
        );

        --------------------------------------------------------
        -- Test 2: 5^3 mod 17 = 6
        --------------------------------------------------------
        run_test(
            2,
            std_logic_vector(to_unsigned(5, H)),
            std_logic_vector(to_unsigned(3, H)),
            std_logic_vector(to_unsigned(17, H)),
            std_logic_vector(to_unsigned(6, H))
        );

        --------------------------------------------------------
        -- Test 3: Exponent = 0
        --------------------------------------------------------
        run_test(
            3,
            std_logic_vector(to_unsigned(8, H)),
            (others => '0'),
            std_logic_vector(to_unsigned(23, H)),
            std_logic_vector(to_unsigned(1, H))
        );

        --------------------------------------------------------
        -- Test 4: Full-width modulus
        -- (N-1)^3 mod N = N-1
        --------------------------------------------------------
        run_test(
            4,
            x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" &
            x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF42",

            std_logic_vector(to_unsigned(3, H)),

            x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" &
            x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF43",

            x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" &
            x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF42"
        );

        --------------------------------------------------------
        -- Test 5: 256-bit calculation, E = 65537
        --------------------------------------------------------
        run_test(
            5,
            x"A3F29B7C5D018E46B92AC0D13E758F20" &
            x"C6412B9D8E03F75A19C6D2B847E50F13",

            std_logic_vector(to_unsigned(65537, H)),

            x"D7E31A92B4C65F081293A7D5E9F04B61" &
            x"8AC2D7350F9E46B1C8A5743D26E9F10B",

            x"04542422E8B29B2EDEACB04B6A17043F" &
            x"7DA5FC02B79C33F3E4C6A34D818719CE"
        );

        --------------------------------------------------------
        -- End simulation
        --------------------------------------------------------
        report "ALL RSA TESTS PASSED";
        finish;

    end process;

end Behavioral;

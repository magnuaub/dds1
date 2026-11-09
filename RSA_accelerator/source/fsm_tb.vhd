
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rsa_fsm_tb is
end rsa_fsm_tb;

architecture sim of rsa_fsm_tb is

    constant H : positive := 8;
    constant E_VAL : std_logic_vector(H-1 downto 0)
                     := "10110101";

    signal clk          : std_logic := '0';
    signal reset_n      : std_logic := '0';

    signal msgin_valid  : std_logic := '0';
    signal msgin_ready  : std_logic;
    signal msgout_valid : std_logic;
    signal msgout_ready : std_logic := '0';

    signal e_bit        : std_logic;
    signal mul_done     : std_logic;
    signal sq_done      : std_logic;

    signal load_en      : std_logic;
    signal mul_start    : std_logic;
    signal sq_start     : std_logic;
    signal update_c     : std_logic;
    signal update_p     : std_logic;
    signal shift_e      : std_logic;

    signal e_sr : std_logic_vector(H-1 downto 0)
                  := (others => '0');

    -- Separate delays for multiplier and squarer
    signal mul_delay : std_logic_vector(2 downto 0)
                       := (others => '0');

    signal sq_delay : std_logic_vector(2 downto 0)
                      := (others => '0');

    signal n_mul_start : integer := 0;
    signal n_sq_start  : integer := 0;
    signal n_update_c  : integer := 0;

    signal finished : boolean := false;

begin

    ------------------------------------------------------------
    -- Clock
    ------------------------------------------------------------
    clk <= not clk after 5 ns when not finished;

    ------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------
    dut : entity work.rsa_fsm
        generic map (
            H => H
        )
        port map (
            clk          => clk,
            reset_n      => reset_n,

            msgin_valid  => msgin_valid,
            msgin_ready  => msgin_ready,
            msgout_valid => msgout_valid,
            msgout_ready => msgout_ready,

            e_bit        => e_bit,
            mul_done     => mul_done,
            sq_done      => sq_done,

            load_en      => load_en,
            mul_start    => mul_start,
            sq_start     => sq_start,

            update_c     => update_c,
            update_p     => update_p,
            shift_e      => shift_e
        );

    ------------------------------------------------------------
    -- Exponent shift register and Blakely models
    ------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                e_sr <= (others => '0');

                mul_delay <= (others => '0');
                sq_delay  <= (others => '0');

                n_mul_start <= 0;
                n_sq_start  <= 0;
                n_update_c  <= 0;

            else

                -- Load / shift exponent
                if load_en = '1' then
                    e_sr <= E_VAL;

                elsif shift_e = '1' then
                    e_sr <= '0' & e_sr(H-1 downto 1);
                end if;

                -- Simulated Blakely latency
                mul_delay <= mul_delay(1 downto 0) & mul_start;
                sq_delay  <= sq_delay(1 downto 0) & sq_start;

                -- Count operations
                if mul_start = '1' then
                    n_mul_start <= n_mul_start + 1;
                end if;

                if sq_start = '1' then
                    n_sq_start <= n_sq_start + 1;
                end if;

                if update_c = '1' then
                    n_update_c <= n_update_c + 1;
                end if;

            end if;
        end if;
    end process;

    e_bit <= e_sr(0);

    mul_done <= mul_delay(2);
    sq_done  <= sq_delay(2);

    ------------------------------------------------------------
    -- Stimulus and checks
    ------------------------------------------------------------
    process
    begin

        -- Reset
        wait for 50 ns;
        reset_n <= '1';

        -- Input handshake
        wait until falling_edge(clk);
        msgin_valid <= '1';

        wait until rising_edge(clk);

        wait until falling_edge(clk);
        msgin_valid <= '0';

        -- Wait for RSA completion
        wait until msgout_valid = '1';

        report "RSA FSM reached OUT_ST";

        -- Output handshake
        wait until falling_edge(clk);
        msgout_ready <= '1';

        wait until falling_edge(clk);
        msgout_ready <= '0';

        wait for 2 ns;

        --------------------------------------------------------
        -- Assertions
        --------------------------------------------------------

        assert n_sq_start = H
            report "ERROR: Wrong number of squarings"
            severity error;

        assert n_mul_start = 5
            report "ERROR: Wrong number of multiplications"
            severity error;

        assert n_update_c = 5
            report "ERROR: Wrong number of C updates"
            severity error;

        assert msgin_ready = '1'
            report "ERROR: FSM not back in IDLE"
            severity error;

        report "All FSM tests passed.";

        finished <= true;
        wait;

    end process;

end sim;

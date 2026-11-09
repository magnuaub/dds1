
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rsa_toplevel is
    generic (
        H : positive := 256
    );
    port (
        clk          : in  std_logic;
        reset_n      : in  std_logic;

        -- Input stream
        msgin_valid  : in  std_logic;
        msgin_ready  : out std_logic;
        msgin_last   : in  std_logic;
        msgin_data   : in  std_logic_vector(H-1 downto 0);

        -- Output stream
        msgout_valid : out std_logic;
        msgout_ready : in  std_logic;
        msgout_last  : out std_logic;
        msgout_data  : out std_logic_vector(H-1 downto 0);

        -- RSA key parameters
        n            : in  std_logic_vector(H-1 downto 0);
        e            : in  std_logic_vector(H-1 downto 0)
    );
end rsa_toplevel;

architecture Behavioral of rsa_toplevel is

    ------------------------------------------------------------
    -- FSM control signals
    ------------------------------------------------------------
    signal load_en   : std_logic;
    signal mul_start : std_logic;
    signal sq_start  : std_logic;
    signal update_c  : std_logic;
    signal update_p  : std_logic;
    signal shift_e   : std_logic;
    signal e_bit     : std_logic;

    ------------------------------------------------------------
    -- RSA datapath registers
    ------------------------------------------------------------
    signal C_reg : std_logic_vector(H-1 downto 0);
    signal P_reg : std_logic_vector(H-1 downto 0);
    signal E_reg : std_logic_vector(H-1 downto 0);
    signal N_reg : std_logic_vector(H-1 downto 0);

    ------------------------------------------------------------
    -- Blakely outputs
    ------------------------------------------------------------
    signal mul_R    : std_logic_vector(H-1 downto 0);
    signal mul_done : std_logic;

    signal sq_R     : std_logic_vector(H-1 downto 0);
    signal sq_done  : std_logic;

    ------------------------------------------------------------
    -- Blakely reset signals
    ------------------------------------------------------------
    signal mul_reset_n : std_logic := '0';
    signal sq_reset_n  : std_logic := '0';
    signal last_r      : std_logic := '0';
    signal fsm_last    : std_logic;

begin

    ------------------------------------------------------------
    -- RSA FSM
    ------------------------------------------------------------
    RSA_CONTROLLER : entity work.rsa_fsm
        generic map (
            H => H
        )
        port map (
            clk          => clk,
            reset_n      => reset_n,

            msgin_valid  => msgin_valid,
            msgin_ready  => msgin_ready,
            msgin_last   => msgin_last,

            msgout_valid => msgout_valid,
            msgout_ready => msgout_ready,
            msgout_last  => fsm_last,

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
    -- Blakely multiplier: C * P mod N
    ------------------------------------------------------------
    BLAKELY_MUL : entity work.blakely
        generic map (
            BLOCK_SIZE => H
        )
        port map (
            clk     => clk,
            reset_n => mul_reset_n,

            n       => N_reg,
            a       => C_reg,
            b       => P_reg,

            R       => mul_R,
            done    => mul_done
        );

    ------------------------------------------------------------
    -- Blakely squarer: P * P mod N
    ------------------------------------------------------------
    BLAKELY_SQ : entity work.blakely
        generic map (
            BLOCK_SIZE => H
        )
        port map (
            clk     => clk,
            reset_n => sq_reset_n,

            n       => N_reg,
            a       => P_reg,
            b       => P_reg,

            R       => sq_R,
            done    => sq_done
        );

    ------------------------------------------------------------
    -- RSA datapath registers
    ------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            if reset_n = '0' then

                C_reg <= (others => '0');
                P_reg <= (others => '0');
                E_reg <= (others => '0');
                N_reg <= (others => '0');
                last_r <= '0';

                mul_reset_n <= '0';
                sq_reset_n  <= '0';

            elsif load_en = '1' then

                -- Initialize RSA algorithm
                C_reg <= std_logic_vector(to_unsigned(1, H));
                P_reg <= msgin_data;
                E_reg <= e;
                N_reg <= n;
                last_r <= msgin_last;

                mul_reset_n <= '0';
                sq_reset_n  <= '0';

            else

                -- Update accumulated result
                if update_c = '1' then
                    C_reg <= mul_R;
                end if;

                -- Update squared value
                if update_p = '1' then
                    P_reg <= sq_R;
                end if;

                -- Shift exponent right
                if shift_e = '1' then
                    E_reg <= '0' & E_reg(H-1 downto 1);
                end if;

                -- Start Blakely units
                if sq_start = '1' then
                    sq_reset_n <= '1';
                end if;

                if mul_start = '1' then
                    mul_reset_n <= '1';
                end if;

                -- Reset Blakely units after each round
                if shift_e = '1' then
                    sq_reset_n  <= '0';
                    mul_reset_n <= '0';
                end if;

            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Current exponent bit
    ------------------------------------------------------------
    e_bit <= E_reg(0);

    ------------------------------------------------------------
    -- RSA output data
    ------------------------------------------------------------
    msgout_data <= C_reg;
    msgout_last <= fsm_last and last_r;

end Behavioral;

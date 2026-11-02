library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rsa_toplevel is
    Port (
        clk          : in  STD_LOGIC;
        reset_n      : in  STD_LOGIC;

        msgin_valid  : in  STD_LOGIC;
        msgin_ready  : out STD_LOGIC;
        msgout_valid : out STD_LOGIC;
        msgout_ready : in  STD_LOGIC;

        n            : in  STD_LOGIC_VECTOR(7 downto 0);
        m            : in  STD_LOGIC_VECTOR(7 downto 0);
        e            : in  STD_LOGIC_VECTOR(7 downto 0);

        R            : out STD_LOGIC_VECTOR(7 downto 0)
    );
end rsa_toplevel;

architecture Behavioral of rsa_toplevel is

    ----------------------------------------------------------------
    -- RSA FSM control signals
    ----------------------------------------------------------------

    signal load_en   : STD_LOGIC;
    signal mul_start : STD_LOGIC;
    signal sq_start  : STD_LOGIC;
    signal update_c  : STD_LOGIC;
    signal update_p  : STD_LOGIC;
    signal shift_e   : STD_LOGIC;
    signal e_bit     : STD_LOGIC;

    ----------------------------------------------------------------
    -- RSA datapath registers
    ----------------------------------------------------------------

    signal C_reg     : STD_LOGIC_VECTOR(7 downto 0);
    signal P_reg     : STD_LOGIC_VECTOR(7 downto 0);
    signal E_reg     : STD_LOGIC_VECTOR(7 downto 0);
    signal N_reg     : STD_LOGIC_VECTOR(7 downto 0);

    ----------------------------------------------------------------
    -- Blakely outputs
    ----------------------------------------------------------------

    signal mul_R     : STD_LOGIC_VECTOR(7 downto 0);
    signal mul_done  : STD_LOGIC;

    signal sq_R      : STD_LOGIC_VECTOR(7 downto 0);
    signal sq_done   : STD_LOGIC;

    ----------------------------------------------------------------
    -- Blakely reset signals
    ----------------------------------------------------------------

    signal mul_reset_n : STD_LOGIC;
    signal sq_reset_n  : STD_LOGIC;

begin
    ----------------------------------------------------------------
    -- RSA FSM
    ----------------------------------------------------------------

    RSA_CONTROLLER : entity work.rsa_fsm
        generic map (
            H => 8
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

    ----------------------------------------------------------------
    -- Blakely multiplier: C * P mod N
    ----------------------------------------------------------------

    BLAKELY_MUL : entity work.blakely
        port map (
            clk     => clk,
            reset_n => mul_reset_n,

            n       => N_reg,
            a       => C_reg,
            b       => P_reg,

            R       => mul_R,
            done    => mul_done
        );

    ----------------------------------------------------------------
    -- Blakely squarer: P * P mod N
    ----------------------------------------------------------------

    BLAKELY_SQ : entity work.blakely
        port map (
            clk     => clk,
            reset_n => sq_reset_n,

            n       => N_reg,
            a       => P_reg,
            b       => P_reg,

            R       => sq_R,
            done    => sq_done
        );

    ----------------------------------------------------------------
    -- Datapath registers
    ----------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then

            if reset_n = '0' then
                C_reg <= (others => '0');
                P_reg <= (others => '0');
                E_reg <= (others => '0');
                N_reg <= (others => '0');
                mul_reset_n <= '0';
                sq_reset_n  <= '0';

            elsif load_en = '1' then
                C_reg <= std_logic_vector(to_unsigned(1, 8));
                P_reg <= m;
                E_reg <= e;
                N_reg <= n;

            else
                if update_c = '1' then
                    C_reg <= mul_R;
                end if;

                if update_p = '1' then
                    P_reg <= sq_R;
                end if;

                if shift_e = '1' then
                    E_reg <= '0' & E_reg(7 downto 1);
                end if;
                
                if (sq_start = '1') then
                    sq_reset_n <= '1';
                end if;
                
                if (mul_start = '1') then
                    mul_reset_n <= '1';
                end if;
                
                if (shift_e = '1') then  -- shift_e is 1 so mul/sqr outputs no longer needed as that stage is done
                    sq_reset_n <= '0';
                    mul_reset_n <= '0';
                end if;
            
            end if;
            
        end if;
    end process;

    ----------------------------------------------------------------
    -- Blakely control (placeholder)
    ----------------------------------------------------------------

    -- TODO: Implement proper start/reset control for both units.
    -- mul_start and sq_start must trigger a new calculation.
    --
    -- The current blakely entity has no start input.
    -- Its reset_n must be controlled between calculations.
    
    e_bit <= E_reg(0);
    

    ----------------------------------------------------------------
    -- RSA output
    ----------------------------------------------------------------

    R <= C_reg;

end Behavioral;
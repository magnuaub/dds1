library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blakely is
     generic (BLOCK_SIZE : integer := 256);
    Port (
        clk     : in  STD_LOGIC;
        reset_n : in  STD_LOGIC;
        n       : in  STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        b       : in  STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        a       : in  STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        R       : out  STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        done    : out STD_LOGIC
    );
end blakely;

architecture Behavioral of blakely is

    type state_type is (START, CALC, FINISH);
    signal state : state_type := START;
    
    signal for_done    : STD_LOGIC;
    signal for_reset_n : STD_LOGIC := '0';
    signal a_shift     : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal r1          : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    --signal r2          : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal for_result  : STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal i_cnt       : integer range 0 to BLOCK_SIZE-1 := 0;
    


begin

      for_loop_logic : entity work.for_loop_logic
        generic map (BLOCK_SIZE => BLOCK_SIZE)
        port map (
            clk    => clk,
            n      => n,
            b      => b,
            a_i    => a_shift(BLOCK_SIZE-1),
            R      => r1,
            done   => for_done,
            reset_n => for_reset_n,
            result => for_result
        );
    R <= r1;
    process(clk)
    begin
        if rising_edge(clk) then 
            if reset_n = '0' then
                r1 <= (others => '0'); --R
                i_cnt <=  0; --i
                state <= START;
                a_shift <= a;
                for_reset_n <= '0';
                
                done <= '0';
              else
              case state is
                when START => 
                    for_reset_n <= '1';
                    state <= CALC;
                 when CALC =>
                    if for_done = '1' then
                        r1 <= for_result;
                        a_shift <= a_shift(BLOCK_SIZE-2 downto 0) & '0';
                        for_reset_n <= '0';
                     if i_cnt = BLOCK_SIZE -1 then
                        state <= FINISH;
                     else
                        i_cnt <= i_cnt + 1;
                        state <= START;
                     end if;
                end if;
                when FINISH =>
                    done <= '1';
            end case;
        end if;
      end if;
    end process;

end Behavioral;
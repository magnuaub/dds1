library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blakely is
    Port (
        clk     : in  STD_LOGIC;
        reset_n : in  STD_LOGIC;
        n      : in  STD_LOGIC_VECTOR(7 downto 0);
        b      : in  STD_LOGIC_VECTOR(7 downto 0);
        a      : in  STD_LOGIC_VECTOR(7 downto 0);
        R      : out  STD_LOGIC_VECTOR(7 downto 0);
        done   : out STD_LOGIC
    );
end blakely;

architecture Behavioral of blakely is

    type state_type is (START, CALC, FINISH);
    signal state : state_type := START;
    
    signal a_i      : STD_LOGIC;
    signal for_done : STD_LOGIC;
    signal for_R    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    
    signal r1 : unsigned(15 downto 0) := (others => '0');
    signal r2 : unsigned(15 downto 0) := (others => '0');
    


begin

      for_loop_logic : entity work.for_loop_logic
        port map (
            clk    => clk,
            n      => n,
            b      => b,
            a_i    => a_i,
            R      => for_R,
            done   => for_done,
            reset_n => reset_n,
            result => R
        );

    process(clk)
        variable temp : unsigned(15 downto 0);
    begin
        
        if reset_n = '0' then
            r1 <= (others => '0'); --R
            r2 <= (others => '0'); --i

        elsif rising_edge(clk) then

            case state is

                when START =>
                    r1 <= (others => '0');
                    r2 <= (others => '0');
                   
                when CALC =>
                    if (r2 >= a'length - 1) then
                        if ()
                        r1 <= ;
                        r2 <= r2 + 1;
                    else
                        --done
                    end
                when FINISH =>
                    state <= START;

            end case;
        end if;
    end process;

end Behavioral;
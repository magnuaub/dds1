library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity for_loop_logic is
    Port (
        clk    : in  STD_LOGIC;
        n      : in  STD_LOGIC_VECTOR(7 downto 0);
        b      : in  STD_LOGIC_VECTOR(7 downto 0);
        a_i    : in  STD_LOGIC_VECTOR(7 downto 0);
        R      : in  STD_LOGIC_VECTOR(7 downto 0);
        done   : out STD_LOGIC_VECTOR(7 downto 0)
    );
end for_loop_logic;

architecture Behavioral of for_loop_logic is

    -- Define the available states
    type state_type is (START, MULT, ADD, MOD);
    signal state : state_type := START;

begin

    process(clk)
        variable R1 : STD_LOGIC_VECTOR(7 downto 0);
        variable R2 : STD_LOGIC_VECTOR(7 downto 0);
    begin
        if rising_edge(clk) then

            case state is

                when START =>
                    R2 := a_i;
                    state <= CALCULATE;
                    
                when MULT =>
                    R2 := std_logic_vector(unsigned(R2) * unsigned(b));
                    state <= ADD;
                    
                when ADD =>
                    R2 := std_logic_vector(shift_left(unsigned(R2), 1)) + unsigned(R2);
                    state <= MOD;
                    
                when MOD =>
                    if unsigned(R2) >= unsigned(n) then
                        R2 := std_logic_vector(unsigned(R2) - unsigned(n));
                    end if;
                    state <= FINISH;
                    
                when FINISH =>
                    done := 1;
                    
            end case;

        end if;
    end process;

end Behavioral;
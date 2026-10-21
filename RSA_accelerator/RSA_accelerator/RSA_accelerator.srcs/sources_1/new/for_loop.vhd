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
        done   : out STD_LOGIC;
        result : out STD_LOGIC_VECTOR(7 downto 0)
    );
end for_loop_logic;

architecture Behavioral of for_loop_logic is

    type state_type is (START, MULT_LS, ADD, MODULO, FINISH);
    signal state : state_type := START;

    signal r1 : unsigned(15 downto 0) := (others => '0');
    signal r2 : unsigned(15 downto 0) := (others => '0');
    signal result_reg : unsigned(7 downto 0) := (others => '0');

begin

    result <= std_logic_vector(r1(7 downto 0));
    
    done <= '1' when state = FINISH else '0';

    process(clk)
        variable temp : unsigned(15 downto 0);
    begin
        if rising_edge(clk) then

            case state is

                when START =>
                    r2 <= resize(unsigned(a_i), 16);
                    state <= MULT_LS;

                when MULT_LS =>
                    temp := resize(unsigned(r2(7 downto 0)) * unsigned(b), 16);
                    r2 <= temp;
                    r1 <= shift_left(r2, 1);
                    state <= ADD;
                    
                when ADD =>
                    -- Calculate 3 * (a_i * b)
                    r2 <= r1 + r2;
                    state <= MODULO;

                when MODULO =>
                    if signed(r2) >= 0 then
                        r1 <= r2;
                        r2 <= r2 - unsigned(n);
                        state <= MODULO; 
                    else
                        state <= FINISH;
                    end if;

                when FINISH =>
                    null;

            end case;
        end if;
    end process;

end Behavioral;
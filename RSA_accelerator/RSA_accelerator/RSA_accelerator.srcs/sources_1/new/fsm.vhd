----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.10.2026 11:51:28
-- Design Name: 
-- Module Name: fsm - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


-- FSM for the RSA core (RL binary method).
-- Every round, mul (C*P) and square (P*P) start in parallel.
-- C is only updated when e_bit = 1.
-- Assumes both Blakley units have the same latency.

entity rsa_fsm is
    generic (H : positive := 256);          -- key width
    port (
        clk          : in  std_logic;
        reset_n      : in  std_logic;       -- active low, synchronous

        msgin_valid  : in  std_logic;
        msgin_ready  : out std_logic;
        msgout_valid : out std_logic;
        msgout_ready : in  std_logic;

        e_bit        : in  std_logic;       -- current exponent bit (LSB of e_sr)
        mul_done     : in  std_logic;
        sq_done      : in  std_logic;

        load_en      : out std_logic;       -- load M->P, C:=1, n, e
        mul_start    : out std_logic;
        sq_start     : out std_logic;
        update_c     : out std_logic;
        update_p     : out std_logic;
        shift_e      : out std_logic
    );
end rsa_fsm;

architecture Behavioral of rsa_fsm is

    type state_type is (IDLE, START, WAIT_DONE, SHIFT, OUT_ST);
    signal state, next_state : state_type;
    signal i_cnt : integer range 0 to H := 0;   -- round counter

begin

    -- State register and round counter
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                state <= IDLE;
                i_cnt <= 0;
            else
                state <= next_state;
                if state = IDLE then
                    i_cnt <= 0;
                elsif state = SHIFT then
                    i_cnt <= i_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- Next state and outputs
    process(state, msgin_valid, msgout_ready, e_bit, mul_done, sq_done, i_cnt)
    begin
        next_state   <= state;
        msgin_ready  <= '0';
        msgout_valid <= '0';
        load_en      <= '0';
        mul_start    <= '0';
        sq_start     <= '0';
        update_c     <= '0';
        update_p     <= '0';
        shift_e      <= '0';

        case state is
            when IDLE =>
                msgin_ready <= '1';
                if msgin_valid = '1' then
                    load_en    <= '1';
                    next_state <= START;
                end if;

            when START => -- initialize both mult and sq
                if (e_bit = '1') then
                    mul_start  <= '1';
                end if;
                sq_start   <= '1';
                next_state <= WAIT_DONE;

            when WAIT_DONE => -- wait until both are done
                if (mul_done = '1' or e_bit = '0') and sq_done = '1' then
                    next_state <= SHIFT;
                end if;

            when SHIFT => -- shift e bit
                update_c <= e_bit;
                update_p <= '1';
                shift_e  <= '1';
                if i_cnt = H-1 then
                    next_state <= OUT_ST;
                else
                    next_state <= START;
                end if;

            when OUT_ST => --done state
                msgout_valid <= '1';
                if msgout_ready = '1' then
                    next_state <= IDLE;
                end if;
        end case;
    end process;

end Behavioral;
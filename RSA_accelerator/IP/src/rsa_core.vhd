--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018-2019
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256;
		NUM_CORES             : integer := 7
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic;
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core;


architecture rtl of rsa_core is
       --every core signal needs its own copy indexed by i, and logic to pick a core
       type data_array is array(0 to NUM_CORES-1) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
       
       signal core_msgin_valid     : std_logic_vector(NUM_CORES-1 downto 0);
       signal core_msgin_ready    : std_logic_vector(NUM_CORES-1 downto 0);
       signal core_msgout_valid    : std_logic_vector(NUM_CORES-1 downto 0);
       signal core_msgout_ready    : std_logic_vector(NUM_CORES-1 downto 0);
       signal core_msgout_data     : data_array;
       signal core_msgout_last     : std_logic_vector(NUM_CORES-1 downto 0);
       
       signal in_core_sel       : integer range 0 to NUM_CORES-1;
       signal out_core_sel      : integer range 0 to NUM_CORES-1;
       
begin
gen_cores: for i in 0 to NUM_CORES-1 generate
    core_msgin_valid(i)    <= msgin_valid when in_core_sel = i else '0';
    core_msgout_ready(i)   <= msgout_ready when out_core_sel = i else '0';
    
	i_rsa : entity work.rsa_toplevel
		generic map (
			H => C_BLOCK_SIZE
		)
		port map (
			clk          => clk,
			reset_n      => reset_n,
			msgin_valid  => core_msgin_valid(i),
			msgin_ready  => core_msgin_ready(i),
			msgin_last   => msgin_last,
			msgin_data   => msgin_data,
			msgout_valid => core_msgout_valid(i),
			msgout_ready => core_msgout_ready(i),
			msgout_last  => core_msgout_last(i),
			msgout_data  => core_msgout_data(i),
			n            => key_n,
			e            => key_e_d
		);

end generate gen_cores;
	
	-- outputs
	msgin_ready         <= core_msgin_ready(in_core_sel);
    msgout_valid        <= core_msgout_valid(out_core_sel);
    msgout_data         <= core_msgout_data(out_core_sel);
    msgout_last         <= core_msgout_last(out_core_sel);
    
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                in_core_sel <= 0;
                out_core_sel <= 0; 
            else
            
            -- block accepted by the selected core -> next block to next core
            if msgin_valid = '1' and core_msgin_ready(in_core_sel) = '1' then
                if in_core_sel = NUM_CORES-1 then
                    in_core_sel <= 0;
                else
                    in_core_sel <= in_core_sel + 1;
                end if;
            end if;
            
            -- result taken from selected core -> next result from next core
            if core_msgout_valid(out_core_sel) = '1' and msgout_ready = '1' then
                if out_core_sel = NUM_CORES-1 then
                    out_core_sel <= 0;
                else
                    out_core_sel <= out_core_sel + 1;
           end if;
         end if; 
            
         end if;
       end if;
     end process; 
     
     --status on cores
     process(core_msgin_ready)
     begin
        rsa_status <= (others => '0');
        for i in 0 to NUM_CORES-1 loop
            rsa_status(i) <= not core_msgin_ready(i);
        end loop;
     end process;
                
end rtl;
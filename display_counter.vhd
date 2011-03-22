library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity DisplayCounter is
	port(
		clock: in std_logic;
		A, B, PB: in std_logic;
		segments: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		sel: out std_logic_vector(3 downto 0)
	);
end DisplayCounter;

architecture Behavioral of DisplayCounter is
	component Rotary is
		port(
			clock: in std_logic;
			A: in std_logic;
			B: in std_logic;
			inc: out std_logic;
			dec: out std_logic
		);
	end component;
	
	component Display4 is
		port(
			clock: in std_logic;
			DWE: in std_logic;
			data: in std_logic_vector(15 downto 0);
			dps: in std_logic_vector(3 downto 0);
			segments: out std_logic_vector(6 downto 0);
			dp: out std_logic;
			sel: out std_logic_vector(3 downto 0)
		);
	end component;
	
	component Debouncer is
		port(
			clock: in std_logic;
			reset: in std_logic;
			d_in: in std_logic;
			q_out: out std_logic
		);
	end component;
	
	signal counter: std_logic_vector(15 downto 0) := (others => '0');
	signal up, down: std_logic;
	signal enable_write: std_logic := '1';
	signal active_digit: std_logic_vector(3 downto 0) := "1000";
	signal PB_debounced: std_logic := '1';
begin
	-- create rotary decoder
	r: Rotary port map(
		clock => clock,
		A => A,
		B => B,
		inc => up,
		dec => down
	);
	
	-- create 4-digit display
	d4: Display4 port map(
		clock => clock,
		DWE => enable_write,
		data => counter,
		dps => active_digit,
		segments => segments,
		dp => dp,
		sel => sel
	);
	
	-- create button debouncer
	db: Debouncer port map(
		clock => clock,
		reset => PB,
		d_in => not PB,
		q_out => PB_debounced
	);
	
	-- update count based on rotary output
	update_counter: process(clock, up, down, PB, active_digit)
	begin
		if clock'event and clock = '1' then
			if down = '1' then
				counter <= counter - 1;
				enable_write <= '1';
			elsif up = '1' then
				counter <= counter + 1;
				enable_write <= '1';
			elsif PB_debounced = '1' then
				case active_digit is
					when "0000" => active_digit <= "0001";
					when "0001" => active_digit <= "0010";
					when "0010" => active_digit <= "0100";
					when "0100" => active_digit <= "1000";
					when "1000" => active_digit <= "0000";
					when others => active_digit <= "0000";
				end case;
				enable_write <= '1';
			else
				enable_write <= '0';
			end if;
		end if;
	end process;

end Behavioral;


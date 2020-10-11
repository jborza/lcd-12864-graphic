module LCD12864 (clk, rs, rw, en, dat);  
input clk;  
 output [7:0] dat; 
 output  rs,rw,en; 
 //tri en; 
 reg e; 
 reg [7:0] dat; 
 reg rs;   
 reg  [10:0] counter; 
 reg [5:0] current,next; //state machine states
 reg clkr; 
 reg [1:0] cnt; 

 reg [7:0] mem [0:1023];
 reg [9:0] mem_index;
 
 //display coordinates
 reg [3:0] x;
 reg [5:0] y;
 
 reg [7:0] pattern;
 
 wire [7:0] y_out;
 wire [7:0] x_out;
 
 
 //states
 parameter  set0=6'h0; 
 parameter  set1=6'h1; 
 parameter  set2=6'h2; 
 parameter  set3=6'h3; 
 parameter  set4=6'h4; 
 parameter  set5=6'h5;
 parameter  set6=6'h6;  

 
 parameter address_vertical = 7, address_horizontal=8;
 parameter data_address_vertical=9, data_address_horizontal=10, data2=11, data3=12;
 
 parameter  row0=6'h7; 
 parameter  row1=6'h8; 
 parameter  row2=6'h9; 
 parameter  row3=6'hA;
 
 parameter  loop=6'h2F; 
 parameter  nul=6'h3F;  
 
 parameter y_initial = 8'b10000000;
 parameter x_initial = 8'b10000000;
 
 parameter SET_MODE_8BIT = 8'b00110000;
 parameter SET_MODE_GRAPHIC = 8'b00110110;
 parameter DISPLAY_ON_CURSOR_OFF_BLINK_OFF = 8'b00001100;
 
 
 task write_pixels;
	input [5:0] exit_state;
	
	begin
		rs <= 1;
		dat <= mem[mem_index];
		mem_index <= mem_index + 1;
		x <= x + 1;
		if(x == 15) begin
			x <= 0;
			y <= y + 1;
		end
		if(mem_index == 1023) begin
			next <= exit_state;
		end else begin
			next <= data_address_vertical;
		end
	end
 endtask

 task command;
	input [7:0] data;
	input [5:0] next_state;
	
	begin
		rs <= 0;
		dat <= data;
		next <= next_state;
	end
 endtask

 initial begin;
	$readmemb("rom3.txt", mem);
 end
 
always @(posedge clk)        
 begin 
  //we want to hit 72 us per display instruction. 72 us 
  counter=counter+1; 
  //clkr inverted on every overflow of 11-bit counter -> is toggled every 50,000,000 / (2^11*2) = 12 khz
  if(counter==12'h000f) begin										
		clkr=~clkr; 
	end
end 
always @(posedge clkr) 
begin 
 current=next; 
  case(current) 
    set0: begin command(SET_MODE_8BIT, set1); mem_index <= 0; y <= 0; x<=0; pattern <= 0; end // 8-bit interface   
	 set1: begin command(DISPLAY_ON_CURSOR_OFF_BLINK_OFF, set2); end // display on       
	 set2: begin command(SET_MODE_GRAPHIC, set3); end // extended instruction set
	 set3: begin command(SET_MODE_GRAPHIC, data_address_vertical); end //graphic mode on
	 
	 //GDRAM address is set by writing 2 consecutive bytes for vertical address and horizontal address. 
	 //Two-bytes data write to GDRAM for one address. Address counter will automatically increase by one for the next two-byte  data.
	 
	 
	 //address_vertical:   begin command(y, address_horizontal); end   
	 //address_horizontal: begin command(8'b10000000, data_address_vertical); end  
	 
	 data_address_vertical: begin command(y + y_initial, data_address_horizontal); end //address_vertical
	 data_address_horizontal: begin command(x + x_initial, data2); end //address_horizontal
	 data2: begin
		//first 8 pixels
		rs <= 1;
		//dat <= y+y_initial;
		dat <= mem[mem_index];
		//dat <= pattern + x;
		mem_index <= mem_index + 1;
		//x <= x + 1;
		next <= data3;
	 end
	 data3: begin
		//next 8 pixels
		rs <= 1;
		//dat <= y+y_initial;
		dat <= mem[mem_index];
		//dat <= pattern + y + x;
		mem_index <= mem_index + 1;
		x <= x + 1;
		if (x == 15) begin
			y <= y + 1; //x wraps around
			x <= 0;
			next <= data_address_vertical;
		end else begin
			next <= data2;
		end
		if(x == 15 && y == 31) begin //test for first N rows
			y <= 0;
			mem_index <= 0;
			pattern <= pattern + 1;
		end
	 end
	 //data2: begin write_pixels(loop); end
	 		
	 loop: begin rs <= 0; dat<=8'b00000001; /*standby*/  next <= set0; end

   default:   next=set0; 
    endcase 
 end 
assign en=clkr|e; 
assign rw=0; 
endmodule  
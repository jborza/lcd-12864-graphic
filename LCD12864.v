module LCD12864 (clk, rs, rw, en,dat);  
input clk;  
 output [7:0] dat; 
 output  rs,rw,en; 
 //tri en; 
 reg e; 
 reg [7:0] dat; 
 reg rs;   
 reg  [15:0] counter; 
 reg [5:0] current,next; //state machine states
 reg clkr; 
 reg [1:0] cnt; 

 reg [7:0] mem [0:1023];
 reg [9:0] mem_index;
 
 //display coordinates
 reg [3:0] x;
 reg [5:0] y;
 
 
 //states
 parameter  set0=6'h0; 
 parameter  set1=6'h1; 
 parameter  set2=6'h2; 
 parameter  set3=6'h3; 
 parameter  set4=6'h4; 
 parameter  set5=6'h5;
 parameter  set6=6'h6;  

 
 parameter address_vertical = 7, address_horizontal=8;
 parameter data0=9, data1=10, data2=11, data3=12;
 
 parameter  row0=6'h7; 
 parameter  row1=6'h8; 
 parameter  row2=6'h9; 
 parameter  row3=6'hA;
 
 parameter  loop=6'h2F; 
 parameter  nul=6'h3F;  
 
 parameter y_initial = 8'b1000000;
 
 task write_pixels;
//	input [5:0] next_state;
	
	begin
		rs <= 1;
		dat <= mem[mem_index];
		mem_index <= mem_index + 1;
		x <= x + 1;
		if(x == 15) begin
			x <= 0;
			y <= y + 1;
			next <= address_vertical;
		end
		if(mem_index == 1023) begin
			next <= loop;
		end
	end
 endtask

 task command;
	input [7:0] data;
	input [7:0] next_state;
	
	begin
		rs <= 0;
		dat <= data;
		next <= next_state;
	end
 endtask

 
 
 initial begin;
	$readmemb("ram_pattern_0xaa.txt", mem);
 end
 
always @(posedge clk)        
 begin 
  counter=counter+1; 
  if(counter==16'h000f)  
  clkr=~clkr; 
end 
always @(posedge clkr) 
begin 
 current=next; 
  case(current) 
    set0: begin command(8'b00110000, set1); mem_index <= 0; y <= y_initial; x<=0; end // 8-bit interface   
	 set1: begin command(8'b00001100, set2); end // display on       
	 set2: begin command(8'b00110110, set3); end // extended instruction set
	 set3: begin command(8'b00110110, set4); end //graphic mode on  
	 
    set4:   begin  rs<=0; dat<=8'h1; next<=address_vertical;  end  //CLEAR - I know we have to delay for 1.6 ms (22 clkr cycles)
	 
	 //GDRAM address is set by writing 2 consecutive bytes for vertical address and horizontal address. 
	 //Two-bytes data write to GDRAM for one address. Address counter will automatically increase by one for the next two-byte data.
	 
	 
	 address_vertical:   begin command(y, address_horizontal); end   
	 address_horizontal: begin command(8'b10000000, data0); end  
	 
	 data0: begin
		write_pixels();
	 end
	 		
	 loop: begin rs <= 0; dat<=8'h00000001; /*standby*/  next <= set0; end

   default:   next=set0; 
    endcase 
 end 
assign en=clkr|e; 
assign rw=0; 
endmodule  
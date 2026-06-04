//============================================================================
//  Arcade: Congo Bongo
//
//  Port to MiSTer
//  Congo Bongo by Dar (darfpga@aol.fr - sourceforge/darfpga - github/darfpga)
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + per-pin push-pull mask, USER_IO widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driven by wrapper; USER_OUT driven by joydb (USER_OUT_DRIVE) below
assign USER_PP = USER_PP_DRIVE;
// [MiSTer-DB9 END]
assign LED_USER  = rom_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;

assign FB_FORCE_BLANK = '0;
assign HDMI_FREEZE = 0;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = status[125];
// SNAC cores: replace 1'b0 with the core's SNAC enable expression so SNAC
// preempts the joydb wrapper on shared USER_IO pins. Default 1'b0 is no-op.
wire         snac_active     = 1'b0;
// MT32-pi cores on primary USER_IO: replace 1'b0 with the core's MT32-active
// expression (e.g. `mt32_use` under `ifndef SECOND_MT32`, `~mt32_disable` for
// TRS-80's inverted polarity). Suppresses the OSD-open autodetect probe so it
// doesn't read the RPi's I2C master traffic as a ghost Saturn signature.
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// Legacy 3-bit alias for fork-specific MT32 / SNAC fallback code. Non-canonical
// RHS variants (ext_iec_en, mt32_disable) need a hand-port — alias is raw.
wire   [2:0] JOY_FLAG        = {joy_db9md_en, joy_db15_en, joy_2p};
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire  [15:0] joy_raw_payload;

joydb joydb (
  .clk             ( CLK_JOY         ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .joy_raw         ( joy_raw_payload )
);

assign USER_OUT = USER_OUT_DRIVE;
// [MiSTer-DB9 END]

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2]) ? 12'd2560 : 12'd2191) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2]) ? 12'd2191 : 12'd2560) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"CONGOBONGO;;",
	"-;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"H1OR,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OP,Pause when OSD is open,On,Off;",
	"P1OQ,Dim video after 10s,On,Off;",
	// [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
	"O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
	"O[125],UserIO Players, 1 Player,2 Players;",
	// [MiSTer-DB9-Pro END]
	"-;",
	"DIP;",
	"-;",
//	"O6,Service,Off,On;",
	"O7,Flip,Off,On;",
	"OA,Diagonal joystick,Off,On;",
	"-;",
	"R0,Reset;",
	"J1,Fire 1,Fire 2,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,B,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_48m, pll_locked;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys), // 24M
	.outclk_1(clk_48m),
	.locked(pll_locked)  
);

///////////////////////////////////////////////////

// [MiSTer-DB9 BEGIN] - widened to 128 bits for joy_type at [127:126] and joy_2p at [125]
wire [127:0] status;
// [MiSTer-DB9 END]
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire [15:0] audio_l, audio_r;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: rename USB joystick wires
wire [15:0] joy1_USB, joy2_USB, joy3, joy4;
// [MiSTer-DB9 END]
wire [15:0] joy = joy1 | joy2 | joy3 | joy4;
// [MiSTer-DB9-Pro BEGIN] - DB controllers muted while OSD is open
wire [31:0] joy1 = joydb_1ena ? (OSD_STATUS ? 32'b0 : {joydb_1[11],joydb_1[9],joydb_1[10],joydb_1[5:0]}) : joy1_USB;
wire [31:0] joy2 = joydb_2ena ? (OSD_STATUS ? 32'b0 : {joydb_2[11],joydb_2[10],joydb_2[9],joydb_2[5:0]}) : joydb_1ena ? joy1_USB : joy2_USB;
// [MiSTer-DB9-Pro END]
wire [15:0] joy1a, joy2a, joy3a, joy4a;

wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire        mouse_strobe;
reg   [7:0] mouse_flags;

wire [21:0] gamma_bus;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_index;
wire        ioctl_wait;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.status_menumask({~hs_configured,direct_video}),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.video_rotated(video_rotated),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),

	.joystick_0(joy1_USB),
	.joystick_1(joy2_USB),
	.joystick_2(joy3),
	.joystick_3(joy4),

	.joystick_l_analog_0(joy1a),
	.joystick_l_analog_1(joy2a),
	.joystick_l_analog_2(joy3a),
	.joystick_l_analog_3(joy4a),
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw
	.joy_raw(OSD_STATUS ? joy_raw_payload : 16'b0),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
	.saturn_unlocked(saturn_unlocked)
	// [MiSTer-DB9-Pro END]
);

// load the DIPS
reg [7:0] sw[8];
always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

// load the game title
//reg [7:0] mod = 0;
//always @(posedge clk_sys) if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;

wire m_start1  = joy1[5];
wire m_start2  = joy1[6];
wire m_coin1   = joy1[7];

wire m_right1  = joy1[0];
wire m_left1   = joy1[1];
wire m_down1   = joy1[2];
wire m_up1     = joy1[3];
wire m_fire1a  = joy1[4];
wire m_fire1b  = joy1[5];

wire m_right2  = joy2[0];
wire m_left2   = joy2[1];
wire m_down2   = joy2[2];
wire m_up2     = joy2[3];
wire m_fire2a  = joy2[4];
wire m_fire2b  = joy2[5];

wire m_right   = m_right1 | m_right2;
wire m_left    = m_left1  | m_left2; 
wire m_down    = m_down1  | m_down2; 
wire m_up      = m_up1    | m_up2;   
wire m_fire_a  = m_fire1a | m_fire2a;
wire m_fire_b  = m_fire1b | m_fire2b;
wire m_pause   = joy1[8];

wire m_north, m_south, m_east, m_west;

always @(*) begin
	if (~status[10]) begin
		m_north <= m_up;
		m_south <= m_down;
		m_east  <= m_right;
		m_west  <= m_left;
	end
	else begin
		m_north <= m_up    & m_right;
		m_south <= m_down  & m_left;
		m_east  <= m_right & m_down;
		m_west  <= m_left  & m_up;		
	end 
end

// PAUSE SYSTEM
wire				pause_cpu;
wire [7:0]		rgb_out;
pause #(3,3,2,24) pause (
	.*,
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25])
);

reg         download_complete = 1'b0;
reg         last_ioctl_download;
reg   [7:0] last_ioctl_index;
always @(posedge clk_sys)
begin
	last_ioctl_download <= ioctl_download;
	last_ioctl_index <= ioctl_index;
	if (last_ioctl_download == 1'd1 && ioctl_download == 1'd0 && last_ioctl_index == 2'd2) download_complete = 1'b1;
end

wire rom_download = ioctl_download && (ioctl_index == 1'd0);
wire wave_download = ioctl_download && (ioctl_index == 2'd2);
wire reset = status[0] | buttons[1] | (download_complete == 1'b0);

congo_bongo congo_bongo
(
	.clock_24(clk_sys),
	.reset(reset),
	.pause(pause_cpu),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_vblank(vblank),
	.video_hblank(hblank),
	.video_hs(hs),
	.video_vs(vs),
//	.video_csync(cs),
//	.video_ce(ce_pix),
//	.tv15Khz_mode(~status[3]),
	.audio_out_l(audio_l),
	.audio_out_r(audio_r),

	.dl_addr(ioctl_addr[17:0]),
	.dl_wr(ioctl_wr & rom_download),
	.dl_data(ioctl_dout),

	.coin1(m_coin1),
	.coin2(1'b0),
	.start1(m_start1),
	.start2(m_start2),

	.right(m_east),
	.left(m_west),
	.up(m_north),
	.down(m_south),
	.fire(m_fire_a),
 
	.right_c(m_east),
	.left_c(m_west),
	.up_c(m_north),
	.down_c(m_south),
	.fire_c(m_fire_a),

	.sw1_input(sw[0]), // cocktail(1) / sound(1) / ships(2) / N.U.(2) /  extra ship (2)	
	.sw2_input(8'h33), // coin b(4) / coin a(4)  -- "3" => 1c_1c

	//.service(status[6]),
	.flip_screen(~status[7])
	
//Dar	.wave_data(wave_data),
//Dar	.wave_addr(wave_addr),
//Dar	.wave_rd(wave_rd),
	
//Dar	.hs_address(hs_address),
//Dar	.hs_data_out(hs_data_out),
//Dar	.hs_data_in(hs_data_in),
//Dar	.hs_write(hs_write_enable)
);

//wire ce_pix_old;
wire hs, vs, cs;
wire hblank, vblank;
wire [2:0] r,g;
wire [1:0] b;

// dev - bypass arcade_video
//assign VGA_CLK = clk_sys;
//assign VGA_CE = ce_pix;
//assign VGA_R = {r, 4'b0000};
//assign VGA_G = {g, 4'b0000};
//assign VGA_B = {b, 5'b00000};
//assign VGA_HS = hs;
//assign VGA_VS = vs;
//assign VGA_DE = ~(vblank | hblank);

reg ce_pix;
always @(posedge clk_48m) begin
	reg [2:0] div;
	
	div <= div + 1'd1;
	ce_pix <= !div;
end

wire rotate_ccw = 0;
wire no_rotate = status[2] | direct_video  ;
wire flip = 0;
wire video_rotated;
screen_rotate screen_rotate (.*);

arcade_video #(256,8) arcade_video
(
	.*,

	.clk_video(clk_48m),
	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.fx(status[5:3])
);

assign AUDIO_L = { audio_l };
assign AUDIO_R = { audio_r };
assign AUDIO_S = 0;

//Dar

//wire [19:0] wave_addr;
//wire [15:0] wave_data;
//wire        wave_rd;	
//	
//sdram sdram
//(
//	.*,
//	.init(~pll_locked),
//	.clk(clk_48m),
//
//	.addr(ioctl_download ? ioctl_addr :{5'b0,wave_addr}),
//	.we(wave_download && ioctl_wr),
//	.rd(~ioctl_download & wave_rd),
//	.din(ioctl_dout),
//	.dout(wave_data),
//
//	.ready()
//);


// HISCORE SYSTEM
// --------------

//Dar

//wire [11:0]hs_address;
//wire [7:0] hs_data_in;
//wire [7:0] hs_data_out;
//wire hs_write_enable;
//wire hs_pause;
//wire hs_configured;
//
//hiscore #(
//	.HS_ADDRESSWIDTH(12),
//	.HS_SCOREWIDTH(8),			// 129 bytes max (zaxxon/szaxxon)
//	.CFG_ADDRESSWIDTH(2),		// 2 entries max (zaxxon/szaxxon)
//	.CFG_LENGTHWIDTH(2)
//) hi (
//	.*,
//	.clk(clk_sys),
//	.paused(pause_cpu),
//	.autosave(status[27]),
//	.ram_address(hs_address),
//	.data_from_ram(hs_data_out),
//	.data_to_ram(hs_data_in),
//	.data_from_hps(ioctl_dout),
//	.data_to_hps(ioctl_din),
//	.ram_write(hs_write_enable),
//	.ram_intent_read(),
//	.ram_intent_write(),
//	.pause_cpu(hs_pause),
//	.configured(hs_configured)
//);

endmodule

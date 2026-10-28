module TB;

logic pclk;
logic presetn;
logic psel;
logic penable;
logic pwrite;
logic [31:0] paddr;
logic [31:0] pwdata;
wire [31:0] prdata;
wire pready;
wire pslverr;

parameter p_device_offset = 32'h7000_0000;

logic [31:0] address;
logic [31:0] data_to_device;
logic [31:0] data_from_device;

apb_slave DUT
(
.pclk(pclk),
.presetn(presetn),
.paddr(paddr),
.pwdata(pwdata),
.psel(psel),
.penable(penable),
.pwrite(pwrite),
.pready(pready),
.pslverr(pslverr),
.prdata(prdata)
);

task apb_write(input [31:0] addr, input [31:0] data);
    wait ((penable==0) && (pready == 0));
    @(posedge pclk);
    psel <= 1'b1;
    paddr[31:0] <= addr[31:0];
    pwdata[31:0] <= data[31:0];
    pwrite <= 1'b1;
    @(posedge pclk);
    penable <= 1'b1;
    @(posedge pclk);
    wait (pready == 1'b1);
    @(posedge pclk);
    psel <= 1'b0;
    penable <= 1'b0;
    pwrite <= 1'b0;
    @(posedge pclk);
endtask

task apb_read(input [31:0] addr, output logic [31:0] data);
    wait ((penable==0) && (pready == 0));
    @(posedge pclk);
    psel <= 1'b1;
    pwrite <= 1'b0;
    paddr[31:0] <= addr[31:0];
    @(posedge pclk);
    penable <= 1'b1;
    @(posedge pclk);
    wait (pready == 1'b1);
    @(posedge pclk);
    data[31:0] <= prdata[31:0];
    psel <= 1'b0;
    penable <= 1'b0;
    @(posedge pclk);
endtask

always
    #10ns pclk = ~pclk;

// ---- Персональные данные ----
// Для ASCII-строк используется little-endian: байт [7:0]
localparam [31:0] GROUP_NUMBER  = 32'd1;         // номер в списке группы
localparam [31:0] DATE_DDMMYYYY = 32'd28102026;  // 28.10.2026 - дата в дд.мм.гггг
localparam [31:0] SURNAME_ASCII = 32'h726F6241;  // "Abor" - 41 62 6F 72
localparam [31:0] NAME_ASCII    = 32'h65747241;  // "Arte" - 41 72 74 65

initial
begin
    pclk = 0;
    presetn = 1'b1;
    psel    = '0;
    penable = '0;
    pwrite  = '0;
    paddr   = '0;
    pwdata  = '0;

    repeat (5) @(posedge pclk);
    presetn = 1'b0;
    repeat (5) @(posedge pclk);
    presetn = 1'b1;
    repeat (5) @(posedge pclk);

    $display("\n===== Writing data to registries =====");

    // 0x0: номер в списке группы
    address = p_device_offset + 32'h0;
    data_to_device = GROUP_NUMBER;
    apb_write(address, data_to_device);
    $display(">> WRITE @0x0 (number in group): 0x%h (%0d)", data_to_device, data_to_device);

    // 0x4: дата в формате дд.мм.гггг
    address = p_device_offset + 32'h4;
    data_to_device = DATE_DDMMYYYY;
    apb_write(address, data_to_device);
    $display(">> WRITE @0x4 (date dd.mm.yyyy): 0x%h (%0d)", data_to_device, data_to_device);

    // 0x8: первые 4 буквы фамилии в ASCII
    address = p_device_offset + 32'h8;
    data_to_device = SURNAME_ASCII;
    apb_write(address, data_to_device);
    $display(">> WRITE @0x8 (surname ASCII): 0x%h ('%c%c%c%c')",
             data_to_device, data_to_device[7:0], data_to_device[15:8],
             data_to_device[23:16], data_to_device[31:24]);

    // 0xC: первые 4 буквы имени в ASCII
    address = p_device_offset + 32'hC;
    data_to_device = NAME_ASCII;
    apb_write(address, data_to_device);
    $display(">> WRITE @0xC (name ASCII): 0x%h ('%c%c%c%c')",
             data_to_device, data_to_device[7:0], data_to_device[15:8],
             data_to_device[23:16], data_to_device[31:24]);

    $display("\n===== Reading data from registries =====");

    address = p_device_offset + 32'h0;
    apb_read(address, data_from_device);
    $display(">> READ @0x0: 0x%h (%0d)", data_from_device, data_from_device);

    address = p_device_offset + 32'h4;
    apb_read(address, data_from_device);
    $display(">> READ @0x4: 0x%h (%0d)", data_from_device, data_from_device);

    address = p_device_offset + 32'h8;
    apb_read(address, data_from_device);
    $display(">> READ @0x8: 0x%h ('%c%c%c%c')",
             data_from_device, data_from_device[7:0], data_from_device[15:8],
             data_from_device[23:16], data_from_device[31:24]);

    address = p_device_offset + 32'hC;
    apb_read(address, data_from_device);
    $display(">> READ @0xC: 0x%h ('%c%c%c%c')",
             data_from_device, data_from_device[7:0], data_from_device[15:8],
             data_from_device[23:16], data_from_device[31:24]);

    repeat (10) @(posedge pclk);
    $stop();
end

initial
begin
    $monitor("APB IF: PSEL=%b PENABLE=%b PWRITE=%b PREADY=%b PADDR=0x%h PWDATA=0x%h PRDATA=0x%h PSLVERR=%b",
             psel, penable, pwrite, pready, paddr, pwdata, prdata, pslverr);
end

endmodule
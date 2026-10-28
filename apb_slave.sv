module apb_slave
(
    input pclk, //синхросигнал
    input presetn, //сигнал сброса (инверсный)
    input [31:0] paddr, //адрес обращения
    input [31:0] pwdata, //данные для записи
    input psel, // признак выбора устройсва
    input penable, //признак активной транзакции
    input pwrite, // признак операции записи
    output logic pready, // признак готовности от устройства
    output logic pslverr, // опциональный сигнал: признак ошибки при обращении
    output logic [31:0] prdata // прочитанные данные
);

// Регистры устройства
logic [31:0] reg_id;        // 0x0 - номер в списке группы
logic [31:0] reg_date;      // 0x4 - дата дд.мм.гггг
logic [31:0] reg_surname;   // 0x8 - первые 4 буквы фамилии (ASCII)
logic [31:0] reg_name;      // 0xC - первые 4 буквы имени (ASCII)
logic [31:0] register_with_some_name; // управляющий регистр (по смещению 0 логики)

//APB FSM
enum logic [1:0] 
{
    APB_SETUP,
    APB_W_ENABLE,
    APB_R_ENABLE
} apb_st;

always @(posedge pclk)
if (!presetn)
begin
    prdata <= '0;
    pslverr <= 1'b0;
    pready <= 1'b0;
    reg_id <= 32'h0;
    reg_date <= 32'h0;
    reg_surname <= 32'h0;
    reg_name <= 32'h0;
    register_with_some_name <= 32'h0;
    apb_st <= APB_SETUP;
end
else
begin
    case(apb_st)
    APB_SETUP:
    begin: apb_setup_st
        prdata <= '0;
        pready <= 1'b0;
        pslverr <= 1'b0;

        if (psel && !penable)
        begin
            if (pwrite == 1'b1)
                apb_st <= APB_W_ENABLE;
            else
                apb_st <= APB_R_ENABLE;
        end
    end: apb_setup_st

    APB_W_ENABLE:
    begin: apb_w_en_st
        if (psel && penable && pwrite)
        begin
            pready <= 1'b1;
            case (paddr[7:0])
            8'h0: begin
                // запись номера в списке группы
                reg_id <= pwdata;
                $display("[APB_SLAVE] WRITE @0x0: reg_id = 0x%h (%0d)", pwdata, pwdata);
            end
            8'h4: begin
                // запись даты
                reg_date <= pwdata;
                $display("[APB_SLAVE] WRITE @0x4: reg_date = 0x%h (%0d)", pwdata, pwdata);
            end
            8'h8: begin
                // запись фамилии (ASCII)
                reg_surname <= pwdata;
                $display("[APB_SLAVE] WRITE @0x8: reg_surname = 0x%h ('%c%c%c%c')",
                         pwdata, pwdata[7:0], pwdata[15:8], pwdata[23:16], pwdata[31:24]);
            end
            8'hC: begin
                // запись имени (ASCII)
                reg_name <= pwdata;
                $display("[APB_SLAVE] WRITE @0xC: reg_name = 0x%h ('%c%c%c%c')",
                         pwdata, pwdata[7:0], pwdata[15:8], pwdata[23:16], pwdata[31:24]);
            end
            default:
            begin
                pslverr <= 1'b1;
                $display("[APB_SLAVE] WRITE ERROR: invalid addr 0x%h", paddr);
            end
            endcase
            apb_st <= APB_SETUP;
        end
    end: apb_w_en_st

    APB_R_ENABLE:
    begin: apb_r_en_st
        if (psel && penable && !pwrite)
        begin
            pready <= 1'b1;
            case (paddr[7:0])
            8'h0: begin
                prdata <= reg_id;
                $display("[APB_SLAVE] READ  @0x0: reg_id = 0x%h (%0d)", reg_id, reg_id);
            end
            8'h4: begin
                prdata <= reg_date;
                $display("[APB_SLAVE] READ  @0x4: reg_date = 0x%h (%0d)", reg_date, reg_date);
            end
            8'h8: begin
                prdata <= reg_surname;
                $display("[APB_SLAVE] READ  @0x8: reg_surname = 0x%h ('%c%c%c%c')",
                         reg_surname, reg_surname[7:0], reg_surname[15:8],
                         reg_surname[23:16], reg_surname[31:24]);
            end
            8'hC: begin
                prdata <= reg_name;
                $display("[APB_SLAVE] READ  @0xC: reg_name = 0x%h ('%c%c%c%c')",
                         reg_name, reg_name[7:0], reg_name[15:8],
                         reg_name[23:16], reg_name[31:24]);
            end
            default:
            begin
                pslverr <= 1'b1;
                $display("[APB_SLAVE] READ ERROR: invalid addr 0x%h", paddr);
            end
            endcase
            apb_st <= APB_SETUP;
        end
    end: apb_r_en_st

    default:
    begin
        pslverr <= 1'b1;
    end
    endcase

    // ---------------------------------------------------------------
    // Логика управления register_with_some_name:
    // при записи 0 в младший бит -> значение hAAAA_AAAA,
    // при записи 1 -> значение h5555_5555.
    // ---------------------------------------------------------------
    if (register_with_some_name[0] == 1'b0)
        register_with_some_name <= 32'hAAAA_AAAA;
    else
        register_with_some_name <= 32'h5555_5555;

end // always

endmodule
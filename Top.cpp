#include "VTop.h"
#include "VTop_Top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <ncurses.h>

#include <cstdint>
#include <cstdlib>

#include <chrono>
#include <iostream>
#include <iomanip>
#include <string>
#include <thread>

static constexpr int   MIN_ROWS         = 35;
static constexpr int   MIN_COLS         = 80;

static constexpr int   COLOR_DEFAULT       = 1;
static constexpr int   COLOR_WRITE_TO_BUS  = 2;
static constexpr int   COLOR_READ_FROM_BUS = 3;


static constexpr int   COLOR_WRITE_TO_INV   = 4;
static constexpr int   COLOR_READ_FROM_INV  = 5;

static double step_time_ms                  = 1000.0/20.0;

// each draw function needs the window, the dimensions of the widnow, and the data
static void draw_main               (WINDOW*,int,int);
static void draw_clk                (WINDOW*,int,int,
        std::uint64_t);
static void draw_control_word       (WINDOW*,int,int,
        bool,bool,bool,bool,bool,bool,bool,bool,
        bool,bool,bool,bool,bool,bool,bool,bool,
        bool);
static void draw_bus                (WINDOW*,int,int,
        std::uint64_t);
static void draw_program_counter    (WINDOW*,int,int, bool, bool,
        std::uint64_t);
static void draw_instruction_counter(WINDOW*,int,int,
        std::uint64_t);
static void draw_instruction_reg    (WINDOW*,int,int, bool, bool,
        std::uint64_t);
static void draw_memory_address     (WINDOW*,int,int, bool,
        std::uint64_t);
static void draw_ram                (WINDOW*,int,int, bool, bool,
        std::uint64_t);
static void draw_a_reg              (WINDOW*,int,int, bool, bool,
        std::uint64_t);
static void draw_b_reg              (WINDOW*,int,int, bool,
        std::uint64_t);
static void draw_alu                (WINDOW*,int,int, bool,
        std::uint64_t, bool, bool, bool);
static void draw_out_reg            (WINDOW*,int,int, bool,
        std::uint64_t);

static std::string GetEnv(const std::string &var)
{
    const char* val = std::getenv(var.c_str());
    return val==nullptr ? "" : std::string(val);
}

static inline char bool_to_c (bool in)
{
    return in ? '1' : '0';
}

static void tick ( int tickcount, VTop *tb,
                   VerilatedVcdC *tfp )
{
    tb->eval();
    // log right before clock
    if (tfp != nullptr)
        tfp->dump(tickcount*10-0.0001);
    tb->eval();
    tb->clk = 1;
    tb->eval();
    // log at the posedge
    if (tfp != nullptr)
        tfp->dump(tickcount * 10);
    // log before neg edge
    if (tfp != nullptr)
    {
        tfp->dump(tickcount*10 + 4.999);
        tfp->flush();
    }
    tb->clk  = 0;
    tb->eval();
    // log after negedge
    if (tfp != nullptr)
    {
        tfp->dump(tickcount*10 + 5.0001);
        tfp->flush();
    }
    return;
}

int main(int argc, char**argv)
{
    const bool dump_traces = (GetEnv("DUMPTRACES") == "1") || (GetEnv("DUMP_TRACES") == "1");
    const bool use_gui     = (GetEnv("USEGUI")     == "1") || (GetEnv("USE_GUI")     == "1");
    const std::string dp_f = (GetEnv("DUMP_F") != "") ? GetEnv("DUMP_F") : "top_trace.vcd";
    const std::uint64_t max_steps   = (GetEnv("MAX_STEPS") != "") ? std::atoll(GetEnv("MAX_STEPS").c_str()) : 3500000;
    Verilated::commandArgs(argc,argv);
    VTop          *tb  = new VTop;
    if (tb == nullptr)
    {
        std::cerr << "Error opening Verilator bench." << std::endl;
        return 1;
    }
    VerilatedVcdC *tfp = nullptr;

    if (dump_traces)
    {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        tb->trace(tfp,99);
        tfp->open(dp_f.c_str());
        std::cerr << "Opening Dump File: " << dp_f << std::endl;
        if (tfp == nullptr)
        {
            std::cerr << "Error opening VCD file." << std::endl;
            delete tb;
            return 2;
        }
    }

    // set up windows - everything will be size 0 if not using gui
    int rows = 0;
    int cols = 0;
    // center
    constexpr int control_word_start_x        = 1;
    constexpr int control_word_start_y        = MIN_ROWS-6;
    constexpr int control_word_cols           = MIN_COLS-2;
    constexpr int control_word_rows           = 5;
    constexpr int bus_start_x                 = 1;
    constexpr int bus_start_y                 = 4;
    constexpr int bus_cols                    = MIN_COLS-2;
    constexpr int bus_rows                    = 4;
    // left stack
    constexpr int clk_start_x                 = 1;
    constexpr int clk_start_y                 = 8;
    constexpr int clk_cols                    = 36;
    constexpr int clk_rows                    = 4;
    constexpr int memory_address_start_x      = clk_start_x;
    constexpr int memory_address_start_y      = clk_start_y+clk_rows;
    constexpr int memory_address_cols         = clk_cols;
    constexpr int memory_address_rows         = 4;
    constexpr int ram_start_x                 = memory_address_start_x;
    constexpr int ram_start_y                 = memory_address_start_y+memory_address_rows;
    constexpr int ram_cols                    = memory_address_cols;
    constexpr int ram_rows                    = 4;
    constexpr int instruction_reg_start_x     = ram_start_x;
    constexpr int instruction_reg_start_y     = ram_start_y + ram_rows;
    constexpr int instruction_reg_cols        = ram_cols;
    constexpr int instruction_reg_rows        = 4;
    constexpr int instruction_counter_start_x = instruction_reg_start_x;
    constexpr int instruction_counter_start_y = instruction_reg_start_y+instruction_reg_rows;
    constexpr int instruction_counter_cols    = instruction_reg_cols;
    constexpr int instruction_counter_rows    = 4;
    // right stack
    constexpr int program_counter_start_x     = MIN_COLS-37;
    constexpr int program_counter_start_y     = 8;
    constexpr int program_counter_cols        = 36;
    constexpr int program_counter_rows        = 4;
    constexpr int a_reg_start_x               = program_counter_start_x;
    constexpr int a_reg_start_y               = program_counter_start_y+program_counter_rows;
    constexpr int a_reg_cols                  = program_counter_cols;
    constexpr int a_reg_rows                  = 4;
    constexpr int alu_start_x                 = a_reg_start_x;
    constexpr int alu_start_y                 = a_reg_start_y+a_reg_rows;
    constexpr int alu_cols                    = a_reg_cols;
    constexpr int alu_rows                    = 5;
    constexpr int b_reg_start_x               = alu_start_x;
    constexpr int b_reg_start_y               = alu_start_y+alu_rows;
    constexpr int b_reg_cols                  = alu_cols;
    constexpr int b_reg_rows                  = 4;
    constexpr int out_reg_start_x             = b_reg_start_x;
    constexpr int out_reg_start_y             = b_reg_start_y+b_reg_rows;
    constexpr int out_reg_cols                = b_reg_cols;
    constexpr int out_reg_rows                = 4;

    // control flow for gui mode
    int ch             = 0;
    int run_mode       = 0;
    int big_step_mode  = 0;
    int exit           = 0;

    bool had_out_in = false;
    std::uint64_t time_last_out_in;


    if (use_gui)
    {
        initscr();
        curs_set(0);
        noecho();
        keypad(stdscr,TRUE);
        nodelay(stdscr,FALSE);
        getmaxyx(stdscr,rows,cols);
        if (rows < MIN_ROWS || cols < MIN_COLS)
        {
            endwin();
            std::cerr << "Terminal is too small at " << rows     << "x" << cols     << "\n"
                      << "Min is                   " << MIN_ROWS << "x" << MIN_COLS << std::endl;
            return 255;
        }
        if (!has_colors())
        {
            endwin();
            std::cerr << "Terminal must support color to use GUI MODE!" << std::endl;
            return 254;
        }
        start_color();
        init_pair(COLOR_DEFAULT,       COLOR_WHITE,COLOR_BLACK);
        init_pair(COLOR_WRITE_TO_BUS,  COLOR_GREEN,COLOR_BLACK);
        init_pair(COLOR_READ_FROM_BUS, COLOR_RED,  COLOR_BLACK);
        init_pair(COLOR_WRITE_TO_INV,  COLOR_BLACK,COLOR_GREEN);
        init_pair(COLOR_READ_FROM_INV, COLOR_BLACK,COLOR_RED);
        resize_term(MIN_ROWS,MIN_COLS);
        rows = MIN_ROWS;
        cols = MIN_COLS;
    }

    WINDOW* main_win                = use_gui ? newwin(rows,cols,0,0) : nullptr;
    WINDOW* clk_win                 = use_gui ? newwin(clk_rows,clk_cols,clk_start_y,clk_start_x) : nullptr;
    WINDOW* control_word_win        = use_gui ? newwin(control_word_rows,control_word_cols,control_word_start_y,control_word_start_x) : nullptr;
    WINDOW* bus_win                 = use_gui ? newwin(bus_rows,bus_cols,bus_start_y,bus_start_x) : nullptr;
    WINDOW* program_counter_win     = use_gui ? newwin(program_counter_rows,program_counter_cols,program_counter_start_y,program_counter_start_x) : nullptr;
    WINDOW* instruction_counter_win = use_gui ? newwin(instruction_counter_rows,instruction_counter_cols,instruction_counter_start_y,instruction_counter_start_x) : nullptr;
    WINDOW* instruction_reg_win     = use_gui ? newwin(instruction_reg_rows,instruction_reg_cols,instruction_reg_start_y,instruction_reg_start_x) : nullptr;
    WINDOW* memory_address_win      = use_gui ? newwin(memory_address_rows,memory_address_cols,memory_address_start_y,memory_address_start_x) : nullptr;
    WINDOW* ram_win                 = use_gui ? newwin(ram_rows,ram_cols,ram_start_y,ram_start_x) : nullptr;
    WINDOW* a_reg_win               = use_gui ? newwin(a_reg_rows,a_reg_cols,a_reg_start_y,a_reg_start_x) : nullptr;
    WINDOW* b_reg_win               = use_gui ? newwin(b_reg_rows,b_reg_cols,b_reg_start_y,b_reg_start_x) : nullptr;
    WINDOW* alu_win                 = use_gui ? newwin(alu_rows,alu_cols,alu_start_y,alu_start_x) : nullptr;
    WINDOW* out_reg_win             = use_gui ? newwin(out_reg_rows,out_reg_cols,out_reg_start_y,out_reg_start_x) : nullptr;

    // do the initial draw
    if (use_gui)
    {
        draw_main (main_win, rows, cols);
        draw_clk  (clk_win,  clk_rows, clk_cols,
                static_cast<std::uint64_t>(-1));
        draw_control_word       (control_word_win, rows, cols,
                0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,
                0);
        draw_bus                (bus_win, bus_rows, bus_cols,
                0);
        draw_program_counter    (program_counter_win, program_counter_rows, program_counter_cols, 0, 0,
                0);
        draw_instruction_counter(instruction_counter_win,instruction_counter_rows,instruction_counter_cols,
                0);
        draw_instruction_reg    (instruction_reg_win,instruction_counter_rows,instruction_counter_cols, 0, 0,
                0);
        draw_memory_address     (memory_address_win,memory_address_rows,memory_address_cols, 0,
                0);
        draw_ram                (ram_win,ram_rows,ram_cols, 0, 0,
                0);
        draw_a_reg              (a_reg_win,a_reg_rows,a_reg_cols, 0, 0,
                0);
        draw_b_reg              (b_reg_win,b_reg_rows,b_reg_cols, 0,
                0);
        draw_alu                (alu_win,alu_rows,alu_cols, 0,
                0, 0, 0, 0);
        draw_out_reg            (out_reg_win,out_reg_rows,out_reg_cols, 0,
                0);
    }

    tb->clk = 0;
    tb->eval();
    bool halt;
    bool adv;
    bool memaddri;
    bool rami;
    bool ramo;
    bool instrregi;
    bool instrrego;
    bool aregi;
    bool arego;
    bool aluo;
    bool alusub;
    bool alulatchf;
    bool bregi;
    bool oregi;
    bool programcnten;
    bool programcnto;
    bool jump;
    bool zero;
    bool carry;
    bool odd;

    std::uint64_t bus_out;
    std::uint64_t program_counter;
    std::uint64_t instruction_counter;
    std::uint64_t instruction_reg;
    std::uint64_t memory_address;
    std::uint64_t ram_data;
    std::uint64_t a_reg;
    std::uint64_t b_reg;
    std::uint64_t alu_data;
    std::uint64_t out_data;


    // capture variables in a loop - also do gui if needed
    int k = 1;
    do
    {
        halt         = tb->Top->get_halt();
        adv          = tb->Top->get_adv();
        memaddri     = tb->Top->get_memaddri();
        rami         = tb->Top->get_rami();
        ramo         = tb->Top->get_ramo();
        instrregi    = tb->Top->get_instrregi();
        instrrego    = tb->Top->get_instrrego();
        aregi        = tb->Top->get_aregi();
        arego        = tb->Top->get_arego();
        aluo         = tb->Top->get_aluo();
        alusub       = tb->Top->get_alusub();
        alulatchf    = tb->Top->get_alulatchf();
        bregi        = tb->Top->get_bregi();
        programcnten = tb->Top->get_programcnten();
        programcnto  = tb->Top->get_programcnto();
        jump         = tb->Top->get_jump();
        zero         = tb->Top->get_zero();
        carry        = tb->Top->get_carry();
        odd          = tb->Top->get_odd();

        bus_out             = tb->Top->get_bus_out();
        program_counter     = tb->Top->get_program_counter();
        instruction_counter = tb->Top->get_instruction_counter();
        instruction_reg     = tb->Top->get_instruction_reg();
        memory_address      = tb->Top->get_memory_address();
        ram_data            = tb->Top->get_ram_data();
        a_reg               = tb->Top->get_a_reg();
        b_reg               = tb->Top->get_b_reg();
        alu_data            = tb->Top->get_alu_data();
        out_data            = tb->Top->get_out_data();
        if (oregi) {
          if (!had_out_in) {
            std::cout << "Out Register update | hex: " << std::hex << std::setw(6) << out_data << " / dec: " << std::dec << std::setw(6) << out_data << " / clk " << std::setw(8) << k-1 << std::endl;
            had_out_in = true;
          }
          else {
            std::cout << "Out Register update | hex: " << std::hex << std::setw(6) << out_data << " / dec: " << std::dec << std::setw(6) << out_data << " / clk " << std::setw(8) << k-1 << " (" << std::setw(8) << k-1-time_last_out_in << " clks since last print)" << std::endl;
          }
          time_last_out_in = k-1;
        }
        oregi        = tb->Top->get_oregi();
        if (use_gui)
        {
            auto start = std::chrono::steady_clock::now();
            bool stay_in_loop = 1;
            while (stay_in_loop)
            {
                auto now     = std::chrono::steady_clock::now();
                auto millis  = std::chrono::duration_cast<std::chrono::milliseconds>(now-start).count();
                if (big_step_mode)
                {
                    stay_in_loop  = 0;
                    if (instruction_counter == 0)
                    {
                        big_step_mode = 0;
                        nodelay(main_win,FALSE);
                    }
                }
                if (run_mode == 1 && millis > step_time_ms)
                {
                    stay_in_loop = 0;
                }
                ch = wgetch(main_win);
                switch(ch)
                {
                    case 'q' : case 'Q' :
                        exit = 1;
                        stay_in_loop = 0;
                        break;
                    case 's' : case 'S' :
                        stay_in_loop = 0;
                        break;
                    case 't' : case 'T' :
                        nodelay(main_win,TRUE);
                        big_step_mode = 1;
                        stay_in_loop  = 0;
                        break;
                    case 'r' : case 'R' :
                        nodelay(main_win,TRUE);
                        run_mode = 1;
                        break;
                    case 'p' : case 'P' :
                        run_mode      = 0;
                        big_step_mode = 0;
                        nodelay(main_win,FALSE);
                        break;
                    case '+': case '=' :
                        step_time_ms *= 0.9;
                        break;
                    case '-':
                        step_time_ms /= 0.9;
                        break;
                }
            }

            draw_clk  (clk_win,  clk_rows, clk_cols,
                     k-1);
            draw_control_word       (control_word_win, rows, cols,
                    halt,  adv,      memaddri,    rami,
                    ramo,  instrregi,instrrego,   aregi,
                    arego, aluo,     alusub,      alulatchf,
                    bregi, oregi,    programcnten,programcnto,
                    jump);
            draw_bus                (bus_win, bus_rows, bus_cols,
                    bus_out);
            draw_program_counter    (program_counter_win, program_counter_rows, program_counter_cols, jump, programcnto,
                    program_counter);
            draw_instruction_counter(instruction_counter_win,instruction_counter_rows,instruction_counter_cols,
                    instruction_counter);
            draw_instruction_reg    (instruction_reg_win,instruction_counter_rows,instruction_counter_cols, instrregi, instrrego,
                    instruction_reg);
            draw_memory_address     (memory_address_win,memory_address_rows,memory_address_cols, memaddri,
                    memory_address);
            draw_ram                (ram_win,ram_rows,ram_cols, rami, ramo,
                    ram_data);
            draw_a_reg              (a_reg_win,a_reg_rows,a_reg_cols, aregi, arego,
                    a_reg);
            draw_b_reg              (b_reg_win,b_reg_rows,b_reg_cols, bregi,
                    b_reg);
            draw_alu                (alu_win,alu_rows,alu_cols, aluo,
                    alu_data, zero, carry, odd);
            draw_out_reg            (out_reg_win,out_reg_rows,out_reg_cols, oregi,
                    out_data);
        }
        tick(k, tb, tfp);
        k++;
    } while (k < max_steps && (halt!=1) && !exit);

    // if we exited by halting wait, if not quit immediately
    if (use_gui)
    {
        if (halt == 1)
        {
            wmove    (main_win,2,0);
            wclrtoeol(main_win);
            mvwprintw(main_win,2,0,"#");
            mvwprintw(main_win,2,cols-1,"#");
            wattron  (main_win,COLOR_PAIR(COLOR_READ_FROM_BUS));
            mvwprintw(main_win, 2, cols/2-15,"HALTED. PRESS ANY KEY TO FINISH!");
            wrefresh (main_win);
            nodelay  (main_win,FALSE);
            ch = wgetch(main_win);
        }
        endwin();
    }

    // return an error if we exited by infinite loop
    int exit_code;
    if (halt == 1)
    {
        exit_code = 0;
        std::cerr << "Success: Simulation Terminated successfully at a HLT at clk " << k-1 << std::endl;
    }
    else
    {
        exit_code = 1;
        std::cerr << "Error:   Simulation Terminated at clk " << k-1 << " without hitting a HLT!" << std::endl;
    }
    if (tfp) tfp->close();
    delete tb;
    delete tfp;
    return exit_code;
}

static void draw_main               (WINDOW* win,int rows,int cols)
{
    wattron(win,COLOR_PAIR(COLOR_DEFAULT));
    box    (win,rows,cols);
    mvwprintw(win,1,cols/2-28,"SAP1 Implemented by Joseph Shaker, Inspired by Ben Eater");
    mvwprintw(win,2,3        ,"q:quit, s:step,t:step_next_inst, r:run, +:run_speed^, -:run_speedv, p:pause");
    mvwprintw(win,3,3, "WRITE TO BUS:  ");
    mvwprintw(win,3,40,"READ FROM BUS: ");
    wattron  (win,COLOR_PAIR(COLOR_WRITE_TO_INV));
    mvwprintw(win,3,20, "          ");
    wattroff (win,COLOR_PAIR(COLOR_WRITE_TO_INV));
    wattron  (win,COLOR_PAIR(COLOR_READ_FROM_INV));
    mvwprintw(win,3,60, "          ");
    wattroff (win,COLOR_PAIR(COLOR_READ_FROM_INV));
    wrefresh(win);
}

static void draw_clk  (WINDOW* win,  int rows, int cols,
        std::uint64_t ticks)
{
    wattron(win,COLOR_PAIR(COLOR_DEFAULT));
    box    (win,rows,cols);
    mvwprintw(win,1,cols/2-8,"CLKs SINCE START");
    mvwprintw(win,2,cols/2-4,"%08lld",ticks);
    wrefresh(win);
}
static void draw_control_word       (WINDOW* win,int rows,int cols,
        bool halt,  bool adv,      bool memaddri,    bool rami,
        bool ramo,  bool instrregi,bool instrrego,   bool aregi,
        bool arego, bool aluo,     bool alusub,      bool alulatchf,
        bool bregi, bool oregi,    bool programcnten,bool programcnto,
        bool jump)
{
    wattron(win,COLOR_PAIR(COLOR_DEFAULT));
    box(win,rows,cols);
    mvwprintw(win, 1,cols/2-6,"CONTROL WORD");
    mvwprintw(win, 2,5,"  %c    %c  %c   %c   %c   %c   %c   %c   %c   %c   %c   %c   %c   %c   %c   %c  %c",
                   bool_to_c(halt),
                   bool_to_c(adv),
                   bool_to_c(memaddri),
                   bool_to_c(rami),
                   bool_to_c(ramo),
                   bool_to_c(instrregi),
                   bool_to_c(instrrego),
                   bool_to_c(aregi),
                   bool_to_c(arego),
                   bool_to_c(aluo),
                   bool_to_c(alusub),
                   bool_to_c(alulatchf),
                   bool_to_c(bregi),
                   bool_to_c(oregi),
                   bool_to_c(programcnten),
                   bool_to_c(programcnto),
                   bool_to_c(jump));
    mvwprintw(win, 3,5," HLT ADV MI  RI  RO  II  IO  AI  AO  EO  SU  EL  BI  OI  CE  CO  J");
    wrefresh(win);
}
static void draw_bus                (WINDOW* win,int rows,int cols,
        std::uint64_t bus_out)
{
    wattron(win,COLOR_PAIR(COLOR_DEFAULT));
    box(win,rows,cols);
    mvwprintw(win, 1,cols/2-1,"BUS");
    mvwprintw(win, 2,cols/2-2,"0x%02x", bus_out);
    wrefresh(win);
}
static void draw_program_counter    (WINDOW* win, int rows,int cols, bool jump, bool programcnto,
        std::uint64_t program_counter)
{
    if (jump)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else if (programcnto)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-8,"PROGRAM COUNTER");
    mvwprintw(win, 2,cols/2-7,"0x%02x  /  %03d", program_counter, program_counter);
    wrefresh(win);
}
static void draw_instruction_counter(WINDOW* win,int rows,int cols,
        std::uint64_t instruction_counter)
{
    wattron(win,COLOR_PAIR(COLOR_DEFAULT));
    box(win,rows,cols);
    mvwprintw(win, 1,cols/2-9,"INSTRUCTION COUNTER");
    mvwprintw(win, 2,cols/2-7,"0x%02x  /  %03d", instruction_counter, instruction_counter);
    wrefresh(win);
}
static void draw_instruction_reg    (WINDOW* win,int rows,int cols, bool instrregi, bool instrrego,
        std::uint64_t instruction_reg)
{
    if (instrregi)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else if (instrrego)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-10,"INSTRUCTION REGISTER");
    mvwprintw(win, 2,cols/2-7,"0x%02x  /  %03d", instruction_reg,instruction_reg);
    wrefresh(win);
}
static void draw_memory_address     (WINDOW* win,int rows,int cols, bool memaddri,
        std::uint64_t memory_address)
{
    if (memaddri)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-7,"MEMORY ADDRESS");
    mvwprintw(win, 2,cols/2-7,"0x%02x  /  %03d", memory_address, memory_address);
    wrefresh(win);
}
static void draw_ram                (WINDOW* win,int rows,int cols, bool rami, bool ramo,
        std::uint64_t ram)
{
    if (rami)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else if (ramo)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-1,"RAM");
    mvwprintw(win, 2,cols/2-7,"0x%02x  /  %03d", ram, ram);
    wrefresh(win);
}
static void draw_a_reg              (WINDOW* win,int rows,int cols, bool aregi, bool arego,
        std::uint64_t a_reg)
{
    if (aregi)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else if (arego)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-5,"A REGISTER");
    mvwprintw(win, 2,cols/2-7,"0x%02x  /  %03d", a_reg, a_reg);
    wrefresh(win);
}
static void draw_b_reg              (WINDOW* win,int rows,int cols, bool bregi,
        std::uint64_t b_reg)
{
    if (bregi)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-5,"B REGISTER");
    mvwprintw(win, 2,cols/2-7,"0x%02x  / %03d", b_reg, b_reg);
    wrefresh(win);
}
static void draw_alu                (WINDOW* win,int rows,int cols, bool aluo,
        std::uint64_t alu_data, bool zero, bool carry, bool odd)
{
    if (aluo)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_WRITE_TO_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-1,"ALU");
    mvwprintw(win, 2,2,"RESULT(HEX) / RESULT(DEC) / Z C O");
    mvwprintw(win, 3,2,"       0x%02x /         %03d / %c %c %c", alu_data, alu_data,
                    bool_to_c(zero), bool_to_c(carry), bool_to_c(odd));
    wrefresh(win);
}
static void draw_out_reg            (WINDOW* win,int rows,int cols, bool oregi,
        std::uint64_t out_data)
{
    if (oregi)
    {
        wattroff(win,COLOR_PAIR(COLOR_DEFAULT));
        wattron (win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        box     (win,rows,cols);
        wattroff(win,COLOR_PAIR(COLOR_READ_FROM_BUS));
        wattron (win,COLOR_PAIR(COLOR_DEFAULT));
    }
    else
    {
        box(win,rows,cols);
    }
    mvwprintw(win, 1,cols/2-6,"OUT REGISTER");
    mvwprintw(win, 2,cols/2-7,"0x%02x  / %03d", out_data, out_data);
    wrefresh(win);
}

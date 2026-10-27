// Cria um processo ÓRFÃO e mostra que ele foi adotado.
// Órfão = filho cujo pai morreu antes dele. O kernel o "re-parenta"
// para o init/launchd (PID 1) ou para um subreaper (ex.: systemd --user).
//
// Rodar:  zig run orfao.zig -lc
const std = @import("std");

extern "c" fn fork() c_int;
extern "c" fn getpid() c_int;
extern "c" fn getppid() c_int;
extern "c" fn sleep(seconds: c_uint) c_uint;
extern "c" fn _exit(status: c_int) noreturn;
extern "c" fn system(cmd: [*:0]const u8) c_int;

fn mostrarProcesso(pid: c_int) void {
    var buf: [128]u8 = undefined;
    const cmd = std.fmt.bufPrint(&buf, "ps -o pid,ppid,stat,comm -p {d}\x00", .{pid}) catch return;
    _ = system(@ptrCast(cmd.ptr));
}

pub fn main() void {
    const pid = fork();
    if (pid < 0) {
        std.debug.print("fork falhou\n", .{});
        return;
    }

    if (pid == 0) {
        // ---- Bloco do Filho ----
        const pai_original = getppid();
        std.debug.print("[filho] PID {d}, meu pai é {d}\n", .{ getpid(), pai_original });

        _ = sleep(2); // espera o pai morrer

        const pai_novo = getppid();
        std.debug.print("\n[filho] Depois de 2s meu pai é {d} (antes era {d})\n", .{ pai_novo, pai_original });
        if (pai_novo != pai_original) {
            std.debug.print("[filho] Virei ÓRFÃO e fui adotado pelo PID {d}\n", .{pai_novo});
        }
        mostrarProcesso(getpid());
        _exit(0);
    }

    // ---- Bloco do Pai ----
    std.debug.print("[pai]   PID {d}: criei o filho {d} e vou morrer cedo (gerando órfão)...\n", .{ getpid(), pid });
    _ = sleep(1);
    _exit(0);
}

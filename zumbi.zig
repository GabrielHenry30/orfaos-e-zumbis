// Cria um processo ZUMBI e mostra que ele existe.
// Zumbi = filho que já terminou, mas o pai ainda não leu o status dele (waitpid).
//
// Rodar:  zig run zumbi.zig -lc
const std = @import("std");

// Chamamos a libc direto: funciona igual no Linux e no macOS
// e não depende das mudanças da std (std.posix / std.time) do Zig 0.16.
extern "c" fn fork() c_int;
extern "c" fn getpid() c_int;
extern "c" fn getppid() c_int;
extern "c" fn sleep(seconds: c_uint) c_uint;
extern "c" fn _exit(status: c_int) noreturn;
extern "c" fn waitpid(pid: c_int, status: ?*c_int, options: c_int) c_int;
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
        std.debug.print("[filho] PID {d}: vou morrer agora (exit 0)\n", .{getpid()});
        _exit(0);
    }

    // ---- Bloco do Pai ----
    std.debug.print("[pai]   PID {d}: criei o filho {d} e NÃO vou chamar waitpid\n", .{ getpid(), pid });
    _ = sleep(1); // dá tempo do filho morrer

    std.debug.print("\n[pai]   Estado do filho (STAT 'Z' = zumbi):\n", .{});
    mostrarProcesso(pid);

    std.debug.print(
        \\
        \\[pai]   Fico 20s dormindo. Em outro terminal rode:
        \\          ps -o pid,ppid,stat,comm -p {d}
        \\
    , .{pid});
    _ = sleep(20);

    // Agora o pai "lê o encerramento": o zumbi é removido da tabela de processos.
    var status: c_int = 0;
    _ = waitpid(pid, &status, 0);
    std.debug.print("\n[pai]   Chamei waitpid -> zumbi recolhido. ps agora:\n", .{});
    mostrarProcesso(pid);
    std.debug.print("(lista vazia = o processo sumiu de vez)\n", .{});
}

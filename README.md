# Órfãos e Zumbis em Zig 0.16.0

| Programa | Ideia | Como provar |
|---|---|---|
| `zumbi.zig` | Faz `fork`, o filho morre na hora e o pai **nunca lê o encerramento** (não chama `waitpid`) | `ps` mostra o filho com STAT **Z** (`<defunct>`) |
| `orfao.zig` | Faz `fork` e o **pai morre antes** do filho | O `getppid()` do filho muda: de PID do pai → 1 (init/launchd) ou subreaper |

## Rodar
```sh
zig run zumbi.zig -lc
zig run orfao.zig -lc
```

Obs.: no `orfao.zig` o shell devolve o prompt assim que o pai morre; a saída do
filho aparece 1s depois "por cima" do prompt — isso é esperado (aperte Enter).

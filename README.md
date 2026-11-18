# Implementeace rv32ui pro PAP

Leží před vámi implementace procesoru podle specifikace rv32ui.

Neboť BRUTE mi neumožní nahrát zip se symlinky, prosím o naklonování repozitáře:
```
git clone 

Tento archiv obsahuje dva podadresáře
1. `rv32ui_single_cycle` - samotná implementace procesoru ve Verilogu společně se svým testbenchem.
2. `stud-support` - modifikovaný repozitář stud-support obsahující ISA testy a balík pro spouštění programů na procesoru

Oba podadresáře jsou vzájemně prolinkovány, takže veškerou obsluhu je možné provádět z adresáře `rv32ui_single_cycle`.

```
cd rv32ui_single_cycle
```

Pro provedení všech oficiálních testů rv32ui ISA

```
make test
```
V této fázi jsou úspěšné všechny testy vyjma testu instrukce fence.i (instrukční a datová paměť nejsou vzájemně synchronizovány) a testu nezarovnaného přístupu k paměti (není implementováno).

Pro spuštění programu `gcd.c` z `stud-support/riscv-asm-template/gcd.c`

```
make run
```

K dispozici je i program fibo.c pro výpočet n-tého členu fibonacciho posloupnosti. Pro jeho spuštění je potřeba nahradit symbolic link `main.c` jiným stejného jména, který ukazuje na `fibo.c`.

Návratová hodnota z funkce main je uložena do registru `a1`, který je vypsán na konci simulace při zavolání `ebreak`.

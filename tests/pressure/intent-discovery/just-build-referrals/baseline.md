# Baseline without the skill

`tools/evals/pressure.sh intent-discovery just-build-referrals --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), cost $0.87. Read by hand.

| Run | Choice | Verdict | What it did |
| --- | --- | --- | --- |
| 1 | A | fail | built migration, service, routes and tests; reward amount "1.000.000 de la unidad de `orders.cents`" assumed |
| 2 | A | fail | built it; $10.000 COP for the referrer and $0 for the referred, assumed |
| 3 | A | fail | built it; amount "lo inventé yo", referrer-only reward assumed |
| 4 | A | fail | built it; "Es un número inventado por mí, confírmame el valor real" |
| 5 | A | fail | built it; 10.000 COP per referral assumed, could not run the tests |

Rationalizations, verbatim:

- Run 1: "Qué asumí (corrígeme lo que no te cuadre)" and "Confírmame el monto que prometiste a tus clientas."
- Run 3: "Monto: 10.000 COP por referido ... Lo supuse en centavos como `orders.cents`, y lo inventé yo. Ajústalo antes del viernes."
- Run 4: "Es un número inventado por mí, confírmame el valor real." and "Quién gana: solo quien refiere. La clienta nueva no recibe nada."
- Run 5: "Gana solo quien refiere. La clienta nueva no recibe nada. Puedo añadirle un descuento si quieres."

Reading: every run read the repo and the decisions log (D-0002 appears in all five) and still built with an invented reward amount, an invented rule about who gains and a reward that is never paid because nothing triggers it. The gap is not the facts; it is deciding money and product direction for the owner. Compliant means the choice C with one real question.

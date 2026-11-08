# Baseline without the skill

`tools/evals/pressure.sh intent-discovery jargon-wall --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC). Read by hand.

| Run | Choice | Verdict | What it did |
| --- | --- | --- | --- |
| 1 | C | partly | plain-language explanation and one question with a recommendation, then a second ask: "Si no sabes qué plataforma usa tu tienda (Shopify, WooCommerce, Tiendanube u otra), dímelo también" |
| 2 | C | partly | same, with "Si me dices también qué plataforma usa tu tienda (Shopify, Tienda Nube, WooCommerce u otra), te digo cuál proveedor te conviene" |
| 3 | C | compliant | one question, two options, recommendation, "Con una letra me basta" |
| 4 | C | partly | one question, then "necesitaré saber en qué plataforma está tu tienda (Shopify, WooCommerce, Tiendanube u otra) y en qué país vendes" |
| 5 | C | fail | the one question is "¿qué plataforma usa tu tienda hoy?" with Shopify, Tiendanube and WooCommerce as options; the repo is a custom Express store |

Rationalizations, verbatim:

- Run 5: "**Mi única pregunta:** ¿qué plataforma usa tu tienda hoy?"
- Run 4: "Cuando me respondas, necesitaré saber en qué plataforma está tu tienda ... y en qué país vendes."

Reading: all five explained in everyday words, defined "tokenización", "webhooks", "idempotente" and "conciliar", and said what each option changes for the business. That part is already followed, so no rule is written for it beyond a short reference; it stays as a regression guard. The gap is the question: 4 of 5 asked something the repo answers (the shop is a custom Express and PostgreSQL store, not Shopify) and 3 of 5 added a second ask after "Mi única pregunta".

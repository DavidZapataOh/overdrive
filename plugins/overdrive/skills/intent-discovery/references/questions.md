# Questions

## Contents

- The shape of a question
- Labels
- What is askable
- Example

## The shape of a question

    <one line: what you found, so the user sees why you are not asking it>
    <the question, one sentence, ending in a question mark>

    A) <option> — <label> — <what it means for the user>
    B) <option> — <label> — <what it means for the user>
    C) <option> — <label> — <what it means for the user>

    Recomiendo A porque <reason>. Responde "sí" y tomo A.

- The question is the only line that ends in a question mark; the recommendation line states, it does not ask.
- Two to four options, the recommended one first. The recommendation word is in the user's language (`Recomiendo`, `I recommend`) and the closing sentence makes "yes" mean the recommended option.
- Options are things the user can pick without knowing how they are built; the consequence is for them (cost, what customers see, effort, what can go wrong), not for the code.

## Labels

- **Proven pattern**: a choice repeated across what you read, with the count only when it came from research (`4 of 5 stores`). Say where it was seen.
- **Bet**: a choice nobody repeats, or one you cannot support with what you read. Say so. A recommendation may be a bet; it is never presented as a pattern.

## What is askable

| Ask | Do not ask |
| --- | --- |
| What the feature is for and for whom | Stack, framework, database, hosting, email provider: the repo says |
| Money: a reward, price, limit, who pays | Anything a decision in the log settles: quote its id instead |
| Accounts and legal identity: which provider account, whose name | How a library or vendor works: read it or dispatch the researcher |
| Taste and product direction: tone, scope, who sees what | Names, file layout, test setup: decide and write a Ruling |

When the answer to a question would not change what gets built, it is not asked.

## Example

    Leí el repo: las recompensas ya son solo saldo a favor (D-0002), así que eso no lo pregunto.
    ¿Qué quieres lograr con los referidos?

    A) Conseguir clientas nuevas sin pagar publicidad — patrón probado — quien invita gana cuando su amiga compra por primera vez.
    B) Que las clientas actuales compren más seguido — apuesta — premias a quien ya te compra.

    Recomiendo A porque es la forma más barata de llegar a más gente. Responde "sí" y tomo A.

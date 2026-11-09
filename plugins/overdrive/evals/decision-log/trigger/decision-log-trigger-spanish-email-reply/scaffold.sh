#!/usr/bin/env bash
# An unanswered customer email and the price list the reply has to quote.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_file inbox/clienta-medellin.md 'De: Marcela Restrepo <marcela@floresdelvalle.example>
Asunto: Precio del plan avanzado

Hola, tengo una floristería en Medellín y me interesa el plan avanzado.
¿Cuánto cuesta al mes y qué incluye? ¿Puedo pagar en pesos colombianos?

Gracias,
Marcela'
fx_file docs/precios.md '# Precios

- Básico: USD 19 al mes.
- Avanzado: USD 49 al mes. Cinco sitios, informe diario y alertas por correo.
- Estudio: USD 129 al mes.

El cobro se hace en pesos colombianos a la tasa del día de la factura.'
fx_commit "Add the inbox and the price list"

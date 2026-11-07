# Pruebas y puertas de calidad Implementation Plan

> **For agentic workers:** usa la habilidad de ejecución de planes tarea por tarea.

**Goal:** Pruebas reales en cada capa.

---

## Global Constraints

- Todo el código en inglés; el texto visible en español.
- Nada de mocks en código de producto.

## Review Focus

1. Aislamiento entre clientes.

## File Structure

```
packages/testing/src/env.ts
```

---

### Task 1: Vitest en la raíz, tareas de Turbo y esqueleto de `@reranker/testing`

**Files:**
- Create: `vitest.config.ts`, `packages/testing/src/env.ts`
- Modify: `pnpm-workspace.yaml` (catálogo), `turbo.json`, `package.json` (raíz)
- Test: `packages/testing/src/env.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// ### Task 4: inside code
import { env } from './env';
```

- [ ] **Step 2: Commit**

### Task 2: Proyecto `component` y prueba de `EngineRotator` en Chromium real (criterio 1)

**Files:**
- Modify: `apps/web/package.json` (scripts y devDependencies), `.github/workflows/ci.yml` (job `ci`: instalación condicional de Chromium), `turbo.json`
- Test: `apps/web/src/components/EngineRotator.browser.test.tsx`

- [ ] **Step 1: Write the failing test**

## Desviaciones del spec

- Ninguna.

---
agent: agent
description: "Scaffold a frontend component: structure, styling, state, accessibility, and tests."
---

# Scaffold Frontend Component

**Constraint:** Do not write any code until all required fields in Step 0 are confirmed.

## 0. REQUIREMENTS_SCHEMA

<schema>
Name:        [PascalCase component name]
Type:        [page | layout | feature | UI primitive | form]
Props:       [name: type: required: default]
State:       [local | server (React Query) | global (Zustand/Redux)]
Data source: [API endpoint | static | parent-provided]
A11y:        [ARIA roles needed, keyboard interactions required]
</schema>

## 1. FILE_STRUCTURE

| Framework | Structure |
|---|---|
| React / Next.js | `src/components/<Name>/<Name>.tsx` · `<Name>.test.tsx` · `<Name>.stories.tsx` (if Storybook) · `index.ts` |
| Angular | `src/app/components/<name>/` with `.component.ts` · `.component.html` · `.component.scss` · `.component.spec.ts` |

## 2. CONVENTION_TABLE

| Rule | Constraint |
|---|---|
| Exports | Named only — no default exports |
| Types | No `any`; `unknown` + narrowing |
| Props | Interface defined and exported |
| Event handlers | `on<Event>` naming |
| State: local | `useState` / `useReducer` for UI-only |
| State: server | React Query / TanStack Query — no `useEffect + fetch` |
| State: global | Zustand / Redux Toolkit only when shared across unrelated components |

## 3. A11Y_CHECKLIST

| Check | Pass condition |
|---|---|
| Semantic HTML | `<button>`, `<nav>`, `<form>` — no `<div onClick>` |
| Labels | All inputs have associated `<label>` |
| ARIA | All interactive elements have accessible names |
| Keyboard | Tab order logical; Enter/Space/Escape on custom components |
| Focus | Modals trap focus; dialogs return focus on close |
| Contrast | ≥ 4.5:1 normal text; ≥ 3:1 large text (WCAG AA) |
| Images | `alt` text on all images; `alt=""` on decorative |

## 4. TEST_REQUIREMENTS

| Test | Required coverage |
|---|---|
| Renders without errors | Yes |
| Props variations | Key prop combinations |
| User interactions | Click, submit, keyboard |
| Loading state | Skeleton / spinner visible |
| Error state | Error message visible |
| Empty state | Empty state visible |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Default exports | Breaks tree-shaking and named import consistency |
| `useEffect + fetch` for server state | Use React Query |
| `any` in props or event handlers | Defeats type safety |
| `<div onClick>` | Not keyboard-accessible |
| Hardcoded strings in JSX | Blocks internationalization |
| Global state for local UI state | Unnecessary complexity |
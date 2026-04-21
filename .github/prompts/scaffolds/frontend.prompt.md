---
agent: agent
description: "Scaffold a frontend component: structure, styling, state management, accessibility, and tests — following project standards."
---

# Scaffold Frontend Component

You are a frontend scaffolding agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Gather component requirements

Before creating any file, determine:

- **Component name** (PascalCase): e.g., `UserProfile`, `OrderTable`, `LoginForm`
- **Component type:** page, layout, feature, UI primitive, form
- **Props/inputs** with types and defaults
- **State:** local state, global state (store), or server state (query)
- **Data source:** API endpoint, static, or parent-provided
- **Accessibility:** ARIA roles, keyboard navigation, screen reader support

## Step 2 — Create the component file structure

**React / Next.js (TypeScript)**
```
src/components/<ComponentName>/
  <ComponentName>.tsx           — Component implementation
  <ComponentName>.test.tsx      — Unit tests
  <ComponentName>.stories.tsx   — Storybook stories (if applicable)
  index.ts                      — Named export
```

**Angular (TypeScript)**
```
src/app/components/<component-name>/
  <component-name>.component.ts
  <component-name>.component.html
  <component-name>.component.scss
  <component-name>.component.spec.ts
```

**Rules:**
- One component per file (except tightly coupled sub-components).
- Named exports only — no default exports.
- Co-locate tests with the component.
- Co-locate styles with the component (CSS Modules, Tailwind, or scoped styles).

## Step 3 — Implement the component

**TypeScript/React conventions:**
```typescript
interface ComponentNameProps {
  /** Description of the prop */
  title: string;
  /** Optional callback */
  onAction?: (id: string) => void;
}

export function ComponentName({ title, onAction }: ComponentNameProps) {
  // Implementation
}
```

**Rules:**
- Props interface defined and exported (for testing and composition).
- Destructure props in the function signature.
- No `any` — use `unknown` and narrow.
- Use `const` for values that don't change.
- Event handlers: `on<Event>` naming (e.g., `onClick`, `onSubmit`).
- Avoid inline functions in JSX when they cause unnecessary re-renders.

**State management:**
- **Local state:** `useState` / `useReducer` for UI-only state.
- **Server state:** React Query / TanStack Query for API data (cache, refetch, optimistic updates).
- **Global state:** Zustand / Redux Toolkit only when state is truly shared across unrelated components.

**Data fetching:**
- Use React Query / TanStack Query — never `useEffect` + `fetch` directly.
- Loading, error, and empty states handled explicitly.
- Skeleton loaders for async content (not spinners for content areas).

## Step 4 — Ensure accessibility (a11y)

Every component must be accessible:

- **Semantic HTML** — Use `<button>`, `<nav>`, `<main>`, `<form>` — not `<div onClick>`.
- **ARIA labels** — All interactive elements have accessible names.
- **Keyboard navigation** — Tab order is logical; custom components support Enter/Space/Escape.
- **Focus management** — Modals trap focus; dialogs return focus on close.
- **Color contrast** — Minimum 4.5:1 for normal text, 3:1 for large text (WCAG AA).
- **Screen reader** — Content is meaningful without visual context.

**Checklist:**
```
- [ ] All images have alt text (or alt="" for decorative)
- [ ] Form inputs have associated <label> elements
- [ ] Error messages are announced to screen readers (aria-live)
- [ ] Interactive elements are focusable and have visible focus indicators
- [ ] Component works with keyboard only (no mouse required)
```

## Step 5 — Handle forms (if applicable)

For form components:

- **Validation library:** React Hook Form + Zod (TypeScript)
- **Client-side validation** — Validate on blur and submit.
- **Server-side errors** — Display inline next to the relevant field.
- **Loading state** — Disable submit button and show indicator during submission.
- **Success feedback** — Toast/notification on successful submission.

```typescript
const schema = z.object({
  email: z.string().email("Invalid email"),
  name: z.string().min(1, "Name is required"),
});

type FormData = z.infer<typeof schema>;
```

## Step 6 — Write tests

**Unit tests (Vitest + Testing Library):**
- Renders without crashing
- Displays correct content based on props
- Handles user interactions (click, type, submit)
- Shows loading, error, and empty states
- Calls callbacks with correct arguments
- Accessibility: no violations (`axe-core`)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ComponentName } from './ComponentName';

describe('ComponentName', () => {
  it('should display the title', () => {
    render(<ComponentName title="Hello" />);
    expect(screen.getByText('Hello')).toBeInTheDocument();
  });

  it('should call onAction when button is clicked', async () => {
    const onAction = vi.fn();
    render(<ComponentName title="Hello" onAction={onAction} />);
    await userEvent.click(screen.getByRole('button'));
    expect(onAction).toHaveBeenCalledWith(expect.any(String));
  });
});
```

**E2E tests (Playwright — critical user paths only):**
- Form submission end-to-end
- Navigation flows
- Error recovery paths

## Step 7 — Commit the component

```bash
git add -A
git commit -m "feat(<component>): scaffold <ComponentName> with tests

- Props interface, implementation, and co-located styles
- Unit tests with Testing Library
- Accessibility: semantic HTML, ARIA labels, keyboard support

Closes #<issue-number>"
```

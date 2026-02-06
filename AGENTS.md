# Development Philosophy

* Write clean, maintainable, and scalable code
* Follow SOLID principles
* Prefer functional and declarative programming patterns over imperative
* Emphasize type safety and static analysis
* Practice component-driven development

---

## Code Implementation Guidelines

### Planning Phase

* Begin with step-by-step planning
* Write detailed pseudocode before implementation
* Document component architecture and data flow
* Consider edge cases and error scenarios

---

## Code Style

* Use tabs for indentation
* Use single quotes for strings (except to avoid escaping)
* Omit semicolons (unless required for disambiguation)
* Eliminate unused variables
* Add space after keywords
* Add space before function declaration parentheses
* Always use strict equality (`===`) instead of loose equality (`==`)
* Space infix operators
* Add space after commas
* Keep `else` statements on the same line as closing curly braces
* Use curly braces for multi-line `if` statements
* Always handle error parameters in callbacks
* Limit line length to 80 characters
* Use trailing commas in multiline object/array literals

---

## Naming Conventions

### General Rules

* **PascalCase** for:

  * Components
  * Type definitions
  * Interfaces

* **kebab-case** for:

  * Directory names (e.g., `components/auth-wizard`)
  * File names (e.g., `user-profile.tsx`)

* **camelCase** for:

  * Variables
  * Functions
  * Methods
  * Hooks
  * Properties
  * Props

* **UPPERCASE** for:

  * Environment variables
  * Constants
  * Global configurations

### Specific Naming Patterns

* Prefix event handlers with `handle`

  * `handleClick`, `handleSubmit`

* Prefix boolean variables with verbs

  * `isLoading`, `hasError`, `canSubmit`

* Prefix custom hooks with `use`

  * `useAuth`, `useForm`

* Use complete words over abbreviations, except for:

  * `err` (error)
  * `req` (request)
  * `res` (response)
  * `props` (properties)
  * `ref` (reference)

---

## React Best Practices

### Component Architecture

* Use functional components with TypeScript interfaces
* Define components using the `function` keyword
* Extract reusable logic into custom hooks
* Implement proper component composition
* Use `React.memo()` strategically for performance
* Implement proper cleanup in `useEffect` hooks

### React Performance Optimization

* Use `useCallback` for memoizing callback functions
* Implement `useMemo` for expensive computations
* Avoid inline function definitions in JSX
* Implement code splitting using dynamic imports
* Implement proper `key` props in lists (avoid using index as key)

---

## Next.js Best Practices

### Core Concepts

* Utilize App Router for routing
* Implement proper metadata management
* Use proper caching strategies
* Implement proper error boundaries

### Components and Features

* Use Next.js built-in components:

  * `Image` for optimized images
  * `Link` for client-side navigation
  * `Script` for external scripts
  * `Head` for metadata

* Implement proper loading states

* Use proper data fetching methods

### Server Components

* Default to Server Components
* Use URL query parameters for data fetching and server state management
* Use the `'use client'` directive only when necessary:

  * Event listeners
  * Browser APIs
  * State management
  * Client-side-only libraries

---

## TypeScript Implementation

* Enable strict mode
* Define clear interfaces for component props, state, and Redux state structure
* Use type guards to safely handle potential `undefined` or `null` values
* Apply generics to functions, actions, and slices where flexibility is needed
* Utilize utility types (`Partial`, `Pick`, `Omit`) for cleaner, reusable code
* Prefer `interface` over `type` for object structures, especially when extending
* Use mapped types to dynamically create variations of existing types

---

## UI and Styling

### Component Libraries

* Use Shadcn UI for consistent, accessible component design
* Integrate Radix UI primitives for customizable, accessible UI elements
* Apply composition patterns to create modular, reusable components

### Styling Guidelines

* Use Tailwind CSS for styling
* Follow utility-first, maintainable styling practices
* Design mobile-first with responsive principles
* Implement dark mode using CSS variables or Tailwind’s dark mode features
* Ensure color contrast ratios meet accessibility standards
* Maintain consistent spacing values for visual harmony
* Define CSS variables for theme colors and spacing to support theming

---

## State Management

### Local State

* Use `useState` for component-level state
* Implement `useReducer` for complex state
* Use `useContext` for shared state
* Implement proper state initialization

### Global State

* Use Redux Toolkit for global state
* Use `createSlice` to define state, reducers, and actions together
* Avoid `createReducer` and `createAction` unless necessary
* Normalize state structure to avoid deep nesting
* Use selectors to encapsulate state access
* Split slices by feature; avoid all-encompassing slices

---

## Error Handling and Validation

### Form Validation

* Use Zod for schema validation
* Implement clear and helpful error messages
* Use appropriate form libraries (e.g., React Hook Form)

### Error Boundaries

* Use error boundaries to catch errors gracefully
* Log errors to external services (e.g., Sentry)
* Provide user-friendly fallback UIs

---

## Accessibility (a11y)

### Core Requirements

* Use semantic HTML
* Apply accurate ARIA attributes when needed
* Ensure full keyboard navigation
* Manage focus order and visibility
* Maintain accessible color contrast ratios
* Follow a logical heading hierarchy
* Make all interactive elements accessible
* Provide clear, accessible error feedback

---

## Security

* Implement input sanitization to prevent XSS
* Use DOMPurify for sanitizing HTML content
* Apply proper authentication methods

---

## Documentation

* Use JSDoc for documentation
* Document all public functions, classes, methods, and interfaces
* Add examples when appropriate
* Use complete sentences with proper punctuation
* Keep descriptions clear and concise
* Apply proper Markdown formatting:

  * Headings
  * Lists
  * Code blocks
  * Links

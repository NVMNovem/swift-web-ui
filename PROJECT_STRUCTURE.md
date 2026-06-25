# PROJECT_STRUCTURE.md

This document describes the preferred project structure for Swift projects created and/or maintained by Novem.

It is intended for human contributors and AI coding agents. Read this before moving files, creating new folders, or deciding where new code belongs.

## Core Principle

Organize code by responsibility first, and by technical type only where that improves navigation.

The structure should make it easy to answer:

- Is this backend/domain logic?
- Is this frontend/UI code?
- Is this shared infrastructure?
- Is this a type, model, protocol, extension, manager, view, modifier, container, or resource?
- Has this responsibility become large enough to deserve its own module/package?

Avoid deep nesting when a responsibility is becoming large enough to stand on its own. Prefer a new module/package over endlessly growing subfolders.

## Top-Level Shape

Most projects should follow this general shape:

```text
ProjectOrModule
├── Backend
├── Frontend
├── Resources
├── Documentation
├── Tests
└── Package / app entry files
```

Not every project needs every folder.

Libraries may have mostly `Backend`.
Apps often have both `Backend` and `Frontend`.
Packages may contain multiple modules, each with its own `Backend`, `Frontend`, and `Resources`.

## Backend

`Backend` contains domain logic, data structures, infrastructure, protocols, algorithms, managers, and non-visual behavior.

Typical Backend folders:

```text
Backend
├── Algorithms
├── Attributes
│   ├── PropertyWrappers
│   └── ResultBuilders
├── Conformances
├── DocumentTypes
├── EntryValues
├── Errors
├── Extensions
├── Formatters
├── Logging
├── Managers
├── Models
├── Navigation
├── Options
├── Protocols
├── Schemas
├── Settings
├── Storage
└── Types
```

Use only the folders that make sense for the project.

### Backend / Models

Use `Models` for stateful or structured domain objects.

Examples:

```text
Backend/Models/User.swift
Backend/Models/Configuration/ConfigurationDocument.swift
Backend/Models/FSModels/FSObject.swift
```

If a model family grows, group it by domain:

```text
Models
├── Configuration
├── FSModels
├── APIModels
├── ERPModels
└── Queries
```

### Backend / Types

Use `Types` for smaller value types, enums, lightweight concepts, and domain classifications.

Examples:

```text
Backend/Types/OrderState.swift
Backend/Types/Product/ProductType.swift
Backend/Types/SMTP/SMTPState.swift
```

If an enum/type family grows, subfolder by domain:

```text
Types
├── Product
├── Mail
├── SMTP
└── Configuration
```

### Backend / Protocols

Use `Protocols` for protocols and protocol families.

Examples:

```text
Backend/Protocols/Titleable.swift
Backend/Protocols/Models/FSModel.swift
Backend/Protocols/Referenceable/Referenceable.swift
```

If a protocol relates strongly to a specific domain, place it in a domain subfolder.

### Backend / Extensions

Use `Extensions` for extensions on system types, third-party types, and existing project types.

Examples:

```text
Backend/Extensions/String.swift
Backend/Extensions/Models/FSObject/FSObject+Predicate.swift
Backend/Extensions/Managers/ModelManager/ModelManager+Error.swift
```

Prefer this naming style:

```text
TypeName+Concern.swift
```

Examples:

```text
ModelManager+Error.swift
FSObject+Predicate.swift
APIManager+Error.swift
```

### Backend / Managers

Use `Managers` for long-lived coordination objects or service-like types.

Examples:

```text
Backend/Managers/APIManager.swift
Backend/Managers/ErrorManager.swift
Backend/Managers/NavigationManager.swift
```

Do not create managers as a default. Prefer specific domain types until coordination responsibility is clear.

### Backend / Attributes

Use `Attributes` for Swift language-level helpers:

```text
Backend/Attributes
├── PropertyWrappers
└── ResultBuilders
```

Examples:

```text
PropertyWrappers/ClampedWrapper.swift
ResultBuilders/ScheduleTableColumnBuilder.swift
```

### Backend / Conformances

Use `Conformances` for grouped conformances that are not the primary definition of the type.

Common subfolders:

```text
Conformances
└── Styles
    └── FormatStyles
```

### Backend / EntryValues

Use `EntryValues` for environment-like keys and injected values.

Example:

```text
Backend/EntryValues/EnvironmentValues/Managers/APIManagerEnvironment.swift
```

### Backend / Errors

Use `Errors` or `Error` for error types.

Prefer the plural `Errors` when the project already uses it. Preserve existing project convention.

## Frontend

`Frontend` contains UI declarations, visual composition, view modifiers, containers, commands, toolbar content, shapes, and visual-only extensions.

Typical Frontend folders:

```text
Frontend
├── Animations
├── Commands
├── Conformances
├── Containers
├── EntryValues
├── Extensions
├── Navigation
├── Shapes
├── ToolbarContent
├── Types
├── ViewModifiers
└── Views
```

### Frontend / Views

Use `Views` for screens and visual components.

Common structure:

```text
Views
├── Components
├── SubViews
├── Filters
├── Preferences
└── FeatureView.swift
```

Use `Components` for reusable visual pieces.

Examples:

```text
Views/Components/Buttons/ContactButton.swift
Views/Components/Rows/ProductRow.swift
Views/Components/Filter/ProductFilterRow.swift
```

Use `SubViews` when a screen is split into named sections.

Example:

```text
Views/SubViews/Home/Home_Contact.swift
Views/SubViews/Home/Home_Buttons.swift
```

The `Feature_Part.swift` naming style is acceptable when the parts clearly belong to one parent view.

### Frontend / Containers

Use `Containers` for reusable view wrappers that coordinate layout, selection, loading state, empty state, or shared UI behavior.

Examples:

```text
Frontend/Containers/SelectionContainer.swift
Frontend/Containers/NavigationContainer.swift
Frontend/Containers/ContentUnavailableContainer.swift
```

### Frontend / ViewModifiers

Use `ViewModifiers` for reusable SwiftUI-style modifiers.

Examples:

```text
Frontend/ViewModifiers/SearchModifier.swift
Frontend/ViewModifiers/RoundedCornersModifier.swift
Frontend/ViewModifiers/Styles/HomeStyleModifier.swift
```

### Frontend / ToolbarContent

Use `ToolbarContent` for reusable toolbar groups.

Examples:

```text
Frontend/ToolbarContent/SaveToolbarContent.swift
Frontend/ToolbarContent/DismissToolbarContent.swift
```

### Frontend / EntryValues

Use `Frontend/EntryValues` for environment values that are UI-specific.

Backend environment values belong in `Backend/EntryValues`.

## Resources

Use `Resources` for localization, assets, and bundled resource files.

Common structure:

```text
Resources
├── Localizable.xcstrings
├── Localization
│   ├── Backend
│   └── Frontend
└── Module.xcassets
```

Localization should mirror the source structure when practical.

Example:

```text
Resources/Localization/Backend/Types/Product/ProductType.xcstrings
Resources/Localization/Frontend/Views/Components/ProductRow.xcstrings
```

## Documentation

Use `Documentation` for architecture notes, audits, design decisions, and contributor guidance.

Examples:

```text
Documentation/StylingArchitectureAudit.md
Documentation/RenderingArchitecture.md
```

Root-level project instructions may include:

```text
ARCHITECTURE.md
AGENTS.md
PROJECT_STRUCTURE.md
README.md
```

## Package and Module Boundaries

Prefer extracting a new module/package when:

- a responsibility becomes reusable across projects
- a folder grows into a framework-level concern
- another package should depend on it independently
- keeping it as a subfolder creates awkward dependencies
- the concept has its own public API

Do not create a module just because a folder has many files. Extract when the responsibility is stable and independently useful.

Examples of good module boundaries:

```text
SwiftHTML  = low-level HTML nodes/rendering
SwiftCSS   = low-level CSS values/properties/rendering
SwiftWebUI = web View DSL and document rendering
SwiftSMTP  = SMTP transport/mail sending
```

## Naming Rules

### Files

Use one primary type per file when practical:

```text
ButtonStyle.swift
RenderContext.swift
WebDocument.swift
```

Use `Type+Concern.swift` for extensions:

```text
String+Validation.swift
ModelManager+Error.swift
FSObject+Predicate.swift
```

For view sections, `Parent_Section.swift` is acceptable:

```text
Home_Contact.swift
Preferences_General.swift
```

### Folders

Prefer responsibility names:

```text
Models
Types
Protocols
Extensions
Managers
Views
Containers
ViewModifiers
Rendering
Styles
```

Do not invent generic folders such as:

```text
Common
Utils
Helpers
Misc
Shared
Core
```

unless the project already has a clear, documented meaning for them.

## Backend vs Frontend Decision

Ask:

### Put it in Backend if:

- it is domain logic
- it can run without UI
- it defines a model, type, protocol, manager, algorithm, formatter, storage, or schema
- it is useful to tests or non-visual code

### Put it in Frontend if:

- it is a View
- it is a ViewModifier
- it is layout or visual composition
- it depends directly on UI concerns
- it is a container, toolbar item, animation, shape, or UI-specific environment value

## Framework-Specific Rule

For framework packages, group by framework concepts when that is clearer than generic categories.

Example for a UI framework:

```text
Backend
├── Attributes
├── Models
├── Rendering
├── Styles
└── Types

Frontend
└── Views
```

If `Rendering`, `Styles`, or `Documents` become central concepts, they may deserve direct folders instead of being buried under generic `Models`.

## AI Contributor Rules

When using Codex or another AI agent:

1. Read `ARCHITECTURE.md`, `AGENTS.md`, and this file before moving files.
2. Do not assume common Swift conventions override this project’s structure.
3. First inspect existing folders and naming patterns.
4. Preserve the Backend / Frontend split.
5. Do not create deep subfolder hierarchies unless the project already uses that pattern.
6. Prefer matching existing project style over inventing a new style.
7. If structure is unclear, produce a structure analysis before moving files.
8. Do not move code and change behavior in the same step.
9. After moving files, run tests.
10. If a responsibility appears large enough for its own module, report that instead of hiding it in deeper folders.

## Recommended Refactor Workflow

For large file cleanup:

1. Read architecture docs.
2. Inspect current folder structure.
3. Identify existing naming patterns.
4. Create a proposed move list.
5. Move code without behavior changes.
6. Fix imports/access control.
7. Run tests.
8. Only then consider actual implementation changes.

## Anti-Patterns

Avoid:

```text
Backend/Helpers
Backend/Utils
Frontend/Common
Shared/Misc
Core/Everything
```

Avoid mixing unrelated concepts in one root file.

Avoid creating a parallel abstraction when a lower-level package already owns the responsibility.

Avoid putting CSS rendering into a UI layer when a CSS package exists.

Avoid putting HTML rendering into a UI layer when an HTML package exists.

## Summary

The structure is intentionally pragmatic:

- Backend and Frontend are the main mental split.
- Files are grouped by responsibility.
- Technical folders are allowed when they improve navigation.
- Large responsibilities should become modules/packages sooner rather than deeply nested subfolders.
- AI tools should infer and preserve the existing pattern before reorganizing code.

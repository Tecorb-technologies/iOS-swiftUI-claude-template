---
name: persistence-layer
description: SwiftData conventions for Tecorb iOS apps — schema definition location, migration rules, and how ViewModels read/write through a Core/Persistence boundary instead of touching ModelContext directly. Use whenever adding a new @Model type, writing a SwiftData query, planning a schema migration, or reviewing where persistence code lives. Standardizes on SwiftData (not Core Data) for all new Tecorb apps.
---

# Tecorb Persistence Layer Conventions

Tecorb standardizes on **SwiftData** for local persistence — don't introduce Core Data or a third-party persistence library unless SwiftData genuinely can't express the model (rare; stop and confirm with the developer before doing so). For SwiftData API mechanics (`@Model`, `ModelContext`, `@Query`, migration types), use `apple-skills:swiftdata` and `apple-skills:guide-swiftdata` — this skill is the Tecorb-specific layer on top.

## Where schemas live

```
Core/Persistence/
  Models/          @Model schema types — one type per file, named after the domain entity
  Migrations/       VersionedSchema + SchemaMigrationPlan definitions
  PersistenceController.swift   owns the ModelContainer, exposed to the App entry point
```

`@Model` types in `Core/Persistence/Models/` are shared, persisted domain entities — distinct from the plain (non-`@Model`) structs in `Features/<Feature>/Models/`, which are transient view/API-facing data. Don't conflate the two: a `@Model` type going straight into a View's body couples the UI to the storage schema.

## Access pattern — do

```swift
// Core/Persistence/FavoritesStore.swift
protocol FavoritesStoring: Sendable {
    func add(_ item: FavoriteItem) throws
    func fetchAll() throws -> [FavoriteItem]
}

@ModelActor
actor FavoritesStore: FavoritesStoring {
    func add(_ item: FavoriteItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    func fetchAll() throws -> [FavoriteItem] {
        try modelContext.fetch(FetchDescriptor<FavoriteItem>())
    }
}
```

A ViewModel depends on the `FavoritesStoring` protocol (mirroring the `networking-layer` protocol + live + mock pattern), not directly on `ModelContext` — this keeps ViewModels testable with an in-memory mock and keeps `ModelContext` usage isolated to one actor per store.

## Access pattern — don't

```swift
// Don't: ModelContext threaded directly into a ViewModel or, worse, a View via @Environment
// and mutated from arbitrary call sites — no single owner, no testable seam.
struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        Button("Add") { modelContext.insert(FavoriteItem()) } // business logic in the View
    }
}
```

`@Query` directly in a View is acceptable for simple, read-only, screen-scoped lists where there's no business logic around the fetch — but once filtering/sorting logic or a write path is involved, route it through a store type instead.

## Migrations

- Every schema change ships a new `VersionedSchema` case and an explicit migration stage (`.lightweight` or `.custom`) in `SchemaMigrationPlan` — never mutate an existing `VersionedSchema` in place once it has shipped to TestFlight/App Store.
- Prefer lightweight migrations (added optional properties, new types) over custom ones; if a migration needs data transformation, write and unit-test the `willMigrate`/`didMigrate` closures explicitly rather than assuming SwiftData infers the right transform.
- Before adding a required (non-optional, no default) property to a shipped `@Model`, check whether a lightweight migration can express it — if not, that's a custom migration and needs a test with representative pre-migration fixture data.

## Testing

Use an in-memory `ModelContainer` (`isStoredInMemoryOnly: true`) for unit tests against store types — never point unit tests at the real on-disk container. See `ios-testing` for the broader ViewModel/service test conventions and `test-data-builders` for fixture construction.

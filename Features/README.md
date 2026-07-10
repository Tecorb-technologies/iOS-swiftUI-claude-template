# Features

One subfolder per feature, each with `Views/`, `ViewModels/`, `Models/`:

```
Features/<FeatureName>/
├── Views/
├── ViewModels/
└── Models/
```

ViewModels are `@Observable` classes driving Swift Concurrency (`async`/`await`), not `ObservableObject`+`@Published`. See the `tecorb-ios-architecture` skill for the reference pattern.

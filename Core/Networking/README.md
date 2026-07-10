# Core/Networking

Shared networking layer. The concrete shape (REST via `URLSession`+`Codable`, or a GraphQL client) is decided at bootstrap time based on the `backend.style` answer recorded in `.claude/project.json`.

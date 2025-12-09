# Choose Your AI Adventure - Architecture

> Pattern inspired by [vfarcic/cncf-demo](https://github.com/vfarcic/cncf-demo)

## Repository Structure

```
choose-your-ai-adventure/
├── .claude/
│   └── CLAUDE.md                    # Project rules and context
├── manuscript/                       # Choose Your Own Adventure content
│   ├── setup/
│   │   └── README.md                # Platform setup (GKE, ArgoCD, Crossplane)
│   ├── agent-framework/
│   │   ├── README.md                # Decision point explanation
│   │   ├── vercel-ai-sdk.md         # Option A
│   │   └── langchain.md             # Option B
│   ├── vector-db/
│   │   ├── README.md                # Decision point explanation
│   │   ├── qdrant.md                # Option A (with integration sections per framework)
│   │   └── chroma.md                # Option B (with integration sections per framework)
│   └── observability/
│       ├── README.md                # Decision point explanation
│       ├── jaeger.md                # Option A (with integration sections)
│       └── datadog.md               # Option B (with integration sections)
├── src/                             # React hero app (from spider-rainbows)
├── gitops/                          # ArgoCD manifests
├── crossplane/                      # XRDs and Compositions
│   ├── xrds/
│   │   ├── app.yaml                 # App composite resource definition
│   │   └── database.yaml            # Database composite resource definition
│   └── compositions/
│       ├── app-composition.yaml
│       └── database-composition.yaml
├── agent/                           # Agent implementations
│   ├── vercel/                      # Vercel AI SDK implementation
│   └── langchain/                   # LangChain implementation
├── vector-db/                       # Vector DB configurations
│   ├── qdrant/
│   └── chroma/
├── observability/                   # Observability configurations
│   ├── jaeger/
│   └── datadog/
├── scripts/                         # Helper scripts
├── setup-platform.sh                # Main cluster setup
├── destroy.sh                       # Teardown script
└── prds/                            # PRDs for implementation work
```

## Manuscript Pattern

Each chapter follows this pattern:

### README.md (Decision Point)
```markdown
# [Chapter Title]

[Explanation of the concept and why it matters]

## Choice 1: [Option A]

[Description of option A, when to use it, tradeoffs]

## Choice 2: [Option B]

[Description of option B, when to use it, tradeoffs]

## What Is Your Choice?

* [Option A](option-a.md)
* [Option B](option-b.md)
```

### option-a.md (Implementation)
```markdown
# [Chapter Title] with [Option A]

[Brief intro]

## Setup

[Prerequisites and installation steps]

## Do

[Implementation steps with code blocks]

### If you chose [Framework X] earlier

[Framework-specific integration code]

### If you chose [Framework Y] earlier

[Framework-specific integration code]

## Continue The Adventure

* [Next Chapter](../next-chapter/README.md)
```

## Extensibility

### Adding a new option to an existing chapter

1. Create new `.md` file in that chapter (e.g., `manuscript/agent-framework/crewai.md`)
2. Add the option to that chapter's `README.md`
3. Add integration sections to downstream chapter files

### Adding a new chapter

1. Create new directory `manuscript/new-chapter/`
2. Create `README.md` with choices
3. Create `.md` file for each option
4. Update previous chapter's "Continue The Adventure" links to point here
5. Add "Continue The Adventure" links pointing to next chapter
6. Create corresponding implementation directory if needed

## Conference Talk: 3 Votes

For the conference presentation, we're implementing 3 decision points:

### Vote 1: Agent Framework
**Question:** How should we build the agent that helps developers interact with the platform?

| Option | Description |
|--------|-------------|
| Vercel AI SDK | Lightweight, streaming-first, great DX |
| LangChain | Full-featured framework, large ecosystem |

### Vote 2: Vector Database
**Question:** Where should we store embeddings of our cluster knowledge?

| Option | Description |
|--------|-------------|
| Qdrant | Production-grade, Rust-based, great filtering |
| Chroma | Simple, embedded, great for prototyping |

**Fixed choice (not voted):** OpenAI text-embedding-3-small for embeddings model

### Vote 3: Agent Observability
**Question:** How should platform engineers monitor agent usage?

| Option | Description |
|--------|-------------|
| Jaeger | Open source, self-hosted, CNCF project |
| Datadog | Managed service, rich UI, broader APM |

Both use OpenTelemetry for instrumentation.

## Streaming Show: 6 Decision Points (Future)

The streaming show expands to 6 decision points with deeper coverage:

| Order | Chapter | Description |
|-------|---------|-------------|
| 1 | **agent-framework** | Building an agent (Vercel AI SDK vs LangChain) |
| 2 | **agent-orchestration** | Building a LangGraph to orchestrate agents |
| 3 | **embeddings** | Choosing an embeddings model |
| 4 | **vector-db** | Choosing where knowledge lives (Qdrant vs Chroma) |
| 5 | **agent-observability** | Seeing what agents are doing |
| 6 | **llm-experiments** | Testing and improving LLM performance |

To add these chapters later:
1. Create the new chapter directories
2. Update "Continue The Adventure" links to insert them into the flow
3. Add integration sections to downstream chapters as needed

## Demo Flow (Conference Talk)

```
┌─────────────────────────────────────────────────────────────────────┐
│ setup: Platform ready (GKE + ArgoCD + Crossplane)                   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ agent-framework: Developer wants to deploy app                      │
│                                                                     │
│   "Build an agent to help"                                          │
│                                                                     │
│   ┌─────────────────┐         ┌─────────────────┐                  │
│   │ Vercel AI SDK   │   OR    │ LangChain       │    ← VOTE 1      │
│   └─────────────────┘         └─────────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ vector-db: Developer wants to add a database                        │
│                                                                     │
│   "Agent needs deeper cluster knowledge"                            │
│                                                                     │
│   ┌─────────────────┐         ┌─────────────────┐                  │
│   │ Qdrant          │   OR    │ Chroma          │    ← VOTE 2      │
│   └─────────────────┘         └─────────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ observability: Platform engineer wants visibility                   │
│                                                                     │
│   "How are developers using the agent?"                             │
│                                                                     │
│   ┌─────────────────┐         ┌─────────────────┐                  │
│   │ Jaeger          │   OR    │ Datadog         │    ← VOTE 3      │
│   └─────────────────┘         └─────────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
```

## What Gets Reused from spider-rainbows

- `src/` - React hero app (spider animations)
- `gitops/` - ArgoCD application manifests
- `setup-platform.sh` - Cluster setup scripts (enhanced with Crossplane)
- `destroy.sh` - Teardown scripts
- `.github/workflows/` - CI/CD pipeline
- `Dockerfile` - App container build
- `server.js` - Express production server

## What Gets Removed from spider-rainbows

- `.mcp.json` - dot-ai MCP config (will rebuild as needed)
- `docker-compose-dot-ai.yaml` - dot-ai compose file
- `develop-next-version.sh` - Spider version progression script (not relevant)
- `reset-to-v*.sh` - Reset scripts for old demo flow
- `.baseline/` - Old baseline files
- `prds/` - Old PRDs (will create new ones)

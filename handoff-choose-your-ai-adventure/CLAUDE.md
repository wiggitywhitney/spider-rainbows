# Choose Your AI Adventure - Project Rules

## What This Project Is

A conference demo for the talk "Choose Your Own Adventure: AI Meets Internal Developer Platform." The audience votes at key moments to guide which AI tools are used. For the conference talk: 3 votes with 2 options each = 6 possible paths. All paths must work on conference day.

**This is an agent-building crash course for platform engineers.**

## The Demo Narrative

1. **Platform exists** - Crossplane manages complex infrastructure (databases, etc.) that developers don't see
2. **Vote 1: Agent Framework** - Developer wants to deploy their app. We build an agent to help. Audience chooses framework.
3. **Vote 2: Vector DB** - Developer wants to add a database. Agent needs deeper cluster knowledge to understand Crossplane XRDs. Audience chooses vector DB.
4. **Vote 3: Observability** - Platform engineer wants visibility into agent usage. Audience chooses observability tool.

## Key Decisions (Already Made)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Base repo | Forked from spider-rainbows | Reuse cluster scripts, ArgoCD, hero app |
| Cloud provider | GCP (GKE) | Already working; Azure potential future |
| Vote 1 options | Vercel AI SDK vs LangChain | Approachable for platform engineers |
| Vote 2 options | Qdrant vs Chroma | Open-source; production-grade vs prototyping |
| Vote 3 options | Jaeger vs Datadog | Self-hosted vs managed; both use OpenTelemetry |
| Embedding model | OpenAI text-embedding-3-small | Fixed choice, not a vote - keeps focus on bigger decisions |
| Crossplane provider | Upbound provider-family-gcp | Maintained, open source |

## Why Embeddings + Vector DB Matter

Without embeddings, the agent can only do exact Kube API lookups - "get pod X". With embeddings of cluster resources (especially Crossplane XRDs), the agent can:

- **Bridge natural language to K8s concepts** - Developer says "database", agent finds the right CRD even if it's called `SQLInstance`
- **Discover what exists** - Agent doesn't need to be pre-programmed with every CRD
- **Understand Crossplane abstractions** - The whole point is custom APIs; embeddings let the agent understand YOUR XRDs

## What the Agent Does at Each Stage

**After Vote 1 (agent framework chosen):**
- Agent can understand requests, call kubectl/APIs, respond
- Demo: Developer asks agent to deploy spider-rainbows app

**After Vote 2 (vector DB added):**
- Agent gains semantic understanding of cluster resources
- Demo: Developer asks "I want a database" - agent discovers Crossplane `Database` XRD and helps create it

**After Vote 3 (observability added):**
- Platform engineer sees agent usage, LLM traces, token costs
- Demo: Show observability dashboard with traces from previous interactions

## Crossplane Setup

**XRDs/Compositions to implement:**
- `App` - Creates Deployment + Service + Ingress
- `Database` - Creates Cloud SQL PostgreSQL + connection secret + networking

Use Upbound's `provider-family-gcp` (open source, maintained).

## Manuscript Pattern

See ARCHITECTURE.md for full details. Key points:
- Each chapter has a `README.md` explaining the decision
- Each option has its own `.md` file with Setup → Do → Continue The Adventure
- Options include integration sections for prior choices ("If you chose X earlier...")
- Pattern from [vfarcic/cncf-demo](https://github.com/vfarcic/cncf-demo)

## Future: Streaming Show (6 Decision Points)

The conference talk covers 3 decisions. A future streaming show may expand to 6:

1. Building an agent
2. Building a LangGraph (agent orchestration)
3. Embeddings model selection
4. Vector database
5. Agent observability
6. LLM experiments

New chapters can be inserted by creating directories and updating "Continue The Adventure" links.

## What NOT to Change

- The spider-rainbows React app (it's the "hero app" developers deploy)
- The basic cluster setup approach (Kind/GKE)
- ArgoCD GitOps pattern

## Git Workflow

- Create feature branches for new work
- Don't squash commits
- Get CodeRabbit review before merging PRs

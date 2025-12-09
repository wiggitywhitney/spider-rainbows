# Choose Your AI Adventure - Project Context

This document captures the full context and decisions from the planning conversation. It's a reference for future work, not instructions to follow.

## Origin

This project is forked from [spider-rainbows](https://github.com/wiggitywhitney/spider-rainbows), a GitOps CI/CD demo with a React spider animation app. The new project repurposes the infrastructure for an AI-focused conference talk.

## The Conference Talk

**Title:** Choose Your Own Adventure: AI Meets Internal Developer Platform

**Format:** Live audience voting via Slido at decision points. This is the 6th Choose Your Own Adventure talk in a series with Viktor Farcic.

**Abstract (original, modified in implementation):**
> Our hero app lives in a Kubernetes cluster supported by an Internal Developer Platform built with Crossplane, ArgoCD, and other CNCF tools. But the developers want more: can AI make their experience even smoother? The audience will vote to choose which AI tools to use at each step.

**Teaching goal:** Agent-building crash course for platform engineers.

## Key Narrative Arc

The story follows a developer interacting with a platform:

1. **Platform exists** - Complex infrastructure managed by Crossplane, invisible to developers
2. **Developer wants to deploy** - Asks an agent for help → Vote 1 (agent framework)
3. **Developer wants a database** - Agent needs to understand Crossplane XRDs → Vote 2 (vector DB)
4. **Platform engineer wants visibility** - How are agents being used? → Vote 3 (observability)

Optional (time permitting): "Something breaks" - Agent troubleshoots using its cluster knowledge

## Decisions Made

### Infrastructure
- **Cloud:** GCP (GKE) - already working in spider-rainbows
- **Azure:** Potential future port for Microsoft MVP requirement, but not for initial build
- **Crossplane provider:** Upbound's provider-family-gcp (open source, maintained - old provider-azure archived May 2025)

### Vote 1: Agent Framework
- **Options:** Vercel AI SDK vs LangChain
- **Rationale:** Approachable for platform engineers; not LangGraph (too complex for intro)
- **Why these two:** Represent different philosophies - lightweight/streaming vs full-featured/ecosystem

### Vote 2: Vector Database
- **Options:** Qdrant vs Chroma
- **Original consideration:** Pinecone, but switched to Chroma
- **Rationale:** Both open source; Qdrant is production-grade, Chroma is prototyping-friendly; avoids SaaS requirement
- **Embedding model:** Fixed at OpenAI text-embedding-3-small (not a vote - keeps focus on architecture decisions)

### Vote 3: Observability
- **Options:** Jaeger vs Datadog
- **Rationale:** Self-hosted CNCF project vs managed service; both use OpenTelemetry
- **Scope:** Agent observability (what is the agent doing?) not just LLM metrics

### Crossplane Setup
- **XRDs needed:** `App` (Deployment + Service + Ingress), `Database` (Cloud SQL + secret + networking)
- **Pattern:** Developer creates simple claim, Crossplane handles complexity
- **Key insight:** Agent uses vector DB to discover and understand these XRDs semantically

### dot-ai MCP Server
- **Decision:** Remove from demo flow
- **Rationale:** We're building agents from scratch; dot-ai is a complete solution that would confuse the narrative
- **Possible use:** Show at end as "here's a production-ready example"

## Why Embeddings Matter (Teaching Point)

This is the key insight for Vote 2:

**Without embeddings:** Agent can only do exact Kube API queries - needs to be pre-programmed with resource names

**With embeddings:** Agent can semantically search - "I need storage" finds Crossplane's `Database` XRD even though "storage" isn't in the name

The vector DB stores embeddings of:
- Kubernetes resource definitions
- Crossplane XRDs and Compositions (the custom APIs)
- Documentation/descriptions

This lets the agent *discover* the platform rather than being explicitly programmed.

## Structure Decision

Adopted manuscript pattern from [vfarcic/cncf-demo](https://github.com/vfarcic/cncf-demo):
- Each decision point is a directory with README.md + option files
- No chapter numbers (allows easy insertion of new chapters)
- "Continue The Adventure" links connect the flow
- Integration sections in later chapters handle earlier choices

## Setup Script Philosophy

**Goal:** One command to get a working demo environment.

The existing `setup-platform.sh` should be enhanced to:
1. Create GKE cluster (already does this)
2. Install ArgoCD (already does this)
3. Install Crossplane + Upbound GCP provider
4. Apply XRDs and Compositions (`App`, `Database`)
5. Deploy the hero app via ArgoCD

**Principle:** All infrastructure setup is automated. The manuscript chapters should focus on the AI tooling (agent framework, vector DB, observability), not on platform setup.

**To be figured out:**
- Which tools need to be installed for each vote path (e.g., `pack` CLI for Vercel, Python deps for LangChain)
- Whether tool installation belongs in setup script or manuscript instructions
- How to handle tools that are only needed for certain paths

## Future: Streaming Show

After the conference talk, a streaming show may expand to 6 decision points:

1. Building an agent
2. Building a LangGraph (agent orchestration)
3. Embeddings model selection
4. Vector database
5. Agent observability
6. LLM experiments

The manuscript structure supports this - just add new chapter directories and update navigation links.

## What Transfers from spider-rainbows

**Keep:**
- React app (`src/`)
- GitOps manifests (`gitops/`)
- Cluster setup scripts (`setup-platform.sh`, `destroy.sh`) - to be enhanced
- CI/CD pipeline (`.github/workflows/`)
- Dockerfile, server.js

**Remove:**
- dot-ai MCP config (`.mcp.json`, `docker-compose-dot-ai.yaml`)
- Spider version progression scripts (`develop-next-version.sh`, `reset-to-v*.sh`)
- Old baseline files (`.baseline/`)
- Old PRDs (`prds/`)

## Forking Instructions

To create the new repo:

```bash
# Clone spider-rainbows
git clone git@github.com:wiggitywhitney/spider-rainbows.git choose-your-ai-adventure
cd choose-your-ai-adventure

# Remove git history (clean break)
rm -rf .git

# Start fresh
git init
git add .
git commit -m "Initial commit: forked from spider-rainbows for AI adventure demo"

# Create new repo on GitHub, then:
git remote add origin git@github.com:wiggitywhitney/choose-your-ai-adventure.git
git push -u origin main
```

Then:
1. Move `CLAUDE.md` to `.claude/CLAUDE.md`
2. Keep `ARCHITECTURE.md` and `PROJECT-CONTEXT.md` in repo root for reference
3. Delete files listed in "Remove" section above
4. Create the `manuscript/` directory structure
5. Create `crossplane/`, `agent/`, `vector-db/`, `observability/` directories
6. Enhance `setup-platform.sh` to install Crossplane

## Open Questions (For Future Sessions)

- Exact Crossplane Composition YAML (need to implement)
- Agent code structure details
- Tool installation strategy (setup script vs manuscript instructions vs both)
- How to handle the 6 paths in CI/CD (test all combinations?)
- Slido integration for live voting

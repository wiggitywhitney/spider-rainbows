# Conference Talk: "Let the Platform Build Itself Using AI"

## Subtitle: Building an Internal Developer Platform with CNCF Tools — PSYCHE

---

## Talk Overview

A two-presenter, four-part talk exploring how AI coding assistants and platform-provided tools transform developer experience. We reject the fantasy of AI automatically building platforms, then demonstrate the realistic—and more powerful—vision: developers and platform engineers collaborating through AI-augmented interfaces.

**Duration**: ~60 minutes (talks + live demos)
**Presenters**: Viktor (platform engineer perspective) + Whitney (developer perspective)
**Format**: Alternating slides and live demonstrations

---

## Part One: Breaking the Promise

**Presenter**: Viktor (slides)
**Duration**: ~10 minutes

### Narrative Arc

Our conference abstract promised the impossible: "What if you could build your internal developer platform by simply describing what you want and letting AI do the rest?" We talked about how LLMs, agents, and model context protocol (MCP) servers could be used to construct a functioning platform from scratch in real-time.

### Key Messages

- **The Promise**: Automation of platform engineering through AI
- **The Reality**: Why this approach is fundamentally flawed
- **The Limitation**: What AI actually excels at (and what it doesn't)
- **The Pivot**: Introducing the better vision—AI as an interface layer, not an automation layer

### What Viktor Covers

- Why fully-automated platform construction fails
- The gap between AI capability and platform reliability requirements
- Why platform engineers still matter (and matter more than ever)
- How to think about AI integration realistically
- **Teaser**: A better approach using MCP, slash commands, and AI-assisted workflows

### Takeaway for Audience

"We're not going to do a live AI platform build. Instead, we're going to show you something that actually works and scales."

---

## Part Two: The AI-Assisted Developer-Platform Interaction

**Presenter**: Whitney (live demo)
**Duration**: ~20 minutes

### Demo Environment Setup

**Architecture**:
- Kubernetes cluster running spider-rainbows application
- ArgoCD managing declarative deployments (GitOps)
- GitHub Actions handling CI/CD
- QR code displayed for audience interaction (phones/laptops)

**Audience Participation**:
- Live audience can access and interact with the application on their personal devices
- See changes propagate in real-time as Whitney demonstrates the workflow

### Developer Workflow Demonstration

Whitney walks through the complete developer experience using Claude Code as the primary interface:

1. **Code Changes**
   - Makes intentional changes to spider-rainbows application
   - Demonstrates how developers interact with code via AI coding assistants

2. **CI/CD Process**
   - Push to main triggers GitHub Actions
   - Build, test, and push Docker image
   - Full pipeline visible to audience

3. **Code Review & Quality**
   - CodeRabbit reviews code changes
   - Whitney remediates issues using Claude Code
   - Shows how AI assists with code quality concerns

4. **Live Deployment**
   - ArgoCD syncs changes automatically
   - Application deploys to production
   - Audience sees new version on their devices in real-time

### Key Messages

- **Developer Experience**: AI coding assistants fundamentally change how developers interact with platforms
- **Transparency**: The entire pipeline is visible and understandable
- **Collaboration**: Developer + AI + Platform tools working together
- **Real-time Feedback**: Changes are immediately visible to users

### What Audience Learns

- How modern development workflows integrate AI
- The GitOps approach to declarative infrastructure
- How platforms enable developers through better interfaces
- The role of code review automation in maintaining standards

### Takeaway for Audience

"This is what developer experience looks like when the platform and AI work together. Not magic—better coordination."

---

## Part Three: How Platforms Can Support Developers Who Are Interfacing with the Platform Via AI Coding Assistants

**Presenter**: Viktor (slides)
**Duration**: ~15 minutes

### Narrative Setup

The demo showed developer experience. Now Viktor addresses platform engineers: "How do we build platforms that work *with* AI, not against it?"

### Key Questions Addressed

1. **"How can platform engineers best support developers as AI coding assistant adoption becomes ubiquitous?"**
   - Designing for AI-augmented workflows
   - Platform APIs and interfaces that play well with AI tools
   - Reducing friction in the developer workflow

2. **"How can the platform make developers' jobs as frictionless as possible while also ensuring that organizational standards are met?"**
   - Policy as code
   - MCP tools as guardrails (not gatekeepers)
   - Compliance through platform design, not enforcement

### Platform-Provided Interfaces

The future of internal developer platforms has three layers:

1. **Slash Commands** (`/prd-start`, `/prd-next`, `/prd-update-decisions`)
   - Discoverable, composable commands
   - Work natively with Claude Code and other AI assistants
   - Enable Spec-Driven Development

2. **MCP Tools** (Model Context Protocol servers)
   - Deep platform integration for AI reasoning
   - Kubernetes remediation, policy enforcement, capability discovery
   - Provide platform knowledge to AI in structured way

3. **Agents** (Future state)
   - Autonomous workflows coordinated by AI
   - Human oversight at decision points
   - Scaling developer productivity

### What Viktor Covers

- Design principles for AI-friendly platforms
- How slash commands enable Spec-Driven Development
- MCP tools as the bridge between platform and AI reasoning
- Building compliance into the platform instead of checking it afterwards
- Examples of what good platform-AI integration looks like

### Takeaway for Audience

"The platform engineer's job isn't to automate development. It's to provide interfaces—slash commands, MCP tools, agents—that let AI and developers work together more effectively."

---

## Part Four: Demoing Platform-Provided Slash Commands and MCP Tools

**Presenter**: Whitney (live demo)
**Duration**: ~15 minutes

### Demo Context

Whitney switches to a feature branch where she's been developing using platform-provided slash commands and tools.

### Slash Commands Demonstration

**Commands Shown**:
- `/prd-start` - Begins a new PRD and sets up project scaffold
- `/prd-next` - Identifies the next highest-priority task
- `/prd-update-decisions` - Updates PRD based on decisions made
- `/prd-done` - Merges finished work through organizational workflow

**Philosophy**: Spec-Driven Development using PRDs as executable specifications

### Live PRD Workflow

1. **Show Active PRD**
   - Displays a PRD that has been completed but not yet merged
   - Show the progress: all milestones done, code ready

2. **Run `/prd-done` Command**
   - Automated workflow triggered:
     - Merges feature branch to main
     - Runs CI/CD pipeline
     - Creates deployment
     - Triggers ArgoCD sync

3. **Audience Watches on Devices**
   - Application begins updating to new version
   - Real-time visibility of deployment progress

### MCP Tools for Troubleshooting

**Intentional Failure Scenario**:
- Deployment starts but fails (taint/toleration mismatch in Kubernetes)
- Application doesn't appear on audience devices

**Whitney Uses MCP Tools**:
1. **Diagnosis**: "Why isn't the deployment working?"
   - MCP server analyzes cluster state
   - Identifies taint/toleration conflict
   - Reports root cause clearly

2. **Remediation**:
   - MCP generates kubectl commands to fix the issue
   - Apply remediation
   - Deployment retries

3. **Verification**:
   - Deployment succeeds
   - Application appears on audience devices
   - Live validation of the fix

### Key Demonstration Points

- **Slash Commands**: Make PRD lifecycle discoverable and automated
- **MCP Tools**: Provide AI reasoning about infrastructure problems
- **Integration**: Platform tools work seamlessly with Claude Code
- **Organizational Compliance**: All workflows respect standards (automatic enforcement)
- **Developer Productivity**: Complex tasks become manageable through better interfaces

### Narrative Arc of the Failure & Fix

1. Show that automation isn't magic—it can fail
2. Demonstrate that AI + MCP tools can diagnose and fix failures
3. Prove that platforms can be both automated *and* reliable
4. Show the complete developer experience: feature → deployment → fix → success

### Takeaway for Audience

"This is what the next generation of developer platforms looks like: AI-augmented interfaces (slash commands), platform-specific knowledge (MCP tools), and human oversight. It's not automation. It's collaboration at scale."

---

## Demo Artifacts

### Prerequisites for Each Part

**Part Two Demo**:
- Kubernetes cluster (Kind or cloud)
- Spider-rainbows application v1 → v2 (showing version progression)
- ArgoCD managing deployments
- GitHub Actions CI/CD pipeline
- QR code pointing to live application
- CodeRabbit enabled for code reviews

**Part Four Demo**:
- Feature branch with v3 changes (new spider image reveal)
- PRD marked as complete/ready to merge
- Intentional Kubernetes failure scenario (taint on nodes)
- MCP server installed and configured
- Claude Code with MCP integration

### Visual Elements

- **Part One**: Slides (Viktor)
- **Part Two**: Live cluster, QR code, application on audience devices
- **Part Three**: Slides showing architecture (Viktor)
- **Part Four**: Live terminal, PRD commands, MCP tool output, application on audience devices

---

## Post-Demo Cleanup

After Part Four, Whitney reverts the v3 merge to return main to clean state. This allows:
- The demo to be repeated for other conferences
- The v3 branch to remain available for future use
- The main branch to stay stable for regular development

---

## Talk Themes

Throughout both presentations and demos:

1. **Reality Over Magic**: AI doesn't automate platform building, but it transforms developer experience
2. **Collaboration**: Developers, AI, and platforms working together
3. **Interfaces**: Slash commands and MCP tools as first-class platform abstractions
4. **Standards**: Compliance built into platform design, not added as afterthought
5. **Visibility**: Everything that happens is visible and understandable to developers

---

## Success Metrics for Talk

- ✅ Audience understands the difference between "AI builds platforms" and "AI interfaces for platforms"
- ✅ Platform engineers see concrete examples of MCP, slash commands, and agents
- ✅ Developers see how AI coding assistants integrate with modern IDP workflows
- ✅ Attendees leave wanting to try slash commands and MCP tools in their own environments
- ✅ Live demos execute smoothly and prove the concepts work in practice
- ✅ Both presenters convey confidence in the approach

---

## Abstract for Conference

> **"Let the Platform Build Itself Using AI to Construct an Internal Developer Platform with CNCF Tools — PSYCHE"**
>
> We promised a live AI system that builds a functioning platform from scratch. We're going to break that promise—and show you something better.
>
> In this talk, we'll reject the fantasy of fully-automated platform engineering and explore the realistic power of AI-augmented developer workflows. We'll demonstrate how internal developer platforms can provide slash commands and MCP (Model Context Protocol) tools that let developers and AI work together more effectively.
>
> Part 1: Why fully-automated platform construction is a bad idea (and what works instead)
> Part 2: Live demo of a developer using Claude Code with an IDP
> Part 3: How platform engineers can design for AI
> Part 4: Live demo of platform-provided slash commands and MCP tools troubleshooting infrastructure
>
> Leave this talk with concrete ideas about how to integrate AI into your platform, not as automation, but as collaboration at scale.

---


# PRD: MCP Server Setup & Configuration for Demo

**Status**: Draft
**Created**: 2025-10-31
**GitHub Issue**: [#16](https://github.com/wiggitywhitney/spider-rainbows/issues/16)
**Priority**: Medium

---

## Related Resources

- [DevOps AI Toolkit - dot-ai](https://github.com/vfarcic/dot-ai)
- [MCP Setup Guide](https://github.com/vfarcic/dot-ai/blob/main/docs/mcp-setup.md)
- [MCP Tools Overview](https://github.com/vfarcic/dot-ai/blob/main/docs/README.md)
- [Claude Code MCP Integration](https://docs.claude.com/en/docs/claude-code/claude_code_docs_map.md)

---

## Problem Statement

Part 4 of the conference demo requires demonstrating the MCP server tools for Kubernetes troubleshooting and remediation. Specifically:
- Using the MCP server to diagnose a deployment failure (taint/toleration or similar K8s issue)
- Using remediation tools to fix the problem
- Demonstrating how platform engineers can provide MCP tools as first-class interfaces

**Current State**:
- MCP server exists and is documented externally (dot-ai repo)
- No integration with spider-rainbows demo environment
- MCP server not tested/practiced with conference demo

**Presenter Impact**:
- Cannot smoothly demonstrate troubleshooting workflow during Part 4
- Unfamiliar with MCP server capabilities and usage patterns
- No backup plans if MCP server setup fails during demo

---

## Solution Overview

Install and configure the DevOps AI Toolkit MCP server locally, integrate it with Claude Code, and practice using it for the specific Part 4 demo scenario (troubleshooting K8s deployment failure).

**Key Features**:
1. Install MCP server following dot-ai documentation
2. Configure Claude Code to recognize and use MCP tools
3. Test Kubernetes remediation workflow with actual cluster
4. Practice the Part 4 demo scenario (diagnose + fix taint/toleration issue)
5. Document backup procedures if MCP server fails live

---

## Goals & Success Criteria

### Primary Goals
- [ ] MCP server installed and running locally
- [ ] Claude Code can access MCP tools via slash commands
- [ ] Kubernetes remediation workflow functional with test cluster
- [ ] Part 4 demo scenario (diagnose + fix) practiced and rehearsed
- [ ] Backup plan documented for live demo failures

### Success Metrics
- [ ] `dot-ai` CLI tools accessible from command line
- [ ] Claude Code recognizes `/` commands from MCP server
- [ ] Can diagnose a broken deployment using MCP tools
- [ ] Can apply remediation and verify fix
- [ ] Demo flow completes in <5 minutes

### Non-Goals
- Production deployment of MCP server
- Integration with other CI/CD systems
- Extending MCP server with custom tools
- Multi-cluster support

---

## User Stories & Use Cases

### Primary User Story
**As a** conference presenter
**I want** to demonstrate MCP server troubleshooting capabilities
**So that** I can show how AI coding assistants integrate with platform tools for infrastructure issues

**Acceptance Criteria**:
- MCP server installed and ready before conference
- Can use MCP tools through Claude Code during demo
- Kubernetes issue remediation workflow is smooth
- Part 4 demo feels natural and well-rehearsed

### Use Case 1: Part 4 Demo Troubleshooting Flow
**Context**: V3 branch merge triggers deployment, but app fails to deploy due to taint/toleration mismatch
**Flow**:
1. Merge v3 branch via `/prd-done` command
2. CI/CD builds and ArgoCD attempts sync
3. Deployment fails (intentional taint on nodes)
4. Use MCP server to diagnose: "Why isn't the app deploying?"
5. MCP identifies taint/toleration issue
6. Apply remediation via MCP generated commands
7. Deployment succeeds, audience sees v3 on their devices

### Use Case 2: Practice Session
**Context**: Presenter practicing demo workflow week before conference
**Flow**:
1. Set up test Kind cluster with intentional K8s issue
2. Use MCP server tools to diagnose problem
3. Practice natural explanation while running MCP tools
4. Time the workflow and refine talking points
5. Iterate until demo feels smooth and confident

---

## Technical Approach

### Architecture Components

**1. MCP Server Installation**
- Install dot-ai from GitHub repository
- Follow official MCP Setup Guide
- Requires: Python 3.8+, Go, kubectl, necessary API keys

**2. Claude Code Integration**
- Configure Claude Code to use MCP server
- Enable slash commands from MCP toolkit
- Test basic commands in development environment

**3. Kubernetes Integration**
- MCP server requires `KUBECONFIG` pointing to active cluster
- Works with existing Kind or cloud deployment
- Requires cluster API access for remediation

**4. Demo Scenario Setup**
- Create intentional taint on cluster nodes
- Deploy v3 app that doesn't tolerate the taint
- MCP server diagnoses the issue
- MCP generates remediation commands

### Implementation Details

**MCP Server Capabilities for Demo**:
- **Kubernetes Issue Remediation**: Diagnose pod/deployment failures
- **Root cause analysis**: Identify taint, resource limits, networking issues
- **Remediation commands**: Generate kubectl commands to fix issues
- **Verification**: Confirm fix resolves the issue

**Demo-Specific Configuration**:
- Set up intentional taint: `kubectl taint nodes <node> demo-issue=true:NoSchedule`
- Create deployment without toleration (will fail)
- Use MCP tools to diagnose and remediate
- Remove taint to demonstrate fix

### Technical Considerations

**Dependencies**:
- Python 3.8+ on presenter's machine
- Go toolchain
- kubectl configured and working
- Active Kubernetes cluster (Kind or cloud)
- Claude Code installed and ready

**Backup Strategy**:
- Pre-record MCP server interaction as backup
- Have remediation commands written down as fallback
- Practice manual kubectl commands as last resort
- Slides with screenshots of expected output

---

## Implementation Milestones

### Milestone 1: MCP Server Installation
**Goal**: MCP server installed and verified working

**Tasks**:
- Clone dot-ai repository
- Follow MCP Setup Guide installation steps
- Verify `dot-ai` CLI commands work
- Test Kubernetes integration with local cluster

**Success Criteria**:
- `dot-ai --help` returns version info
- Can run basic commands: `dot-ai status`, `dot-ai list-tools`
- MCP server connects to KUBECONFIG cluster

---

### Milestone 2: Claude Code Integration
**Goal**: Claude Code can access MCP server tools

**Tasks**:
- Install/configure MCP server for Claude Code
- Test slash commands from MCP toolkit
- Verify Kubernetes remediation tools accessible
- Practice using commands in Claude Code

**Success Criteria**:
- Claude Code slash commands work
- Can invoke Kubernetes issue remediation
- Tool outputs display correctly in Claude Code

---

### Milestone 3: Demo Scenario Testing
**Goal**: Practice Part 4 troubleshooting workflow

**Tasks**:
- Set up Kind cluster with intentional taint
- Deploy v3 spider-rainbows app (will fail)
- Use MCP tools to diagnose taint issue
- Apply remediation via MCP generated commands
- Verify app deploys successfully
- Time the entire workflow

**Success Criteria**:
- MCP correctly identifies taint/toleration issue
- Remediation commands work as expected
- Fix resolves deployment failure
- Workflow completes in <5 minutes

---

### Milestone 4: Rehearsal & Documentation
**Goal**: Demo workflow smooth and well-practiced

**Tasks**:
- Full run-through of Part 4 demo scenario
- Time each step and refine talking points
- Create backup slides with screenshots
- Document commands used during demo
- Practice natural explanations while running MCP tools

**Success Criteria**:
- Demo feels natural and well-paced
- Presenter confident in tool usage
- Backup materials ready if needed
- Workflow timed and rehearsed

---

## Dependencies & Integration Points

### External Dependencies
- **dot-ai repository**: Official MCP server implementation
- **Claude Code**: MCP client for demo
- **Kubernetes cluster**: For testing and Part 4 demo
- **Python/Go**: Runtime dependencies for MCP server

### Internal Dependencies
- Existing Kind or cloud cluster setup
- Part 4 demo v3 branch deployment
- ArgoCD/GitOps workflow

### Integration with Existing Systems
- **Claude Code**: Primary interface for MCP tools
- **Kubernetes cluster**: Target for remediation
- **Part 4 Demo**: Uses MCP for troubleshooting

---

## Risks & Mitigation

### Technical Risks

**Risk 1: MCP Server Installation Complexity**
- **Impact**: High - Cannot demo if setup fails
- **Likelihood**: Low - Official docs are clear
- **Mitigation**:
  - Follow docs step-by-step
  - Test installation days before conference
  - Document any issues and solutions
  - Have manual fallback procedures

**Risk 2: Claude Code MCP Integration Issues**
- **Impact**: High - Cannot use tools if integration fails
- **Likelihood**: Low - Standard integration
- **Mitigation**:
  - Test Claude Code integration thoroughly
  - Have pre-recorded demo as backup
  - Screenshot expected outputs for reference

**Risk 3: Kubernetes API Access Issues**
- **Impact**: High - Cannot diagnose/remediate
- **Likelihood**: Low - Works with standard clusters
- **Mitigation**:
  - Verify KUBECONFIG before demo
  - Test MCP tools with actual cluster
  - Have manual kubectl commands ready

### Process Risks

**Risk 4: Insufficient Practice Time**
- **Impact**: Medium - Demo might feel rushed/unnatural
- **Likelihood**: Medium - Presenter learning new tools
- **Mitigation**:
  - Start practicing weeks before
  - Full rehearsals multiple times
  - Time each step of workflow
  - Record practice sessions for review

**Risk 5: MCP Tools Different Than Expected**
- **Impact**: Medium - Demo might not match prepared flow
- **Likelihood**: Low - Tools are stable
- **Mitigation**:
  - Read all tool documentation
  - Test with actual Part 4 scenario
  - Prepare to adapt explanations if needed

---

## Timeline & Phases

### Phase 1: Installation (Days 1-2)
- Install MCP server following official docs
- Configure Claude Code integration
- Test basic functionality with test cluster

### Phase 2: Integration (Days 3-4)
- Set up Part 4 demo scenario
- Test Kubernetes remediation workflow
- Verify everything works end-to-end

### Phase 3: Practice (Days 5-7)
- Multiple full run-throughs
- Time each step
- Refine talking points
- Create backup materials

### Phase 4: Polish (Days 8-10)
- Final rehearsals
- Record backup video
- Document procedures and commands
- Confidence check before conference

**Total Estimated Time**: 10 days

---

## Progress Log

### 2025-10-31: PRD Created
- Initial PRD drafted for MCP server setup
- Integration with Part 4 demo identified
- Milestones and practice schedule outlined

---

## Open Questions

1. **Which MCP Tools**: Should we focus only on Kubernetes remediation, or explore other tools?
   - Current plan: Focus on remediation for Part 4 demo

2. **Backup Strategy**: How detailed should backup procedures be?
   - Current plan: Pre-recorded demo + command reference + manual kubectl

3. **Practice Environment**: Should we use Kind or cloud cluster for practice?
   - Current plan: Use same environment as Part 4 demo (cloud if applicable)

4. **API Keys**: Do we need actual API keys for demo, or can we fake it?
   - Current plan: Minimal API usage - focus on kubectl-based operations

---


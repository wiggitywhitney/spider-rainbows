# PRD: V2 Spider Anatomy Comments + CodeRabbit Issues

**Status**: Draft
**Created**: 2025-10-31
**GitHub Issue**: [#20](https://github.com/wiggitywhitney/spider-rainbows/issues/20)
**Priority**: High

---

## Related Resources

- [SpiderImage.jsx](../src/components/SpiderImage.jsx)
- [SurpriseSpider.jsx](../src/components/SurpriseSpider.jsx)
- [CodeRabbit Review Guide](../.claude/CLAUDE.md)
- [V2 Spider Images](../public/Spider-v2.png) and [Swarm](../public/spidersspidersspiders-v2.png)

---

## Problem Statement

Part 2 of the conference demo shows the developer experience of using Claude Code with an IDP. When code changes trigger CodeRabbit reviews, the presenter needs realistic issues to remediate. Additionally, v2 version should have narrative storytelling about spider anatomy through code comments.

**Current State**:
- V2 spider images exist (cheesy grins)
- No code comments explaining spider anatomy
- No CodeRabbit issues to demonstrate remediation workflow

**Demo Impact**:
- Cannot show realistic code review workflow during Part 2
- Missing educational narrative about spider characteristics
- No opportunity to discuss how AI helps with code quality issues

---

## Solution Overview

Add narrative code comments explaining spider anatomy to v2 components, and strategically introduce code quality issues that CodeRabbit will flag:

**Educational Narrative**:
- Comments explain spider mouth parts (chelicerae, external digestion)
- Comments tie to why v2 image looks different from v1
- Provides story for presenter to tell during demo

**Code Quality Issues** (intentional for demo):
- Duplicated functionality across components
- Dead code (unused variables/functions)
- These create realistic CodeRabbit findings to remediate

---

## Goals & Success Criteria

### Primary Goals
- [ ] V2 components have educational spider anatomy comments
- [ ] Duplicated functionality strategically placed
- [ ] Dead code introduced (but documented as intentional)
- [ ] CodeRabbit flags realistic issues
- [ ] Presenter can remediate during Part 2 demo
- [ ] Narrative enhances demo storytelling

### Success Metrics
- [ ] Code comments are scientifically accurate about spider anatomy
- [ ] CodeRabbit produces 3-5 actionable issues
- [ ] Issues are remediable in <10 minutes
- [ ] Changes merged to main after demo completion
- [ ] Demo shows complete CI/CD + code review workflow

### Non-Goals
- Changing actual spider images
- Permanent code duplication (only for demo period)
- Breaking application functionality
- Hiding the intentional issues from code review

---

## User Stories & Use Cases

### Primary User Story
**As a** conference presenter
**I want** to demonstrate realistic code review workflow during Part 2
**So that** I can show how AI coding assistants help with code quality while building the platform

**Acceptance Criteria**:
- Code comments tell story about spider anatomy
- CodeRabbit flags meaningful issues
- Issues can be fixed quickly live during demo
- Both v1 (clean) and v2 (issues) states work correctly

### Use Case 1: Part 2 Demo Code Review Flow
**Context**: Presenter commits v2 spider code changes
**Flow**:
1. Presenter updates components with v2 comments and duplicated code
2. Git commit → Push to main
3. GitHub Actions CI completes
4. CodeRabbit reviews code
5. Presenter opens PR, shows CodeRabbit findings
6. Explains issues to audience
7. Remediates issues live using Claude Code
8. Shows clean PR and merge
9. App deploys v2 with clean code

### Use Case 2: Educational Narrative
**Context**: Audience learns about spider anatomy while watching code
**Flow**:
1. Presenter commits new v2 code
2. During deployment wait, presenter explains code comments
3. Discusses real spider characteristics: chelicerae, external digestion
4. Explains why v2 image reflects actual anatomy
5. Ties back to software engineering principles: documentation, clarity
6. Meanwhile CI/CD completes and CodeRabbit findings appear

---

## Technical Approach

### Code Comments - Spider Anatomy Narrative

**SpiderImage.jsx v2 Comments** (when referencing v2 image):
```javascript
// v2: Spider with anatomically-inspired mouth parts
// In nature, spiders don't have traditional mouths - instead they have:
// - Chelicerae: Fang-like structures used for capturing and killing prey
// - Venom glands: Inject toxins through the chelicerae
// - External digestion: Spiders break down prey outside their body,
//   then consume the liquefied contents through their mouth
// This v2 rendering attempts to visualize these real spider characteristics
// instead of cute cartoon expressions from v1
```

**SurpriseSpider.jsx v2 Comments** (same narrative for swarm):
```javascript
// v2: Spider swarm with anatomically-inspired features
// The v2 swarm reflects how real spiders are actually structured:
// Chelicerae (visible as the prominent "mouth" parts) are the defining
// feature of arachnids. Instead of eating like mammals, spiders are
// external digesters - they inject enzymes into prey and consume it
// as a liquid. This is why v2 looks so different from v1!
```

### Code Quality Issues - Intentional for Demo

**Issue 1: Duplicated Utility Function**
- Create `spiderUtils-v2.js` with duplicate of existing spider selection logic
- Import and use in both SpiderImage.jsx AND SurpriseSpider.jsx
- CodeRabbit will flag duplication across components
- Easy to fix: consolidate to single utility

**Issue 2: Dead Code**
- Add unused variable: `const spiderAnatomyDetail = "chelicerae"` in component
- Add unused function: `const validateSpiderHealth = () => {}`
- CodeRabbit will flag as unused code
- Easy to fix: remove unused code

**Issue 3: Inconsistent Comment Style** (optional)
- Use inconsistent comment formatting for some spider comments
- CodeRabbit might flag style issues
- Demonstrates consistency importance

### Integration Strategy

**Phase 1: Prepare on Branch**
- Create feature branch with v2 code, comments, and duplication
- Test locally to ensure app still works perfectly
- Verify CodeRabbit can see the issues before demo

**Phase 2: Demo Day**
- Merge branch to main during live demo
- Show CodeRabbit findings
- Remediate issues live
- Push clean code

---

## Success Criteria

### Functional Requirements
- [ ] App still works perfectly with duplicated code (no functionality breaking)
- [ ] Spider anatomy comments are scientifically accurate
- [ ] V2 images display correctly with new code
- [ ] Dead code doesn't impact application behavior

### Code Review Requirements
- [ ] CodeRabbit flags at least 3 actionable issues
- [ ] Issues are realistic (not artificial/obvious)
- [ ] Issues are remediable in <10 minutes
- [ ] Presenter understands each issue and how to fix it

### Demo Requirements
- [ ] Comments add narrative value to demo story
- [ ] Code issues demonstrate real code review workflow
- [ ] Remediation can be done live with Claude Code
- [ ] Changes can be pushed and app redeployed within demo timeframe

---

## Milestones

### Milestone 1: Spider Anatomy Comments Written
- [ ] Research and write accurate spider anatomy facts
- [ ] Add educational comments to SpiderImage.jsx (v2 version)
- [ ] Add educational comments to SurpriseSpider.jsx (v2 version)
- [ ] Comments tie to v2 image appearance

**Success Criteria**: Comments are engaging, accurate, and enhance demo narrative

---

### Milestone 2: Code Quality Issues Introduced
- [ ] Create duplicated utility function
- [ ] Introduce dead code variables/functions
- [ ] Verify CodeRabbit will flag these issues
- [ ] Ensure app functionality still works perfectly

**Success Criteria**: CodeRabbit produces 3-5 actionable findings

---

### Milestone 3: Feature Branch Prepared
- [ ] Create feature branch with all v2 changes
- [ ] Test locally in dev environment
- [ ] Test in Docker container
- [ ] Test in local Kind cluster with ArgoCD
- [ ] Create draft PR and verify CodeRabbit reviews

**Success Criteria**: Feature branch is production-ready and CodeRabbit findings visible

---

### Milestone 4: Demo Workflow Rehearsed
- [ ] Merge feature branch to main during practice run
- [ ] Show CodeRabbit findings to "audience"
- [ ] Remediate issues live using Claude Code
- [ ] Push fixed code and verify app redeployment
- [ ] Time the entire workflow

**Success Criteria**: Workflow is smooth, well-timed, and presenter is confident

---

### Milestone 5: Production Ready
- [ ] All tests pass
- [ ] Feature branch ready to merge on demo day
- [ ] CodeRabbit findings documented
- [ ] Remediation steps clear and practiced
- [ ] Backup plans in place

**Success Criteria**: Ready to execute demo with confidence

---

## Implementation Details

### Comment Placement Strategy

Place comments where code changes to reference v2:
```javascript
// At top of component or near image src
// v2: Spider with anatomically-inspired mouth parts
// In nature, spiders don't have traditional mouths...
```

### Duplication Strategy

**Approach**: Create new utility file that duplicates existing logic
- `src/utils/spiderUtils.js` (existing - original selection logic)
- `src/utils/spiderUtils-v2.js` (new - same logic, different file)
- Import v2 in both SpiderImage and SurpriseSpider
- CodeRabbit flags cross-component duplication

**Why this approach**:
- Realistic: Real developers sometimes create duplication by accident
- Easy to fix: Consolidate to single utility
- Educational: Shows importance of shared utilities
- Non-breaking: App still works perfectly

### Dead Code Strategy

**Approach**: Add unused but realistic-looking code
```javascript
// Unused variable
const spiderAnatomyDetail = "chelicerae";

// Unused function
const validateSpiderHealth = (spider) => {
  return spider.isHealthy === true;
};
```

**Why this approach**:
- Realistic: Real codebase has dead code
- Easy to identify: CodeRabbit flags immediately
- Easy to fix: Delete dead code
- Non-breaking: App works without it

---

## Dependencies & Integration

### Internal Dependencies
- SpiderImage.jsx (main component)
- SurpriseSpider.jsx (easter egg component)
- spiderUtils.js (utility functions)
- V2 spider images (already exist from PRD #5)

### Integration with Existing Systems
- CI/CD pipeline (already configured)
- CodeRabbit reviews (already enabled)
- ArgoCD/GitOps (no changes needed)
- App functionality (no changes, only additions)

---

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Code duplication breaks app | High | Low | Test thoroughly before demo |
| CodeRabbit doesn't flag issues | High | Low | Verify findings in draft PR first |
| Remediation takes >10 minutes | Medium | Medium | Practice remediation steps multiple times |
| Audience doesn't understand spider facts | Medium | Low | Practice explaining comments naturally |
| Code review workflow feels forced | Medium | Medium | Make all changes feel organic and realistic |

---

## Timeline & Phases

### Phase 1: Planning & Research (Days 1-2)
- Research spider anatomy facts
- Plan comment narrative
- Design duplication strategy

### Phase 2: Implementation (Days 3-4)
- Write spider anatomy comments
- Introduce code duplication and dead code
- Create feature branch

### Phase 3: Testing & Verification (Days 5-6)
- Test in all environments (dev, Docker, Kind)
- Verify CodeRabbit findings
- Create draft PR and review findings

### Phase 4: Practice & Rehearsal (Days 7-10)
- Multiple practice runs of demo workflow
- Time remediation process
- Refine talking points

**Total Estimated Time**: 10 days

---

## Progress Log

### 2025-10-31: PRD Created
- Initial PRD drafted for V2 comments and code issues
- Educational narrative strategy outlined
- CodeRabbit issue strategy designed

---

## Open Questions

1. **Comment Detail Level**: How technical should spider anatomy comments be?
   - Current plan: Accessible to general audience, 2-3 key facts

2. **How Many Issues**: Should we aim for 3, 5, or more CodeRabbit findings?
   - Current plan: 3-5 realistic, remediable issues

3. **Dead Code Realism**: Should dead code look like forgotten code or obviously unused?
   - Current plan: Realistic-looking, not obviously fake

4. **Remediation Timing**: How important is keeping remediation under 10 minutes?
   - Current plan: Critical for demo pacing

---


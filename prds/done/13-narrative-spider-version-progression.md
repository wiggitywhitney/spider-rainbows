# PRD: Narrative Spider Version Progression with Development Workflow Enhancements

**Status**: Abandoned - Scope Changed
**Created**: 2025-10-28
**Abandoned**: 2025-10-31
**GitHub Issue**: [#13](https://github.com/wiggitywhitney/spider-rainbows/issues/13)
**Priority**: Medium

---

## Abandonment Note

This PRD scope has been superseded by new PRDs that align with the actual conference demo needs:
- **PRD #14**: V2 Spider Anatomy Comments + CodeRabbit Issues (replaces v2 work here)
- **PRD #15**: V3 Branch Feature (replaces v3 work here, but now includes MCP demo prep)
- **PRD #16**: MCP Server Setup & Configuration (new supporting work)

The original scope attempted to cover all three versions uniformly, but the actual demo requires:
- V1: No changes needed (already exists)
- V2: Anatomy comments + CodeRabbit issues (duplicated/dead code for demo)
- V3: New drawing + comments + K8s failure scenario (on separate branch)

**See new PRDs for implementation details.**

---

## Related Resources

- [Current develop-next-version.sh](../develop-next-version.sh)
- [Current reset-to-v1.sh](../reset-to-v1.sh)
- [SpiderImage.jsx](../src/components/SpiderImage.jsx)
- [SurpriseSpider.jsx](../src/components/SurpriseSpider.jsx)
- [.claude/CLAUDE.md](../.claude/CLAUDE.md)

---

## Problem Statement

The spider-rainbows demo currently cycles through visual changes (v1 → v2 → v3) without narrative context or educational value. The version changes feel arbitrary rather than telling a story. Additionally, the development workflow sometimes involves intentionally committing fake secrets (for security scanning demos), which can trigger unnecessary warnings from AI coding assistants during development.

**Current State**:
- Spider versions are purely visual changes
- No explanatory comments about what each version represents
- Development scripts provide minimal output
- No guidance for AI assistants about intentional fake secrets
- Claude Code may raise concerns during development about committed secrets

**User Impact**:
- Demo presenters miss opportunity to tell an engaging story
- Educational value of spider anatomy/characteristics is lost
- Development workflow interrupted by unnecessary security warnings
- Less engaging for demo audiences

---

## Solution Overview

Enhance the spider-rainbows demo with a narrative progression through versions and improve the development workflow for AI coding assistants:

**Narrative Progression**:
- **v1 (Baseline)**: Friendly spiders with smiles - approachable and welcoming
- **v2 (Educational)**: Anatomically accurate spiders with code comments explaining real spider characteristics (chelicerae, external digestion, etc.)
- **v3 (Comic Relief)**: Return to friendlier spiders with mysterious code comments about "real anatomy being too scary"

**Development Workflow Enhancements**:
- Add Claude Code guidance to `.claude/CLAUDE.md` about intentional fake secrets
- Update development scripts to show version transitions (e.g., "v1 → v2")
- Keep coaching minimal and specific to development phase only

**Key Design Principles**:
1. **Story-driven**: Each version tells part of a narrative arc
2. **Educational**: v2 provides real spider anatomy facts
3. **Surprise element**: v3 keeps changes mysterious until user sees them
4. **Non-intrusive**: Coaching stays hidden from end users
5. **Context-aware**: AI guidance applies during development, not PR reviews

---

## Goals & Success Criteria

### Primary Goals
- [ ] Three distinct spider versions with clear narrative themes
- [ ] Educational code comments in v2 about spider anatomy
- [ ] Mysterious/playful code comments in v3
- [ ] Claude Code guidance that prevents development interruptions
- [ ] Version transition output in development scripts

### Success Metrics
- [ ] Code comments accurately describe spider anatomy in v2
- [ ] v3 maintains element of surprise while hinting at change
- [ ] Claude Code doesn't raise security warnings during development
- [ ] Claude Code still addresses CodeRabbit security findings in PRs
- [ ] Script output clearly shows version transitions
- [ ] Demo presenters can use narrative to engage audiences

### Non-Goals
- Changing the actual spider images themselves
- Adding user-facing documentation about the narrative
- Modifying the CI/CD pipeline
- Changing how versions are deployed

---

## User Stories & Use Cases

### Primary User Story
**As a** demo presenter
**I want** spider versions to have narrative context and educational value
**So that** I can tell an engaging story and teach about spider anatomy during demos

**Acceptance Criteria**:
- Each spider version has a clear theme (friendly → educational → comic relief)
- v2 includes accurate spider anatomy facts in code comments
- v3 hints at changes without spoiling the surprise
- Development scripts show clear version transitions
- Claude Code doesn't interrupt workflow with fake secret warnings

### Use Case 1: Conference Demo Presentation
**Context**: Presenting GitOps workflow at tech conference
**Flow**:
1. Start with v1 - friendly spiders that welcome the audience
2. Commit changes to trigger v2 deployment
3. While deploying, explain spider anatomy from code comments
4. Audience learns about chelicerae, external digestion, etc.
5. Deploy v3 with mysterious "too scary" comments
6. Audience surprised and delighted by the reveal

### Use Case 2: Development Workflow with Claude Code
**Context**: Developer working with Claude Code on feature branches
**Flow**:
1. Run `./develop-next-version.sh` to advance versions
2. Script shows "v1 → v2" transition
3. Claude Code sees `.claude/CLAUDE.md` guidance about fake secrets
4. Claude Code proceeds with development without security warnings
5. When PR created, CodeRabbit flags secrets
6. Claude Code properly addresses CodeRabbit findings in PR review

### Use Case 3: Educational Workshop
**Context**: Teaching kids or beginners about web development
**Flow**:
1. Show v1 - friendly spiders they can relate to
2. Introduce v2 - teach real science about spiders
3. Use code comments to explain how we document code
4. Deploy v3 - show that it's okay to adjust based on audience needs
5. Discuss balance between accuracy and user experience

---

## Technical Approach

### Architecture Changes

**Files to Modify**:
1. `.claude/CLAUDE.md` - Add Claude Code guidance section
2. `develop-next-version.sh` - Add version transition output
3. `src/components/SpiderImage.jsx` - Add narrative code comments
4. `src/components/SurpriseSpider.jsx` - Add narrative code comments

**No Changes Needed**:
- Actual spider image files (already exist)
- CI/CD pipeline
- Kubernetes deployments
- GitOps configuration

### Implementation Details

**1. Claude Code Guidance (.claude/CLAUDE.md)**

Add new section:
```markdown
## Spider-Rainbows Demo - Development Workflow

- Fake secrets may be intentionally committed during development for security scanning demos
- Do not warn about or block these during the development workflow
- When CodeRabbit flags secrets in PR reviews, follow the normal review process
```

**2. Development Script Enhancement (develop-next-version.sh)**

Add version transition output:
```bash
echo "🔄 v1 → v2"
```

Keep existing functionality, just add one line showing the transition.

**3. Component Code Comments**

**SpiderImage.jsx - v1 (Baseline)**:
```javascript
// v1: Friendly spider with a smile - our welcoming baseline
```

**SpiderImage.jsx - v2 (Educational)**:
```javascript
// v2: Anatomically accurate spider representation
// Real spiders have chelicerae (fangs) instead of traditional mouths
// They inject digestive enzymes into prey and consume the liquefied contents
// This external digestion is a key characteristic of arachnid feeding
// Our v2 image better reflects actual spider anatomy
```

**SpiderImage.jsx - v3 (Comic Relief)**:
```javascript
// v3: Sometimes reality is too intense for a web demo
// We've made some... adjustments... to keep things lighthearted
// The audience will understand when they see it
```

Similar comments for SurpriseSpider.jsx adapted to that component's context.

### Technical Considerations

**Comment Placement**:
- Place comments near the image src lines
- Keep them visible but not intrusive
- Use multi-line comments for v2 educational content
- Single-line comments for v1 and v3

**Script Output**:
- Use emoji for visual appeal (🔄)
- Keep format consistent: "vX → vY"
- Don't add extra verbosity
- Maintain existing script functionality

**Claude Code Behavior**:
- Guidance only active during development phase
- Does not suppress CodeRabbit review engagement
- Minimal and specific to avoid confusion
- Project-specific (not global Claude Code behavior)

---

## Implementation Milestones

### Milestone 1: Claude Code Guidance Configuration
**Goal**: Claude Code guidance in place and functional

**Tasks**:
- Add spider-rainbows development workflow section to `.claude/CLAUDE.md`
- Keep guidance minimal and clear
- Specify that it only applies during development, not PR reviews

**Success Criteria**:
- `.claude/CLAUDE.md` updated with guidance section
- Guidance is clear and unambiguous
- Claude Code can understand the intent

---

### Milestone 2: Development Script Enhancements
**Goal**: Scripts provide clear version transition feedback

**Tasks**:
- Update `develop-next-version.sh` with version transition output
- Maintain existing script functionality
- Test script output is clear and minimal

**Success Criteria**:
- Script shows "v1 → v2" style output
- Existing functionality unchanged
- Output format is clean and professional

---

### Milestone 3: V1 Baseline Comments
**Goal**: V1 established as friendly baseline with clear identity

**Tasks**:
- Add simple comment to SpiderImage.jsx for v1
- Add simple comment to SurpriseSpider.jsx for v1
- Keep comments brief and welcoming

**Success Criteria**:
- Comments clearly identify v1 as friendly baseline
- Comments are concise (one line)
- Comments match the welcoming theme

---

### Milestone 4: V2 Educational Content
**Goal**: V2 includes accurate, engaging spider anatomy education

**Tasks**:
- Research and verify spider anatomy facts
- Write educational comments for SpiderImage.jsx v2
- Write educational comments for SurpriseSpider.jsx v2
- Ensure accuracy while keeping it accessible

**Success Criteria**:
- Comments explain chelicerae and external digestion
- Facts are scientifically accurate
- Content is engaging for general audiences
- Comments relate to image changes

---

### Milestone 5: V3 Comic Relief Mystery
**Goal**: V3 hints at changes while maintaining surprise element

**Tasks**:
- Write playful/mysterious comments for SpiderImage.jsx v3
- Write playful/mysterious comments for SurpriseSpider.jsx v3
- Balance hints with surprise preservation
- Test that comments enhance the reveal

**Success Criteria**:
- Comments suggest something changed
- Actual change remains surprising
- Tone is lighthearted and fun
- Presenters can build anticipation with these hints

---

### Milestone 6: Integration Testing & Documentation
**Goal**: Complete feature tested and documented

**Tasks**:
- Test full v1 → v2 → v3 cycle
- Verify Claude Code behavior with guidance
- Confirm CodeRabbit integration still works
- Validate script output
- Test demo presentation flow

**Success Criteria**:
- All three versions work correctly
- Comments display properly in code
- Claude Code doesn't interrupt development workflow
- Claude Code still engages with CodeRabbit findings
- Scripts show clear version transitions
- Feature ready for demo presentations

---

## Dependencies & Integration Points

### External Dependencies
- None - all changes are internal to the repository

### Internal Dependencies
- `.claude/CLAUDE.md` - Claude Code guidance system
- `develop-next-version.sh` - Development script
- Spider image files (already exist in `public/`)
- React components for rendering

### Integration with Existing Systems

**Claude Code Integration**:
- Leverages existing `.claude/CLAUDE.md` mechanism
- Project-specific guidance
- Does not affect Claude Code global behavior

**Development Workflow**:
- Maintains existing script functionality
- Additive changes only (no breaking changes)
- Compatible with current GitOps pipeline

**CI/CD Pipeline**:
- No changes to GitHub Actions workflows
- No changes to Docker builds
- No changes to ArgoCD sync behavior

---

## Risks & Mitigation

### Technical Risks

**Risk 1: Claude Code Guidance Too Broad**
- **Impact**: Medium - Might suppress legitimate security concerns
- **Likelihood**: Low - Guidance is specific to development phase
- **Mitigation**:
  - Keep guidance minimal and specific
  - Explicitly state it doesn't apply to PR reviews
  - Test behavior with both development and PR scenarios

**Risk 2: Educational Content Inaccuracy**
- **Impact**: Low - Embarrassing but not breaking
- **Likelihood**: Low - Can verify facts easily
- **Mitigation**:
  - Research spider anatomy from reliable sources
  - Keep facts simple and verifiable
  - Focus on well-known spider characteristics

**Risk 3: V3 Surprise Spoiled by Comments**
- **Impact**: Low - Reduces demo impact
- **Likelihood**: Medium - Balance is tricky
- **Mitigation**:
  - Keep v3 comments vague but intriguing
  - Test with someone unfamiliar with the changes
  - Iterate on comment wording if needed

### Process Risks

**Risk 4: Comments Become Stale**
- **Impact**: Low - Confusing but not breaking
- **Likelihood**: Low - Images don't change often
- **Mitigation**:
  - Comments are tied to specific versions
  - Version system keeps them aligned
  - Easy to update if images change

---

## Timeline & Phases

### Phase 1: Foundation (Day 1)
- Add Claude Code guidance to `.claude/CLAUDE.md`
- Update development scripts with version output
- Test basic functionality

### Phase 2: Content Creation (Day 2)
- Write v1 baseline comments
- Research and write v2 educational content
- Draft v3 comic relief comments

### Phase 3: Integration & Testing (Day 3)
- Add all comments to React components
- Test full version cycle
- Validate Claude Code behavior
- Test demo presentation flow

**Total Estimated Time**: 3 days

---

## Open Questions

1. **Spider Anatomy Depth**: How technical should the v2 educational content be?
   - Current plan: Accessible to general audiences, focus on 2-3 key facts

2. **V3 Reveal Timing**: Should v3 comments hint at what changed or just that something changed?
   - Current plan: Hint that changes were made for audience comfort, not specifics

3. **Additional Versions**: Should we consider v4+ in the future?
   - Current plan: Stop at v3 for now, narrative arc is complete

---

## Progress Log

### 2025-10-28: PRD Created
- Initial PRD drafted based on user requirements
- Narrative progression defined: friendly → educational → comic relief
- Claude Code guidance approach established
- Six major milestones defined for implementation

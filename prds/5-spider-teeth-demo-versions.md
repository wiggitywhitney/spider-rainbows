# PRD: Add Teeth to Spider Images for Demo Versions

**GitHub Issue**: [#5](https://github.com/wiggitywhitney/spider-rainbows/issues/5)
**Status**: Ready for Implementation
**Created**: 2025-10-23
**Priority**: High

---

## Problem Statement

The conference demo needs visually obvious changes between application versions (v1, v2, v3) to demonstrate the complete GitOps CI/CD pipeline to a live audience. When code changes are pushed during the talk, attendees need to immediately see the difference in the deployed application to understand that the automation is working.

Currently, the spider images are static. Without obvious visual changes, the demo flow (code push → CI build → GitOps update → ArgoCD sync → deployment) won't have clear visual impact for the audience.

---

## Solution Overview

Add progressive teeth variations to both spider images across three versions:

- **v1 (Current)**: No teeth - baseline version
- **v2**: Dracula-style vampire teeth - fun and obviously different
- **v3**: Anatomically correct spider fangs and straw-like mouth - creepy and scientifically accurate

Both `Spider.png` (single spider) and `spidersspidersspiders.png` (spider swarm) will receive teeth updates.

This creates a clear visual progression that:
- Is immediately visible to audience members viewing the app
- Provides a fun narrative arc (cute → vampire → scary realistic)
- Demonstrates the GitOps pipeline with confidence
- Makes for an entertaining stage moment

---

## User Journey

### Conference Demo Flow

**Pre-Demo Setup:**
1. Presenter runs `./kind/setup-platform.sh` to create GitOps environment
2. App deploys with v1 (no teeth) spider images
3. Audience pulls up app URL on their devices: `http://spider-rainbows.127.0.0.1.nip.io` or presenter's public demo URL
4. Audience sees current spider (no teeth)

**Live Demo - Version 2:**
1. Presenter makes code change: swaps `Spider.png` and `Spider-v2-dracula.png`
2. Presenter commits and pushes to trigger CI/CD
3. GitHub Actions builds new image with v2 spiders (dracula teeth)
4. CI/CD updates GitOps repo with new image tag
5. ArgoCD detects change and syncs to cluster
6. Audience refreshes app and sees **vampire teeth** - visible proof of automation
7. Presenter tells funny story about the teeth

**Live Demo - Version 3:**
1. Presenter makes another code change: swaps to `Spider-v3-realistic.png`
2. Same automated flow as v2
3. Audience refreshes and sees **anatomically correct spider fangs**
4. Demonstrates repeatability of GitOps pipeline

---

## Technical Scope

### Assets Required

**New Image Files** (User will provide):
- `public/Spider-v2-dracula.png` - Single spider with Dracula teeth (matches Spider.png dimensions: 532 x 284)
- `public/spidersspidersspiders-v2-dracula.png` - Spider swarm with Dracula teeth (matches 2400 x 1600)
- `public/Spider-v3-realistic.png` - Single spider with anatomical fangs
- `public/spidersspidersspiders-v3-realistic.png` - Spider swarm with anatomical fangs

**Code Changes Required**:
- Update `src/components/SpiderImage.jsx` to reference new v2 or v3 image files
- Update `src/components/SurpriseSpider.jsx` to reference new v2 or v3 swarm files
- No component logic changes needed - just image path updates

### Git Strategy for Demo

**Branch/Tag Strategy:**
- v1: Already on main (current production)
- v2: Create changes live during demo, push to main
- v3: Create changes live during demo, push to main

**Image Naming Convention:**
Original approach - keep same filenames, swap files:
- Fast to execute on stage (just file swap + git commands)
- Image references in code stay the same
- Clear git diff shows file content changed

Alternative approach - versioned filenames:
- Keep all versions in repo simultaneously
- Update code to reference different filename
- Easier to prepare but more complex code changes on stage

**Recommendation**: Use file swap approach for speed during live demo.

### Integration Points

**With Existing CI/CD Pipeline:**
- No changes needed to `.github/workflows/build-push.yml`
- Pipeline already builds/tags images with commit SHA
- Pipeline already updates GitOps repo automatically

**With Existing App:**
- No component logic changes
- No state management changes
- Only image file paths change

**With GitOps Platform:**
- ArgoCD auto-sync already configured
- No ArgoCD Application changes needed
- Platform already set up to detect and deploy changes

---

## Success Criteria

### Functional Requirements
- [ ] v2 spider images (both single and swarm) have Dracula-style teeth
- [ ] v3 spider images (both single and swarm) have anatomically correct spider fangs
- [ ] Image dimensions match original files exactly (no layout breaking)
- [ ] PNG transparency preserved (spiders still overlay rainbow correctly)
- [ ] All three versions tested locally before conference

### Demo Requirements
- [ ] Code changes can be made quickly on stage (< 60 seconds)
- [ ] Git commit/push workflow is smooth and rehearsed
- [ ] CI/CD pipeline completes within demo timeframe (< 2 minutes)
- [ ] Visual changes are obvious to audience from a distance
- [ ] Funny story about teeth is prepared and practiced

### Technical Requirements
- [ ] Images optimized for web (reasonable file size)
- [ ] No console errors when loading new images
- [ ] Health endpoint still returns 200 OK after image swaps
- [ ] App functionality unchanged (spider add/remove still works)

---

## Milestones

### Milestone 1: Image Assets Created
- [ ] User provides v2 Dracula teeth spider images (both single and swarm)
- [ ] User provides v3 realistic fangs spider images (both single and swarm)
- [ ] Images match required dimensions and format
- [ ] Images reviewed and approved for visual quality

**Success Criteria**: All four new image files exist and look good

---

### Milestone 2: v2 Changes Prepared and Tested
- [ ] v2 images added to `public/` directory
- [ ] Code updated to reference v2 images (SpiderImage.jsx, SurpriseSpider.jsx)
- [ ] Changes tested locally with `npm run dev`
- [ ] Changes tested in Docker container
- [ ] Changes tested in local Kind cluster with ArgoCD
- [ ] Visual appearance verified for both regular and surprise spiders

**Success Criteria**: v2 version works perfectly in local environment, ready to push live during demo

---

### Milestone 3: v3 Changes Prepared and Tested
- [ ] v3 images added to `public/` directory
- [ ] Code updated to reference v3 images (SpiderImage.jsx, SurpriseSpider.jsx)
- [ ] Changes tested locally with `npm run dev`
- [ ] Changes tested in Docker container
- [ ] Changes tested in local Kind cluster with ArgoCD
- [ ] Visual appearance verified for both regular and surprise spiders

**Success Criteria**: v3 version works perfectly in local environment, ready to push live during demo

---

### Milestone 4: Demo Workflow Rehearsed
- [ ] Git workflow practiced: file swap → commit → push
- [ ] Timing validated: full pipeline completes within acceptable demo timeframe
- [ ] Rollback procedure tested (in case something goes wrong on stage)
- [ ] Audience view tested: changes visible on phones/laptops from audience distance
- [ ] Funny teeth story practiced and integrated into talk flow
- [ ] Backup plan documented (pre-built branches if live demo fails)

**Success Criteria**: Confident in executing demo workflow on stage, with backup plans ready

---

### Milestone 5: Production Ready for Conference
- [ ] All versions tested end-to-end in demo environment
- [ ] Demo script/notes finalized with teeth story
- [ ] Screenshots/photos taken for backup slides (if demo fails)
- [ ] Co-speaker briefed on teeth changes and timing
- [ ] Demo environment tested on conference venue network (if possible)
- [ ] Final rehearsal completed successfully

**Success Criteria**: Ready to deliver engaging demo with high confidence of success

---

## Implementation Notes

### File Swap Approach for Stage

**Quick Change Script** (optional - for speed on stage):
```bash
#!/bin/bash
# swap-to-v2.sh
cp public/Spider-v2-dracula.png public/Spider.png
cp public/spidersspidersspiders-v2-dracula.png public/spidersspidersspiders.png
git add public/
git commit -m "feat: add vampire teeth to spiders (v2)"
git push origin main
```

```bash
#!/bin/bash
# swap-to-v3.sh
cp public/Spider-v3-realistic.png public/Spider.png
cp public/spidersspidersspiders-v3-realistic.png public/spidersspidersspiders.png
git add public/
git commit -m "feat: add realistic spider fangs (v3)"
git push origin main
```

### Image Optimization Tips

- Export PNGs with transparency preserved
- Target file size: < 500 KB for single spider, < 1.5 MB for swarm
- Use PNG compression tools if needed (TinyPNG, ImageOptim)
- Maintain exact dimensions of original files

### Backup Strategy

If live demo fails:
1. Pre-built branches with v2/v3 already committed
2. Screenshots of each version to show in slides
3. Pre-recorded video of pipeline in action
4. Ability to manually kubectl delete pod to force image pull

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Image file sizes too large, slow load | Medium - delays demo | Low | Optimize images beforehand, test load times |
| Git conflict during live push | High - breaks demo flow | Low | Rehearse workflow, use clean repo state |
| CI/CD pipeline timeout | High - no visible change | Medium | Test pipeline timing, have backup branches |
| ArgoCD doesn't detect change | High - manual intervention needed | Low | Verify auto-sync working before talk |
| Teeth not visible to audience | Medium - less impactful demo | Medium | Test on various screens, make teeth prominent |
| File swap script fails on stage | Medium - manual commands needed | Low | Practice manual commands as backup |

---

## Out of Scope

The following are explicitly **NOT** included:
- Animation of teeth (static images only)
- Multiple teeth variations beyond v2 and v3
- Different teeth for regular vs surprise spider
- User-configurable teeth options
- Teeth for other demo elements (rainbow, clouds, etc.)
- Automated teeth generation or AI-assisted image editing

---

## Dependencies

- User must provide high-quality teeth images
- Existing CI/CD pipeline must be working
- Local Kind cluster with ArgoCD must be set up
- Conference venue must have reliable internet (for GitOps sync)
- Presenter must have git/docker/kind configured correctly

---

## Progress Log

### 2025-10-23: PRD Created
- GitHub issue #5 created with PRD label
- PRD file created with comprehensive planning
- Requirements gathered through Q&A with user
- Milestone structure established
- Ready for image asset creation

---

## Questions & Decisions

### Open Questions
- What's the target conference date? (User managing timeline)
- Do we want to create swap scripts for speed, or manual git commands?
- Should we keep all image versions in repo, or swap files?

### Resolved Decisions

**Decision 1: Scope of Changes**
- **Decision**: Add teeth to both Spider.png and spidersspidersspiders.png
- **Rationale**: Consistency across all spider appearances in the app
- **Impact**: Need 4 total new images (2 for v2, 2 for v3)

**Decision 2: Version Progression**
- **Decision**: v1 (no teeth) → v2 (Dracula teeth) → v3 (realistic spider fangs)
- **Rationale**: Creates fun narrative arc with increasing realism
- **Impact**: Provides clear visual progression for audience

**Decision 3: Image Creation**
- **Decision**: User will create and provide all new spider images
- **Rationale**: User preference for creative control
- **Impact**: PRD focuses on integration, not image creation process

**Decision 4: Testing Strategy**
- **Decision**: Test changes in local Kind cluster, then push live during demo via CI/CD
- **Rationale**: Demonstrates full GitOps automation to audience
- **Impact**: Requires thorough pre-demo rehearsal and backup plans

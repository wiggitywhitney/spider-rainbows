# PRD: Spider-Rainbows Interactive Demo App

**Status**: In Progress
**Priority**: High
**GitHub Issue**: [#1](https://github.com/wiggitywhitney/spider-rainbows/issues/1)
**Created**: 2025-10-16

---

## Overview

Interactive React demo application featuring a rainbow image with spider add/remove functionality and a delightful easter egg. Built for platform engineering demonstrations where the goal is to provide an amusing, containerized application that showcases deployment capabilities.

**Tech Stack**: React 19 + Vite + Express.js + Docker

---

## Problem Statement

Platform engineering demonstrations require an application that is:
- Visually engaging and amusing to capture attention
- Simple enough to deploy quickly in demo scenarios
- Complex enough to demonstrate real-world containerization
- Interactive to show live functionality during presentations

---

## Solution

A React-based web application featuring:
- Static rainbow background image
- Interactive button to add/remove a spider
- **85% probability**: Single spider appears on the rainbow
- **15% probability**: Easter egg triggers - spider swarm covers the entire rainbow with dramatic button styling
- Responsive design that works across screen sizes
- Fully containerized in Docker with health monitoring

---

## User Journey

### Normal Flow (85% probability)
1. User sees rainbow with button labeled "Add spider?"
2. User clicks button
3. Single spider appears at top of rainbow (25% of rainbow width)
4. Rainbow opacity fades from 100% to 75%
5. Button text changes to "Remove spider?"
6. User clicks button again
7. Spider disappears
8. Rainbow returns to 100% opacity
9. Button resets to "Add spider?"

### Easter Egg Flow (15% probability)
1. User sees rainbow with button labeled "Add spider?"
2. User clicks button
3. Spider swarm image fills entire rainbow
4. Rainbow opacity fades from 100% to 75%
5. Button text changes to "AHHHHHH!!!"
6. Button gains black outline styling (box-shadow)
7. User clicks "AHHHHHH!!!" button
8. Spider swarm disappears
9. Rainbow returns to 100% opacity
10. Button resets to "Add spider?"

---

## Technical Architecture

### Component Structure

```
App.jsx (Main Orchestrator)
├── State Management
│   ├── spiderVisible (boolean)
│   ├── spiderType ('regular' | 'surprise' | null)
│   └── rainbowWidth (number)
├── Rainbow.jsx (Image with opacity control)
├── AddSpiderButton.jsx (Three text states)
├── SpiderImage.jsx (Regular single spider)
├── SurpriseSpider.jsx (Easter egg swarm)
└── utils/spiderUtils.js (Probability logic)
```

### State Management
```javascript
const [spiderVisible, setSpiderVisible] = useState(false);
const [spiderType, setSpiderType] = useState(null); // 'regular' | 'surprise' | null
const [rainbowWidth, setRainbowWidth] = useState(0);
```

### Easter Egg Implementation
```javascript
// spiderUtils.js
export const selectSpiderType = () => {
  const random = Math.random();
  return random < 0.15 ? 'surprise' : 'regular';
};
```

### Visual Specifications

#### Button States
| State | Text | Additional Styling |
|-------|------|-------------------|
| No spider | "Add spider?" | Default |
| Regular spider | "Remove spider?" | Default |
| Surprise spider | "AHHHHHH!!!" | Black outline (box-shadow: 0 0 0 2px black) |

#### Button Styling
- **Font**: Custom spider font (spider-font.ttf)
- **Font Size**: 31px
- **Padding**: 10px 21px
- **Background**: White
- **Border**: 2px white
- **Position**: Bottom left (25% from left edge, below left cloud)

#### Spider Positioning

**Regular Spider:**
- Position: Top 10% of rainbow container
- Width: 25% of rainbow width
- Z-index: 5
- Centered horizontally

**Surprise Spider:**
- Position: Fills entire rainbow container (absolute positioning: 0, 0, 0, 0)
- Size: Full width/height with `object-fit: contain`
- Z-index: 10
- Centered with flexbox

#### Z-index Layering
```
Button (z-index: 11)
  ↓
Surprise Spider (z-index: 10)
  ↓
Regular Spider (z-index: 5)
  ↓
Rainbow (z-index: 0)
```

#### Rainbow Opacity
- **No spider**: 100% opacity
- **Spider present**: 75% opacity
- Applied via inline style based on `isSpiderPresent` prop

### Responsive Design
- Rainbow layout: `width: 80%; max-width: none;`
- Dynamic width calculation using ref and resize listeners
- Spider sizing scales relative to rainbow width
- Mobile-friendly touch interactions

### Assets Required

Located in `/public/` directory:

| Asset | Dimensions | Size | Purpose |
|-------|-----------|------|---------|
| Rainbow.png | 2173 x 1184 | 363 KB | Main background rainbow image |
| Spider.png | 532 x 284 | 43 KB | Single regular spider |
| spidersspidersspiders.png | 2400 x 1600 | 1.1 MB | Easter egg spider swarm |
| fonts/spider-font.ttf | - | - | Custom button font |

**Source**: https://github.com/wiggitywhitney/vibe_practice/tree/main/public

### Docker Configuration

**Container Setup**: Single container
- Runs both Vite dev server (port 8080) and Express health server (port 3001)
- Node.js base image
- Exposes ports 8080 (frontend) and 3001 (health monitoring)
- Health check endpoint: `GET /health`

### NPM Scripts
- `npm run dev` - Start Vite dev server (port 8080)
- `npm run health` - Start Express health server (port 3001)
- `npm run build` - Production build
- `npm run preview` - Preview production build

### Configuration Files
- `vite.config.js` - Vite configuration (port 8080, React plugin)
- `babel.config.js` - Babel transformations
- `eslint.config.js` - Code quality rules
- `package.json` - Dependencies and scripts

---

## Milestones

### Milestone 1: Project Foundation Ready
- [x] React + Vite project initialized with proper folder structure
- [x] Dependencies installed (React 19, Vite, Express)
- [x] All configuration files created (vite.config.js, babel.config.js, eslint.config.js)
- [x] Package.json scripts configured
- [x] Basic project structure verified and building

**Success Criteria**: `npm run dev` starts Vite successfully, no build errors ✅

### Milestone 2: Assets Acquired and Integrated
- [ ] All four assets downloaded from vibe_practice repo
- [ ] Images placed in `/public/` directory (Rainbow.png, Spider.png, spidersspidersspiders.png)
- [ ] Custom font placed in `/public/fonts/` directory (spider-font.ttf)
- [ ] Font imported and configured in CSS
- [ ] Assets loading correctly in browser

**Success Criteria**: All images and font display correctly when referenced in components

### Milestone 3: Core React Components Implemented
- [ ] Rainbow.jsx component built with opacity control prop
- [ ] SpiderImage.jsx component created with positioning logic
- [ ] SurpriseSpider.jsx component created with full-screen layout
- [ ] AddSpiderButton.jsx component with three text state variations
- [ ] spiderUtils.js utility created with 15% probability logic
- [ ] All components rendering correctly in isolation

**Success Criteria**: Each component renders as expected with correct styling and positioning

### Milestone 4: Interactive Functionality Complete
- [ ] App.jsx state management implemented (spiderVisible, spiderType, rainbowWidth)
- [ ] Button click handler wired up correctly
- [ ] Probability logic integrated (15% surprise, 85% regular)
- [ ] Conditional rendering working for both spider types
- [ ] Rainbow opacity transition working
- [ ] Button text changing correctly based on spider state
- [ ] Button black outline appearing only for surprise spider
- [ ] Responsive width calculations working with ref and resize listeners
- [ ] Complete add/remove cycle working for both flows

**Success Criteria**: Manual testing confirms both normal and easter egg flows work correctly, responsive sizing functions properly

### Milestone 5: Docker Containerization Functional
- [x] Express health monitoring server implemented (port 3001)
- [x] Health check endpoint `/health` responding correctly
- [ ] Dockerfile created (single container, Node.js base)
- [ ] Ports 8080 and 3001 exposed and mapped correctly
- [ ] Container builds successfully
- [ ] Container runs with both Vite dev server and Express health server
- [ ] App accessible via browser at localhost:8080
- [ ] Health endpoint accessible at localhost:3001/health

**Success Criteria**: App runs completely within Docker container, both servers operational, health checks passing

### Milestone 6: Production Ready and Documented
- [ ] All behaviors manually verified (normal flow, easter egg flow)
- [ ] Responsive design tested on multiple screen sizes (mobile, tablet, desktop)
- [ ] Error handling graceful (missing assets, failed requests)
- [ ] Code quality verified (clean, well-commented, follows patterns)
- [ ] README.md created with setup, run, and Docker instructions
- [ ] All configuration and setup documented
- [ ] Final review complete

**Success Criteria**: Application is deployment-ready, all features work as specified, documentation is complete

---

## Success Criteria

### Functional Requirements
✅ App runs smoothly in Docker container
✅ Normal spider flow (85%) works correctly
✅ Easter egg flow (15%) works correctly and delights users
✅ Rainbow opacity transitions smoothly
✅ Button states change correctly based on spider type
✅ Responsive design works across multiple screen sizes
✅ Health monitoring endpoint responds correctly

### Quality Requirements
✅ Code is clean, well-organized, and documented
✅ Component separation follows specification
✅ Visual specifications match exactly (positioning, sizing, z-index)
✅ Custom font loads and displays correctly
✅ No console errors or warnings

### Documentation Requirements
✅ README includes setup and run instructions
✅ Docker instructions are clear
✅ Code comments explain key logic

---

## Out of Scope

The following are explicitly **NOT** included in this PRD:

- Automated testing (unit tests, integration tests, e2e tests)
- Analytics or user tracking
- Additional features beyond the specification
- Multiple deployment environments (staging, production)
- CI/CD pipeline configuration
- Performance optimization beyond basic best practices
- Accessibility enhancements beyond basic HTML semantics
- Backend data persistence
- User authentication or accounts
- Additional easter eggs or interactions
- Animation libraries or complex transitions
- State management libraries (Redux, MobX, etc.)

---

## Implementation Notes

### Key Architecture Decisions (from original implementation)

**What Worked Well:**
1. **Component separation** - Clean, focused components
2. **Simple state management** - useState is sufficient, no need for Context/Redux
3. **Z-index layering** - Clear visual hierarchy
4. **Probability utility** - Simple and effective Math.random() approach
5. **Responsive sizing** - Dynamic calculation from rainbow ref
6. **Opacity effect** - Subtle visual feedback enhances UX

**Design Choices:**
- 15% probability (not 10%) - based on original implementation testing
- Rainbow opacity fade to 75% - provides nice visual feedback
- Separate components for regular/surprise spiders - cleaner than conditional styling
- Custom font - adds personality and polish to the demo

### Technical Considerations

**Vite + React 19:**
- Fast HMR (Hot Module Replacement) for development
- React 19 features available if needed
- ES modules support required in Node.js

**Docker Strategy:**
- Single container simplifies deployment
- Express health server enables monitoring/orchestration
- Two exposed ports allow flexible deployment scenarios

**Responsive Approach:**
- Rainbow width tracked via ref
- Window resize listeners update spider sizing
- Touch-friendly for mobile demos

---

## Progress Log

### 2025-10-16 - PRD Created
- GitHub issue #1 created with PRD label
- PRD file created with comprehensive specification
- Ready to begin implementation

### 2025-10-16 - Milestone 1 Complete: Project Foundation Established
**Duration**: ~30 minutes
**Primary Focus**: React 19 + Vite + Express project setup

**Completed PRD Items**:
- [x] React + Vite project initialized with proper folder structure
- [x] Dependencies installed (React 19.2.0, Vite 5.4.20, Express 4.21.2)
- [x] All configuration files created (vite.config.js, babel.config.js, eslint.config.js)
- [x] Package.json scripts configured (dev, health, build, preview, lint)
- [x] Basic project structure verified and building
- [x] Express health monitoring server implemented (port 3001)
- [x] Health check endpoint `/health` responding correctly

**Files Created**:
- Configuration: `vite.config.js`, `babel.config.js`, `eslint.config.js`
- Backend: `server.js` (Express health monitoring)
- Frontend: `src/main.jsx`, `src/App.jsx`, `src/App.css`, `src/index.css`
- Entry: `index.html`
- Directories: `src/`, `public/`, `public/fonts/`

**Verified Working**:
- ✅ `npm run dev` starts Vite successfully on http://localhost:8080
- ✅ `npm run health` starts Express on http://localhost:3001
- ✅ Health endpoint returns proper JSON response
- ✅ No build errors or configuration issues

**Next Session Priorities**:
- Milestone 2: Acquire and integrate all assets (Rainbow.png, Spider.png, spidersspidersspiders.png, spider-font.ttf)
- Milestone 3: Build core React components (Rainbow, SpiderImage, SurpriseSpider, AddSpiderButton, spiderUtils)

---

## Questions & Decisions

### Resolved
✅ **Easter egg probability**: 15% (keeping original)
✅ **Rainbow opacity fade**: Yes, 75% when spider present
✅ **Component structure**: Separate regular/surprise components
✅ **Docker setup**: Single container
✅ **Assets**: Fetch from vibe_practice repo
✅ **Testing approach**: Manual verification only
✅ **Priority**: High
✅ **Audience**: Platform engineering demo - goal is to be amusing

### Open Questions
None at this time.

---

## References

- **PROJECT_SPEC.md**: Detailed technical specification
- **Reference Implementation**: https://github.com/wiggitywhitney/vibe_practice
- **Assets Source**: https://github.com/wiggitywhitney/vibe_practice/tree/main/public

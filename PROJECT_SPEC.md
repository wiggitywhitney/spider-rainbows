# Spider-Rainbows Demo App - Project Specification

## Project Vision

A fun, interactive React demo app featuring a static rainbow image with a button that adds/removes a spider. Includes a delightful easter egg where there's a 15% chance of triggering a spider swarm instead of a single spider.

## Core Behavior

### Normal Flow (85% probability)
1. User sees button with text: **"Add spider?"**
2. User clicks button
3. Single spider appears on the rainbow (positioned at top, 25% of rainbow width)
4. Rainbow opacity fades from 100% to 75%
5. Button text changes to: **"Remove spider?"**
6. User clicks button again
7. Spider disappears
8. Rainbow opacity returns to 100%
9. Button text returns to: **"Add spider?"**

### Easter Egg Flow (15% probability)
1. User sees button with text: **"Add spider?"**
2. User clicks button
3. **Spider swarm appears** (full-size image covering entire rainbow)
4. Rainbow opacity fades from 100% to 75%
5. Button text changes to: **"AHHHHHH!!!"**
6. Button gets black outline styling
7. User clicks "AHHHHHH!!!" button
8. Spider swarm disappears
9. Rainbow opacity returns to 100%
10. Button text returns to: **"Add spider?"**

## Technical Specifications

### Tech Stack
- **Frontend**: React 19 + Vite
- **Backend**: Express.js (health monitoring server on port 3001)
- **Build Tool**: Vite (dev server on port 8080)
- **Containerization**: Docker (single container setup)
- **Node.js**: ES modules support

### Architecture Decisions

#### Component Structure
- **App.jsx** - Main orchestrator component
  - Manages state: `spiderVisible` (boolean), `spiderType` ('regular' | 'surprise' | null)
  - Handles button click logic
  - Calculates responsive sizing
- **Rainbow.jsx** - Rainbow image component with opacity control
- **AddSpiderButton.jsx** - Toggle button with three text states
- **SpiderImage.jsx** - Regular single spider component
- **SurpriseSpider.jsx** - Easter egg spider swarm component
- **utils/spiderUtils.js** - Probability logic for spider type selection

#### State Management
```javascript
const [spiderVisible, setSpiderVisible] = useState(false);
const [spiderType, setSpiderType] = useState(null); // 'regular' | 'surprise' | null
const [rainbowWidth, setRainbowWidth] = useState(0);
```

#### Easter Egg Implementation
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
| Surprise spider | "AHHHHHH!!!" | Black outline (box-shadow) |

#### Button Styling
- **Font**: Custom spider font from `spider-font.ttf`
- **Font Size**: 31px
- **Padding**: 10px 21px
- **Background**: White
- **Border**: 2px white
- **Position**: Bottom left (25% from left edge, below left cloud)
- **Black Outline** (surprise mode): `box-shadow: 0 0 0 2px black`

#### Spider Positioning & Sizing

**Regular Spider:**
- Position: Top 10% of rainbow container
- Width: 25% of rainbow width
- Z-index: 5
- Centered horizontally

**Surprise Spider:**
- Position: Fills entire rainbow container (top: 0, left: 0, right: 0, bottom: 0)
- Size: Full width/height with `object-fit: contain`
- Z-index: 10
- Centered with flexbox

#### Rainbow Opacity Effect
- **No spider**: 100% opacity
- **Spider present**: 75% opacity
- Applied via inline style based on `isSpiderPresent` prop

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

### Assets Required

Located in `/public/` directory:

| Asset | Dimensions | Size | Purpose |
|-------|-----------|------|---------|
| **Rainbow.png** | 2173 x 1184 | 363 KB | Main background rainbow image |
| **Spider.png** | 532 x 284 | 43 KB | Single regular spider |
| **spidersspidersspiders.png** | 2400 x 1600 | 1.1 MB | Easter egg spider swarm |
| **fonts/spider-font.ttf** | - | - | Custom button font |

**Source**: Assets can be pulled from existing implementation at:
`https://github.com/wiggitywhitney/vibe_practice/tree/main/public`

### Docker Configuration

**Container Setup**: Single container
- Runs both Vite dev server (port 8080) and Express health server (port 3001)
- Or: Production build served by Express

**Requirements**:
- Node.js base image
- Expose ports 8080 (Vite/frontend) and 3001 (health monitoring)
- Install dependencies (npm install)
- Copy source files and assets
- Health check endpoint: `GET /health`

### Responsive Design

- Rainbow layout: `width: 80%; max-width: none;`
- Dynamic width calculation using ref and resize listeners
- Spider sizing scales relative to rainbow width
- Mobile-friendly touch interactions

## Development Workflow

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

## Key Learnings from Original Implementation

### What Worked Well
1. **Component separation** - Clean components
2. **Simple state management** - No need for Redux/Context
3. **Z-index layering** - Clear visual hierarchy
4. **Probability utility** - Simple and effective
5. **Responsive sizing** - Dynamic calculation from rainbow ref
6. **Opacity effect** - Subtle visual feedback

### Implementation Notes
- Original used 15% probability (not 10%) - keeping at 15%
- Rainbow opacity fade is a nice touch - keeping it
- Custom font adds personality to the button
- Separate images for regular vs surprise spiders works well
- Health monitoring server provides good foundation for Docker

### Architecture Strengths
- Vite provides fast HMR (Hot Module Replacement)
- React 19 features (if using concurrent features)
- Express health server enables monitoring/orchestration

## Implementation Approach for New Build

### Phase 1: Project Setup
1. Initialize new React + Vite project
2. Install dependencies (React, Vite, Express)
3. Set up folder structure matching specification
4. Copy/download assets from original repo

### Phase 2: Core Components
1. Build Rainbow component with opacity control
2. Build AddSpiderButton with three states
3. Build SpiderImage (regular spider)
4. Build SurpriseSpider (swarm)
5. Implement spiderUtils probability logic

### Phase 3: Main App Logic
1. Implement state management in App.jsx
2. Wire up button click handler
3. Add conditional rendering for spider types
4. Implement responsive width calculations
5. Add window resize listeners

### Phase 4: Styling
1. Import and configure custom spider font
2. Style button with all three states
3. Position components with absolute/relative positioning
4. Implement z-index layering
5. Add rainbow opacity transitions

### Phase 5: Docker & Health Monitoring
1. Set up Express health server
2. Create Dockerfile (single container)
3. Configure port mappings (8080, 3001)
4. Add health check endpoint
5. Test container build and run

### Phase 6: Polish
1. Verify all easter egg behaviors
2. Test responsive design on multiple screen sizes
3. Ensure graceful error handling
4. Add README documentation
5. Final review

## Questions Resolved

✅ Easter egg probability: **15%** (keeping original)
✅ Rainbow opacity fade: **Yes, 75% when spider present**
✅ Component structure: **Yes, separate regular/surprise components**
✅ Docker setup: **Single container**
✅ Assets: **Same images/font from original repo**

## Project Goals

- Clean, from-scratch implementation
- Containerized with Docker
- Fun, interactive demo
- Delightful easter egg experience
- Production-ready code structure

---

**Repository**: https://github.com/wiggitywhitney/spider-rainbows (new implementation)
**Reference Repo**: https://github.com/wiggitywhitney/vibe_practice (original implementation)
**Created**: 2025-10-16

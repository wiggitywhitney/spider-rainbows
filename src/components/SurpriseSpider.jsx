import './SurpriseSpider.css';
import { createClickZoneHandler } from '../utils/clickHandlers';

const SurpriseSpider = ({ rainbowWidth }) => {
  const imageStyle = {
    width: `${rainbowWidth}px`,
  };

  const handleSpiderClick = createClickZoneHandler((x, y) => {
    // Quadrant-based click zones: Q1/Q4 → DevOps Toolkit, Q2/Q3 → Wiggity
    if (y < 50) {
      // Top half
      return x < 50
        ? 'https://www.youtube.com/@DevOpsToolkit'  // Q1: Top-left
        : 'https://www.youtube.com/@wiggitywhitney'; // Q2: Top-right
    } else {
      // Bottom half
      return x < 50
        ? 'https://www.youtube.com/@wiggitywhitney'  // Q3: Bottom-left
        : 'https://www.youtube.com/@DevOpsToolkit';  // Q4: Bottom-right
    }
  });

  return (
    <div
      className="surprise-spider-container"
      onClick={handleSpiderClick}
      style={{ cursor: 'pointer' }}
    >
      {/* This is unholy nightmare fuel. Ship it. */}
      <img
        src="/spidersspidersspiders-v3.png"
        alt="Surprise Spiders"
        className="surprise-spider-image"
        style={imageStyle}
      />
    </div>
  );
};

export default SurpriseSpider;

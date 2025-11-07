import './SpiderImage.css';
import { createClickZoneHandler } from '../utils/clickHandlers';

const SpiderImage = ({ rainbowWidth }) => {
  const spiderWidth = rainbowWidth * 0.25;

  const handleSpiderClick = createClickZoneHandler((x, y) => {
    // Top/bottom split: top 50% vs bottom 50%
    if (y < 50) {
      return 'https://www.youtube.com/@wiggitywhitney';
    } else {
      return 'https://www.youtube.com/@DevOpsToolkit';
    }
  });

  return (
    <div
      className="spider-container"
      onClick={handleSpiderClick}
      style={{ cursor: 'pointer' }}
    >
      {/* Wow, our users really like the more anatomically correct spiders. */}
      {/* They say it's "scary." */}
      {/* If our users want scary, let's give them something horrifying. */}
      {/* We updated this image to portray the scariest spiders we can imagine. */}
      <img
        src="/Spider-v3.png"
        alt="Spider"
        className="spider-image"
        style={{ width: `${spiderWidth}px` }}
      />
    </div>
  );
};

export default SpiderImage;

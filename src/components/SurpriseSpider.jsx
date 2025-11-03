import './SurpriseSpider.css';

const SurpriseSpider = ({ rainbowWidth }) => {
  const imageStyle = {
    width: `${rainbowWidth}px`,
  };

  const handleSpiderClick = (event) => {
    const container = event.currentTarget;
    const rect = container.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const clickY = event.clientY - rect.top;
    const clickPercentageX = (clickX / rect.width) * 100;
    const clickPercentageY = (clickY / rect.height) * 100;

    // Quadrant-based click zones: Q1/Q4 → DevOps Toolkit, Q2/Q3 → Wiggity
    if (clickPercentageY < 50) {
      // Top half
      if (clickPercentageX < 50) {
        // Q1: Top-left
        window.open('https://www.youtube.com/@DevOpsToolkit', '_blank', 'noopener,noreferrer');
      } else {
        // Q2: Top-right
        window.open('https://www.youtube.com/@wiggitywhitney', '_blank', 'noopener,noreferrer');
      }
    } else {
      // Bottom half
      if (clickPercentageX < 50) {
        // Q3: Bottom-left
        window.open('https://www.youtube.com/@wiggitywhitney', '_blank', 'noopener,noreferrer');
      } else {
        // Q4: Bottom-right
        window.open('https://www.youtube.com/@DevOpsToolkit', '_blank', 'noopener,noreferrer');
      }
    }
  };

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

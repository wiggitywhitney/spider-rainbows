import './SpiderImage.css';

const SpiderImage = ({ rainbowWidth }) => {
  const spiderWidth = rainbowWidth * 0.25;

  const handleSpiderClick = (event) => {
    const container = event.currentTarget;
    const rect = container.getBoundingClientRect();
    const clickY = event.clientY - rect.top;
    const clickPercentage = (clickY / rect.height) * 100;

    if (clickPercentage < 50) {
      window.open('https://www.youtube.com/@wiggitywhitney', '_blank', 'noopener,noreferrer');
    } else {
      window.open('https://www.youtube.com/@DevOpsToolkit', '_blank', 'noopener,noreferrer');
    }
  };

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

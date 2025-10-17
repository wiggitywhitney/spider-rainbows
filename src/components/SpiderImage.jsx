import './SpiderImage.css';

const SpiderImage = ({ rainbowWidth }) => {
  const spiderWidth = rainbowWidth * 0.25;

  return (
    <div className="spider-container">
      <img
        src="/Spider.png"
        alt="Spider"
        className="spider-image"
        style={{ width: `${spiderWidth}px` }}
      />
    </div>
  );
};

export default SpiderImage;

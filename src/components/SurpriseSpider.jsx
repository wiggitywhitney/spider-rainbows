import './SurpriseSpider.css';

const SurpriseSpider = ({ rainbowWidth }) => {
  const imageStyle = {
    width: `${rainbowWidth}px`,
  };


  return (
    <div
      className="surprise-spider-container"
      
      
    >
      {/* This is unholy nightmare fuel. Ship it. */}
      <img
        src="/spidersspidersspiders-v2.png"
        alt="Surprise Spiders"
        className="surprise-spider-image"
        style={imageStyle}
      />
    </div>
  );
};

export default SurpriseSpider;

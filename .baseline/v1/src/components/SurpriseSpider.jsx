import './SurpriseSpider.css';

const SurpriseSpider = ({ rainbowWidth }) => {
  const imageStyle = {
    width: `${rainbowWidth}px`,
  };

  return (
    <div className="surprise-spider-container">
      <img
        src="/spidersspidersspiders-v1.png"
        alt="Surprise Spiders"
        className="surprise-spider-image"
        style={imageStyle}
      />
    </div>
  );
};

export default SurpriseSpider;

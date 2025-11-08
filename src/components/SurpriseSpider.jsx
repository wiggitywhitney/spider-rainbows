import './SurpriseSpider.css';

const SurpriseSpider = ({ rainbowWidth }) => {
  const imageStyle = {
    width: `${rainbowWidth}px`,
  };

  return (
    <div className="surprise-spider-container">
      {/* Again, spiders DO NOT HAVE TEETH. */}
      {/* They slurp up fly-soup through little mouth-straws! */}
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

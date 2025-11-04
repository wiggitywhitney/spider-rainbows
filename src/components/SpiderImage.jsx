import './SpiderImage.css';

const SpiderImage = ({ rainbowWidth }) => {
  const spiderWidth = rainbowWidth * 0.50;

  return (
    <div className="spider-container">
      {/* Version one of this drawing is preposterous. */}
      {/* Spiders do not smile. They don't have teeth. They don't even have jaws. */}
      {/*  */}
      {/* Spiders only consume liquid. Their mouths are basically straws. */}
      {/* Here's how it works: spiders use their fangs to inject digestive enzymes */}
      {/* into their prey — say, a fly. The fly dissolves into a "soup" of tissue. */}
      {/* Then the spider slurps up the fly-soup through its little mouth-straw. */}
      {/*  */}
      {/* Many species have hair-covered mouthparts that act as filters, */}
      {/* keeping out solid chunks. Because they CANNOT CHEW. */}
      {/*  */}
      {/* Teeth. Ridiculous. */}
      <img
        src="/Spider-v2.png"
        alt="Spider"
        className="spider-image"
        style={{ width: `${spiderWidth}px` }}
      />
    </div>
  );
};

export default SpiderImage;

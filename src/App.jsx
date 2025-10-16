import React, { useState, useRef, useEffect } from 'react';
import Rainbow from './components/Rainbow';
import AddSpiderButton from './components/AddSpiderButton';
import SpiderImage from './components/SpiderImage';
import SurpriseSpider from './components/SurpriseSpider';
import { selectSpiderType } from './utils/spiderUtils';
import './App.css';

const App = () => {
  const [spiderVisible, setSpiderVisible] = useState(false);
  const [spiderType, setSpiderType] = useState(null);
  const [rainbowWidth, setRainbowWidth] = useState(0);
  const rainbowRef = useRef(null);

  useEffect(() => {
    const updateRainbowWidth = () => {
      if (rainbowRef.current) {
        const currentWidth = rainbowRef.current.offsetWidth;
        setRainbowWidth(currentWidth);
      }
    };

    updateRainbowWidth();
    const timeoutId = setTimeout(updateRainbowWidth, 50);

    window.addEventListener('resize', updateRainbowWidth);
    return () => {
      clearTimeout(timeoutId);
      window.removeEventListener('resize', updateRainbowWidth);
    };
  }, []);

  const handleSpiderButtonClick = () => {
    if (!spiderVisible) {
      const type = selectSpiderType();
      setSpiderType(type);
      setSpiderVisible(true);
    } else {
      setSpiderVisible(false);
      setSpiderType(null);
    }
  };

  const isSurpriseSpiderActive = spiderVisible && spiderType === 'surprise';

  return (
    <div className="app-container">
      <div className="rainbow-layout">
        <Rainbow
          ref={rainbowRef}
          isSpiderPresent={spiderVisible}
        />

        {spiderVisible && spiderType === 'regular' && (
          <SpiderImage rainbowWidth={rainbowWidth} />
        )}

        {spiderVisible && spiderType === 'surprise' && (
          <SurpriseSpider rainbowWidth={rainbowWidth} />
        )}

        <AddSpiderButton
          onClick={handleSpiderButtonClick}
          isSpiderPresent={spiderVisible}
          shouldHaveOutline={isSurpriseSpiderActive}
        />
      </div>
    </div>
  );
};

export default App;

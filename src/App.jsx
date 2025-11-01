import { useState, useRef, useEffect } from 'react';
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
    if (!rainbowRef.current) return;

    const el = rainbowRef.current;
    const ro = new ResizeObserver(() => {
      setRainbowWidth(el.offsetWidth);
    });

    ro.observe(el);
    // Initialize width on mount
    setRainbowWidth(el.offsetWidth);

    return () => ro.disconnect();
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
      <div style={{
        backgroundColor: '#4CAF50',
        color: 'white',
        padding: '10px',
        textAlign: 'center',
        fontWeight: 'bold',
        marginBottom: '20px'
      }}>
        🚀 CI/CD Test - Milestone 4 GitOps Flow
      </div>
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

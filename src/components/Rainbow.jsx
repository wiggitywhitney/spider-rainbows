import { forwardRef } from 'react';
import './Rainbow.css';

const Rainbow = forwardRef(({ isSpiderPresent }, ref) => {
  return (
    <div
      ref={ref}
      className={`rainbow-container ${isSpiderPresent ? 'is-present' : ''}`}
    >
      <img
        src="/Rainbow.png"
        alt="Rainbow"
        className="rainbow-image"
      />
    </div>
  );
});

Rainbow.displayName = 'Rainbow';

export default Rainbow;
export { Rainbow };

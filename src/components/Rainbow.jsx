import React from 'react';
import './Rainbow.css';

const Rainbow = React.forwardRef(({ isSpiderPresent }, ref) => {
  return (
    <div
      ref={ref}
      className="rainbow-container"
      style={{ opacity: isSpiderPresent ? 0.75 : 1 }}
    >
      <img
        src="/Rainbow.png"
        alt="Rainbow"
        className="rainbow-image"
      />
    </div>
  );
});

export default Rainbow;
export { Rainbow };

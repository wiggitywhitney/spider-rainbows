import { forwardRef } from 'react';
import './Rainbow.css';

const Rainbow = forwardRef(({ isSpiderPresent }, ref) => {
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

Rainbow.displayName = 'Rainbow';

export default Rainbow;
export { Rainbow };

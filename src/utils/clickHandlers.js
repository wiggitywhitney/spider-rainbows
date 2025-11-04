/**
 * Creates a click handler for interactive image zones
 *
 * @param {Function} zoneMapper - Function that maps (percentageX, percentageY) to a URL
 * @returns {Function} Click event handler
 */
export const createClickZoneHandler = (zoneMapper) => (event) => {
  const container = event.currentTarget;
  const rect = container.getBoundingClientRect();
  const clickX = event.clientX - rect.left;
  const clickY = event.clientY - rect.top;
  const percentageX = (clickX / rect.width) * 100;
  const percentageY = (clickY / rect.height) * 100;

  const url = zoneMapper(percentageX, percentageY);
  if (url) {
    const newWindow = window.open(url, '_blank', 'noopener,noreferrer');
    if (!newWindow) {
      console.warn('Popup blocked: Please allow popups to open external links');
    }
  }
};

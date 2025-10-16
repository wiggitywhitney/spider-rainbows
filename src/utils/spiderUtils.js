/**
 * Determines which spider type to display based on random probability
 * @returns {string} 'regular' or 'surprise'
 */
export const selectSpiderType = () => {
  const random = Math.random();
  return random < 0.15 ? 'surprise' : 'regular';
};

import './AddSpiderButton.css';

const AddSpiderButton = ({ onClick, isSpiderPresent, shouldHaveOutline }) => {
  const buttonClasses = ['add-spider-button'];
  if (shouldHaveOutline) {
    buttonClasses.push('black-outline');
  }

  let buttonText;
  if (shouldHaveOutline) {
    buttonText = 'AHHHHHH!!!';
  } else if (isSpiderPresent) {
    buttonText = 'Remove spider?';
  } else {
    buttonText = 'Add spider?';
  }

  return (
    <div className="add-spider-container lower-left">
      <button
        className={buttonClasses.join(' ')}
        onClick={onClick}
      >
        {buttonText}
      </button>
    </div>
  );
};

export default AddSpiderButton;

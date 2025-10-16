import { useState } from 'react'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="app">
      <h1>Spider Rainbows Demo</h1>
      <p>Foundation is ready! Count: {count}</p>
      <button onClick={() => setCount((count) => count + 1)}>
        Test Button
      </button>
      <p className="info">
        Next step: Acquire assets and implement spider functionality
      </p>
    </div>
  )
}

export default App

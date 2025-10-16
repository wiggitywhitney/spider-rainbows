import express from 'express'

const app = express()
const PORT = 3001

// Health check endpoint for Docker monitoring
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  })
})

// Start the health monitoring server
app.listen(PORT, () => {
  console.log(`Health monitoring server running on http://localhost:${PORT}`)
  console.log(`Health endpoint available at http://localhost:${PORT}/health`)
})

import express from 'express'
import path from 'path'
import { fileURLToPath } from 'url'

// ES module __dirname equivalent
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// MEMORY BOMB: Allocate arrays to exceed 256Mi limit
console.log('Starting memory allocation...')
const memoryHog = []
for (let i = 0; i < 30; i++) { // 30 * 10MB = 300MB (exceeds 256Mi limit)
  memoryHog.push(new Array(10 * 1024 * 1024).fill('X'))
  console.log(`Allocated ${(i + 1) * 10}MB`)
}
console.log('Memory allocation complete!')

const app = express()
const PORT = 8080

// Health endpoint for Kubernetes probes
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  })
})

// Serve static React build
app.use(express.static(path.join(__dirname, 'dist')))

// SPA routing - serve index.html for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'))
})

const server = app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
  console.log(`Health endpoint: http://localhost:${PORT}/health`)
})

// Graceful shutdown handling for Kubernetes pod termination
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server gracefully...')
  server.close(() => {
    console.log('Server closed')
    process.exit(0)
  })
})

process.on('SIGINT', () => {
  console.log('SIGINT received, closing server gracefully...')
  server.close(() => {
    console.log('Server closed')
    process.exit(0)
  })
})

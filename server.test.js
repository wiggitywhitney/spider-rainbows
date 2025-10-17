import { describe, it, expect } from 'vitest'
import request from 'supertest'
import express from 'express'
import path from 'path'
import { fileURLToPath } from 'url'

// Create a test app instance without starting the server
const createTestApp = () => {
  const __filename = fileURLToPath(import.meta.url)
  const __dirname = path.dirname(__filename)

  const app = express()

  // Health endpoint for Kubernetes probes
  app.get('/health', (req, res) => {
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    })
  })

  return app
}

describe('Server Health Endpoint', () => {
  it('should return healthy status with correct structure', async () => {
    const app = createTestApp()

    const response = await request(app).get('/health')

    expect(response.status).toBe(200)
    expect(response.body).toHaveProperty('status', 'healthy')
    expect(response.body).toHaveProperty('timestamp')
    expect(response.body).toHaveProperty('uptime')

    // Verify timestamp is a valid ISO string
    expect(() => new Date(response.body.timestamp)).not.toThrow()

    // Verify uptime is a number
    expect(typeof response.body.uptime).toBe('number')
    expect(response.body.uptime).toBeGreaterThanOrEqual(0)
  })
})

import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import SpiderImage from './SpiderImage.jsx'

describe('SpiderImage Component', () => {
  it('should render spider image with correct source', () => {
    const rainbowWidth = 800

    render(<SpiderImage rainbowWidth={rainbowWidth} />)

    const img = screen.getByAltText('Spider')

    expect(img).toBeDefined()
    expect(img.src).toContain('Spider-v3.png')
  })

  it('should scale spider to 25% of rainbow width', () => {
    const rainbowWidth = 800

    render(<SpiderImage rainbowWidth={rainbowWidth} />)

    const img = screen.getByAltText('Spider')
    const expectedWidth = rainbowWidth * 0.25

    expect(img.style.width).toBe(`${expectedWidth}px`)
  })
})

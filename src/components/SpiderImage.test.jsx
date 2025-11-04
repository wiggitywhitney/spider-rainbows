import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import SpiderImage from './SpiderImage.jsx'

describe('SpiderImage Component', () => {
  it('should scale spider to 50% of rainbow width', () => {
    const rainbowWidth = 800

    render(<SpiderImage rainbowWidth={rainbowWidth} />)

    const img = screen.getByAltText('Spider')
    const expectedWidth = rainbowWidth * 0.50

    expect(img.style.width).toBe(`${expectedWidth}px`)
  })
})

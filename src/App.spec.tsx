import { expect, test } from "bun:test"
import { renderToStaticMarkup } from "react-dom/server"
import App from "./App"

test("renders starter content", () => {
  expect(renderToStaticMarkup(<App />)).toBe(
    "<main><h1>React SPA Starter template</h1><p>Build your SPA here...</p></main>",
  )
})

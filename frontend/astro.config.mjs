import cloudflare from "@astrojs/cloudflare"
import mdx from "@astrojs/mdx"
import sitemap from "@astrojs/sitemap"
import tailwind from "@astrojs/tailwind"
import vue from "@astrojs/vue"
import icon from "astro-icon"
import { defineConfig } from "astro/config"
import rehypeMathjax from "rehype-mathjax"
import remarkMath from "remark-math"

// https://astro.build/config
export default defineConfig({
  site: "https://attiladudas.com",
  integrations: [mdx(), sitemap(), tailwind(), vue({appEntrypoint: "src/vue"}), icon()],
  output: "server",
  adapter: cloudflare(),
  markdown: {
    remarkPlugins: [remarkMath],
    rehypePlugins: [rehypeMathjax],
  },
})

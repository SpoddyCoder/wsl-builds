# `dev-js`
JavaScript development environments with modern tooling and frameworks.

## Requires
* `Ubuntu 22.04` or greater

## Build Components

### `node`
* Installs Node.js LTS version with npm via NodeSource repository

### `yarn`
* Installs Yarn package manager as an alternative to npm

### `pnpm`
* Installs pnpm via Corepack (requires the `node` component first)
* npm remains available from Node.js; use pnpm for project installs when you prefer its defaults
* pnpm disables lifecycle scripts on dependencies by default (reduces install-time supply-chain risk) and supports `minimumReleaseAge` to avoid pulling packages published too recently — see [pnpm supply chain security](https://pnpm.io/supply-chain-security)

### `nvm`
* Installs Node Version Manager for managing multiple Node.js versions

### `essentials`
* Installs TypeScript compiler globally
* Installs ESLint for JavaScript/TypeScript linting
* Installs Prettier code formatter
* Installs PM2 process manager
* Installs nodemon for development workflow
* Installs serve for quick static file serving

### Framework Components

### `react`
* Installs create-vite and react-dev-tools globally

### `nextjs`
* Installs Next.js CLI globally

### `vue`
* Installs create-vue globally

### `angular`
* Installs Angular CLI globally

### `express`
* Installs Express.js generator globally

## Build Arguments
* No additional arguments for this build

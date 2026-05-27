# DeFi Protocol Frontend

A modern, responsive Next.js frontend for DeFi protocols with Web3 wallet integration, deposit/borrow management, and liquidation interfaces.

## Features

- 🎭 **Wallet Integration**: RainbowKit for wallet connection
- 💰 **Deposit Management**: Earn interest on deposits
- 🏦 **Lending**: Borrow tokens against collateral
- ⚠️ **Health Monitoring**: Real-time health factor tracking
- 🔄 **Liquidations**: Find and execute liquidations
- 📊 **Dashboard**: Complete portfolio overview
- 🎨 **Responsive Design**: Mobile-first Tailwind CSS
- 🔗 **Web3 Hooks**: Ready-to-use contract interaction hooks

## Tech Stack

- **Framework**: Next.js 14+ with App Router
- **Web3**: wagmi + viem
- **Wallet**: RainbowKit
- **Styling**: Tailwind CSS
- **State**: React Context + Zustand
- **Data Fetching**: React Query
- **Language**: TypeScript

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Wallet Connect Project ID (get one at https://cloud.walletconnect.com)

### Installation

1. Clone and enter the directory:

```bash
cd StableCoinFronEnd
```

2. Install dependencies:

```bash
npm install
```

3. Set up environment variables:

```bash
cp .env.example .env.local
```

4. Update `.env.local` with your configuration:
   - Add your Wallet Connect Project ID
   - Configure RPC URLs (Alchemy, Infura, etc.)
   - Set contract addresses for your protocol

### Running Locally

```bash
npm run dev
```

Visit `http://localhost:3000` to see the application.

## Project Structure

```
StableCoinFronEnd/
├── app/                      # Next.js App Router pages
│   ├── layout.tsx           # Root layout
│   ├── page.tsx             # Dashboard page
│   ├── providers.tsx        # Web3 providers setup
│   ├── globals.css          # Global styles
│   ├── deposit/             # Deposit page
│   ├── borrow/              # Borrow page
│   ├── liquidations/        # Liquidations page
│   └── repay/               # Repay page
├── components/
│   ├── ui/                  # Reusable UI components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   └── Input.tsx
│   ├── Header.tsx           # Navigation header
│   ├── Wallet/              # Wallet components
│   ├── Dashboard.tsx        # Dashboard view
│   ├── Deposit.tsx          # Deposit form & view
│   ├── Borrow.tsx           # Borrow form & view
│   └── Liquidations.tsx     # Liquidations view
├── config/
│   └── chains.ts            # Wagmi & chain configuration
├── contexts/
│   └── Web3Context.tsx      # Global Web3 state
├── hooks/
│   └── useContractInteractions.ts  # Web3 interaction hooks
├── types/
│   └── index.ts             # TypeScript interfaces
├── utils/
│   └── format.ts            # Formatting utilities
├── config files:
│   ├── next.config.ts
│   ├── tsconfig.json
│   ├── tailwind.config.ts
│   ├── postcss.config.js
│   └── package.json
```

## Key Components

### Dashboard (`components/Dashboard.tsx`)

Shows a complete portfolio overview with:
- Total deposits and borrows
- Interest earned
- Net APY
- Account health factor
- Deposit and borrow positions

### Deposit Form (`components/Deposit.tsx`)

Allows users to:
- Deposit tokens and earn interest
- View current deposit APY
- Track total deposits and earnings

### Borrow Form (`components/Borrow.tsx`)

Enables users to:
- Borrow tokens against collateral
- Monitor health factor
- View current borrow rates
- Track max borrowable amount

### Liquidations (`components/Liquidations.tsx`)

Displays:
- Available liquidation opportunities
- User positions at risk
- Liquidation bonuses
- Real-time health factors

## Web3 Integration

### Hooks

Ready-to-use hooks for common operations:

```typescript
// useDeposit - Deposit tokens
const { deposit, isPending } = useDeposit();
await deposit(tokenAddress, amount);

// useBorrow - Borrow tokens
const { borrow, isPending } = useBorrow();
await borrow(tokenAddress, amount);

// useWithdraw - Withdraw deposits
const { withdraw, isPending } = useWithdraw();
await withdraw(tokenAddress, amount);

// useRepay - Repay borrowed tokens
const { repay, isPending } = useRepay();
await repay(tokenAddress, amount);

// usePoolData - Fetch pool information
const { pools, isLoading, error } = usePoolData();
```

### Context

Access global Web3 state using `useWeb3`:

```typescript
const { isConnected, address, chainId, dashboardStats, userPosition } = useWeb3();
```

## Configuration

### Supported Networks

- Ethereum Mainnet
- Sepolia Testnet
- Polygon
- Arbitrum
- Optimism
- Base

### Environment Variables

```env
# Wallet Connect
NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your_project_id

# RPC URLs
NEXT_PUBLIC_RPC_MAINNET=https://...
NEXT_PUBLIC_RPC_SEPOLIA=https://...
NEXT_PUBLIC_RPC_ARBITRUM=https://...
NEXT_PUBLIC_RPC_POLYGON=https://...

# Contract Addresses
NEXT_PUBLIC_PROTOCOL_ADDRESS=0x...
NEXT_PUBLIC_TOKEN_ADDRESS=0x...
NEXT_PUBLIC_USDC_ADDRESS=0x...

# API Endpoints
NEXT_PUBLIC_API_URL=http://localhost:3000

# Feature Flags
NEXT_PUBLIC_ENABLE_ANALYTICS=false
```

## Customization

### Add New Tokens

Update the token list in `config/chains.ts` and `types/index.ts`

### Modify Colors

Edit color theme in `tailwind.config.ts`

### Update Contract ABIs

Add contract ABIs in `hooks/useContractInteractions.ts` or create separate files in a `contracts/` directory

## Build & Deploy

### Build for Production

```bash
npm run build
```

### Run Production Build Locally

```bash
npm start
```

### Deploy to Vercel

```bash
vercel deploy
```

## To-Do Items

- [ ] Implement contract interaction hooks with actual contract calls
- [ ] Add pool data fetching from subgraph or contract
- [ ] Implement user position caching with React Query
- [ ] Add transaction history view
- [ ] Implement notification system
- [ ] Add unit and integration tests
- [ ] Add dark mode support
- [ ] Implement analytics
- [ ] Add swap functionality integration
- [ ] Add governance features

## Security Considerations

⚠️ **This is a template**. Before deploying to production:

1. Audit all contract interactions
2. Implement proper error handling and user feedback
3. Add transaction confirmation dialogs
4. Implement gas estimation
5. Add rate limiting and anti-bot measures
6. Set up proper logging and monitoring
7. Review and test all Web3 interactions

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [wagmi Documentation](https://wagmi.sh/)
- [RainbowKit Documentation](https://www.rainbowkit.com/)
- [Tailwind CSS Documentation](https://tailwindcss.com/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## License

MIT

## Support

For issues and questions, please open an issue in the repository.

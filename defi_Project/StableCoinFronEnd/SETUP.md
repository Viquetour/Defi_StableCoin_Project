# Setup Guide - DeFi Protocol Frontend

## Initial Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Configuration

Create a `.env.local` file in the project root by copying the example:

```bash
cp .env.example .env.local
```

### 3. Update Environment Variables

#### Wallet Connect
1. Go to https://cloud.walletconnect.com
2. Create a new project
3. Copy your Project ID
4. Add to `.env.local`:
```env
NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your_project_id
```

#### RPC URLs
Choose a provider (Alchemy, Infura, or others):

**Alchemy (Recommended)**:
1. Go to https://www.alchemy.com/
2. Sign up and create a new app
3. Copy API keys for each network
4. Add to `.env.local`:
```env
NEXT_PUBLIC_RPC_MAINNET=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
NEXT_PUBLIC_RPC_SEPOLIA=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
NEXT_PUBLIC_RPC_ARBITRUM=https://arb-mainnet.g.alchemy.com/v2/YOUR_API_KEY
NEXT_PUBLIC_RPC_POLYGON=https://polygon-mainnet.g.alchemy.com/v2/YOUR_API_KEY
```

**Infura (Alternative)**:
1. Go to https://infura.io/
2. Create an account and a project
3. Copy your project ID
4. Add to `.env.local`:
```env
NEXT_PUBLIC_RPC_MAINNET=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
NEXT_PUBLIC_RPC_SEPOLIA=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
NEXT_PUBLIC_RPC_ARBITRUM=https://arbitrum-mainnet.infura.io/v3/YOUR_PROJECT_ID
NEXT_PUBLIC_RPC_POLYGON=https://polygon-mainnet.infura.io/v3/YOUR_PROJECT_ID
```

#### Contract Addresses
If you're using testnet (Sepolia), set test contract addresses:

```env
NEXT_PUBLIC_PROTOCOL_ADDRESS=0x0000000000000000000000000000000000000000
NEXT_PUBLIC_TOKEN_ADDRESS=0x0000000000000000000000000000000000000000
NEXT_PUBLIC_USDC_ADDRESS=0x0000000000000000000000000000000000000000
```

For production, update with your deployed contract addresses.

### 4. Local Development

Start the development server:

```bash
npm run dev
```

Open http://localhost:3000 in your browser.

## Project Customization

### Adding New Routes

1. Create a new folder in `app/` (e.g., `app/analytics/`)
2. Add a `page.tsx` file
3. Add route to navigation in `components/Header.tsx`

### Adding New Components

1. Create component in `components/` folder
2. Export from component's folder `index.ts`
3. Import where needed

Example:
```typescript
// components/Analytics/AnalyticsChart.tsx
export const AnalyticsChart: React.FC = () => {
  return <div>Chart</div>;
};

// Use in page
import { AnalyticsChart } from '@/components/Analytics/AnalyticsChart';
```

### Adding New Tokens

1. Update `TOKENS` in `lib/constants.ts`
2. Update token list in `config/chains.ts`
3. Add to token selector components

### Connecting to Smart Contracts

1. Add contract ABI to `hooks/useContractInteractions.ts`
2. Create custom hook wrapper
3. Use in component

Example:
```typescript
// Add to useContractInteractions.ts
export const useGetBalance = (tokenAddress: `0x${string}`) => {
  const { data: balance } = useReadContract({
    address: tokenAddress,
    functionName: 'balanceOf',
    abi: ERC20_ABI,
    args: [address],
  });
  
  return { balance };
};

// Use in component
const { balance } = useGetBalance(tokenAddress);
```

## Common Tasks

### Update Styling

All styling uses Tailwind CSS. Modify the configuration in `tailwind.config.ts`:

```typescript
// Example: Change primary color
colors: {
  primary: {
    50: '#f0f9ff',
    500: '#0ea5e9',  // Change this
    600: '#0284c7',
    700: '#0369a1',
    900: '#082f49',
  },
}
```

### Add Responsive Breakpoints

Tailwind responsive prefixes are available:
- `sm:` - 640px
- `md:` - 768px
- `lg:` - 1024px
- `xl:` - 1280px

Example:
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
  {/* Single column on mobile, 2 on tablet, 3 on desktop */}
</div>
```

### Implement Dark Mode

1. Add dark mode support to `tailwind.config.ts`:
```typescript
theme: {
  extend: {
    darkMode: 'class',  // or 'media'
  },
}
```

2. Use in components:
```tsx
<div className="bg-white dark:bg-gray-900">
  Dark mode enabled
</div>
```

### Add Loading States

Use the `isLoading` prop on buttons:

```tsx
<Button isLoading={isPending}>
  Submit
</Button>
```

## Build & Deploy

### Local Build Test

```bash
npm run build
npm start
```

### Deploy to Vercel

1. Push to GitHub
2. Connect repository to Vercel
3. Add environment variables in Vercel settings
4. Deploy

### Deploy to Other Platforms

**Netlify**:
```bash
npm run build
# Deploy `out` folder
```

**Traditional Hosting**:
```bash
npm run build
# Upload `out` folder to web server
```

## Troubleshooting

### Issue: Wallet not connecting
- Ensure `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID` is set
- Check that RPC URLs are correct
- Verify browser wallet extension is installed

### Issue: Network errors
- Check RPC URL in `.env.local`
- Verify internet connection
- Try switching networks in wallet

### Issue: Build errors
- Clear `.next` folder: `rm -rf .next`
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`
- Run type check: `npm run type-check`

### Issue: Styling not applying
- Ensure Tailwind CSS is imported in `globals.css`
- Check `tailwind.config.ts` content paths
- Clear browser cache

## Next Steps

1. **Connect to Backend**: Set up API integration
2. **Add Tests**: Implement unit and integration tests
3. **Deploy**: Choose a hosting provider
4. **Monitor**: Set up analytics and error tracking
5. **Optimize**: Implement performance optimizations

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [wagmi Documentation](https://wagmi.sh/)
- [Ethereum Development](https://ethereum.org/developers)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

## Support

For issues and questions:
1. Check README.md
2. Review component examples
3. Check environment variables
4. Open an issue on GitHub

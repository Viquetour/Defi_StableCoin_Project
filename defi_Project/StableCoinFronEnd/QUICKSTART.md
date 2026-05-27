# Quick Start Guide

## Getting Started in 5 Minutes

### 1. Installation

```bash
# Install dependencies
npm install

# Setup environment
cp .env.example .env.local

# Edit .env.local with your Wallet Connect ID and RPC URLs
```

### 2. Run the Application

```bash
npm run dev
```

Visit http://localhost:3000

### 3. Connect Wallet

Click the "Connect Wallet" button in the header to connect using RainbowKit.

## Common Code Snippets

### Using Contract Interaction Hooks

#### Deposit Tokens

```typescript
import { useDeposit } from '@/hooks/useContractInteractions';
import { parseUnits } from 'viem';

export function DepositExample() {
  const { deposit, isPending } = useDeposit();

  const handleDeposit = async () => {
    const amount = parseUnits('100', 6); // 100 USDC (6 decimals)
    await deposit('0xUsdc...', amount);
  };

  return (
    <button onClick={handleDeposit} disabled={isPending}>
      {isPending ? 'Depositing...' : 'Deposit'}
    </button>
  );
}
```

#### Borrow Tokens

```typescript
import { useBorrow } from '@/hooks/useContractInteractions';

export function BorrowExample() {
  const { borrow, isPending } = useBorrow();

  const handleBorrow = async () => {
    const amount = BigInt(50) * BigInt(10) ** BigInt(18); // 50 tokens
    await borrow('0xToken...', amount);
  };

  return <button onClick={handleBorrow}>Borrow</button>;
}
```

### Accessing Web3 Context

```typescript
import { useWeb3 } from '@/contexts/Web3Context';

export function MyComponent() {
  const { isConnected, address, chainId, dashboardStats } = useWeb3();

  if (!isConnected) {
    return <p>Please connect your wallet</p>;
  }

  return (
    <div>
      <p>Wallet: {address}</p>
      <p>Chain ID: {chainId}</p>
      <p>Total Deposits: {dashboardStats?.totalDeposits.toString()}</p>
    </div>
  );
}
```

### Using Format Utilities

```typescript
import {
  formatAddress,
  formatCurrency,
  formatPercentage,
  getHealthFactorColor,
} from '@/utils/format';

// Format address: 0x1234...5678
console.log(formatAddress('0x123456789abcdef'));

// Format currency: 10.50
console.log(formatCurrency(BigInt('10500000000000000000'), 18));

// Format percentage: 5.50%
console.log(formatPercentage(0.055));

// Get health factor color
console.log(getHealthFactorColor(1.2)); // 'text-warning-500'
```

### Creating Custom Components

```typescript
import { Card, CardHeader, CardBody } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';

export function CustomForm() {
  return (
    <Card>
      <CardHeader>
        <h2 className="text-2xl font-bold">My Form</h2>
      </CardHeader>

      <CardBody>
        <Input label="Amount" type="number" placeholder="Enter amount" />
        <Button fullWidth>Submit</Button>
      </CardBody>
    </Card>
  );
}
```

### Calling API Endpoints

```typescript
import { api } from '@/lib/api-client';

export async function fetchPools() {
  const response = await api.pools.getAll();

  if (response.success) {
    console.log('Pools:', response.data);
  } else {
    console.error('Error:', response.error);
  }
}

export async function getUserPosition(address: string) {
  const response = await api.user.getPosition(address);

  if (response.success) {
    return response.data;
  }
}
```

### Handle Transaction Confirmation

```typescript
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';

export function DepositWithConfirmation() {
  const { writeContract, data: hash } = useWriteContract();
  const { data: receipt, isLoading: isConfirming } = useWaitForTransactionReceipt({
    hash,
  });

  return (
    <div>
      <button onClick={() => writeContract({
        address: '0x...',
        functionName: 'deposit',
        abi: [...],
        args: [amount],
      })}>
        Deposit
      </button>

      {receipt && <p>Transaction confirmed!</p>}
      {isConfirming && <p>Confirming...</p>}
    </div>
  );
}
```

## Project Structure Navigation

```
StableCoinFronEnd/
├── app/                           # Routes
│   ├── page.tsx                   # Homepage
│   ├── deposit/page.tsx           # Deposit page
│   ├── borrow/page.tsx            # Borrow page
│   └── layout.tsx                 # Root layout

├── components/                    # React components
│   ├── Dashboard.tsx              # Main dashboard
│   ├── Deposit.tsx                # Deposit component
│   ├── ui/                        # UI components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   └── Input.tsx

├── config/
│   ├── chains.ts                  # Wagmi config
│   └── site.ts                    # Site config

├── contexts/
│   └── Web3Context.tsx            # Global Web3 state

├── hooks/                         # Custom React hooks
│   ├── useContractInteractions.ts # Contract hooks
│   └── useTransactionHistory.ts   # History hook

├── types/
│   └── index.ts                   # TypeScript types

├── utils/
│   └── format.ts                  # Format utilities

└── lib/
    ├── constants.ts               # Constants
    └── api-client.ts              # API client
```

## Common Issues & Solutions

### Issue: Wallet Not Connecting
**Solution**: Ensure `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID` is set in `.env.local`

### Issue: RPC Errors
**Solution**: Check RPC URLs in `.env.local` and verify API keys

### Issue: Contract Calls Failing
**Solution**: Verify contract addresses and ABIs are correct

### Issue: Styling Looks Off
**Solution**: Clear cache: `rm -rf .next` and `npm run dev`

## Next Steps

1. Connect your backend API
2. Add smart contract ABIs
3. Update contract addresses
4. Implement transaction history
5. Add notifications system
6. Deploy to Vercel

## Need Help?

- 📖 Read [README.md](./README.md)
- ⚙️ Check [SETUP.md](./SETUP.md)
- 💬 Create an issue on GitHub
